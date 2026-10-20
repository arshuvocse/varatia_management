using System.Data;
using System.Text.Json;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace PromotionWeb.Services;

public sealed class SubscriptionService : ISubscriptionService
{
    private readonly SqlConnectionFactory _connectionFactory;
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<SubscriptionService> _logger;

    private static bool _schemaEnsured;

    public SubscriptionService(
        SqlConnectionFactory connectionFactory,
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<SubscriptionService> logger)
    {
        _connectionFactory = connectionFactory;
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
    }

    private string GetStoreId() =>
        _configuration["SslCommerz:StoreId"]?.Trim() ?? "amarthikanaalive";

    private string GetStorePassword() =>
        _configuration["SslCommerz:StorePassword"]?.Trim() ?? "6A27E77A0A4AC55109";

    private bool IsSandbox() =>
        bool.TryParse(_configuration["SslCommerz:Sandbox"], out var sb) && sb;

    private string InitiateUrl => IsSandbox()
        ? "https://sandbox.sslcommerz.com/gwprocess/v4/api.php"
        : "https://securepay.sslcommerz.com/gwprocess/v4/api.php";

    private async Task EnsureSchemaAsync(SqlConnection connection, CancellationToken cancellationToken)
    {
        if (_schemaEnsured) return;

        const string sql = """
            IF OBJECT_ID(N'dbo.SubscriptionPlans', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.SubscriptionPlans (
                    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SubscriptionPlans PRIMARY KEY,
                    ServiceCode NVARCHAR(50) NOT NULL CONSTRAINT UQ_SubscriptionPlans_ServiceCode UNIQUE,
                    Title NVARCHAR(200) NOT NULL,
                    TargetRole NVARCHAR(50) NOT NULL,
                    Description NVARCHAR(500) NOT NULL,
                    Fee DECIMAL(18,2) NOT NULL,
                    DeliveryDays INT NOT NULL CONSTRAINT DF_SubscriptionPlans_DeliveryDays DEFAULT (7),
                    IsActive BIT NOT NULL CONSTRAINT DF_SubscriptionPlans_IsActive DEFAULT (1),
                    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_SubscriptionPlans_UpdatedAt DEFAULT SYSUTCDATETIME()
                );

                EXEC(N'INSERT INTO dbo.SubscriptionPlans (ServiceCode, Title, TargetRole, Description, Fee, DeliveryDays, IsActive) VALUES
                    (N''find_flat'', N''বাসা / ফ্ল্যাট অনুসন্ধান সাবস্ক্রিপশন'', N''Tenant'', N''অ্যাডমিন টিম আপনার পছন্দ ও বাজেট অনুযায়ী নির্ধারিত সময়ের মধ্যে ভেরিফাইড বাসা খুঁজে দিবে।'', 500.00, 7, 1),
                    (N''find_tenant'', N''ভাড়াটিয়া ম্যাচিং সাবস্ক্রিপশন'', N''Owner'', N''আপনার খালি ফ্ল্যাট বা ইউনিটের জন্য যাচাইকৃত জেনুইন ভাড়াটিয়া খুঁজে দেওয়ার গ্যারান্টি সার্ভিস।'', 500.00, 7, 1),
                    (N''find_tutor'', N''টিউটর / গৃহশিক্ষক ম্যাচিং সাবস্ক্রিপশন'', N''Student'', N''অভিভাবক ও শিক্ষার্থীদের জন্য কাঙ্ক্ষিত ক্লাসের অভিজ্ঞ গৃহশিক্ষক ম্যাচিং সার্ভিস।'', 300.00, 10, 1),
                    (N''find_student'', N''টিউশন / শিক্ষার্থী সন্ধান সাবস্ক্রিপশন'', N''Teacher'', N''শিক্ষক ও টিউটরদের জন্য পছন্দসই লোকেশনে উপযুক্ত শিক্ষার্থী ও টিউশন ম্যাচিং সার্ভিস।'', 400.00, 15, 1)');
            END;

            IF OBJECT_ID(N'dbo.UserSubscriptions', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.UserSubscriptions (
                    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_UserSubscriptions PRIMARY KEY,
                    UserId NVARCHAR(100) NOT NULL,
                    ServiceCode NVARCHAR(50) NOT NULL,
                    Title NVARCHAR(200) NOT NULL,
                    Amount DECIMAL(18,2) NOT NULL,
                    TransactionId NVARCHAR(100) NOT NULL CONSTRAINT UQ_UserSubscriptions_TransactionId UNIQUE,
                    PaymentStatus NVARCHAR(50) NOT NULL CONSTRAINT DF_UserSubscriptions_PaymentStatus DEFAULT ('pending'),
                    SubscriptionStatus NVARCHAR(50) NOT NULL CONSTRAINT DF_UserSubscriptions_SubscriptionStatus DEFAULT ('in_progress'),
                    UserRequirements NVARCHAR(1000) NULL,
                    DeliveryDays INT NOT NULL,
                    SubscribedAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserSubscriptions_SubscribedAt DEFAULT SYSUTCDATETIME(),
                    DeadlineAt DATETIME2(0) NOT NULL,
                    FulfilledAt DATETIME2(0) NULL,
                    AdminNotes NVARCHAR(1000) NULL,
                    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserSubscriptions_CreatedAt DEFAULT SYSUTCDATETIME(),
                    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserSubscriptions_UpdatedAt DEFAULT SYSUTCDATETIME()
                );
            END;
            """;

        try
        {
            await connection.ExecuteAsync(new CommandDefinition(sql, cancellationToken: cancellationToken));
            _schemaEnsured = true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed ensuring subscription schema.");
            throw;
        }
    }

    public async Task<IReadOnlyList<SubscriptionPlanDto>> GetPlansAsync(
        bool activeOnly = false,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSchemaAsync(connection, cancellationToken);

        var sql = """
            SELECT
                Id,
                ServiceCode,
                Title,
                TargetRole,
                Description,
                Fee,
                DeliveryDays,
                IsActive
            FROM dbo.SubscriptionPlans
            """ + (activeOnly ? " WHERE IsActive = 1" : "") + " ORDER BY Id ASC;";

        var rows = await connection.QueryAsync<dynamic>(new CommandDefinition(sql, cancellationToken: cancellationToken));
        return rows.Select(r => new SubscriptionPlanDto
        {
            Id = Convert.ToInt32(r.Id),
            ServiceCode = Convert.ToString(r.ServiceCode) ?? "",
            Title = Convert.ToString(r.Title) ?? "",
            TargetRole = Convert.ToString(r.TargetRole) ?? "",
            Description = Convert.ToString(r.Description) ?? "",
            Fee = Convert.ToDecimal(r.Fee),
            DeliveryDays = Convert.ToInt32(r.DeliveryDays),
            IsActive = Convert.ToBoolean(r.IsActive)
        }).ToList();
    }

    public async Task<SubscriptionPlanDto?> GetPlanByCodeAsync(
        string serviceCode,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(serviceCode)) return null;

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSchemaAsync(connection, cancellationToken);

        const string sql = """
            SELECT TOP (1)
                Id,
                ServiceCode,
                Title,
                TargetRole,
                Description,
                Fee,
                DeliveryDays,
                IsActive
            FROM dbo.SubscriptionPlans
            WHERE LOWER(ServiceCode) = LOWER(@serviceCode);
            """;

        var r = await connection.QuerySingleOrDefaultAsync<dynamic>(
            new CommandDefinition(sql, new { serviceCode = serviceCode.Trim() }, cancellationToken: cancellationToken));

        if (r is null) return null;

        return new SubscriptionPlanDto
        {
            Id = Convert.ToInt32(r.Id),
            ServiceCode = Convert.ToString(r.ServiceCode) ?? "",
            Title = Convert.ToString(r.Title) ?? "",
            TargetRole = Convert.ToString(r.TargetRole) ?? "",
            Description = Convert.ToString(r.Description) ?? "",
            Fee = Convert.ToDecimal(r.Fee),
            DeliveryDays = Convert.ToInt32(r.DeliveryDays),
            IsActive = Convert.ToBoolean(r.IsActive)
        };
    }

    public async Task<bool> UpdatePlanAsync(
        UpdateSubscriptionPlanRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.ServiceCode)) return false;

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSchemaAsync(connection, cancellationToken);

        const string sql = """
            UPDATE dbo.SubscriptionPlans
            SET Title = @Title,
                Description = @Description,
                Fee = @Fee,
                DeliveryDays = @DeliveryDays,
                IsActive = @IsActive,
                UpdatedAt = SYSUTCDATETIME()
            WHERE LOWER(ServiceCode) = LOWER(@ServiceCode);
            """;

        var affected = await connection.ExecuteAsync(new CommandDefinition(
            sql,
            new
            {
                ServiceCode = request.ServiceCode.Trim(),
                Title = request.Title.Trim(),
                Description = request.Description.Trim(),
                Fee = Math.Max(0, request.Fee),
                DeliveryDays = Math.Max(1, request.DeliveryDays),
                IsActive = request.IsActive
            },
            cancellationToken: cancellationToken));

        return affected > 0;
    }

    public async Task<InitiatePaymentResponse> InitiateSubscriptionPaymentAsync(
        string userId,
        string serviceCode,
        string? requirements,
        string baseUrl,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("User ID is required.", nameof(userId));
        }
        if (string.IsNullOrWhiteSpace(serviceCode))
        {
            throw new ArgumentException("Service code is required.", nameof(serviceCode));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSchemaAsync(connection, cancellationToken);

        var plan = await GetPlanByCodeAsync(serviceCode, cancellationToken);
        if (plan is null || !plan.IsActive)
        {
            throw new InvalidOperationException("Requested subscription plan is not available or active.");
        }

        Guid? parsedGuid = Guid.TryParse(userId.Trim(), out var g) ? g : null;
        const string userSql = """
            SELECT TOP (1) Id, FullName, PhoneNumber
            FROM dbo.Users
            WHERE (@ParsedGuid IS NOT NULL AND Id = @ParsedGuid)
               OR PhoneNumber = @UserIdString;
            """;

        var user = await connection.QuerySingleOrDefaultAsync<dynamic>(
            new CommandDefinition(
                userSql,
                new { ParsedGuid = parsedGuid, UserIdString = userId.Trim() },
                cancellationToken: cancellationToken));

        string userName = user?.FullName != null && !string.IsNullOrWhiteSpace(Convert.ToString(user.FullName))
            ? Convert.ToString(user.FullName)!
            : "Amar Thikana User";

        string userPhone = user?.PhoneNumber != null && !string.IsNullOrWhiteSpace(Convert.ToString(user.PhoneNumber))
            ? Convert.ToString(user.PhoneNumber)!
            : (userId.Trim().StartsWith("01") ? userId.Trim() : "01700000000");

        var transactionId = $"SUB-{Guid.NewGuid():N}".Substring(0, 20).ToUpper();
        var deadline = DateTime.UtcNow.AddDays(plan.DeliveryDays);

        // 1. Insert into UserSubscriptions
        const string insertSubSql = """
            INSERT INTO dbo.UserSubscriptions
                (UserId, ServiceCode, Title, Amount, TransactionId, PaymentStatus, SubscriptionStatus, UserRequirements, DeliveryDays, SubscribedAt, DeadlineAt)
            VALUES
                (@UserId, @ServiceCode, @Title, @Amount, @TransactionId, 'pending', 'in_progress', @UserRequirements, @DeliveryDays, SYSUTCDATETIME(), @DeadlineAt);
            """;

        await connection.ExecuteAsync(new CommandDefinition(
            insertSubSql,
            new
            {
                UserId = userId.Trim(),
                ServiceCode = plan.ServiceCode,
                Title = plan.Title,
                Amount = plan.Fee,
                TransactionId = transactionId,
                UserRequirements = requirements?.Trim(),
                DeliveryDays = plan.DeliveryDays,
                DeadlineAt = deadline
            },
            cancellationToken: cancellationToken));

        // 2. Insert into MonthlyPayments
        const string insertPaymentSql = """
            INSERT INTO dbo.MonthlyPayments (UserId, TransactionId, Amount, Status, MonthYear)
            VALUES (@UserId, @TransactionId, @Amount, 'pending', 'SUB');
            """;

        await connection.ExecuteAsync(new CommandDefinition(
            insertPaymentSql,
            new
            {
                UserId = userId.Trim(),
                TransactionId = transactionId,
                Amount = plan.Fee
            },
            cancellationToken: cancellationToken));

        // 3. Initiate SSLCommerz Session
        var values = new Dictionary<string, string>
        {
            { "store_id", GetStoreId() },
            { "store_passwd", GetStorePassword() },
            { "total_amount", plan.Fee.ToString("F2") },
            { "currency", "BDT" },
            { "tran_id", transactionId },
            { "success_url", $"{baseUrl}/api/payments/success?tran_id={transactionId}" },
            { "fail_url", $"{baseUrl}/api/payments/fail?tran_id={transactionId}" },
            { "cancel_url", $"{baseUrl}/api/payments/cancel?tran_id={transactionId}" },
            { "ipn_url", $"{baseUrl}/api/payments/ipn?tran_id={transactionId}" },
            { "cus_name", userName },
            { "cus_email", "subscription@amarthikana.com" },
            { "cus_phone", userPhone },
            { "cus_add1", "Dhaka" },
            { "cus_city", "Dhaka" },
            { "cus_country", "Bangladesh" },
            { "shipping_method", "NO" },
            { "product_name", plan.Title },
            { "product_category", "Subscription" },
            { "product_profile", "general" }
        };

        var content = new FormUrlEncodedContent(values);
        var response = await _httpClient.PostAsync(InitiateUrl, content, cancellationToken);
        response.EnsureSuccessStatusCode();

        var responseString = await response.Content.ReadAsStringAsync(cancellationToken);
        using var document = JsonDocument.Parse(responseString);
        var root = document.RootElement;

        var status = root.GetProperty("status").GetString();
        if (string.Equals(status, "SUCCESS", StringComparison.OrdinalIgnoreCase))
        {
            return new InitiatePaymentResponse
            {
                GatewayPageUrl = root.GetProperty("GatewayPageURL").GetString() ?? string.Empty,
                TransactionId = transactionId
            };
        }

        var failedReason = root.TryGetProperty("failedreason", out var fr) ? fr.GetString() : "Unknown error";
        throw new InvalidOperationException($"Could not initiate SSLCommerz payment: {failedReason}");
    }

    public async Task<IReadOnlyList<UserSubscriptionDto>> GetUserSubscriptionsAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId)) return Array.Empty<UserSubscriptionDto>();

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSchemaAsync(connection, cancellationToken);

        const string sql = """
            SELECT
                s.Id,
                s.UserId,
                COALESCE(u.FullName, s.UserId) AS UserName,
                COALESCE(u.PhoneNumber, s.UserId) AS UserPhone,
                COALESCE(u.Role, '') AS UserRole,
                s.ServiceCode,
                s.Title,
                s.Amount,
                s.TransactionId,
                s.PaymentStatus,
                s.SubscriptionStatus,
                s.UserRequirements,
                s.DeliveryDays,
                s.SubscribedAt,
                s.DeadlineAt,
                s.FulfilledAt,
                s.AdminNotes,
                s.CreatedAt
            FROM dbo.UserSubscriptions s
            LEFT JOIN dbo.Users u ON (u.Id = TRY_CAST(s.UserId AS uniqueidentifier) OR u.PhoneNumber = s.UserId)
            WHERE s.UserId = @userId
               OR u.PhoneNumber = @userId
               OR u.Id = TRY_CAST(@userId AS uniqueidentifier)
            ORDER BY s.CreatedAt DESC;
            """;

        var rows = await connection.QueryAsync<dynamic>(
            new CommandDefinition(sql, new { userId = userId.Trim() }, cancellationToken: cancellationToken));

        var now = DateTime.UtcNow;

        return rows.Select(r =>
        {
            DateTime deadline = Convert.ToDateTime(r.DeadlineAt);
            int remainingDays = Math.Max(0, (deadline - now).Days);
            string subStatus = Convert.ToString(r.SubscriptionStatus) ?? "in_progress";
            bool isExpired = now > deadline && string.Equals(subStatus, "in_progress", StringComparison.OrdinalIgnoreCase);

            return new UserSubscriptionDto
            {
                Id = Convert.ToInt32(r.Id),
                UserId = Convert.ToString(r.UserId) ?? "",
                UserName = Convert.ToString(r.UserName) ?? "",
                UserPhone = Convert.ToString(r.UserPhone) ?? "",
                UserRole = Convert.ToString(r.UserRole) ?? "",
                ServiceCode = Convert.ToString(r.ServiceCode) ?? "",
                Title = Convert.ToString(r.Title) ?? "",
                Amount = Convert.ToDecimal(r.Amount),
                TransactionId = Convert.ToString(r.TransactionId) ?? "",
                PaymentStatus = Convert.ToString(r.PaymentStatus) ?? "pending",
                SubscriptionStatus = isExpired ? "expired" : subStatus,
                UserRequirements = r.UserRequirements != null ? Convert.ToString(r.UserRequirements) : null,
                DeliveryDays = Convert.ToInt32(r.DeliveryDays),
                SubscribedAt = Convert.ToDateTime(r.SubscribedAt),
                DeadlineAt = deadline,
                RemainingDays = remainingDays,
                IsExpired = isExpired,
                FulfilledAt = r.FulfilledAt != null ? Convert.ToDateTime(r.FulfilledAt) : null,
                AdminNotes = r.AdminNotes != null ? Convert.ToString(r.AdminNotes) : null,
                CreatedAt = Convert.ToDateTime(r.CreatedAt)
            };
        }).ToList();
    }

    public async Task<IReadOnlyList<UserSubscriptionDto>> GetAllSubscriptionsAsync(
        string? search = null,
        string? status = null,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSchemaAsync(connection, cancellationToken);

        var searchTrimmed = string.IsNullOrWhiteSpace(search) ? null : $"%{search.Trim()}%";
        var statusFilter = string.IsNullOrWhiteSpace(status) || status.Equals("all", StringComparison.OrdinalIgnoreCase)
            ? null
            : status.Trim().ToLowerInvariant();

        const string sql = """
            SELECT
                s.Id,
                s.UserId,
                COALESCE(u.FullName, s.UserId) AS UserName,
                COALESCE(u.PhoneNumber, s.UserId) AS UserPhone,
                COALESCE(u.Role, '') AS UserRole,
                s.ServiceCode,
                s.Title,
                s.Amount,
                s.TransactionId,
                s.PaymentStatus,
                s.SubscriptionStatus,
                s.UserRequirements,
                s.DeliveryDays,
                s.SubscribedAt,
                s.DeadlineAt,
                s.FulfilledAt,
                s.AdminNotes,
                s.CreatedAt
            FROM dbo.UserSubscriptions s
            LEFT JOIN dbo.Users u ON (u.Id = TRY_CAST(s.UserId AS uniqueidentifier) OR u.PhoneNumber = s.UserId)
            WHERE (
                @Search IS NULL
                OR s.TransactionId LIKE @Search
                OR s.UserId LIKE @Search
                OR s.Title LIKE @Search
                OR s.UserRequirements LIKE @Search
                OR u.FullName LIKE @Search
                OR u.PhoneNumber LIKE @Search
            )
            AND (
                @Status IS NULL
                OR LOWER(s.SubscriptionStatus) = @Status
                OR LOWER(s.PaymentStatus) = @Status
            )
            ORDER BY s.CreatedAt DESC;
            """;

        var rows = await connection.QueryAsync<dynamic>(
            new CommandDefinition(sql, new { Search = searchTrimmed, Status = statusFilter }, cancellationToken: cancellationToken));

        var now = DateTime.UtcNow;

        return rows.Select(r =>
        {
            DateTime deadline = Convert.ToDateTime(r.DeadlineAt);
            int remainingDays = Math.Max(0, (deadline - now).Days);
            string subStatus = Convert.ToString(r.SubscriptionStatus) ?? "in_progress";
            bool isExpired = now > deadline && string.Equals(subStatus, "in_progress", StringComparison.OrdinalIgnoreCase);

            return new UserSubscriptionDto
            {
                Id = Convert.ToInt32(r.Id),
                UserId = Convert.ToString(r.UserId) ?? "",
                UserName = Convert.ToString(r.UserName) ?? "",
                UserPhone = Convert.ToString(r.UserPhone) ?? "",
                UserRole = Convert.ToString(r.UserRole) ?? "",
                ServiceCode = Convert.ToString(r.ServiceCode) ?? "",
                Title = Convert.ToString(r.Title) ?? "",
                Amount = Convert.ToDecimal(r.Amount),
                TransactionId = Convert.ToString(r.TransactionId) ?? "",
                PaymentStatus = Convert.ToString(r.PaymentStatus) ?? "pending",
                SubscriptionStatus = isExpired ? "expired" : subStatus,
                UserRequirements = r.UserRequirements != null ? Convert.ToString(r.UserRequirements) : null,
                DeliveryDays = Convert.ToInt32(r.DeliveryDays),
                SubscribedAt = Convert.ToDateTime(r.SubscribedAt),
                DeadlineAt = deadline,
                RemainingDays = remainingDays,
                IsExpired = isExpired,
                FulfilledAt = r.FulfilledAt != null ? Convert.ToDateTime(r.FulfilledAt) : null,
                AdminNotes = r.AdminNotes != null ? Convert.ToString(r.AdminNotes) : null,
                CreatedAt = Convert.ToDateTime(r.CreatedAt)
            };
        }).ToList();
    }

    public async Task<bool> UpdateSubscriptionStatusAsync(
        int subscriptionId,
        string status,
        string? notes,
        CancellationToken cancellationToken = default)
    {
        if (subscriptionId <= 0) return false;

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSchemaAsync(connection, cancellationToken);

        var isFulfilled = string.Equals(status, "matched", StringComparison.OrdinalIgnoreCase) ||
                          string.Equals(status, "fulfilled", StringComparison.OrdinalIgnoreCase);

        const string sql = """
            UPDATE dbo.UserSubscriptions
            SET SubscriptionStatus = @Status,
                AdminNotes = COALESCE(@Notes, AdminNotes),
                FulfilledAt = CASE WHEN @IsFulfilled = 1 THEN SYSUTCDATETIME() ELSE FulfilledAt END,
                UpdatedAt = SYSUTCDATETIME()
            WHERE Id = @Id;
            """;

        var affected = await connection.ExecuteAsync(new CommandDefinition(
            sql,
            new
            {
                Id = subscriptionId,
                Status = status.Trim().ToLowerInvariant(),
                Notes = notes?.Trim(),
                IsFulfilled = isFulfilled ? 1 : 0
            },
            cancellationToken: cancellationToken));

        return affected > 0;
    }
}
