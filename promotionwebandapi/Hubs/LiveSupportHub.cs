using Microsoft.AspNetCore.SignalR;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Hubs;

public sealed class LiveSupportHub(LiveSupportStore store) : Hub
{
    private const int MaxMessageLength = 2000;

    // Guests call this method to initialize their session
    public async Task<bool> JoinSession(string sessionId, string name, string phone)
    {
        sessionId = NormalizeSessionId(sessionId);
        name = RequiredText(name, 150, "Name");
        phone = RequiredText(phone, 20, "Phone");
        if (!System.Text.RegularExpressions.Regex.IsMatch(phone, @"^01\d{9}$"))
            throw new HubException("Please provide a valid 11-digit mobile number.");

        var session = store.CreateSession(sessionId, name, phone);
        if (session.Status == "Resolved")
        {
            await Clients.Caller.SendAsync("SessionClosed");
            return false;
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, $"session:{sessionId}");
        Context.Items["LiveSupportSessionId"] = sessionId;
        
        // Notify agents that a session has been updated/started
        await Clients.Group("Agents").SendAsync("SessionUpdated", session);
        
        // Send history back to the guest
        var messages = store.GetMessages(sessionId);
        await Clients.Caller.SendAsync("LoadHistory", messages);
        return true;
    }

    // Guests call this method to send a message
    public async Task SendGuestMessage(string sessionId, string messageText)
    {
        sessionId = NormalizeSessionId(sessionId);
        if (!string.Equals(Context.Items["LiveSupportSessionId"] as string, sessionId, StringComparison.Ordinal))
            throw new HubException("Join this chat session before sending a message.");

        messageText = RequiredText(messageText, MaxMessageLength, "Message");
        var session = store.GetSession(sessionId);
        if (session is null || session.Status is not ("Active" or "Assigned"))
            throw new HubException("This chat is no longer active.");

        var message = store.AddMessage(sessionId, "Guest", null, messageText);
        
        // Send to everyone in the session group (guest + assigned agent)
        await Clients.Group($"session:{sessionId}").SendAsync("ReceiveMessage", message);
        
        // Send a notification to all agents in the "Agents" group
        await Clients.Group("Agents").SendAsync("IncomingGuestMessage", sessionId, message);
    }

    // Agents call this to join the dashboard
    public async Task JoinDashboard()
    {
        EnsureSupportAgent();
        var agentId = GetUserId();
        await Groups.AddToGroupAsync(Context.ConnectionId, "Agents");
        await Groups.AddToGroupAsync(Context.ConnectionId, $"agent:{agentId}");
        
        // Send active sessions to agent
        var activeSessions = store.GetActiveSessions();
        await Clients.Caller.SendAsync("LoadActiveSessions", activeSessions);
    }

    // Agents call this to claim a session
    public async Task ClaimSession(string sessionId)
    {
        sessionId = NormalizeSessionId(sessionId);
        EnsureSupportAgent();
        var agentId = GetUserId();
        if (!store.AssignSession(sessionId, agentId))
            throw new HubException("This chat has already been assigned to another support agent.");
        
        // Add agent to the session group
        await Groups.AddToGroupAsync(Context.ConnectionId, $"session:{sessionId}");
        
        // Load history for agent
        var messages = store.GetMessages(sessionId);
        await Clients.Caller.SendAsync("SessionHistory", sessionId, messages);
        
        // Broadcast to all agents that session is claimed
        await Clients.Group("Agents").SendAsync("SessionClaimed", sessionId, agentId);
        
        // Notify the guest that an agent joined
        var agentInfo = store.GetAgentInfo(agentId);
        await Clients.Group($"session:{sessionId}").SendAsync("AgentJoined", agentInfo);
    }

    // Agents call this to reply to a guest
    public async Task SendAgentMessage(string sessionId, string messageText)
    {
        sessionId = NormalizeSessionId(sessionId);
        messageText = RequiredText(messageText, MaxMessageLength, "Message");
        EnsureSupportAgent();
        var agentId = GetUserId();
        var session = store.GetSession(sessionId);
        if (session?.AssignedAgentId != agentId || session.Status != "Assigned")
            throw new HubException("Claim this chat before replying.");
        var message = store.AddMessage(sessionId, "Agent", agentId, messageText);
        
        // Populate agent details before broadcasting
        var agentInfo = store.GetAgentInfo(agentId);
        var messageObj = new
        {
            message.MessageId,
            message.SessionId,
            message.SenderType,
            message.SenderId,
            message.MessageText,
            message.SentAt,
            AgentName = agentInfo?.Name,
            AgentProfilePictureUrl = agentInfo?.ProfilePictureUrl
        };

        // Broadcast to guest and agent
        await Clients.Group($"session:{sessionId}").SendAsync("ReceiveMessage", messageObj);
    }
    
    public async Task ResolveSession(string sessionId)
    {
        sessionId = NormalizeSessionId(sessionId);
        EnsureSupportAgent();
        var agentId = GetUserId();
        var session = store.GetSession(sessionId);
        if (session?.AssignedAgentId != agentId)
            throw new HubException("Only the assigned support agent can resolve this chat.");
        store.ResolveSession(sessionId);
        await Clients.Group($"session:{sessionId}").SendAsync("SessionResolved", sessionId);
        await Clients.Group("Agents").SendAsync("SessionResolved", sessionId);
    }

    public async Task<object> OpenSession(string sessionId)
    {
        sessionId = NormalizeSessionId(sessionId);
        EnsureSupportAgent();
        var agentId = GetUserId();
        var session = store.GetSession(sessionId)
            ?? throw new HubException("Chat session was not found.");
        var canReply = session.Status == "Assigned" && session.AssignedAgentId == agentId;
        if (canReply)
            await Groups.AddToGroupAsync(Context.ConnectionId, $"session:{sessionId}");

        return new
        {
            messages = store.GetMessages(sessionId),
            canReply,
            session.Status
        };
    }

    private int GetUserId()
    {
        var httpContext = Context.GetHttpContext();
        var userId = httpContext?.Session.GetInt32("UserId");
        if (userId == null)
            throw new HubException("Unauthorized. Please log in.");
        
        return userId.Value;
    }

    private void EnsureSupportAgent()
    {
        var role = Context.GetHttpContext()?.Session.GetString("UserRole");
        if (role is not (Roles.Agent or Roles.Company or Roles.SupportAgent))
            throw new HubException("Unauthorized support access.");
        if (role == Roles.SupportAgent && !store.IsUserActive(GetUserId()))
            throw new HubException("This support account is inactive.");
    }

    private static string NormalizeSessionId(string? sessionId)
    {
        var value = sessionId?.Trim();
        if (string.IsNullOrWhiteSpace(value) || value.Length > 100
            || !System.Text.RegularExpressions.Regex.IsMatch(value, @"^[A-Za-z0-9-]+$"))
            throw new HubException("Invalid chat session.");
        return value;
    }

    private static string RequiredText(string? value, int maxLength, string field)
    {
        var text = value?.Trim();
        if (string.IsNullOrWhiteSpace(text))
            throw new HubException($"{field} is required.");
        if (text.Length > maxLength)
            throw new HubException($"{field} cannot exceed {maxLength} characters.");
        return text;
    }
}
