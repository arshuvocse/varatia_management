using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IReportService
{
    Task<ReportSummaryResponse> GetSummaryAsync(
        string userId,
        CancellationToken cancellationToken = default);

    Task<string> ExportPaymentsCsvAsync(
        string userId,
        CancellationToken cancellationToken = default);
}
