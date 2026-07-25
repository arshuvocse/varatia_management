namespace PromotionWeb.Models;

public sealed class ShopkeeperActivationViewModel
{
    public Shopkeeper Shop { get; init; } = new();
    public decimal Amount { get; init; } = 50m;
    public bool IsPaid { get; init; }
    public bool IsConfigured { get; init; }
    public ShopkeeperActivationPayment? LatestPayment { get; init; }
}

public sealed class ShopkeeperActivationPayment
{
    public int Id { get; init; }
    public int ShopkeeperId { get; init; }
    public string TransactionId { get; init; } = "";
    public string? SessionKey { get; init; }
    public decimal Amount { get; init; }
    public string Currency { get; init; } = "BDT";
    public string Status { get; init; } = "Pending";
    public string? ValidationId { get; init; }
    public string? BankTransactionId { get; init; }
    public string? CardType { get; init; }
    public string? GatewayResponse { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime? PaidAt { get; init; }
}

public sealed class SslCommerzSessionResult
{
    public bool Success { get; init; }
    public string? GatewayUrl { get; init; }
    public string? SessionKey { get; init; }
    public string? Error { get; init; }
    public string RawResponse { get; init; } = "";
}

public sealed class SslCommerzValidationResult
{
    public bool IsValid { get; init; }
    public string? Status { get; init; }
    public string? TransactionId { get; init; }
    public string? ValidationId { get; init; }
    public string? BankTransactionId { get; init; }
    public string? CardType { get; init; }
    public decimal Amount { get; init; }
    public string? Currency { get; init; }
    public int RiskLevel { get; init; }
    public string RawResponse { get; init; } = "";
    public string? Error { get; init; }
}
