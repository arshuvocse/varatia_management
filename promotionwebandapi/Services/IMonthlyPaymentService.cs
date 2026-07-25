using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IMonthlyPaymentService
{
    Task<PaymentStatusResponse> GetPaymentStatusAsync(string userId, CancellationToken cancellationToken);
    Task<MonthlyPaymentHistoryResponse> GetPaymentHistoryAsync(
        string userId,
        int year,
        CancellationToken cancellationToken);
    Task<InitiatePaymentResponse> InitiatePaymentAsync(string userId, string baseUrl, CancellationToken cancellationToken);
    Task<MonthlyPaymentCallbackResult> ProcessCallbackAsync(
        MonthlyPaymentCallbackData callbackData,
        CancellationToken cancellationToken);
}

public sealed class MonthlyPaymentCallbackData
{
    public string? TransactionId { get; init; }
    public string? ValidationId { get; init; }
    public string? Status { get; init; }
    public string? Amount { get; init; }
    public string? Currency { get; init; }
    public string? RawData { get; init; }
}

public sealed class MonthlyPaymentCallbackResult
{
    public bool Success { get; init; }
    public bool AlreadyProcessed { get; init; }
    public string Message { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
}
