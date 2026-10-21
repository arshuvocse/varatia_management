using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface ITenantTutorService
{
    Task<TenantTutorPostListResponse> GetPostsAsync(
        string? tenantId = null,
        string? type = null,
        string? subject = null,
        string? area = null,
        bool verifiedOnly = false,
        int page = 1,
        int limit = 50,
        CancellationToken cancellationToken = default);

    Task<CreateTenantTutorPostResponse> CreatePostAsync(
        CreateTenantTutorPostRequest request,
        CancellationToken cancellationToken = default);

    Task<TutorBdjobsProfileDto?> GetTutorProfileAsync(
        string userId,
        CancellationToken cancellationToken = default);

    Task<TutorBdjobsProfileResponse> SaveTutorProfileAsync(
        SaveTutorBdjobsProfileRequest request,
        CancellationToken cancellationToken = default);
}
