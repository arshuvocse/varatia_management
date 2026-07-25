namespace OrderProcessAPI.Contracts;

public sealed class TenantOwnerInfoResponse
{
    public TenantOwnerInfoDto Owner { get; init; } = new();
    public TenantOwnerPropertyInfoDto Property { get; init; } = new();
}

public sealed class TenantOwnerInfoDto
{
    public string Id { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Phone { get; init; } = string.Empty;
    public string Subtitle { get; init; } = string.Empty;
    public string BadgeLabel { get; init; } = "Owner";
    public bool IsVerified { get; init; }
}

public sealed class TenantOwnerPropertyInfoDto
{
    public string Id { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Location { get; init; } = string.Empty;
    public string BuildingId { get; init; } = string.Empty;
    public string BuildingName { get; init; } = string.Empty;
    public string FloorId { get; init; } = string.Empty;
    public string FloorLabel { get; init; } = string.Empty;
    public int MonthlyRent { get; init; }
    public int DueAmount { get; init; }
}
