using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IOwnerTenantService
{
    Task<OwnerTenantListResponse> GetTenantsAsync(
        CancellationToken cancellationToken = default);

    Task<CreateOwnerTenantResponse> CreateTenantAsync(
        CreateOwnerTenantRequest request,
        CancellationToken cancellationToken = default);

    Task<UpdateOwnerTenantResponse> UpdateTenantAsync(
        string tenantId,
        UpdateOwnerTenantRequest request,
        CancellationToken cancellationToken = default);

    Task<DeleteOwnerTenantResponse> DeleteTenantAsync(
        string tenantId,
        CancellationToken cancellationToken = default);

    Task<MoveOutOwnerTenantResponse> MoveOutTenantAsync(
        string tenantId,
        CancellationToken cancellationToken = default);
}
