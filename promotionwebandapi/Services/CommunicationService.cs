using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class CommunicationService : ICommunicationService
{
    private readonly SqlConnectionFactory _connectionFactory;
    private readonly IMessageRealtimeService _messageRealtimeService;

    public CommunicationService(
        SqlConnectionFactory connectionFactory,
        IMessageRealtimeService messageRealtimeService)
    {
        _connectionFactory = connectionFactory;
        _messageRealtimeService = messageRealtimeService;
    }

    public async Task<IReadOnlyList<CommunicationMessageDto>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var items = await connection.QueryAsync<CommunicationMessageDto>(
            new CommandDefinition(
                """
                SELECT Id, Sender, Message, PropertyName, TimeLabel
                FROM dbo.Messages
                ORDER BY Id DESC;
                """,
                cancellationToken: cancellationToken));

        return items.ToList();
    }

    public async Task<CreateCommunicationMessageResponse> CreateAsync(
        CreateCommunicationMessageRequest request,
        CancellationToken cancellationToken = default)
    {
        var sender = request.Sender.Trim();
        var message = request.Message.Trim();
        var propertyName = request.PropertyName.Trim();

        if (string.IsNullOrWhiteSpace(sender) || sender.Length < 2)
        {
            throw new CommunicationValidationException(
                "Sender name must contain at least 2 characters.");
        }

        if (string.IsNullOrWhiteSpace(message) || message.Length < 2)
        {
            throw new CommunicationValidationException(
                "Message must contain at least 2 characters.");
        }

        if (string.IsNullOrWhiteSpace(propertyName))
        {
            throw new CommunicationValidationException("Property name is required.");
        }

        var timeLabel = DateTime.Now.ToString("hh:mm tt");

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var messageId = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                INSERT INTO dbo.Messages (Sender, Message, PropertyName, TimeLabel)
                OUTPUT INSERTED.Id
                VALUES (@Sender, @Message, @PropertyName, @TimeLabel);
                """,
                new
                {
                    Sender = sender,
                    Message = message,
                    PropertyName = propertyName,
                    TimeLabel = timeLabel,
                },
                cancellationToken: cancellationToken));

        var createdMessage = new CommunicationMessageDto
        {
            Id = messageId,
            Sender = sender,
            Message = message,
            PropertyName = propertyName,
            TimeLabel = timeLabel,
        };

        await _messageRealtimeService.BroadcastMessageCreatedAsync(createdMessage);

        return new CreateCommunicationMessageResponse
        {
            Item = createdMessage,
            Message = "Message created successfully.",
        };
    }
}

public sealed class CommunicationValidationException : Exception
{
    public CommunicationValidationException(string message)
        : base(message)
    {
    }
}
