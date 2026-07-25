namespace OrderProcessAPI.Contracts;

public sealed class InitiatePaymentRequest
{
    public string UserId { get; init; } = string.Empty;
}

public sealed class InitiatePaymentResponse
{
    public string GatewayPageUrl { get; init; } = string.Empty;
    public string TransactionId { get; init; } = string.Empty;
}

public sealed class PaymentStatusResponse
{
    public string UserId { get; init; } = string.Empty;
    public string Role { get; init; } = string.Empty;
    public string PaymentMonth { get; init; } = string.Empty;
    public string PaymentStatus { get; init; } = string.Empty;
    public decimal Amount { get; init; }
    public DateTime? PaidAt { get; init; }
    public DateTime? ExpiresAt { get; init; }
    public bool AccessAllowed { get; init; }
}

public sealed class MonthlyPaymentHistoryResponse
{
    public string UserId { get; init; } = string.Empty;
    public string Role { get; init; } = string.Empty;
    public int Year { get; init; }
    public IReadOnlyList<MonthlyPaymentHistoryItem> Months { get; init; } =
        Array.Empty<MonthlyPaymentHistoryItem>();
}

public sealed class MonthlyPaymentHistoryItem
{
    public int MonthNumber { get; init; }
    public string PaymentMonth { get; init; } = string.Empty;
    public string PaymentStatus { get; init; } = string.Empty;
    public decimal Amount { get; init; }
    public DateTime? PaidAt { get; init; }
    public bool AccessAllowed { get; init; }
}
