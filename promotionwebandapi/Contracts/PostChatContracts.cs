namespace OrderProcessAPI.Contracts;

public sealed class OpenPostChatRequest
{
    public string UserId { get; init; } = string.Empty;
}

public sealed class SendPostChatMessageRequest
{
    public string UserId { get; init; } = string.Empty;
    public string MessageText { get; init; } = string.Empty;
}

public sealed class PostChatConversationDto
{
    public int Id { get; set; }
    public int PostId { get; set; }
    public string PostTitle { get; set; } = string.Empty;
    public string RequesterUserId { get; set; } = string.Empty;
    public string RequesterName { get; set; } = string.Empty;
    public string PostOwnerUserId { get; set; } = string.Empty;
    public string PostOwnerName { get; set; } = string.Empty;
    public string LastMessage { get; set; } = string.Empty;
    public DateTime? LastMessageOn { get; set; }
    public int UnreadCount { get; set; }
    public IReadOnlyList<PostChatMessageDto> Messages { get; set; } = Array.Empty<PostChatMessageDto>();
}

public sealed class PostChatMessageDto
{
    public long Id { get; init; }
    public int ConversationId { get; init; }
    public string SenderUserId { get; init; } = string.Empty;
    public string SenderName { get; init; } = string.Empty;
    public string SenderRole { get; init; } = string.Empty;
    public string MessageText { get; init; } = string.Empty;
    public DateTime SentOn { get; init; }
    public DateTime? ReadOn { get; init; }
}
