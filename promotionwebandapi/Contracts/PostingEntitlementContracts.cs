namespace OrderProcessAPI.Contracts;

public sealed class PostingEntitlementDto
{
    public string UserId { get; init; } = string.Empty;
    public int FreePostsAllowed { get; init; } = 4;
    public int FreePostsUsed { get; init; }
    public int RemainingFreePosts { get; init; }
    public int PaidCreditsBalance { get; init; }
    public decimal TotalPaidAmount { get; init; }
    public bool CanPost { get; init; }
    public bool RequiresPayment { get; init; }
    public decimal MinimumPaymentAmount { get; init; } = 100.00m;
}

public sealed class InitiatePostingCreditPaymentRequest
{
    public string UserId { get; init; } = string.Empty;
    public decimal Amount { get; init; } = 100.00m;
}
