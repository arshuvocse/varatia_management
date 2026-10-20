using OrderProcessAPI.Contracts;

namespace PromotionWeb.Services;

public interface ISubscriptionService
{
    Task<IReadOnlyList<SubscriptionPlanDto>> GetPlansAsync(bool activeOnly = false, CancellationToken cancellationToken = default);
    Task<SubscriptionPlanDto?> GetPlanByCodeAsync(string serviceCode, CancellationToken cancellationToken = default);
    Task<bool> UpdatePlanAsync(UpdateSubscriptionPlanRequest request, CancellationToken cancellationToken = default);
    Task<InitiatePaymentResponse> InitiateSubscriptionPaymentAsync(string userId, string serviceCode, string? requirements, string baseUrl, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<UserSubscriptionDto>> GetUserSubscriptionsAsync(string userId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<UserSubscriptionDto>> GetAllSubscriptionsAsync(string? search = null, string? status = null, CancellationToken cancellationToken = default);
    Task<bool> UpdateSubscriptionStatusAsync(int subscriptionId, string status, string? notes, CancellationToken cancellationToken = default);
}
