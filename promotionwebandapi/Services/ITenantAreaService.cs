using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface ITenantAreaService
{
    Task<TenantAreaHomeResponse> GetHomeAsync(
        string? tenantId,
        CancellationToken cancellationToken = default);

    Task<TenantAreaWardsResponse> GetWardsAsync(
        string? tenantId,
        string? city = null,
        string? search = null,
        CancellationToken cancellationToken = default);

    Task<TenantAreaPostsResponse> GetPostsAsync(
        string? tenantId,
        string? wardId = null,
        string? category = null,
        int page = 1,
        int limit = 20,
        CancellationToken cancellationToken = default);

    Task<CreateTenantAreaPostResponse> CreatePostAsync(
        CreateTenantAreaPostRequest request,
        CancellationToken cancellationToken = default);
}
