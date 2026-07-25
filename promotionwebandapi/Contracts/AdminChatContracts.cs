namespace OrderProcessAPI.Contracts;

public sealed class AdminChatConversationDto
{
    public int Id { get; init; }
    public string RequesterUserId { get; init; } = "";
    public string RequesterName { get; init; } = "";
    public string AdminUserId { get; init; } = "";
    public string AdminName { get; init; } = "";
    public string LastMessage { get; init; } = "";
    public DateTime? LastMessageOn { get; init; }
    public int UnreadCount { get; init; }
}

public sealed class AdminChatMessageDto
{
    public long Id { get; init; }
    public int ConversationId { get; init; }
    public string SenderUserId { get; init; } = "";
    public string SenderName { get; init; } = "";
    public string MessageText { get; init; } = "";
    public DateTime SentOn { get; init; }
}

public sealed class AdminContactDto
{
    public string UserId { get; init; } = "";
    public string FullName { get; init; } = "";
    public string PhoneNumber { get; init; } = "";
}

public sealed class OpenAdminChatRequest
{
    public string RequesterUserId { get; set; } = "";
    public string AdminUserId { get; set; } = "";
}

public sealed class SendAdminChatMessageRequest
{
    public string SenderUserId { get; set; } = "";
    public string MessageText { get; set; } = "";
}
