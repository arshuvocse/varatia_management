namespace OrderProcessAPI.Contracts;

public sealed class CommunicationMessageDto
{
    public int Id { get; init; }
    public string Sender { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public string PropertyName { get; init; } = string.Empty;
    public string TimeLabel { get; init; } = string.Empty;
}

public sealed class CreateCommunicationMessageRequest
{
    public string Sender { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public string PropertyName { get; init; } = string.Empty;
}

public sealed class CreateCommunicationMessageResponse
{
    public CommunicationMessageDto Item { get; init; } = new();
    public string Message { get; init; } = string.Empty;
}
