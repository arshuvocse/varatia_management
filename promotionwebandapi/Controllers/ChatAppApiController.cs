using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using PromotionWeb.Hubs;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

[ApiController]
[Route("api/chat-app")]
public sealed class ChatAppApiController(
    AppStore appStore,
    ChatStore chatStore,
    DeliveryApiTokenStore tokenStore,
    IHubContext<ChatHub> hubContext) : ControllerBase
{
    [HttpPost("login")]
    public IActionResult Login([FromBody] ChatAppLoginRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Phone) || string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new { success = false, message = "Phone and password are required." });
        }

        var user = appStore.ValidateUser(request.Phone.Trim(), request.Password);
        if (user is null || user.Role is not (Roles.Customer or Roles.Shopkeeper))
        {
            return Unauthorized(new { success = false, message = "Invalid chat app login." });
        }

        var token = tokenStore.Create(user.Id, user.Name, user.Phone, user.Role);
        return Ok(new
        {
            success = true,
            token,
            signalRUrl = "/hubs/chat?access_token=" + token,
            user = new
            {
                user.Id,
                user.Name,
                user.Phone,
                user.Role
            }
        });
    }

    [HttpPost("logout")]
    public IActionResult Logout()
    {
        tokenStore.Revoke(Request.Headers.Authorization);
        return Ok(new { success = true });
    }

    [HttpGet("shops")]
    public IActionResult Shops()
    {
        var session = GetSession();
        if (session is null) return UnauthorizedResponse();
        if (session.Role != Roles.Customer) return Forbid();

        return Ok(new
        {
            success = true,
            shops = appStore.GetShopkeepers().Select(shop => new
            {
                shop.Id,
                shop.ShopName,
                shop.OwnerName,
                shop.Phone,
                shop.Area,
                shop.Address,
                shop.ThanaName,
                shop.DistrictName,
                shop.Latitude,
                shop.Longitude,
                shop.ShopType
            })
        });
    }

    [HttpGet("inbox")]
    public IActionResult Inbox()
    {
        var session = GetSession();
        if (session is null) return UnauthorizedResponse();
        if (session.Role is not (Roles.Customer or Roles.Shopkeeper)) return Forbid();

        return Ok(new
        {
            success = true,
            unreadCount = chatStore.GetUnreadCount(session.UserId),
            conversations = chatStore.GetInbox(session.UserId)
        });
    }

    [HttpPost("shops/{shopkeeperId:int}/open")]
    public IActionResult OpenCustomerChat(int shopkeeperId)
    {
        var session = GetSession();
        if (session is null) return UnauthorizedResponse();
        if (session.Role != Roles.Customer) return Forbid();

        try
        {
            var conversation = chatStore.OpenForCustomer(session.UserId, shopkeeperId);
            chatStore.MarkRead(conversation.Id, session.UserId);
            return Ok(new { success = true, conversation });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    [HttpGet("conversations/{conversationId:int}")]
    public IActionResult Conversation(int conversationId)
    {
        var session = GetSession();
        if (session is null) return UnauthorizedResponse();

        try
        {
            var conversation = chatStore.OpenForUser(conversationId, session.UserId);
            chatStore.MarkRead(conversationId, session.UserId);
            return Ok(new { success = true, conversation });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    [HttpPost("conversations/{conversationId:int}/messages")]
    public async Task<IActionResult> SendMessage(int conversationId, [FromBody] ChatAppSendMessageRequest request)
    {
        var session = GetSession();
        if (session is null) return UnauthorizedResponse();

        try
        {
            var conversation = chatStore.OpenForUser(conversationId, session.UserId);
            var message = chatStore.SendMessage(conversationId, session.UserId, request.MessageText ?? "");
            var recipientUserId = session.UserId == conversation.CustomerUserId
                ? conversation.ShopkeeperUserId
                : conversation.CustomerUserId;

            await hubContext.Clients.Group(ConversationGroup(conversationId)).SendAsync("ReceiveMessage", message);
            await hubContext.Clients.Group(UserGroup(recipientUserId)).SendAsync("ReceiveNotification", new
            {
                conversationId,
                message.SenderName,
                message.MessageText,
                message.SentAt,
                conversation.CustomerName,
                conversation.CustomerPhone,
                conversation.ShopName,
                conversation.ShopkeeperPhone
            });

            return Ok(new { success = true, message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    [HttpPost("conversations/{conversationId:int}/read")]
    public IActionResult MarkRead(int conversationId)
    {
        var session = GetSession();
        if (session is null) return UnauthorizedResponse();

        try
        {
            chatStore.MarkRead(conversationId, session.UserId);
            return Ok(new { success = true, unreadCount = chatStore.GetUnreadCount(session.UserId) });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    private DeliveryApiSession? GetSession() => tokenStore.Get(Request.Headers.Authorization);

    private UnauthorizedObjectResult UnauthorizedResponse() =>
        Unauthorized(new { success = false, message = "Login expired. Please login again." });

    private static string UserGroup(int userId) => $"user:{userId}";
    private static string ConversationGroup(int conversationId) => $"conversation:{conversationId}";
}
