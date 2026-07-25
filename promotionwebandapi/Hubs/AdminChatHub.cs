using Microsoft.AspNetCore.SignalR;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Hubs;

public sealed class AdminChatHub : Hub
{
    private readonly IAdminChatService _adminChatService;

    public AdminChatHub(IAdminChatService adminChatService)
    {
        _adminChatService = adminChatService;
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
        await _adminChatService.GetConversationAsync(conversationId, userId, Context.ConnectionAborted);
        await Groups.AddToGroupAsync(Context.ConnectionId, ConversationGroup(conversationId));
        await _adminChatService.MarkReadAsync(conversationId, userId, Context.ConnectionAborted);
    }

    public async Task SendMessage(int conversationId, string messageText)
    {
        var userId = GetUserId();
        var conversation = await _adminChatService.GetConversationAsync(
            conversationId,
            userId,
            Context.ConnectionAborted);
        
        var message = await _adminChatService.SendMessageAsync(
            conversationId,
            userId,
            messageText ?? string.Empty,
            Context.ConnectionAborted);

        var recipientUserId = GetRecipientUserId(conversation, userId);

        await Clients.Group(ConversationGroup(conversationId)).SendAsync("ReceiveMessage", message);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("ReceiveNotification", new
        {
            conversationId,
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
            answer
        });
    }

    public async Task SendIceCandidate(int conversationId, string candidate)
    {
        var (conversation, recipientUserId, _) = await GetCallTarget(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("IceCandidateReceived", new
        {
            conversationId,
            candidate
        });
    }

    public async Task EndCall(int conversationId)
    {
        var (conversation, recipientUserId, _) = await GetCallTarget(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("CallEnded", new
        {
            conversationId
        });
    }

    private async Task StartCall(int conversationId, string type, string offer)
    {
        var (conversation, recipientUserId, callerUserId) = await GetCallTarget(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("IncomingCall", new
        {
            conversationId,
            type,
            offer,
            callerUserId
        });
    }

    private async Task<(AdminChatConversationDto Conversation, string RecipientUserId, string CallerUserId)> GetCallTarget(int conversationId)
    {
        var userId = GetUserId();
        var conversation = await _adminChatService.GetConversationAsync(
            conversationId,
            userId,
            Context.ConnectionAborted);
        var recipientUserId = GetRecipientUserId(conversation, userId);
        return (conversation, recipientUserId, userId);
    }

    private static string GetRecipientUserId(AdminChatConversationDto conversation, string userId)
    {
        return string.Equals(conversation.RequesterUserId, userId, StringComparison.OrdinalIgnoreCase)
            ? conversation.AdminUserId
            : conversation.RequesterUserId;
    }

    private string GetUserId() => GetUserIdOrNull() ?? throw new HubException("User ID is required.");

    private string? GetUserIdOrNull()
    {
        var httpContext = Context.GetHttpContext();
        return httpContext?.Request.Query["userId"];
    }

    private static string UserGroup(string userId) => $"User_{userId}";
    private static string ConversationGroup(int conversationId) => $"AdminChat_{conversationId}";
}
