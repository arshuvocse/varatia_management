using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/notifications")]
public sealed class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public NotificationsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<NotificationListItemDto>>> GetAll(
        CancellationToken cancellationToken)
    {
        var response = await _notificationService.GetAllAsync(cancellationToken);
        return Ok(response);
    }

    [HttpPost("send")]
    public async Task<ActionResult<SendUserNotificationResponse>> SendToUser(
        [FromBody] SendUserNotificationRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _notificationService.SendToUserAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (NotificationValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (NotificationNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (FirebaseAdmin.Messaging.FirebaseMessagingException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpPost("{notificationId:int}/read")]
    public async Task<ActionResult<MarkNotificationReadResponse>> MarkAsRead(
        int notificationId,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _notificationService.MarkAsReadAsync(
                notificationId,
                cancellationToken);

            return Ok(response);
        }
        catch (NotificationValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (NotificationNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }
}
