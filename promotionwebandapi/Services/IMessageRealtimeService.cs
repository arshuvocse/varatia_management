using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IMessageRealtimeService
{
    Task BroadcastMessageCreatedAsync(CommunicationMessageDto message);
}
