using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class TenantOwnerInfoService : ITenantOwnerInfoService
{
    private const int MaxTenantIdLength = 100;

    private const string OwnerInfoQuery = """
        SELECT TOP (1)
            t.Id AS TenantId,
            p.Id AS PropertyId,
            p.Name AS PropertyName,
            p.Location,
            COALESCE(p.BuildingId, N'') AS BuildingId,
            COALESCE(b.Name, N'') AS BuildingName,
            COALESCE(p.FloorId, N'') AS FloorId,
            COALESCE(f.Label, N'') AS FloorLabel,
            p.MonthlyRent,
            p.DueAmount,
            COALESCE(NULLIF(b.UserId, N''), NULLIF(ownerPost.OwnerId, N''), N'') AS OwnerId,
            COALESCE(ownerByBuilding.FullName, ownerByPostId.FullName, ownerByPostPhone.FullName, N'') AS OwnerName,
            COALESCE(ownerByBuilding.PhoneNumber, ownerByPostId.PhoneNumber, ownerByPostPhone.PhoneNumber, ownerPost.ContactNumber, N'') AS OwnerPhone,
            CAST(
                CASE
                    WHEN COALESCE(
                        ownerByBuilding.IsPhoneVerified,
                        ownerByPostId.IsPhoneVerified,
                        ownerByPostPhone.IsPhoneVerified,
                        CAST(0 AS bit)) = CAST(1 AS bit)
                    THEN 1
                    ELSE 0
                END AS bit) AS OwnerIsVerified
        FROM dbo.Tenants t
        INNER JOIN dbo.Properties p ON p.Id = t.PropertyId
        LEFT JOIN dbo.Buildings b ON b.Id = p.BuildingId
        LEFT JOIN dbo.Floors f ON f.Id = p.FloorId
        OUTER APPLY
        (
            SELECT TOP (1)
                OwnerId,
                ContactNumber
            FROM dbo.OwnerPosts
            WHERE PropertyId = p.Id
            ORDER BY
                CASE
                    WHEN LOWER(Status) IN (N'published', N'active') THEN 0
                    ELSE 1
                END,
                CreatedAt DESC,
                Id DESC
        ) ownerPost
        LEFT JOIN dbo.Users ownerByBuilding
            ON TRY_CONVERT(uniqueidentifier, NULLIF(b.UserId, N'')) = ownerByBuilding.Id
        LEFT JOIN dbo.Users ownerByPostId
            ON TRY_CONVERT(uniqueidentifier, NULLIF(ownerPost.OwnerId, N'')) = ownerByPostId.Id
        LEFT JOIN dbo.Users ownerByPostPhone
            ON NULLIF(ownerPost.ContactNumber, N'') IS NOT NULL
           AND (
                ownerByPostPhone.NormalizedPhoneNumber = ownerPost.ContactNumber
                OR ownerByPostPhone.PhoneNumber = ownerPost.ContactNumber
           )
        WHERE t.Id = @TenantId;
        """;

    private readonly SqlConnectionFactory _connectionFactory;

    public TenantOwnerInfoService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<TenantOwnerInfoResponse> GetOwnerInfoAsync(
        string? tenantId,
        CancellationToken cancellationToken = default)
    {
        var normalizedTenantId = NormalizeTenantId(tenantId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var row = await connection.QuerySingleOrDefaultAsync<TenantOwnerInfoRow>(
            new CommandDefinition(
                OwnerInfoQuery,
                new { TenantId = normalizedTenantId },
                cancellationToken: cancellationToken));

        if (row is null)
        {
            throw new TenantOwnerInfoNotFoundException(
                "Tenant or assigned property was not found.");
        }

        return new TenantOwnerInfoResponse
        {
            Owner = new TenantOwnerInfoDto
            {
                Id = row.OwnerId,
                Name = string.IsNullOrWhiteSpace(row.OwnerName)
                    ? "Owner"
                    : row.OwnerName,
                Phone = row.OwnerPhone,
                Subtitle = BuildOwnerSubtitle(row.Location),
                BadgeLabel = "Owner",
                IsVerified = row.OwnerIsVerified,
            },
            Property = new TenantOwnerPropertyInfoDto
            {
                Id = row.PropertyId,
                Name = row.PropertyName,
                Location = row.Location,
                BuildingId = row.BuildingId,
                BuildingName = row.BuildingName,
                FloorId = row.FloorId,
                FloorLabel = row.FloorLabel,
                MonthlyRent = row.MonthlyRent,
                DueAmount = row.DueAmount,
            },
        };
    }

    private static string NormalizeTenantId(string? tenantId)
    {
        var normalizedTenantId = tenantId?.Trim() ?? string.Empty;
        if (normalizedTenantId.Length == 0)
        {
            throw new TenantOwnerInfoValidationException("Tenant id is required.");
        }

        if (normalizedTenantId.Length > MaxTenantIdLength)
        {
            throw new TenantOwnerInfoValidationException(
                $"Tenant id cannot exceed {MaxTenantIdLength} characters.");
        }

        return normalizedTenantId;
    }

    private static string BuildOwnerSubtitle(string location)
    {
        var area = location
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .FirstOrDefault();

        return string.IsNullOrWhiteSpace(area)
            ? "Flat Owner"
            : $"Flat Owner \u2022 {area}";
    }

    private sealed class TenantOwnerInfoRow
    {
        public string PropertyId { get; init; } = string.Empty;
        public string PropertyName { get; init; } = string.Empty;
        public string Location { get; init; } = string.Empty;
        public string BuildingId { get; init; } = string.Empty;
        public string BuildingName { get; init; } = string.Empty;
        public string FloorId { get; init; } = string.Empty;
        public string FloorLabel { get; init; } = string.Empty;
        public int MonthlyRent { get; init; }
        public int DueAmount { get; init; }
        public string OwnerId { get; init; } = string.Empty;
        public string OwnerName { get; init; } = string.Empty;
        public string OwnerPhone { get; init; } = string.Empty;
        public bool OwnerIsVerified { get; init; }
    }
}

public sealed class TenantOwnerInfoValidationException : Exception
{
    public TenantOwnerInfoValidationException(string message)
        : base(message)
    {
    }
}

public sealed class TenantOwnerInfoNotFoundException : Exception
{
    public TenantOwnerInfoNotFoundException(string message)
        : base(message)
    {
    }
}
