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

public sealed class RegistrationFeeInfoResponse
{
    public decimal Fee { get; init; }
    public bool IsActive { get; init; }
    public string Currency { get; init; } = "BDT";
}

public sealed class RegistrationFeeStatusResponse
{
    public string UserId { get; init; } = string.Empty;
    public bool IsPaid { get; init; }
    public bool IsRequired { get; init; }
    public decimal Fee { get; init; }
    public string Currency { get; init; } = "BDT";
    public string? TransactionId { get; init; }
    public DateTime? PaidAt { get; init; }
}

public sealed class InitiateRegistrationPaymentRequest
{
    public string UserId { get; init; } = string.Empty;
}

public sealed class UserPaymentHistoryResponse
{
    public string UserId { get; init; } = string.Empty;
    public decimal TotalPaid { get; init; }
    public IReadOnlyList<UserPaymentHistoryItem> Payments { get; init; } = [];
}

public sealed class UserPaymentHistoryItem
{
    public int Id { get; init; }
    public string TransactionId { get; init; } = string.Empty;
    public string PaymentType { get; init; } = string.Empty;
    public string Title { get; init; } = string.Empty;
    public decimal Amount { get; init; }
    public string Status { get; init; } = string.Empty;
    public string MonthYear { get; init; } = string.Empty;
    public string Gateway { get; init; } = "SSLCommerz";
    public DateTime? PaymentDate { get; init; }
    public DateTime CreatedOn { get; init; }
}
