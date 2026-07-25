namespace OrderProcessAPI.Contracts;

public sealed class ReportSummaryResponse
{
    public DashboardSummaryDto DashboardSummary { get; init; } = new();
    public IReadOnlyList<MonthlyMetricDto> IncomeMetrics { get; init; } =
        Array.Empty<MonthlyMetricDto>();
    public IReadOnlyList<MonthlyMetricDto> ExpenseMetrics { get; init; } =
        Array.Empty<MonthlyMetricDto>();
    public DateTime GeneratedAtUtc { get; init; }
}
