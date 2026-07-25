using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class ManagementDataService : IManagementDataService
{
    private const string BootstrapQuery = """
        SELECT
            (SELECT COUNT(*) FROM dbo.Properties) AS TotalProperties,
            (SELECT COUNT(*) FROM dbo.Tenants) AS TotalTenants,
            (SELECT ISNULL(SUM(CASE WHEN Status = 'paid' THEN Amount ELSE 0 END), 0) FROM dbo.RentPayments) AS MonthlyIncome,
            (SELECT ISNULL(SUM(CASE WHEN Status = 'due' THEN Amount ELSE 0 END), 0) FROM dbo.RentPayments) AS DueRent;

        SELECT Title, Subtitle, TimeLabel
        FROM dbo.Activities
        ORDER BY Id DESC;

        SELECT
            Id,
            COALESCE(UserId, '') AS UserId,
            Name,
            TotalFloors,
            Location,
            COALESCE(Address, '') AS Address,
            Latitude,
            Longitude,
            COALESCE(ZoneId, '') AS ZoneId,
            COALESCE(StationId, '') AS StationId,
            WardId
        FROM dbo.Buildings
        ORDER BY Id;

        SELECT Id, BuildingId, Label, TotalUnits
        FROM dbo.Floors
        ORDER BY Id;

        SELECT
            p.Id,
            p.Name,
            p.Location,
            p.MonthlyRent,
            p.Status,
            p.TenantName,
            p.DueAmount,
            p.BuildingId,
            b.Name AS BuildingName,
            p.FloorId,
            f.Label AS FloorLabel
        FROM dbo.Properties p
        LEFT JOIN dbo.Buildings b ON b.Id = p.BuildingId
        LEFT JOIN dbo.Floors f ON f.Id = p.FloorId
        ORDER BY p.Id;

        SELECT
            Id,
            Name,
            Phone,
            Nid,
            PropertyName
        FROM dbo.vw_OwnerTenantList
        ORDER BY Id;

        SELECT
            p.Name AS PropertyName,
            COALESCE(r.TenantName, 'Vacant') AS TenantName,
            r.MonthLabel,
            r.Amount,
            r.Status,
            r.PaidOn
        FROM dbo.RentPayments r
        INNER JOIN dbo.Properties p ON p.Id = r.PropertyId
        ORDER BY r.Id;

        SELECT Id, Title, Category, Amount, MonthLabel
        FROM dbo.Expenses
        ORDER BY Id;

        SELECT Id, Title, Subtitle, CreatedAt, IsUnread
        FROM dbo.Notifications
        ORDER BY CreatedAt DESC;

        SELECT Id, Sender, Message, PropertyName, TimeLabel
        FROM dbo.Messages
        ORDER BY Id DESC;

        SELECT Label, Value
        FROM dbo.Metrics
        WHERE MetricType = 'income'
        ORDER BY Id;

        SELECT Label, Value
        FROM dbo.Metrics
        WHERE MetricType = 'expense'
        ORDER BY Id;
        """;

    private readonly SqlConnectionFactory _connectionFactory;

    public ManagementDataService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<ManagementBootstrapResponse> GetBootstrapAsync(
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var command = new CommandDefinition(
            BootstrapQuery,
            cancellationToken: cancellationToken);

        using var multi = await connection.QueryMultipleAsync(command);

        var summary = await multi.ReadFirstAsync<DashboardSummaryDto>();
        var activities = (await multi.ReadAsync<ActivityItemDto>()).ToList();
        var buildings = (await multi.ReadAsync<BuildingBlockDto>()).ToList();
        var floors = (await multi.ReadAsync<BuildingFloorDto>()).ToList();
        var properties = (await multi.ReadAsync<PropertyUnitDto>()).ToList();
        var tenants = (await multi.ReadAsync<TenantProfileDto>()).ToList();
        var payments = (await multi.ReadAsync<RentPaymentDto>()).ToList();
        var expenses = (await multi.ReadAsync<ExpenseItemDto>()).ToList();
        var notifications =
            (await multi.ReadAsync<AppNotificationItemDto>()).ToList();
        var messages = (await multi.ReadAsync<CommunicationEntryDto>()).ToList();
        var incomeMetrics = (await multi.ReadAsync<MonthlyMetricDto>()).ToList();
        var expenseMetrics =
            (await multi.ReadAsync<MonthlyMetricDto>()).ToList();

        return new ManagementBootstrapResponse
        {
            DashboardSummary = summary,
            RecentActivities = activities,
            Buildings = buildings,
            Floors = floors,
            Properties = properties,
            Tenants = tenants,
            Payments = payments,
            Expenses = expenses,
            Notifications = notifications,
            Messages = messages,
            IncomeMetrics = incomeMetrics,
            ExpenseMetrics = expenseMetrics,
        };
    }
}
