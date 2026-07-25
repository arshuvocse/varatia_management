using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Hubs;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/post-chat")]
public sealed class PostChatController : ControllerBase
{
    private readonly IPostChatService _postChatService;
    private readonly IHubContext<PostChatHub> _hubContext;

    public PostChatController(
        IPostChatService postChatService,
        IHubContext<PostChatHub> hubContext)
    {
        _postChatService = postChatService;
        _hubContext = hubContext;
    }

    [HttpPost("posts/{postId:int}/open")]
    public async Task<ActionResult<PostChatConversationDto>> OpenPostChat(
        int postId,
        [FromBody] OpenPostChatRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var conversation = await _postChatService.OpenForPostAsync(
                postId,
                request.UserId,
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
    public async Task<ActionResult<IReadOnlyList<PostChatConversationDto>>> GetInbox(
        [FromQuery] string userId,
        CancellationToken cancellationToken)
    {
        try
        {
            var conversations = await _postChatService.GetInboxAsync(userId, cancellationToken);
            return Ok(new { success = true, conversations });
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { success = false, message = exception.Message });
        }
    }

    [HttpGet("conversations/{conversationId:int}")]
    public async Task<ActionResult<PostChatConversationDto>> GetConversation(
        int conversationId,
        [FromQuery] string userId,
        CancellationToken cancellationToken)
    {
        try
        {
            var conversation = await _postChatService.GetConversationAsync(
                conversationId,
                userId,
                cancellationToken);
            await _postChatService.MarkReadAsync(conversationId, userId, cancellationToken);

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
    public async Task<ActionResult<PostChatMessageDto>> SendMessage(
        int conversationId,
        [FromBody] SendPostChatMessageRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var conversation = await _postChatService.GetConversationAsync(
                conversationId,
                request.UserId,
                cancellationToken);
            var message = await _postChatService.SendMessageAsync(
                conversationId,
                request.UserId,
                request.MessageText,
                cancellationToken);
            var recipientUserId = string.Equals(
                    conversation.RequesterUserId,
                    request.UserId,
                    StringComparison.OrdinalIgnoreCase)
                ? conversation.PostOwnerUserId
                : conversation.RequesterUserId;

            await _hubContext.Clients.Group(ConversationGroup(conversationId)).SendAsync("ReceiveMessage", message);
            await _hubContext.Clients.Group(UserGroup(recipientUserId)).SendAsync("ReceiveNotification", new
            {
                conversationId,
                conversation.PostId,
                conversation.PostTitle,
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
            return BadRequest(new { success = false, message = exception.Message });
        }
    }

    [HttpPost("conversations/{conversationId:int}/read")]
    public async Task<IActionResult> MarkRead(
        int conversationId,
        [FromBody] OpenPostChatRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            await _postChatService.MarkReadAsync(conversationId, request.UserId, cancellationToken);
            return Ok(new { success = true });
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

    private static string UserGroup(string userId) => $"post-user:{userId}";
    private static string ConversationGroup(int conversationId) => $"post-conversation:{conversationId}";
}
