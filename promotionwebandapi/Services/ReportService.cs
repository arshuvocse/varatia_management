using System.Text;
using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class ReportService : IReportService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public ReportService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<ReportSummaryResponse> GetSummaryAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        using var multi = await connection.QueryMultipleAsync(
            new CommandDefinition(
                """
                SELECT
                    (SELECT COUNT(*) FROM dbo.Properties p INNER JOIN dbo.Buildings b ON p.BuildingId = b.Id WHERE b.UserId = @UserId) AS TotalProperties,
                    (SELECT COUNT(*) FROM dbo.Tenants t INNER JOIN dbo.Properties p ON t.PropertyId = p.Id INNER JOIN dbo.Buildings b ON p.BuildingId = b.Id WHERE b.UserId = @UserId) AS TotalTenants,
                    (SELECT ISNULL(SUM(CASE WHEN rp.Status = 'paid' THEN rp.Amount ELSE 0 END), 0) FROM dbo.RentPayments rp INNER JOIN dbo.Properties p ON rp.PropertyId = p.Id INNER JOIN dbo.Buildings b ON p.BuildingId = b.Id WHERE b.UserId = @UserId) AS MonthlyIncome,
                    (SELECT ISNULL(SUM(CASE WHEN rp.Status = 'due' THEN rp.Amount ELSE 0 END), 0) FROM dbo.RentPayments rp INNER JOIN dbo.Properties p ON rp.PropertyId = p.Id INNER JOIN dbo.Buildings b ON p.BuildingId = b.Id WHERE b.UserId = @UserId) AS DueRent;

                SELECT Label, Value
                FROM dbo.Metrics
                WHERE MetricType = 'income'
                ORDER BY Id;

                SELECT Label, Value
                FROM dbo.Metrics
                WHERE MetricType = 'expense'
                ORDER BY Id;
                """,
                new { UserId = userId },
                cancellationToken: cancellationToken));

        return new ReportSummaryResponse
        {
            DashboardSummary = await multi.ReadFirstAsync<DashboardSummaryDto>(),
            IncomeMetrics = (await multi.ReadAsync<MonthlyMetricDto>()).ToList(),
            ExpenseMetrics = (await multi.ReadAsync<MonthlyMetricDto>()).ToList(),
            GeneratedAtUtc = DateTime.UtcNow,
        };
    }

    public async Task<string> ExportPaymentsCsvAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var items = await connection.QueryAsync<PaymentExportRow>(
            new CommandDefinition(
                """
                SELECT
                    p.Name AS PropertyName,
                    COALESCE(r.TenantName, 'Vacant') AS TenantName,
                    r.MonthLabel,
                    r.Amount,
                    r.Status,
                    r.PaidOn
                FROM dbo.RentPayments r
                INNER JOIN dbo.Properties p ON p.Id = r.PropertyId
                INNER JOIN dbo.Buildings b ON p.BuildingId = b.Id
                WHERE b.UserId = @UserId
                ORDER BY r.Id DESC;
                """,
                new { UserId = userId },
                cancellationToken: cancellationToken));

        var builder = new StringBuilder();
        builder.AppendLine("PropertyName,TenantName,MonthLabel,Amount,Status,PaidOn");

        foreach (var item in items)
        {
            builder
                .Append(EscapeCsv(item.PropertyName)).Append(',')
                .Append(EscapeCsv(item.TenantName)).Append(',')
                .Append(EscapeCsv(item.MonthLabel)).Append(',')
                .Append(item.Amount).Append(',')
                .Append(EscapeCsv(item.Status)).Append(',')
                .Append(EscapeCsv(item.PaidOn?.ToString("O") ?? string.Empty))
                .AppendLine();
        }

        return builder.ToString();
    }

    private static string EscapeCsv(string value)
    {
        var normalizedValue = value.Replace("\"", "\"\"");
        return $"\"{normalizedValue}\"";
    }

    private sealed class PaymentExportRow
    {
        public string PropertyName { get; init; } = string.Empty;
        public string TenantName { get; init; } = string.Empty;
        public string MonthLabel { get; init; } = string.Empty;
        public int Amount { get; init; }
        public string Status { get; init; } = string.Empty;
        public DateTime? PaidOn { get; init; }
    }
}
