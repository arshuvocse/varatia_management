namespace OrderProcessAPI.Contracts;

public sealed class ManagementBootstrapResponse
{
    public DashboardSummaryDto DashboardSummary { get; init; } = new();
    public IReadOnlyList<ActivityItemDto> RecentActivities { get; init; } =
        Array.Empty<ActivityItemDto>();
    public IReadOnlyList<BuildingBlockDto> Buildings { get; init; } =
        Array.Empty<BuildingBlockDto>();
    public IReadOnlyList<BuildingFloorDto> Floors { get; init; } =
        Array.Empty<BuildingFloorDto>();
    public IReadOnlyList<PropertyUnitDto> Properties { get; init; } =
        Array.Empty<PropertyUnitDto>();
    public IReadOnlyList<TenantProfileDto> Tenants { get; init; } =
        Array.Empty<TenantProfileDto>();
    public IReadOnlyList<RentPaymentDto> Payments { get; init; } =
        Array.Empty<RentPaymentDto>();
    public IReadOnlyList<ExpenseItemDto> Expenses { get; init; } =
        Array.Empty<ExpenseItemDto>();
    public IReadOnlyList<AppNotificationItemDto> Notifications { get; init; } =
        Array.Empty<AppNotificationItemDto>();
    public IReadOnlyList<CommunicationEntryDto> Messages { get; init; } =
        Array.Empty<CommunicationEntryDto>();
    public IReadOnlyList<MonthlyMetricDto> IncomeMetrics { get; init; } =
        Array.Empty<MonthlyMetricDto>();
    public IReadOnlyList<MonthlyMetricDto> ExpenseMetrics { get; init; } =
        Array.Empty<MonthlyMetricDto>();
}

public sealed class DashboardSummaryDto
{
    public int TotalProperties { get; init; }
    public int TotalTenants { get; init; }
    public int MonthlyIncome { get; init; }
    public int DueRent { get; init; }
}

public sealed class ActivityItemDto
{
    public string Title { get; init; } = string.Empty;
    public string Subtitle { get; init; } = string.Empty;
    public string TimeLabel { get; init; } = string.Empty;
}

public sealed class BuildingBlockDto
{
    public string Id { get; init; } = string.Empty;
    public string UserId { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public int TotalFloors { get; init; }
    public string Location { get; init; } = string.Empty;
    public string Address { get; init; } = string.Empty;
    public decimal? Latitude { get; init; }
    public decimal? Longitude { get; init; }
    public string ZoneId { get; init; } = string.Empty;
    public string StationId { get; init; } = string.Empty;
    public int? WardId { get; init; }
}

public sealed class BuildingFloorDto
{
    public string Id { get; init; } = string.Empty;
    public string BuildingId { get; init; } = string.Empty;
    public string Label { get; init; } = string.Empty;
    public int TotalUnits { get; init; }
}

public sealed class PropertyUnitDto
{
    public string Id { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Location { get; init; } = string.Empty;
    public int MonthlyRent { get; init; }
    public string Status { get; init; } = string.Empty;
    public string? TenantName { get; init; }
    public int DueAmount { get; init; }
    public string? BuildingId { get; init; }
    public string? BuildingName { get; init; }
    public string? FloorId { get; init; }
    public string? FloorLabel { get; init; }
}

public sealed class TenantProfileDto
{
    public string Id { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Phone { get; init; } = string.Empty;
    public string Nid { get; init; } = string.Empty;
    public string PropertyName { get; init; } = string.Empty;
}

public sealed class RentPaymentDto
{
    public string PropertyName { get; init; } = string.Empty;
    public string TenantName { get; init; } = string.Empty;
    public string MonthLabel { get; init; } = string.Empty;
    public int Amount { get; init; }
    public string Status { get; init; } = string.Empty;
    public DateTime? PaidOn { get; init; }
}

public sealed class ExpenseItemDto
{
    public int Id { get; init; }
    public string Title { get; init; } = string.Empty;
    public string Category { get; init; } = string.Empty;
    public int Amount { get; init; }
    public string MonthLabel { get; init; } = string.Empty;
}

public sealed class AppNotificationItemDto
{
    public int Id { get; init; }
    public string Title { get; init; } = string.Empty;
    public string Subtitle { get; init; } = string.Empty;
    public DateTime CreatedAt { get; init; }
    public bool IsUnread { get; init; }
}

public sealed class CommunicationEntryDto
{
    public int Id { get; init; }
    public string Sender { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public string PropertyName { get; init; } = string.Empty;
    public string TimeLabel { get; init; } = string.Empty;
}

public sealed class MonthlyMetricDto
{
    public string Label { get; init; } = string.Empty;
    public decimal Value { get; init; }
}
