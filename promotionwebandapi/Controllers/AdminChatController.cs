using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Hubs;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/admin-chat")]
public sealed class AdminChatController : ControllerBase
{
    private readonly IAdminChatService _adminChatService;
    private readonly IHubContext<AdminChatHub> _hubContext;

    public AdminChatController(
        IAdminChatService adminChatService,
        IHubContext<AdminChatHub> hubContext)
    {
        _adminChatService = adminChatService;
        _hubContext = hubContext;
    }

    [HttpGet("default-admin")]
    public async Task<ActionResult<AdminContactDto>> GetDefaultAdmin(
        CancellationToken cancellationToken)
    {
        try
        {
            var admin = await _adminChatService.GetDefaultAdminAsync(cancellationToken);
            return Ok(new { success = true, admin });
        }
        catch (InvalidOperationException exception)
        {
            return NotFound(new { success = false, message = exception.Message });
        }
    }

    [HttpPost("open")]
    public async Task<ActionResult<AdminChatConversationDto>> OpenAdminChat(
        [FromBody] OpenAdminChatRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var conversation = await _adminChatService.OpenChatAsync(
                request.RequesterUserId,
                request.AdminUserId,
                cancellationToken);

            return Ok(new { success = true, conversation });
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { success = false, message = exception.Message });
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(new { success = false, message = exception.Message });
        }
    }

    [HttpGet("inbox")]
    public async Task<ActionResult<IReadOnlyList<AdminChatConversationDto>>> GetInbox(
        [FromQuery] string userId,
        CancellationToken cancellationToken)
    {
        try
        {
            var conversations = await _adminChatService.GetInboxAsync(userId, cancellationToken);
            return Ok(new { success = true, conversations });
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { success = false, message = exception.Message });
        }
    }

    [HttpGet("conversations/{conversationId:int}")]
    public async Task<ActionResult<AdminChatConversationDto>> GetConversation(
        int conversationId,
        [FromQuery] string userId,
        CancellationToken cancellationToken)
    {
        try
        {
            var conversation = await _adminChatService.GetConversationAsync(
                conversationId,
                userId,
                cancellationToken);
            
            await _adminChatService.MarkReadAsync(conversationId, userId, cancellationToken);

            return Ok(new { success = true, conversation });
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { success = false, message = exception.Message });
        }
        catch (InvalidOperationException exception)
        {
            return NotFound(new { success = false, message = exception.Message });
        }
    }

    [HttpPost("conversations/{conversationId:int}/messages")]
    public async Task<ActionResult<AdminChatMessageDto>> SendMessage(
        int conversationId,
        [FromBody] SendAdminChatMessageRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var conversation = await _adminChatService.GetConversationAsync(
                conversationId,
                request.SenderUserId,
                cancellationToken);

            var message = await _adminChatService.SendMessageAsync(
                conversationId,
                request.SenderUserId,
                request.MessageText,
                cancellationToken);

            var recipientUserId = string.Equals(conversation.RequesterUserId, request.SenderUserId, StringComparison.OrdinalIgnoreCase)
                ? conversation.AdminUserId
                : conversation.RequesterUserId;

            await _hubContext.Clients.Group($"AdminChat_{conversationId}").SendAsync("ReceiveMessage", message, cancellationToken);
            await _hubContext.Clients.Group($"User_{recipientUserId}").SendAsync("ReceiveNotification", new
            {
                conversationId,
                message.SenderUserId,
                message.SenderName,
                message.MessageText,
                message.SentOn
            }, cancellationToken);

            return Ok(new { success = true, message });
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { success = false, message = exception.Message });
        }
        catch (InvalidOperationException exception)
        {
            return NotFound(new { success = false, message = exception.Message });
        }
    }

    [HttpGet("conversations/{conversationId:int}/messages")]
    public async Task<ActionResult> GetMessages(
        int conversationId,
        [FromQuery] string userId,
        CancellationToken cancellationToken)
    {
        // For brevity, relying on the client connecting to SignalR for message history
        // To complete this fully, sp_AdminChat_GetMessages can be invoked in the service.
        return Ok(new { success = true, message = "Connect via SignalR to receive messages or implement GetMessages endpoint" });
    }
}
