using Microsoft.AspNetCore.SignalR;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Hubs;

public sealed class PostChatHub : Hub
{
    private readonly IPostChatService _postChatService;

    public PostChatHub(IPostChatService postChatService)
    {
        _postChatService = postChatService;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = GetUserIdOrNull();
        if (userId is null)
        {
            Context.Abort();
            return;
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, UserGroup(userId));
        await base.OnConnectedAsync();
    }

    public async Task JoinConversation(int conversationId)
    {
        var userId = GetUserId();
        await _postChatService.GetConversationAsync(conversationId, userId, Context.ConnectionAborted);
        await Groups.AddToGroupAsync(Context.ConnectionId, ConversationGroup(conversationId));
        await _postChatService.MarkReadAsync(conversationId, userId, Context.ConnectionAborted);
    }

    public async Task SendMessage(int conversationId, string messageText)
    {
        var userId = GetUserId();
        var conversation = await _postChatService.GetConversationAsync(
            conversationId,
            userId,
            Context.ConnectionAborted);
        var message = await _postChatService.SendMessageAsync(
            conversationId,
            userId,
            messageText ?? string.Empty,
            Context.ConnectionAborted);
        var recipientUserId = GetRecipientUserId(conversation, userId);

        await Clients.Group(ConversationGroup(conversationId)).SendAsync("ReceiveMessage", message);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("ReceiveNotification", new
        {
            conversationId,
            conversation.PostId,
            conversation.PostTitle,
            message.SenderUserId,
            message.SenderName,
            message.MessageText,
            message.SentOn
        });
    }

    public Task StartAudioCall(int conversationId, string offer) =>
        StartCall(conversationId, "audio", offer);

    public Task StartVideoCall(int conversationId, string offer) =>
        StartCall(conversationId, "video", offer);

    public async Task AnswerCall(int conversationId, string answer)
    {
        var (conversation, recipientUserId, _) = await GetCallTarget(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("CallAnswered", new
        {
            conversationId,
            conversation.PostId,
            answer
        });
    }

    public async Task SendIceCandidate(int conversationId, string candidate)
    {
        var (conversation, recipientUserId, _) = await GetCallTarget(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("IceCandidateReceived", new
        {
            conversationId,
            conversation.PostId,
            candidate
        });
    }

    public async Task EndCall(int conversationId)
    {
        var (conversation, recipientUserId, _) = await GetCallTarget(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("CallEnded", new
        {
            conversationId,
            conversation.PostId
        });
    }

    private async Task StartCall(int conversationId, string callType, string offer)
    {
        var (conversation, recipientUserId, callerUserId) = await GetCallTarget(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("IncomingCall", new
        {
            conversationId,
            conversation.PostId,
            conversation.PostTitle,
            callType,
            offer,
            callerUserId,
            callerName = callerUserId == conversation.RequesterUserId
                ? conversation.RequesterName
                : conversation.PostOwnerName
        });
    }

    private async Task<(PostChatConversationDto Conversation, string RecipientUserId, string CallerUserId)> GetCallTarget(
        int conversationId)
    {
        var userId = GetUserId();
        var conversation = await _postChatService.GetConversationAsync(
            conversationId,
            userId,
            Context.ConnectionAborted);
        return (conversation, GetRecipientUserId(conversation, userId), userId);
    }

    private static string GetRecipientUserId(PostChatConversationDto conversation, string userId)
    {
        return string.Equals(conversation.RequesterUserId, userId, StringComparison.OrdinalIgnoreCase)
            ? conversation.PostOwnerUserId
            : conversation.RequesterUserId;
    }

    private string GetUserId()
    {
        return GetUserIdOrNull()
            ?? throw new HubException("User ID is required.");
    }

    private string? GetUserIdOrNull()
    {
        var httpContext = Context.GetHttpContext();
        return httpContext?.Request.Query["userId"].FirstOrDefault()?.Trim();
    }

    private static string UserGroup(string userId) => $"post-user:{userId}";
    private static string ConversationGroup(int conversationId) => $"post-conversation:{conversationId}";
}
