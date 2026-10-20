using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IPostingEntitlementService
{
    Task<PostingEntitlementDto> GetEntitlementAsync(
        string userId,
        CancellationToken cancellationToken = default);

    Task ConsumePostingSlotAsync(
        string userId,
        CancellationToken cancellationToken = default);

    Task<PostingEntitlementDto> GrantPostingCreditsAsync(
        string userId,
        decimal amount,
        string transactionId,
        CancellationToken cancellationToken = default);
}
