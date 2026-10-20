using System.Data;
using System.Text.Json;
using System.Text.Json.Serialization;
using Dapper;
using Microsoft.Data.SqlClient;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class MonthlyPaymentService : IMonthlyPaymentService
{
    private readonly SqlConnectionFactory _connectionFactory;
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly IPostingEntitlementService _postingEntitlementService;
    private const string StoreId = "amarthikanaalive";
    private const string StorePassword = "6A27E77A0A4AC55109";
    private const string InitiateUrl = "https://securepay.sslcommerz.com/gwprocess/v4/api.php";
    private const string ValidateUrl = "https://securepay.sslcommerz.com/validator/api/validationserverAPI.php";
    private const decimal MonthlyServiceCharge = 50.00m;

    public MonthlyPaymentService(
        SqlConnectionFactory connectionFactory,
        HttpClient httpClient,
        IConfiguration configuration,
        IPostingEntitlementService postingEntitlementService)
    {
        _connectionFactory = connectionFactory;
        _httpClient = httpClient;
        _configuration = configuration;
        _postingEntitlementService = postingEntitlementService;
    }

    public async Task<PaymentStatusResponse> GetPaymentStatusAsync(string userId, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Valid user id is required.", nameof(userId));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        try
        {
            return await connection.QuerySingleAsync<PaymentStatusResponse>(
                new CommandDefinition(
                    "dbo.sp_MonthlyPayment_GetStatus",
                    new { UserId = parsedUserId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken));
        }
        catch (SqlException exception) when (exception.Number == 51040)
        {
            throw new InvalidOperationException("User not found.", exception);
        }
    }

    public async Task<MonthlyPaymentHistoryResponse> GetPaymentHistoryAsync(
        string userId,
        int year,
        CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Valid user id is required.", nameof(userId));
        }

        if (year is < 2000 or > 2100)
        {
            throw new ArgumentException(
                "Year must be between 2000 and 2100.",
                nameof(year));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        try
        {
            var rows = (await connection.QueryAsync<MonthlyPaymentHistoryRow>(
                new CommandDefinition(
                    "dbo.sp_MonthlyPayment_GetHistory",
                    new { UserId = parsedUserId, Year = year },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))).AsList();

            var firstRow = rows.First();
            return new MonthlyPaymentHistoryResponse
            {
                UserId = firstRow.UserId,
                Role = firstRow.Role,
                Year = firstRow.Year,
                Months = rows.Select(row => new MonthlyPaymentHistoryItem
                {
                    MonthNumber = row.MonthNumber,
                    PaymentMonth = row.PaymentMonth,
                    PaymentStatus = row.PaymentStatus,
                    Amount = row.Amount,
                    PaidAt = row.PaidAt,
                    AccessAllowed = row.AccessAllowed,
                }).ToArray(),
            };
        }
        catch (SqlException exception) when (exception.Number == 51040)
        {
            throw new InvalidOperationException("User not found.", exception);
        }
    }

    public async Task<InitiatePaymentResponse> InitiatePaymentAsync(string userId, string baseUrl, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Valid user id is required.", nameof(userId));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        // Fetch User Info
        var user = await connection.QuerySingleOrDefaultAsync<UserLookup>(
            new CommandDefinition(
                """
                SELECT FullName, PhoneNumber
                FROM dbo.Users
                WHERE Id = @UserId;
                """,
                new { UserId = parsedUserId },
                cancellationToken: cancellationToken));

        if (user is null)
        {
            throw new InvalidOperationException("User not found.");
        }

        var transactionId = $"TXN-{Guid.NewGuid().ToString("N").Substring(0, 16).ToUpper()}";
        var monthYear = DateTime.UtcNow.AddHours(6).ToString("yyyy-MM");
        const decimal amount = MonthlyServiceCharge;

        // Save pending payment record to database
        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                INSERT INTO dbo.MonthlyPayments (UserId, TransactionId, Amount, Status, MonthYear)
                VALUES (@UserId, @TransactionId, @Amount, 'pending', @MonthYear);
                """,
                new
                {
                    UserId = userId,
                    TransactionId = transactionId,
                    Amount = amount,
                    MonthYear = monthYear
                },
                cancellationToken: cancellationToken));

        // Prepare SSLCommerz Payload
        var values = new Dictionary<string, string>
        {
            { "store_id", GetStoreId() },
            { "store_passwd", GetStorePassword() },
            { "total_amount", amount.ToString("F2") },
            { "currency", "BDT" },
            { "tran_id", transactionId },
            { "success_url", $"{baseUrl}/api/payments/success?tran_id={transactionId}" },
            { "fail_url", $"{baseUrl}/api/payments/fail?tran_id={transactionId}" },
            { "cancel_url", $"{baseUrl}/api/payments/cancel?tran_id={transactionId}" },
            { "ipn_url", $"{baseUrl}/api/payments/ipn?tran_id={transactionId}" },
            { "cus_name", string.IsNullOrWhiteSpace(user.FullName) ? "Amar Thikana User" : user.FullName },
            { "cus_email", "payment@amarthikana.com" },
            { "cus_phone", string.IsNullOrWhiteSpace(user.PhoneNumber) ? "01700000000" : user.PhoneNumber },
            { "cus_add1", "Dhaka" },
            { "cus_city", "Dhaka" },
            { "cus_country", "Bangladesh" },
            { "shipping_method", "NO" },
            { "product_name", "Monthly Service Charge" },
            { "product_category", "Service" },
            { "product_profile", "general" }
        };

        var content = new FormUrlEncodedContent(values);
        var response = await _httpClient.PostAsync(InitiateUrl, content, cancellationToken);
        response.EnsureSuccessStatusCode();

        var responseString = await response.Content.ReadAsStringAsync(cancellationToken);
        using var document = JsonDocument.Parse(responseString);
        var root = document.RootElement;

        var status = root.GetProperty("status").GetString();
        if (!string.Equals(status, "SUCCESS", StringComparison.OrdinalIgnoreCase))
        {
            var failedReason = root.TryGetProperty("failedreason", out var reasonProp) ? reasonProp.GetString() : "Unknown SSLCommerz error";
            throw new InvalidOperationException($"SSLCommerz initiation failed: {failedReason}");
        }

        var gatewayUrl = root.GetProperty("GatewayPageURL").GetString();
        if (string.IsNullOrWhiteSpace(gatewayUrl))
        {
            throw new InvalidOperationException("GatewayPageURL is missing in SSLCommerz response.");
        }

        return new InitiatePaymentResponse
        {
            GatewayPageUrl = gatewayUrl,
            TransactionId = transactionId
        };
    }

    public async Task<InitiatePaymentResponse> InitiatePostingPaymentAsync(
        string userId,
        decimal amount,
        string baseUrl,
        CancellationToken cancellationToken)
    {
        if (amount < 100.00m)
        {
            throw new ArgumentException("Posting credit payment must be at least BDT 100.00.", nameof(amount));
        }

        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("Valid user id is required.", nameof(userId));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var user = await connection.QuerySingleOrDefaultAsync<UserLookup>(
            new CommandDefinition(
                """
                SELECT FullName, PhoneNumber
                FROM dbo.Users
                WHERE Id = TRY_CAST(@userId AS uniqueidentifier)
                   OR PhoneNumber = @userId;
                """,
                new { userId },
                cancellationToken: cancellationToken));

        var transactionId = $"POST-{Guid.NewGuid():N}".Substring(0, 20).ToUpper();

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                INSERT INTO dbo.MonthlyPayments (UserId, TransactionId, Amount, Status, MonthYear)
                VALUES (@userId, @transactionId, @amount, 'pending', 'POSTING');
                """,
                new
                {
                    userId,
                    transactionId,
                    amount
                },
                cancellationToken: cancellationToken));

        var values = new Dictionary<string, string>
        {
            { "store_id", GetStoreId() },
            { "store_passwd", GetStorePassword() },
            { "total_amount", amount.ToString("F2") },
            { "currency", "BDT" },
            { "tran_id", transactionId },
            { "success_url", $"{baseUrl}/api/payments/success?tran_id={transactionId}" },
            { "fail_url", $"{baseUrl}/api/payments/fail?tran_id={transactionId}" },
            { "cancel_url", $"{baseUrl}/api/payments/cancel?tran_id={transactionId}" },
            { "ipn_url", $"{baseUrl}/api/payments/ipn?tran_id={transactionId}" },
            { "cus_name", string.IsNullOrWhiteSpace(user?.FullName) ? "Amar Thikana User" : user.FullName },
            { "cus_email", "payment@amarthikana.com" },
            { "cus_phone", string.IsNullOrWhiteSpace(user?.PhoneNumber) ? "01700000000" : user.PhoneNumber },
            { "cus_add1", "Dhaka" },
            { "cus_city", "Dhaka" },
            { "cus_country", "Bangladesh" },
            { "shipping_method", "NO" },
            { "product_name", "Amar Thikanaa Post Creation Fee" },
            { "product_category", "Service" },
            { "product_profile", "general" },
            { "value_b", "PostingCredit" }
        };

        var content = new FormUrlEncodedContent(values);
        var response = await _httpClient.PostAsync(InitiateUrl, content, cancellationToken);
        var rawResponse = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"SSLCOMMERZ gateway returned status {response.StatusCode}: {rawResponse}");
        }

        using var jsonDoc = JsonDocument.Parse(rawResponse);
        var root = jsonDoc.RootElement;
        var status = root.TryGetProperty("status", out var s) ? s.GetString() : null;

        if (string.Equals(status, "SUCCESS", StringComparison.OrdinalIgnoreCase))
        {
            var gatewayPageUrl = root.GetProperty("GatewayPageURL").GetString() ?? "";
            return new InitiatePaymentResponse
            {
                GatewayPageUrl = gatewayPageUrl,
                TransactionId = transactionId
            };
        }

        var failedReason = root.TryGetProperty("failedreason", out var fr) ? fr.GetString() : "Unknown error";
        throw new InvalidOperationException($"Could not initiate SSLCommerz payment: {failedReason}");
    }

    private static bool _schemaEnsured;

    private async Task EnsureSchemaAsync(SqlConnection connection, CancellationToken cancellationToken)
    {
        if (_schemaEnsured) return;

        const string sql = """
            IF OBJECT_ID(N'dbo.tbl_CompanySettings', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.tbl_CompanySettings (
                    Id INT NOT NULL CONSTRAINT PK_tbl_CompanySettings PRIMARY KEY,
                    CommissionRate DECIMAL(5,2) NOT NULL DEFAULT (1),
                    CashbackRate DECIMAL(5,2) NOT NULL DEFAULT (2),
                    DeliveryCharge DECIMAL(18,2) NOT NULL DEFAULT (60),
                    SupportPhone NVARCHAR(30) NOT NULL DEFAULT (N'09678-123456'),
                    PaymentGateway NVARCHAR(100) NOT NULL DEFAULT (N'SSLCommerz'),
                    RegistrationFee DECIMAL(18,2) NOT NULL CONSTRAINT DF_tbl_CompanySettings_RegistrationFee DEFAULT (50.00),
                    IsRegistrationFeeActive BIT NOT NULL CONSTRAINT DF_tbl_CompanySettings_IsRegistrationFeeActive DEFAULT (1),
                    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_CompanySettings_UpdatedAt DEFAULT SYSUTCDATETIME()
                );
                EXEC(N'INSERT INTO dbo.tbl_CompanySettings (Id, CommissionRate, CashbackRate, DeliveryCharge, SupportPhone, PaymentGateway, RegistrationFee, IsRegistrationFeeActive) VALUES (1, 1, 2, 60, N''09678-123456'', N''SSLCommerz'', 50.00, 1)');
            END
            ELSE
            BEGIN
                IF COL_LENGTH(N'dbo.tbl_CompanySettings', N'RegistrationFee') IS NULL
                BEGIN
                    EXEC(N'ALTER TABLE dbo.tbl_CompanySettings ADD RegistrationFee DECIMAL(18,2) NOT NULL CONSTRAINT DF_tbl_CompanySettings_RegistrationFee DEFAULT (50.00)');
                END;
                IF COL_LENGTH(N'dbo.tbl_CompanySettings', N'IsRegistrationFeeActive') IS NULL
                BEGIN
                    EXEC(N'ALTER TABLE dbo.tbl_CompanySettings ADD IsRegistrationFeeActive BIT NOT NULL CONSTRAINT DF_tbl_CompanySettings_IsRegistrationFeeActive DEFAULT (1)');
                END;
            END;

            IF COL_LENGTH(N'dbo.Users', N'IsRegistrationFeePaid') IS NULL
            BEGIN
                EXEC(N'ALTER TABLE dbo.Users ADD IsRegistrationFeePaid BIT NOT NULL CONSTRAINT DF_Users_IsRegistrationFeePaid DEFAULT (0)');
            END;
            IF COL_LENGTH(N'dbo.Users', N'RegistrationFeeTransactionId') IS NULL
            BEGIN
                EXEC(N'ALTER TABLE dbo.Users ADD RegistrationFeeTransactionId NVARCHAR(100) NULL');
            END;
            IF COL_LENGTH(N'dbo.Users', N'RegistrationFeePaidAt') IS NULL
            BEGIN
                EXEC(N'ALTER TABLE dbo.Users ADD RegistrationFeePaidAt DATETIME2 NULL');
            END;

            IF EXISTS (
                SELECT 1 FROM sys.columns 
                WHERE object_id = OBJECT_ID(N'dbo.MonthlyPayments') 
                  AND name = N'MonthYear' 
                  AND max_length < 40
            )
            BEGIN
                EXEC(N'ALTER TABLE dbo.MonthlyPayments ALTER COLUMN MonthYear NVARCHAR(20) NOT NULL');
            END;
            """;

        try
        {
            await connection.ExecuteAsync(new CommandDefinition(sql, cancellationToken: cancellationToken));
            _schemaEnsured = true;
        }
        catch
        {
            // Ignore if concurrently initialized
        }
    }

    private async Task<(decimal Fee, bool IsActive)> GetRegistrationFeeSettingsAsync(
        SqlConnection connection,
        CancellationToken cancellationToken)
    {
        await EnsureSchemaAsync(connection, cancellationToken);

        const string sql = """
            SELECT TOP (1)
                COALESCE(RegistrationFee, 50.00) AS Fee,
                COALESCE(IsRegistrationFeeActive, CAST(1 AS BIT)) AS IsActive
            FROM dbo.tbl_CompanySettings
            WHERE Id = 1;
            """;

        try
        {
            var result = await connection.QuerySingleOrDefaultAsync<dynamic>(
                new CommandDefinition(sql, cancellationToken: cancellationToken));
            if (result != null)
            {
                decimal fee = Convert.ToDecimal(result.Fee);
                bool isActive = Convert.ToBoolean(result.IsActive);
                return (fee, isActive);
            }
        }
        catch
        {
            // fallback
        }

        return (50.00m, true);
    }

    public async Task<RegistrationFeeInfoResponse> GetRegistrationFeeInfoAsync(CancellationToken cancellationToken)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var (fee, isActive) = await GetRegistrationFeeSettingsAsync(connection, cancellationToken);
        return new RegistrationFeeInfoResponse
        {
            Fee = fee,
            IsActive = isActive,
            Currency = "BDT"
        };
    }

    public async Task<RegistrationFeeStatusResponse> GetRegistrationFeeStatusAsync(
        string userId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("Valid user id is required.", nameof(userId));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var (fee, isActive) = await GetRegistrationFeeSettingsAsync(connection, cancellationToken);

        const string userSql = """
            SELECT TOP (1)
                Id,
                IsRegistrationFeePaid,
                RegistrationFeeTransactionId,
                RegistrationFeePaidAt
            FROM dbo.Users
            WHERE Id = TRY_CAST(@userId AS uniqueidentifier)
               OR PhoneNumber = @userId;
            """;

        var user = await connection.QuerySingleOrDefaultAsync<dynamic>(
            new CommandDefinition(userSql, new { userId = userId.Trim() }, cancellationToken: cancellationToken));

        if (user is null)
        {
            return new RegistrationFeeStatusResponse
            {
                UserId = userId,
                IsPaid = false,
                IsRequired = isActive,
                Fee = fee,
                Currency = "BDT"
            };
        }

        bool isPaid = user.IsRegistrationFeePaid != null && Convert.ToBoolean(user.IsRegistrationFeePaid);
        string? tranId = user.RegistrationFeeTransactionId as string;
        DateTime? paidAt = user.RegistrationFeePaidAt != null ? Convert.ToDateTime(user.RegistrationFeePaidAt) : null;

        return new RegistrationFeeStatusResponse
        {
            UserId = userId,
            IsPaid = isPaid,
            IsRequired = isActive && !isPaid,
            Fee = fee,
            Currency = "BDT",
            TransactionId = tranId,
            PaidAt = paidAt
        };
    }

    public async Task<InitiatePaymentResponse> InitiateRegistrationFeePaymentAsync(
        string userId,
        string baseUrl,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("Valid user id is required.", nameof(userId));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var (fee, isActive) = await GetRegistrationFeeSettingsAsync(connection, cancellationToken);

        var user = await connection.QuerySingleOrDefaultAsync<UserLookup>(
            new CommandDefinition(
                """
                SELECT FullName, PhoneNumber
                FROM dbo.Users
                WHERE Id = TRY_CAST(@userId AS uniqueidentifier)
                   OR PhoneNumber = @userId;
                """,
                new { userId = userId.Trim() },
                cancellationToken: cancellationToken));

        if (user is null)
        {
            throw new InvalidOperationException("User not found.");
        }

        var transactionId = $"REG-{Guid.NewGuid():N}".Substring(0, 20).ToUpper();

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                INSERT INTO dbo.MonthlyPayments (UserId, TransactionId, Amount, Status, MonthYear)
                VALUES (@userId, @transactionId, @amount, 'pending', 'REG');
                """,
                new
                {
                    userId = userId.Trim(),
                    transactionId,
                    amount = fee
                },
                cancellationToken: cancellationToken));

        var values = new Dictionary<string, string>
        {
            { "store_id", GetStoreId() },
            { "store_passwd", GetStorePassword() },
            { "total_amount", fee.ToString("F2") },
            { "currency", "BDT" },
            { "tran_id", transactionId },
            { "success_url", $"{baseUrl}/api/payments/success?tran_id={transactionId}" },
            { "fail_url", $"{baseUrl}/api/payments/fail?tran_id={transactionId}" },
            { "cancel_url", $"{baseUrl}/api/payments/cancel?tran_id={transactionId}" },
            { "ipn_url", $"{baseUrl}/api/payments/ipn?tran_id={transactionId}" },
            { "cus_name", string.IsNullOrWhiteSpace(user.FullName) ? "Amar Thikana User" : user.FullName },
            { "cus_email", "payment@amarthikana.com" },
            { "cus_phone", string.IsNullOrWhiteSpace(user.PhoneNumber) ? "01700000000" : user.PhoneNumber },
            { "cus_add1", "Dhaka" },
            { "cus_city", "Dhaka" },
            { "cus_country", "Bangladesh" },
            { "shipping_method", "NO" },
            { "product_name", "User Registration Fee" },
            { "product_category", "Registration" },
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

    public async Task<UserPaymentHistoryResponse> GetUserPaymentHistoryAsync(
        string userId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("Valid user id is required.", nameof(userId));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSchemaAsync(connection, cancellationToken);

        var user = await connection.QuerySingleOrDefaultAsync<UserLookup>(
            new CommandDefinition(
                """
                SELECT Id, FullName, PhoneNumber
                FROM dbo.Users
                WHERE Id = TRY_CAST(@userId AS uniqueidentifier)
                   OR PhoneNumber = @userId;
                """,
                new { userId = userId.Trim() },
                cancellationToken: cancellationToken));

        var userGuidStr = user?.Id?.ToString() ?? "";
        var userName = user?.FullName ?? "";
        var userPhone = user?.PhoneNumber ?? "";

        const string paymentsSql = """
            SELECT
                Id,
                TransactionId,
                Amount,
                Status,
                MonthYear,
                PaymentDate,
                CreatedOn
            FROM dbo.MonthlyPayments
            WHERE UserId = @userId
               OR (@userGuidStr != '' AND UserId = @userGuidStr)
               OR (@userPhone != '' AND UserId = @userPhone)
               OR (@userName != '' AND UserId = @userName)
            ORDER BY CreatedOn DESC;
            """;

        var paymentRows = (await connection.QueryAsync<dynamic>(
            new CommandDefinition(
                paymentsSql,
                new { userId = userId.Trim(), userGuidStr, userPhone, userName },
                cancellationToken: cancellationToken))).ToList();

        const string rentSql = """
            SELECT
                Id,
                PropertyId,
                TenantName,
                MonthLabel,
                Amount,
                Status,
                PaidOn
            FROM dbo.RentPayments
            WHERE (@userName != '' AND TenantName = @userName)
               OR (@userPhone != '' AND TenantName = @userPhone)
               OR TenantName = @userId
            ORDER BY Id DESC;
            """;

        var rentRows = (await connection.QueryAsync<dynamic>(
            new CommandDefinition(
                rentSql,
                new { userName, userPhone, userId = userId.Trim() },
                cancellationToken: cancellationToken))).ToList();

        var historyItems = new List<UserPaymentHistoryItem>();

        foreach (var p in paymentRows)
        {
            string monthYear = p.MonthYear ?? "";
            string tranId = p.TransactionId ?? "";
            string pType = "Monthly Charge";
            string title = $"মাসিক চার্জ ({monthYear})";

            if (string.Equals(monthYear, "REG", StringComparison.OrdinalIgnoreCase) ||
                tranId.StartsWith("REG-", StringComparison.OrdinalIgnoreCase))
            {
                pType = "Registration Fee";
                title = "রেজিস্ট্রেশন ফি";
            }
            else if (string.Equals(monthYear, "POSTING", StringComparison.OrdinalIgnoreCase) ||
                     tranId.StartsWith("POST-", StringComparison.OrdinalIgnoreCase))
            {
                pType = "Posting Credits";
                title = "পোস্টিং ক্রেডিট পেমেন্ট";
            }
            else if (string.Equals(monthYear, "SUB", StringComparison.OrdinalIgnoreCase) ||
                     tranId.StartsWith("SUB-", StringComparison.OrdinalIgnoreCase))
            {
                pType = "Subscription Service";
                title = "ম্যাচমেকিং সাবস্ক্রিপশন সার্ভিস";
            }

            historyItems.Add(new UserPaymentHistoryItem
            {
                Id = (int)p.Id,
                TransactionId = tranId,
                PaymentType = pType,
                Title = title,
                Amount = (decimal)p.Amount,
                Status = (string)(p.Status ?? "pending"),
                MonthYear = monthYear,
                Gateway = "SSLCommerz",
                PaymentDate = p.PaymentDate as DateTime?,
                CreatedOn = (DateTime)p.CreatedOn
            });
        }

        foreach (var r in rentRows)
        {
            historyItems.Add(new UserPaymentHistoryItem
            {
                Id = (int)r.Id + 100000,
                TransactionId = $"RENT-{r.Id}",
                PaymentType = "Rent Payment",
                Title = $"ভাড়া পরিশোধ ({r.MonthLabel ?? ""})",
                Amount = (decimal)r.Amount,
                Status = (string)(r.Status ?? "Paid"),
                MonthYear = (string)(r.MonthLabel ?? ""),
                Gateway = "Rent",
                PaymentDate = r.PaidOn as DateTime?,
                CreatedOn = (r.PaidOn as DateTime?) ?? DateTime.UtcNow
            });
        }

        var sorted = historyItems.OrderByDescending(x => x.PaymentDate ?? x.CreatedOn).ToList();
        var totalPaid = sorted.Where(x => string.Equals(x.Status, "success", StringComparison.OrdinalIgnoreCase) ||
                                          string.Equals(x.Status, "Paid", StringComparison.OrdinalIgnoreCase))
                              .Sum(x => x.Amount);

        return new UserPaymentHistoryResponse
        {
            UserId = userId,
            TotalPaid = totalPaid,
            Payments = sorted
        };
    }

    public async Task<MonthlyPaymentCallbackResult> ProcessCallbackAsync(
        MonthlyPaymentCallbackData callbackData,
        CancellationToken cancellationToken)
    {
        var transactionId = callbackData.TransactionId?.Trim();
        if (string.IsNullOrWhiteSpace(transactionId))
        {
            return new MonthlyPaymentCallbackResult
            {
                Success = false,
                Status = "failed",
                Message = "Payment callback is missing transaction id."
            };
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var payment = await connection.QuerySingleOrDefaultAsync<MonthlyPaymentAttempt>(
            new CommandDefinition(
                """
                SELECT TOP (1)
                    UserId,
                    TransactionId,
                    Amount,
                    Status,
                    MonthYear
                FROM dbo.MonthlyPayments
                WHERE TransactionId = @TransactionId;
                """,
                new { TransactionId = transactionId },
                cancellationToken: cancellationToken));

        if (payment is null)
        {
            return new MonthlyPaymentCallbackResult
            {
                Success = false,
                Status = "failed",
                Message = "Payment transaction was not found."
            };
        }

        if (string.Equals(payment.Status, "success", StringComparison.OrdinalIgnoreCase))
        {
            return new MonthlyPaymentCallbackResult
            {
                Success = true,
                AlreadyProcessed = true,
                Status = "success",
                Message = "Payment was already verified."
            };
        }

        var callbackStatus = callbackData.Status?.Trim();
        if (string.Equals(callbackStatus, "CANCEL", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(callbackStatus, "CANCELLED", StringComparison.OrdinalIgnoreCase))
        {
            await MarkPaymentAsync(connection, transactionId, "cancelled", null, cancellationToken);
            if (string.Equals(payment.MonthYear, "SUB", StringComparison.OrdinalIgnoreCase) ||
                payment.TransactionId.StartsWith("SUB-", StringComparison.OrdinalIgnoreCase))
            {
                await connection.ExecuteAsync(new CommandDefinition(
                    "UPDATE dbo.UserSubscriptions SET PaymentStatus = 'cancelled', SubscriptionStatus = 'cancelled', UpdatedAt = SYSUTCDATETIME() WHERE TransactionId = @TransactionId;",
                    new { TransactionId = transactionId },
                    cancellationToken: cancellationToken));
            }

            return new MonthlyPaymentCallbackResult
            {
                Success = false,
                Status = "cancelled",
                Message = "Payment was cancelled."
            };
        }

        if (string.Equals(callbackStatus, "FAILED", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(callbackStatus, "FAIL", StringComparison.OrdinalIgnoreCase))
        {
            await MarkPaymentAsync(connection, transactionId, "failed", null, cancellationToken);
            if (string.Equals(payment.MonthYear, "SUB", StringComparison.OrdinalIgnoreCase) ||
                payment.TransactionId.StartsWith("SUB-", StringComparison.OrdinalIgnoreCase))
            {
                await connection.ExecuteAsync(new CommandDefinition(
                    "UPDATE dbo.UserSubscriptions SET PaymentStatus = 'failed', SubscriptionStatus = 'cancelled', UpdatedAt = SYSUTCDATETIME() WHERE TransactionId = @TransactionId;",
                    new { TransactionId = transactionId },
                    cancellationToken: cancellationToken));
            }

            return new MonthlyPaymentCallbackResult
            {
                Success = false,
                Status = "failed",
                Message = "Payment failed."
            };
        }

        var validationId = callbackData.ValidationId?.Trim();
        if (string.IsNullOrWhiteSpace(validationId))
        {
            await MarkPaymentAsync(connection, transactionId, "failed", null, cancellationToken);
            return new MonthlyPaymentCallbackResult
            {
                Success = false,
                Status = "failed",
                Message = "Payment callback is missing validation id."
            };
        }

        var validation = await ValidatePaymentAsync(validationId, cancellationToken);
        var validTransaction = string.Equals(
            validation.TransactionId,
            payment.TransactionId,
            StringComparison.Ordinal);
        var validAmount = validation.Amount == payment.Amount;
        var validCurrency = string.Equals(validation.Currency, "BDT", StringComparison.OrdinalIgnoreCase);

        if (!validation.IsValid || !validTransaction || !validAmount || !validCurrency || validation.RiskLevel != 0)
        {
            await MarkPaymentAsync(connection, transactionId, "failed", null, cancellationToken);
            return new MonthlyPaymentCallbackResult
            {
                Success = false,
                Status = "failed",
                Message = validation.RiskLevel == 1
                    ? "Payment is marked as risky and requires manual review."
                    : validation.Error ?? "Payment could not be verified."
            };
        }

        await MarkPaymentAsync(
            connection,
            transactionId,
            "success",
            DateTime.UtcNow.AddHours(6),
            cancellationToken);

        if (string.Equals(payment.MonthYear, "POSTING", StringComparison.OrdinalIgnoreCase))
        {
            await _postingEntitlementService.GrantPostingCreditsAsync(
                payment.UserId,
                payment.Amount,
                transactionId,
                cancellationToken);
        }

        if (string.Equals(payment.MonthYear, "REG", StringComparison.OrdinalIgnoreCase) ||
            payment.TransactionId.StartsWith("REG-", StringComparison.OrdinalIgnoreCase))
        {
            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    UPDATE dbo.Users
                    SET IsRegistrationFeePaid = 1,
                        RegistrationFeeTransactionId = @TransactionId,
                        RegistrationFeePaidAt = SYSUTCDATETIME()
                    WHERE Id = TRY_CAST(@UserId AS uniqueidentifier)
                       OR PhoneNumber = @UserId;
                    """,
                    new
                    {
                        TransactionId = transactionId,
                        UserId = payment.UserId
                    },
                    cancellationToken: cancellationToken));
        }

        if (string.Equals(payment.MonthYear, "SUB", StringComparison.OrdinalIgnoreCase) ||
            payment.TransactionId.StartsWith("SUB-", StringComparison.OrdinalIgnoreCase))
        {
            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    UPDATE dbo.UserSubscriptions
                    SET PaymentStatus = 'success',
                        SubscriptionStatus = 'in_progress',
                        SubscribedAt = SYSUTCDATETIME(),
                        DeadlineAt = DATEADD(DAY, DeliveryDays, SYSUTCDATETIME()),
                        UpdatedAt = SYSUTCDATETIME()
                    WHERE TransactionId = @TransactionId;
                    """,
                    new { TransactionId = transactionId },
                    cancellationToken: cancellationToken));
        }

        return new MonthlyPaymentCallbackResult
        {
            Success = true,
            Status = "success",
            Message = "Payment verified."
        };
    }

    private async Task MarkPaymentAsync(
        SqlConnection connection,
        string transactionId,
        string status,
        DateTime? paymentDate,
        CancellationToken cancellationToken)
    {
        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.MonthlyPayments
                SET Status = @Status,
                    PaymentDate = @PaymentDate,
                    UpdatedOn = SYSUTCDATETIME()
                WHERE TransactionId = @TransactionId;
                """,
                new
                {
                    Status = status,
                    PaymentDate = paymentDate,
                    TransactionId = transactionId
                },
                cancellationToken: cancellationToken));
    }

    private async Task<SslCommerzValidationResult> ValidatePaymentAsync(
        string validationId,
        CancellationToken cancellationToken)
    {
        var url = Microsoft.AspNetCore.WebUtilities.QueryHelpers.AddQueryString(
            ValidateUrl,
            new Dictionary<string, string?>
            {
                ["val_id"] = validationId,
                ["store_id"] = GetStoreId(),
                ["store_passwd"] = GetStorePassword(),
                ["v"] = "1",
                ["format"] = "json"
            });

        try
        {
            using var response = await _httpClient.GetAsync(url, cancellationToken);
            var raw = await response.Content.ReadAsStringAsync(cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return new SslCommerzValidationResult
                {
                    Error = $"SSLCommerz validation failed with HTTP {(int)response.StatusCode}.",
                    RawResponse = raw
                };
            }

            using var document = JsonDocument.Parse(raw);
            var root = document.RootElement;
            var status = GetString(root, "status");

            return new SslCommerzValidationResult
            {
                IsValid = status is "VALID" or "VALIDATED",
                Status = status,
                TransactionId = GetString(root, "tran_id"),
                ValidationId = GetString(root, "val_id"),
                Amount = GetDecimal(root, "amount"),
                Currency = GetString(root, "currency"),
                RiskLevel = GetInt(root, "risk_level"),
                RawResponse = raw
            };
        }
        catch (Exception exception) when (exception is HttpRequestException or JsonException or TaskCanceledException)
        {
            return new SslCommerzValidationResult
            {
                Error = "Payment validation failed.",
                RawResponse = exception.Message
            };
        }
    }

    private string GetStoreId() =>
        _configuration["SslCommerz:StoreId"]?.Trim() is { Length: > 0 } configured
            ? configured
            : StoreId;

    private string GetStorePassword() =>
        _configuration["SslCommerz:StorePassword"]?.Trim() is { Length: > 0 } configured
            ? configured
            : StorePassword;

    private static string? GetString(JsonElement root, string name) =>
        root.TryGetProperty(name, out var value) ? value.ToString() : null;

    private static decimal GetDecimal(JsonElement root, string name) =>
        root.TryGetProperty(name, out var value)
        && decimal.TryParse(value.ToString(), System.Globalization.NumberStyles.Number, System.Globalization.CultureInfo.InvariantCulture, out var parsed)
            ? parsed
            : 0m;

    private static int GetInt(JsonElement root, string name) =>
        root.TryGetProperty(name, out var value) && int.TryParse(value.ToString(), out var parsed)
            ? parsed
            : 0;

    private sealed class UserLookup
    {
        public Guid? Id { get; init; }
        public string FullName { get; init; } = string.Empty;
        public string PhoneNumber { get; init; } = string.Empty;
    }

    private sealed class MonthlyPaymentAttempt
    {
        public string UserId { get; init; } = string.Empty;
        public string TransactionId { get; init; } = string.Empty;
        public decimal Amount { get; init; }
        public string Status { get; init; } = string.Empty;
        public string MonthYear { get; init; } = string.Empty;
    }

    private sealed class SslCommerzValidationResult
    {
        public bool IsValid { get; init; }
        public string? Status { get; init; }
        public string? TransactionId { get; init; }
        public string? ValidationId { get; init; }
        public decimal Amount { get; init; }
        public string? Currency { get; init; }
        public int RiskLevel { get; init; }
        public string? Error { get; init; }
        public string? RawResponse { get; init; }
    }

    private sealed class MonthlyPaymentHistoryRow
    {
        public string UserId { get; init; } = string.Empty;
        public string Role { get; init; } = string.Empty;
        public int Year { get; init; }
        public int MonthNumber { get; init; }
        public string PaymentMonth { get; init; } = string.Empty;
        public string PaymentStatus { get; init; } = string.Empty;
        public decimal Amount { get; init; }
        public DateTime? PaidAt { get; init; }
        public bool AccessAllowed { get; init; }
    }
}
