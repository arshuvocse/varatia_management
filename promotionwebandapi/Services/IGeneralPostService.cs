using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IGeneralPostService
{
    Task<CreateGeneralPostResponse> CreatePostAsync(
        CreateGeneralPostRequest request,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<GeneralPostDto>> GetActivePostsAsync(
        string? viewerUserId = null,
        string? publicBaseUrl = null,
        CancellationToken cancellationToken = default);

    Task<GeneralPostDto?> GetPostByIdAsync(
        int postId,
        string? viewerUserId = null,
        string? publicBaseUrl = null,
        CancellationToken cancellationToken = default);

    Task<GeneralPostLikeResponse> LikePostAsync(
        int postId,
        string userId,
        CancellationToken cancellationToken = default);

    Task<GeneralPostLikeResponse> UnlikePostAsync(
        int postId,
        string userId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<GeneralPostCommentDto>> GetCommentsAsync(
        int postId,
        CancellationToken cancellationToken = default);

    Task<GeneralPostCommentDto> AddCommentAsync(
        int postId,
        CreateGeneralPostCommentRequest request,
        CancellationToken cancellationToken = default);
}
