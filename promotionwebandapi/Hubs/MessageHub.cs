using Microsoft.AspNetCore.SignalR;

namespace OrderProcessAPI.Hubs;

public sealed class MessageHub : Hub<IMessageClient>
{
}
