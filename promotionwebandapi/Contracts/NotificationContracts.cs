namespace OrderProcessAPI.Contracts;

public sealed class SendUserNotificationRequest
{
    public string UserId { get; init; } = string.Empty;
    public string Title { get; init; } = string.Empty;
    public string Body { get; init; } = string.Empty;
    public IReadOnlyDictionary<string, string>? Data { get; init; }
}

public sealed class NotificationListItemDto
{
    public int Id { get; init; }
    public string Title { get; init; } = string.Empty;
    public string Subtitle { get; init; } = string.Empty;
    public DateTime CreatedAt { get; init; }
    public bool IsUnread { get; init; }
}

public sealed class SendUserNotificationResponse
{
    public string UserId { get; init; } = string.Empty;
    public string FirebaseMessageId { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}

public sealed class MarkNotificationReadResponse
{
    public int NotificationId { get; init; }
    public string Message { get; init; } = string.Empty;
}
