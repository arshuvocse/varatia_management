using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Hubs;

public interface IMessageClient
{
    Task MessageCreated(CommunicationMessageDto message);
}
