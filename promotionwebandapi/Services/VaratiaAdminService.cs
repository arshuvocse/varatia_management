using Dapper;
using Microsoft.Data.SqlClient;
using OrderProcessAPI.Configuration;
using PromotionWeb.Models;

namespace PromotionWeb.Services;

public sealed class VaratiaAdminService : IVaratiaAdminService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public VaratiaAdminService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<AdminTeachLearnViewModel> GetTeachLearnDataAsync(
        string? postType = null,
        string? verification = null,
        string? search = null,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        const string statsSql = """
            SELECT
                COUNT(1) AS TotalPosts,
                SUM(CASE WHEN PostType = 'tutor' THEN 1 ELSE 0 END) AS TutorPostsCount,
                SUM(CASE WHEN PostType = 'request' THEN 1 ELSE 0 END) AS RequestPostsCount,
                SUM(CASE WHEN IsVerified = 1 THEN 1 ELSE 0 END) AS VerifiedPostsCount
            FROM dbo.TenantTutorPosts;
            """;

        var stats = await connection.QuerySingleOrDefaultAsync<dynamic>(
            new CommandDefinition(statsSql, cancellationToken: cancellationToken));

        int totalPosts = stats?.TotalPosts != null ? (int)stats.TotalPosts : 0;
        int tutorPostsCount = stats?.TutorPostsCount != null ? (int)stats.TutorPostsCount : 0;
        int requestPostsCount = stats?.RequestPostsCount != null ? (int)stats.RequestPostsCount : 0;
        int verifiedPostsCount = stats?.VerifiedPostsCount != null ? (int)stats.VerifiedPostsCount : 0;

        var normalizedType = string.IsNullOrWhiteSpace(postType) || postType.Equals("all", StringComparison.OrdinalIgnoreCase)
            ? null
            : postType.Trim().ToLowerInvariant();

        bool? isVerifiedFilter = null;
        if (!string.IsNullOrWhiteSpace(verification) && !verification.Equals("all", StringComparison.OrdinalIgnoreCase))
        {
            if (verification.Equals("verified", StringComparison.OrdinalIgnoreCase))
            {
                isVerifiedFilter = true;
            }
            else if (verification.Equals("unverified", StringComparison.OrdinalIgnoreCase))
            {
                isVerifiedFilter = false;
            }
        }

        var searchTrimmed = string.IsNullOrWhiteSpace(search) ? null : search.Trim();
        var searchPattern = searchTrimmed is null ? null : $"%{searchTrimmed}%";

        const string querySql = """
            SELECT
                Id,
                TenantId,
                PostType,
                Name,
                RoleBn,
                RoleEn,
                SubjectBn,
                SubjectEn,
                AreaBn,
                AreaEn,
                PriceBn,
                PriceEn,
                AvailabilityBn,
                AvailabilityEn,
                BadgeBn,
                BadgeEn,
                Rating,
                Phone,
                DescriptionBn,
                DescriptionEn,
                ExperienceBn,
                ExperienceEn,
                FulfillmentStatus,
                Remarks,
                IsVerified,
                CreatedAt,
                UpdatedAt
            FROM dbo.TenantTutorPosts
            WHERE (@PostType IS NULL OR LOWER(PostType) = @PostType)
              AND (@IsVerified IS NULL OR IsVerified = @IsVerified)
              AND (
                  @SearchPattern IS NULL
                  OR Name LIKE @SearchPattern
                  OR Phone LIKE @SearchPattern
                  OR SubjectBn LIKE @SearchPattern
                  OR SubjectEn LIKE @SearchPattern
                  OR AreaBn LIKE @SearchPattern
                  OR AreaEn LIKE @SearchPattern
                  OR Id LIKE @SearchPattern
              )
            ORDER BY CreatedAt DESC, Id DESC;
            """;

        var rows = (await connection.QueryAsync<AdminTutorPostItemViewModel>(
            new CommandDefinition(
                querySql,
                new
                {
                    PostType = normalizedType,
                    IsVerified = isVerifiedFilter,
                    SearchPattern = searchPattern
                },
                cancellationToken: cancellationToken))).ToList();

        return new AdminTeachLearnViewModel
        {
            Posts = rows,
            TotalPosts = totalPosts,
            TutorPostsCount = tutorPostsCount,
            RequestPostsCount = requestPostsCount,
            VerifiedPostsCount = verifiedPostsCount,
            FilterType = postType,
            FilterVerification = verification,
            SearchQuery = search
        };
    }

    public async Task<bool> ToggleTutorPostVerificationAsync(
        string postId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(postId)) return false;

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        const string updateSql = """
            UPDATE dbo.TenantTutorPosts
            SET IsVerified = CASE WHEN IsVerified = 1 THEN 0 ELSE 1 END,
                UpdatedAt = SYSUTCDATETIME()
            WHERE Id = @PostId;
            """;

        var affected = await connection.ExecuteAsync(
            new CommandDefinition(updateSql, new { PostId = postId.Trim() }, cancellationToken: cancellationToken));

        return affected > 0;
    }

    public async Task<bool> DeleteTutorPostAsync(
        string postId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(postId)) return false;

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        const string deleteSql = "DELETE FROM dbo.TenantTutorPosts WHERE Id = @PostId;";

        var affected = await connection.ExecuteAsync(
            new CommandDefinition(deleteSql, new { PostId = postId.Trim() }, cancellationToken: cancellationToken));

        return affected > 0;
    }

    public async Task<AdminVaratiaManagementViewModel> GetVaratiaManagementDataAsync(
        string? search = null,
        string? statusFilter = null,
        string? tab = null,
        string? category = null,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureVaratiaSchemaAsync(connection, cancellationToken);

        var searchTrimmed = string.IsNullOrWhiteSpace(search) ? null : search.Trim();
        var searchPattern = searchTrimmed is null ? null : $"%{searchTrimmed}%";

        var normalizedStatus = string.IsNullOrWhiteSpace(statusFilter) || statusFilter.Equals("all", StringComparison.OrdinalIgnoreCase)
            ? null
            : statusFilter.Trim().ToLowerInvariant();

        var normalizedCategory = string.IsNullOrWhiteSpace(category) || category.Equals("all", StringComparison.OrdinalIgnoreCase)
            ? null
            : category.Trim().ToLowerInvariant();

        // 0. General Posts query
        const string generalPostsSql = """
            SELECT TOP 150
                gp.Id,
                gp.UserId,
                COALESCE(u.FullName, gp.UserId) AS UserName,
                COALESCE(u.PhoneNumber, '') AS UserPhone,
                COALESCE(u.Role, '') AS UserRole,
                gp.Category,
                gp.TenantType,
                gp.Title,
                gp.Price,
                gp.Advance,
                gp.UtilityIncluded,
                gp.DivisionId,
                gp.AreaId,
                gp.FullAddress,
                gp.Description,
                gp.MediaInfo,
                COALESCE(e.FreePostsUsed, 0) AS FreePostsUsed,
                COALESCE(e.PaidCreditsBalance, 0) AS PaidCreditsBalance,
                gp.Status,
                COALESCE(gp.IsVerified, 0) AS IsVerified,
                gp.CreatedOn,
                gp.UpdatedOn
            FROM dbo.GeneralPosts gp
            LEFT JOIN dbo.Users u ON (u.Id = TRY_CAST(gp.UserId AS uniqueidentifier) OR u.PhoneNumber = gp.UserId)
            LEFT JOIN dbo.UserPostingEntitlements e ON e.UserId = gp.UserId
            WHERE (@Category IS NULL OR LOWER(gp.Category) = @Category)
              AND (@Status IS NULL OR LOWER(gp.Status) = @Status)
              AND (
                  @SearchPattern IS NULL
                  OR gp.Title LIKE @SearchPattern
                  OR gp.FullAddress LIKE @SearchPattern
                  OR gp.Category LIKE @SearchPattern
                  OR u.FullName LIKE @SearchPattern
                  OR u.PhoneNumber LIKE @SearchPattern
                  OR gp.UserId LIKE @SearchPattern
              )
            ORDER BY gp.CreatedOn DESC;
            """;

        var generalPostsRaw = (await connection.QueryAsync<dynamic>(
            new CommandDefinition(generalPostsSql, new { Category = normalizedCategory, Status = normalizedStatus, SearchPattern = searchPattern }, cancellationToken: cancellationToken))).ToList();

        var generalPosts = generalPostsRaw.Select(r =>
        {
            string? mediaInfo = r.MediaInfo != null ? Convert.ToString(r.MediaInfo) : null;
            int mediaCount = 0;
            if (!string.IsNullOrWhiteSpace(mediaInfo))
            {
                try
                {
                    using var doc = System.Text.Json.JsonDocument.Parse(mediaInfo);
                    if (doc.RootElement.ValueKind == System.Text.Json.JsonValueKind.Array)
                    {
                        mediaCount = doc.RootElement.GetArrayLength();
                    }
                }
                catch
                {
                    mediaCount = 1;
                }
            }

            return new AdminGeneralPostItemViewModel
            {
                Id = Convert.ToInt32(r.Id),
                UserId = Convert.ToString(r.UserId) ?? "",
                UserName = Convert.ToString(r.UserName) ?? "",
                UserPhone = Convert.ToString(r.UserPhone) ?? "",
                UserRole = Convert.ToString(r.UserRole) ?? "",
                Category = Convert.ToString(r.Category) ?? "",
                TenantType = r.TenantType != null ? Convert.ToString(r.TenantType) : null,
                Title = Convert.ToString(r.Title) ?? "",
                Price = Convert.ToDecimal(r.Price),
                Advance = r.Advance != null ? Convert.ToDecimal(r.Advance) : null,
                UtilityIncluded = Convert.ToBoolean(r.UtilityIncluded),
                DivisionId = Convert.ToString(r.DivisionId) ?? "",
                AreaId = Convert.ToString(r.AreaId) ?? "",
                FullAddress = r.FullAddress != null ? Convert.ToString(r.FullAddress) : null,
                Description = r.Description != null ? Convert.ToString(r.Description) : null,
                MediaInfo = mediaInfo,
                MediaCount = mediaCount,
                FreePostsUsed = Convert.ToInt32(r.FreePostsUsed),
                PaidCreditsBalance = Convert.ToInt32(r.PaidCreditsBalance),
                Status = Convert.ToString(r.Status) ?? "active",
                IsVerified = Convert.ToBoolean(r.IsVerified),
                CreatedOn = Convert.ToDateTime(r.CreatedOn),
                UpdatedOn = Convert.ToDateTime(r.UpdatedOn)
            };
        }).ToList();

        // 1. Tenants query
        const string tenantsSql = """
            SELECT
                t.Id,
                t.Name,
                t.Phone,
                t.Nid,
                t.PropertyId,
                COALESCE(p.Name, '') AS PropertyName,
                COALESCE(b.Name, '') AS BuildingName,
                COALESCE(p.Location, '') AS Location,
                COALESCE(p.MonthlyRent, 0) AS MonthlyRent,
                COALESCE(p.DueAmount, 0) AS DueAmount,
                COALESCE(p.Status, 'available') AS Status
            FROM dbo.Tenants t
            LEFT JOIN dbo.Properties p ON p.Id = t.PropertyId
            LEFT JOIN dbo.Buildings b ON b.Id = p.BuildingId
            WHERE (
                @SearchPattern IS NULL
                OR t.Name LIKE @SearchPattern
                OR t.Phone LIKE @SearchPattern
                OR t.Nid LIKE @SearchPattern
                OR p.Name LIKE @SearchPattern
                OR b.Name LIKE @SearchPattern
            )
            ORDER BY t.Id;
            """;

        var tenants = (await connection.QueryAsync<AdminTenantItemViewModel>(
            new CommandDefinition(tenantsSql, new { SearchPattern = searchPattern }, cancellationToken: cancellationToken))).ToList();

        // 2. Properties query
        const string propertiesSql = """
            SELECT
                p.Id,
                p.Name,
                COALESCE(b.Name, '') AS BuildingName,
                p.Location,
                p.MonthlyRent,
                p.Status,
                p.TenantName,
                p.DueAmount
            FROM dbo.Properties p
            LEFT JOIN dbo.Buildings b ON b.Id = p.BuildingId
            WHERE (@Status IS NULL OR LOWER(p.Status) = @Status)
              AND (
                  @SearchPattern IS NULL
                  OR p.Name LIKE @SearchPattern
                  OR p.Location LIKE @SearchPattern
                  OR b.Name LIKE @SearchPattern
                  OR p.TenantName LIKE @SearchPattern
              )
            ORDER BY p.Id;
            """;

        var properties = (await connection.QueryAsync<AdminPropertyItemViewModel>(
            new CommandDefinition(propertiesSql, new { Status = normalizedStatus, SearchPattern = searchPattern }, cancellationToken: cancellationToken))).ToList();

        // 3. Rent Payments query
        const string paymentsSql = """
            SELECT TOP 100
                rp.Id,
                rp.PropertyId,
                COALESCE(p.Name, rp.PropertyId) AS PropertyName,
                rp.TenantName,
                rp.MonthLabel,
                rp.Amount,
                rp.Status,
                rp.PaidOn
            FROM dbo.RentPayments rp
            LEFT JOIN dbo.Properties p ON p.Id = rp.PropertyId
            WHERE (
                @SearchPattern IS NULL
                OR rp.TenantName LIKE @SearchPattern
                OR p.Name LIKE @SearchPattern
                OR rp.MonthLabel LIKE @SearchPattern
            )
            ORDER BY rp.Id DESC;
            """;

        var payments = (await connection.QueryAsync<AdminRentPaymentItemViewModel>(
            new CommandDefinition(paymentsSql, new { SearchPattern = searchPattern }, cancellationToken: cancellationToken))).ToList();

        // 4. SSLCommerz Online Payment History query
        await EnsureVaratiaSchemaAsync(connection, cancellationToken);

        const string sslPaymentsSql = """
            SELECT TOP 100
                mp.Id,
                mp.UserId,
                COALESCE(u.FullName, mp.UserId) AS UserName,
                COALESCE(u.PhoneNumber, '') AS UserPhone,
                COALESCE(u.Role, '') AS UserRole,
                mp.TransactionId,
                CASE
                    WHEN mp.MonthYear = 'REG' OR mp.TransactionId LIKE 'REG-%' THEN N'রেজিস্ট্রেশন ফি'
                    WHEN mp.MonthYear = 'SUB' OR mp.TransactionId LIKE 'SUB-%' THEN N'সাবস্ক্রিপশন ও ম্যাচমেকিং'
                    WHEN mp.MonthYear = 'POSTING' OR mp.TransactionId LIKE 'POST-%' THEN N'পোস্টিং ক্রেডিট'
                    ELSE N'মাসিক সার্ভিস চার্জ (' + mp.MonthYear + N')'
                END AS PaymentType,
                mp.Amount,
                mp.Status,
                N'SSLCommerz' AS Gateway,
                mp.PaymentDate,
                mp.CreatedOn
            FROM dbo.MonthlyPayments mp
            LEFT JOIN dbo.Users u ON (u.Id = TRY_CAST(mp.UserId AS uniqueidentifier) OR u.PhoneNumber = mp.UserId)
            WHERE (
                @SearchPattern IS NULL
                OR mp.TransactionId LIKE @SearchPattern
                OR mp.UserId LIKE @SearchPattern
                OR u.FullName LIKE @SearchPattern
                OR u.PhoneNumber LIKE @SearchPattern
            )
            ORDER BY mp.CreatedOn DESC;
            """;

        var sslPayments = (await connection.QueryAsync<AdminPaymentHistoryItemViewModel>(
            new CommandDefinition(sslPaymentsSql, new { SearchPattern = searchPattern }, cancellationToken: cancellationToken))).ToList();

        // 5. Registered App Users (Owners / Tenants)
        const string usersSql = """
            SELECT TOP 50
                Id,
                FullName,
                PhoneNumber,
                Role,
                IsPhoneVerified,
                COALESCE(IsRegistrationFeePaid, 0) AS IsRegistrationFeePaid,
                RegistrationFeeTransactionId,
                RegistrationFeePaidAt,
                CreatedAt
            FROM dbo.Users
            WHERE (
                @SearchPattern IS NULL
                OR FullName LIKE @SearchPattern
                OR PhoneNumber LIKE @SearchPattern
                OR Role LIKE @SearchPattern
            )
            ORDER BY CreatedAt DESC;
            """;

        var users = (await connection.QueryAsync<AdminAppUserItemViewModel>(
            new CommandDefinition(usersSql, new { SearchPattern = searchPattern }, cancellationToken: cancellationToken))).ToList();

        // 6. Subscription plans and user subscriptions
        const string plansSql = """
            SELECT Id, ServiceCode, Title, TargetRole, Description, Fee, DeliveryDays, IsActive
            FROM dbo.SubscriptionPlans
            ORDER BY Id ASC;
            """;
        var subPlans = (await connection.QueryAsync<dynamic>(new CommandDefinition(plansSql, cancellationToken: cancellationToken)))
            .Select(r => new OrderProcessAPI.Contracts.SubscriptionPlanDto
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

        const string subsSql = """
            SELECT TOP 100
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
                @SearchPattern IS NULL
                OR s.TransactionId LIKE @SearchPattern
                OR s.UserId LIKE @SearchPattern
                OR s.Title LIKE @SearchPattern
                OR s.UserRequirements LIKE @SearchPattern
                OR u.FullName LIKE @SearchPattern
                OR u.PhoneNumber LIKE @SearchPattern
            )
            ORDER BY s.CreatedAt DESC;
            """;

        var now = DateTime.UtcNow;
        var userSubs = (await connection.QueryAsync<dynamic>(new CommandDefinition(subsSql, new { SearchPattern = searchPattern }, cancellationToken: cancellationToken)))
            .Select(r =>
            {
                DateTime deadline = Convert.ToDateTime(r.DeadlineAt);
                int remainingDays = Math.Max(0, (deadline - now).Days);
                string subStatus = Convert.ToString(r.SubscriptionStatus) ?? "in_progress";
                bool isExpired = now > deadline && string.Equals(subStatus, "in_progress", StringComparison.OrdinalIgnoreCase);

                return new OrderProcessAPI.Contracts.UserSubscriptionDto
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

        // 7. Total counts & summary stats from full database
        const string summarySql = """
            SELECT
                (SELECT COUNT(1) FROM dbo.GeneralPosts) AS TotalGeneralPosts,
                (SELECT COUNT(1) FROM dbo.GeneralPosts WHERE LOWER(Status) = 'active') AS ActiveGeneralPostsCount,
                (SELECT COUNT(1) FROM dbo.GeneralPosts WHERE IsVerified = 1) AS VerifiedGeneralPostsCount,
                (SELECT COUNT(1) FROM dbo.Tenants) AS TotalTenants,
                (SELECT COUNT(1) FROM dbo.Properties) AS TotalProperties,
                (SELECT COUNT(1) FROM dbo.Properties WHERE LOWER(Status) = 'rented') AS RentedPropertiesCount,
                (SELECT COUNT(1) FROM dbo.Properties WHERE LOWER(Status) != 'rented') AS AvailablePropertiesCount,
                (SELECT COALESCE(SUM(DueAmount), 0) FROM dbo.Properties) AS TotalRentDue,
                (SELECT COUNT(1) FROM dbo.Buildings) AS TotalBuildings,
                (SELECT COALESCE(SUM(CASE WHEN (MonthYear = 'REG' OR TransactionId LIKE 'REG-%') AND LOWER(Status) = 'success' THEN Amount ELSE 0 END), 0) FROM dbo.MonthlyPayments) AS TotalRegistrationFees,
                (SELECT COALESCE(SUM(CASE WHEN (MonthYear = 'SUB' OR TransactionId LIKE 'SUB-%') AND LOWER(Status) = 'success' THEN Amount ELSE 0 END), 0) FROM dbo.MonthlyPayments) AS TotalSubscriptionFees,
                (SELECT COALESCE(SUM(CASE WHEN MonthYear NOT IN ('REG', 'SUB', 'POSTING') AND TransactionId NOT LIKE 'REG-%' AND TransactionId NOT LIKE 'SUB-%' AND LOWER(Status) = 'success' THEN Amount ELSE 0 END), 0) FROM dbo.MonthlyPayments) AS TotalMonthlyFees,
                (SELECT TOP (1) COALESCE(RegistrationFee, 50.00) FROM dbo.tbl_CompanySettings WHERE Id = 1) AS RegistrationFee,
                (SELECT TOP (1) COALESCE(IsRegistrationFeeActive, CAST(1 AS BIT)) FROM dbo.tbl_CompanySettings WHERE Id = 1) AS IsRegistrationFeeActive;
            """;

        var summary = await connection.QuerySingleOrDefaultAsync<dynamic>(
            new CommandDefinition(summarySql, cancellationToken: cancellationToken));

        int totalGeneralPosts = summary?.TotalGeneralPosts != null ? Convert.ToInt32(summary.TotalGeneralPosts) : generalPosts.Count;
        int activeGeneralPostsCount = summary?.ActiveGeneralPostsCount != null ? Convert.ToInt32(summary.ActiveGeneralPostsCount) : 0;
        int verifiedGeneralPostsCount = summary?.VerifiedGeneralPostsCount != null ? Convert.ToInt32(summary.VerifiedGeneralPostsCount) : 0;
        int totalTenants = summary?.TotalTenants != null ? Convert.ToInt32(summary.TotalTenants) : tenants.Count;
        int totalProperties = summary?.TotalProperties != null ? Convert.ToInt32(summary.TotalProperties) : properties.Count;
        int rentedCount = summary?.RentedPropertiesCount != null ? Convert.ToInt32(summary.RentedPropertiesCount) : 0;
        int availableCount = summary?.AvailablePropertiesCount != null ? Convert.ToInt32(summary.AvailablePropertiesCount) : 0;
        int totalDue = summary?.TotalRentDue != null ? Convert.ToInt32(summary.TotalRentDue) : 0;
        int totalBuildings = summary?.TotalBuildings != null ? Convert.ToInt32(summary.TotalBuildings) : 0;
        decimal totalRegFees = summary?.TotalRegistrationFees != null ? Convert.ToDecimal(summary.TotalRegistrationFees) : 0m;
        decimal totalSubFees = summary?.TotalSubscriptionFees != null ? Convert.ToDecimal(summary.TotalSubscriptionFees) : 0m;
        decimal totalMonthlyFees = summary?.TotalMonthlyFees != null ? Convert.ToDecimal(summary.TotalMonthlyFees) : 0m;
        decimal regFee = summary?.RegistrationFee != null ? Convert.ToDecimal(summary.RegistrationFee) : 50.00m;
        bool isRegFeeActive = summary?.IsRegistrationFeeActive == null || Convert.ToBoolean(summary.IsRegistrationFeeActive);

        return new AdminVaratiaManagementViewModel
        {
            GeneralPosts = generalPosts,
            TotalGeneralPosts = totalGeneralPosts,
            ActiveGeneralPostsCount = activeGeneralPostsCount,
            VerifiedGeneralPostsCount = verifiedGeneralPostsCount,
            CategoryFilter = normalizedCategory,
            Tenants = tenants,
            Properties = properties,
            Payments = payments,
            SslCommerzPayments = sslPayments,
            Users = users,
            SubscriptionPlans = subPlans,
            Subscriptions = userSubs,
            TotalTenants = totalTenants,
            TotalProperties = totalProperties,
            RentedPropertiesCount = rentedCount,
            AvailablePropertiesCount = availableCount,
            TotalRentDue = totalDue,
            TotalBuildings = totalBuildings,
            RegistrationFee = regFee,
            IsRegistrationFeeActive = isRegFeeActive,
            TotalRegistrationFeesCollected = totalRegFees,
            TotalSubscriptionFeesCollected = totalSubFees,
            TotalMonthlyFeesCollected = totalMonthlyFees,
            SearchQuery = search,
            StatusFilter = statusFilter,
            ActiveTab = string.IsNullOrWhiteSpace(tab) ? "tenants" : tab.Trim().ToLowerInvariant()
        };
    }

    public async Task<bool> ToggleGeneralPostStatusAsync(
        int postId,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureVaratiaSchemaAsync(connection, cancellationToken);

        const string sql = """
            UPDATE dbo.GeneralPosts
            SET Status = CASE WHEN LOWER(Status) = 'active' THEN 'inactive' ELSE 'active' END,
                UpdatedOn = SYSUTCDATETIME()
            WHERE Id = @PostId;
            """;

        var affected = await connection.ExecuteAsync(
            new CommandDefinition(sql, new { PostId = postId }, cancellationToken: cancellationToken));

        return affected > 0;
    }

    public async Task<bool> ToggleGeneralPostVerificationAsync(
        int postId,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureVaratiaSchemaAsync(connection, cancellationToken);

        const string sql = """
            UPDATE dbo.GeneralPosts
            SET IsVerified = CASE WHEN COALESCE(IsVerified, 0) = 1 THEN 0 ELSE 1 END,
                UpdatedOn = SYSUTCDATETIME()
            WHERE Id = @PostId;
            """;

        var affected = await connection.ExecuteAsync(
            new CommandDefinition(sql, new { PostId = postId }, cancellationToken: cancellationToken));

        return affected > 0;
    }

    public async Task<bool> DeleteGeneralPostAsync(
        int postId,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        const string sql = "DELETE FROM dbo.GeneralPosts WHERE Id = @PostId;";

        var affected = await connection.ExecuteAsync(
            new CommandDefinition(sql, new { PostId = postId }, cancellationToken: cancellationToken));

        return affected > 0;
    }

    public async Task<bool> GrantPostingCreditsAsync(
        string userId,
        int credits,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId) || credits <= 0) return false;

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureVaratiaSchemaAsync(connection, cancellationToken);

        const string sql = """
            MERGE dbo.UserPostingEntitlements AS target
            USING (SELECT @UserId AS UserId) AS source
            ON (target.UserId = source.UserId)
            WHEN MATCHED THEN
                UPDATE SET PaidCreditsBalance = target.PaidCreditsBalance + @Credits,
                           UpdatedAt = SYSUTCDATETIME()
            WHEN NOT MATCHED THEN
                INSERT (UserId, FreePostsAllowed, FreePostsUsed, PaidCreditsBalance, TotalPaidAmount, CreatedAt, UpdatedAt)
                VALUES (source.UserId, 4, 0, @Credits, 0, SYSUTCDATETIME(), SYSUTCDATETIME());
            """;

        var affected = await connection.ExecuteAsync(
            new CommandDefinition(sql, new { UserId = userId.Trim(), Credits = credits }, cancellationToken: cancellationToken));

        return affected > 0;
    }

    public async Task<bool> UpdateRegistrationFeeAsync(
        decimal fee,
        bool isActive,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureVaratiaSchemaAsync(connection, cancellationToken);

        const string updateSql = """
            UPDATE dbo.tbl_CompanySettings
            SET RegistrationFee = @Fee,
                IsRegistrationFeeActive = @IsActive,
                UpdatedAt = SYSUTCDATETIME()
            WHERE Id = 1;
            """;

        var affected = await connection.ExecuteAsync(
            new CommandDefinition(updateSql, new { Fee = Math.Max(0, fee), IsActive = isActive }, cancellationToken: cancellationToken));

        return affected > 0;
    }

    private static bool _schemaEnsured;

    private static async Task EnsureVaratiaSchemaAsync(SqlConnection connection, CancellationToken cancellationToken)
    {
        if (_schemaEnsured) return;

        const string sql = """
            IF COL_LENGTH(N'dbo.GeneralPosts', N'IsVerified') IS NULL
            BEGIN
                EXEC(N'ALTER TABLE dbo.GeneralPosts ADD IsVerified BIT NOT NULL CONSTRAINT DF_GeneralPosts_IsVerified DEFAULT (0)');
            END;
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
        catch
        {
            // Ignore if concurrently initialized
        }
    }
}
