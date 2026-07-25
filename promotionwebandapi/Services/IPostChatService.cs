using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IPostChatService
{
    Task<PostChatConversationDto> OpenForPostAsync(
        int postId,
        string requesterUserId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PostChatConversationDto>> GetInboxAsync(
        string userId,
        CancellationToken cancellationToken = default);

    Task<PostChatConversationDto> GetConversationAsync(
        int conversationId,
        string userId,
        CancellationToken cancellationToken = default);

    Task<PostChatMessageDto> SendMessageAsync(
        int conversationId,
        string senderUserId,
        string messageText,
        CancellationToken cancellationToken = default);

    Task MarkReadAsync(
        int conversationId,
        string userId,
        CancellationToken cancellationToken = default);
}
