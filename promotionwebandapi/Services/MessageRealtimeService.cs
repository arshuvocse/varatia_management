using Microsoft.AspNetCore.SignalR;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Hubs;

namespace OrderProcessAPI.Services;

public sealed class MessageRealtimeService : IMessageRealtimeService
{
    private readonly IHubContext<MessageHub, IMessageClient> _hubContext;
    private readonly ILogger<MessageRealtimeService> _logger;

    public MessageRealtimeService(
        IHubContext<MessageHub, IMessageClient> hubContext,
        ILogger<MessageRealtimeService> logger)
    {
        _hubContext = hubContext;
        _logger = logger;
    }

    public async Task BroadcastMessageCreatedAsync(CommunicationMessageDto message)
    {
        try
        {
            await _hubContext.Clients.All.MessageCreated(message);
        }
        catch (Exception exception)
        {
            _logger.LogWarning(
                exception,
                "Failed to broadcast message {MessageId} over SignalR.",
                message.Id);
        }
    }
}
