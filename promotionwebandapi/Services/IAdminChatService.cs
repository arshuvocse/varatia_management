using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IAdminChatService
{
    Task<AdminContactDto> GetDefaultAdminAsync(
        CancellationToken cancellationToken = default);

    Task<AdminChatConversationDto> OpenChatAsync(
        string requesterUserId,
        string adminUserId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AdminChatConversationDto>> GetInboxAsync(
        string userId,
        CancellationToken cancellationToken = default);

    Task<AdminChatConversationDto> GetConversationAsync(
        int conversationId,
        string userId,
        CancellationToken cancellationToken = default);

    Task<AdminChatMessageDto> SendMessageAsync(
        int conversationId,
        string senderUserId,
        string messageText,
        CancellationToken cancellationToken = default);

    Task MarkReadAsync(
        int conversationId,
        string userId,
        CancellationToken cancellationToken = default);
}
