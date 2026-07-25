namespace PromotionWeb.Models;

public sealed class ChatConversationViewModel
{
    public int Id { get; init; }
    public int CustomerUserId { get; init; }
    public int ShopkeeperUserId { get; init; }
    public int ShopkeeperId { get; init; }
    public string CustomerName { get; init; } = "";
    public string CustomerPhone { get; init; } = "";
    public string ShopName { get; init; } = "";
    public string ShopkeeperPhone { get; init; } = "";
    public string LastMessage { get; init; } = "";
    public DateTime? LastMessageAt { get; init; }
    public int UnreadCount { get; init; }
    public IReadOnlyList<ChatMessageViewModel> Messages { get; init; } = [];
}

public sealed class ChatMessageViewModel
{
    public long Id { get; init; }
    public int ConversationId { get; init; }
    public int SenderUserId { get; init; }
    public string SenderName { get; init; } = "";
    public string SenderRole { get; init; } = "";
    public string MessageType { get; init; } = "Text";
    public string MessageText { get; init; } = "";
    public string? MediaUrl { get; init; }
    public DateTime SentAt { get; init; }
}

public sealed class ChatAppLoginRequest
{
    public string Phone { get; set; } = "";
    public string Password { get; set; } = "";
}

public sealed class ChatAppSendMessageRequest
{
    public string MessageText { get; set; } = "";
}
