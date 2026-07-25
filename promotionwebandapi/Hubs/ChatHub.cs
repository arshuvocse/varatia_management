using Microsoft.AspNetCore.SignalR;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Hubs;

public sealed class ChatHub(ChatStore chatStore, DeliveryApiTokenStore tokenStore) : Hub
{
    public override async Task OnConnectedAsync()
    {
        var userId = TryGetUserId();
        if (userId is null)
        {
            Context.Abort();
            return;
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, UserGroup(userId.Value));
        await base.OnConnectedAsync();
    }

    public async Task<ChatConversationViewModel> OpenCustomerChat(int shopkeeperId)
    {
        EnsureRole(Roles.Customer);
        var conversation = chatStore.OpenForCustomer(GetUserId(), shopkeeperId);
        await JoinAndRead(conversation.Id);
        return conversation;
    }

    public async Task<ChatConversationViewModel> OpenConversation(int conversationId)
    {
        var conversation = chatStore.OpenForUser(conversationId, GetUserId());
        await JoinAndRead(conversation.Id);
        return conversation;
    }

    public async Task SendMessage(int conversationId, string messageText)
    {
        var senderUserId = GetUserId();
        var conversation = chatStore.OpenForUser(conversationId, senderUserId);
        var message = chatStore.SendMessage(conversationId, senderUserId, messageText ?? "");
        var recipientUserId = senderUserId == conversation.CustomerUserId
            ? conversation.ShopkeeperUserId
            : conversation.CustomerUserId;

        await Clients.Group(ConversationGroup(conversationId)).SendAsync("ReceiveMessage", message);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("ReceiveNotification", new
        {
            conversationId,
            message.SenderName,
            message.MessageText,
            message.SentAt,
            conversation.CustomerName,
            conversation.CustomerPhone,
            conversation.ShopName,
            conversation.ShopkeeperPhone
        });
    }

    public async Task MarkRead(int conversationId)
    {
        chatStore.MarkRead(conversationId, GetUserId());
        await Clients.Caller.SendAsync("UnreadCountChanged", chatStore.GetUnreadCount(GetUserId()));
    }

    public async Task SendTypingStatus(int conversationId, bool isTyping)
    {
        var (conversation, recipientUserId) = GetCallRecipient(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("UserTyping", new
        {
            conversationId,
            isTyping
        });
    }

    public async Task StartAudioCall(int conversationId, string offer)
    {
        var (conversation, recipientUserId) = GetCallRecipient(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("IncomingAudioCall", new
        {
            conversationId,
            offer,
            callerName = GetUserId() == conversation.CustomerUserId
                ? conversation.CustomerName
                : conversation.ShopName
        });
    }

    public async Task AnswerAudioCall(int conversationId, string answer)
    {
        var (_, recipientUserId) = GetCallRecipient(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("AudioCallAnswered", new
        {
            conversationId,
            answer
        });
    }

    public async Task SendIceCandidate(int conversationId, string candidate)
    {
        var (_, recipientUserId) = GetCallRecipient(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("AudioIceCandidate", new
        {
            conversationId,
            candidate
        });
    }

    public async Task EndAudioCall(int conversationId)
    {
        var (_, recipientUserId) = GetCallRecipient(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("AudioCallEnded", new
        {
            conversationId
        });
    }

    public async Task StartVideoCall(int conversationId, string offer)
    {
        var (conversation, recipientUserId) = GetCallRecipient(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("IncomingVideoCall", new
        {
            conversationId,
            offer,
            callerName = GetUserId() == conversation.CustomerUserId
                ? conversation.CustomerName
                : conversation.ShopName
        });
    }

    public async Task AnswerVideoCall(int conversationId, string answer)
    {
        var (_, recipientUserId) = GetCallRecipient(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("VideoCallAnswered", new
        {
            conversationId,
            answer
        });
    }

    public async Task SendVideoIceCandidate(int conversationId, string candidate)
    {
        var (_, recipientUserId) = GetCallRecipient(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("VideoIceCandidate", new
        {
            conversationId,
            candidate
        });
    }

    public async Task EndVideoCall(int conversationId)
    {
        var (_, recipientUserId) = GetCallRecipient(conversationId);
        await Clients.Group(UserGroup(recipientUserId)).SendAsync("VideoCallEnded", new
        {
            conversationId
        });
    }

    private async Task JoinAndRead(int conversationId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, ConversationGroup(conversationId));
        chatStore.MarkRead(conversationId, GetUserId());
        await Clients.Caller.SendAsync("UnreadCountChanged", chatStore.GetUnreadCount(GetUserId()));
    }

    private int GetUserId()
    {
        var userId = TryGetUserId();
        return userId ?? throw new HubException("Your session has expired. Please login again.");
    }

    private int? TryGetUserId()
    {
        var httpContext = Context.GetHttpContext();
        return httpContext?.Session.GetInt32("UserId") ?? GetTokenSession()?.UserId;
    }

    private (ChatConversationViewModel Conversation, int RecipientUserId) GetCallRecipient(int conversationId)
    {
        var userId = GetUserId();
        var conversation = chatStore.OpenForUser(conversationId, userId);
        var recipientUserId = userId == conversation.CustomerUserId
            ? conversation.ShopkeeperUserId
            : conversation.CustomerUserId;
        return (conversation, recipientUserId);
    }

    private void EnsureRole(string role)
    {
        var httpContext = Context.GetHttpContext();
        var currentRole = httpContext?.Session.GetString("UserRole") ?? GetTokenSession()?.Role;
        if (currentRole != role)
        {
            throw new HubException("You are not allowed to perform this action.");
        }
    }

    private DeliveryApiSession? GetTokenSession()
    {
        var httpContext = Context.GetHttpContext();
        var authorization = httpContext?.Request.Headers.Authorization.ToString();
        var session = tokenStore.Get(authorization);
        if (session is not null) return session;

        var token = httpContext?.Request.Query["access_token"].FirstOrDefault();
        return tokenStore.GetToken(token);
    }

    private static string UserGroup(int userId) => $"user:{userId}";
    private static string ConversationGroup(int conversationId) => $"conversation:{conversationId}";
}
