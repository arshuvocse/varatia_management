using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IOwnerPostService
{
    Task<OwnerPostListResponse> GetPostsAsync(
        string? ownerId = null,
        string? status = null,
        CancellationToken cancellationToken = default);

    Task<CreateOwnerPostResponse> CreatePostAsync(
        CreateOwnerPostRequest request,
        CancellationToken cancellationToken = default);
}
