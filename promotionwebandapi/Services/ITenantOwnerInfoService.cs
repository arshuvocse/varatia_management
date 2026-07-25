using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface ITenantOwnerInfoService
{
    Task<TenantOwnerInfoResponse> GetOwnerInfoAsync(
        string? tenantId,
        CancellationToken cancellationToken = default);
}
