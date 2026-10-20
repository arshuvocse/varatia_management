using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/contact-requests")]
public sealed class ContactRequestsController : ControllerBase
{
    private readonly IContactRequestService _contactRequestService;

    public ContactRequestsController(IContactRequestService contactRequestService)
    {
        _contactRequestService = contactRequestService;
    }

    [HttpPost]
    public async Task<ActionResult<ContactAccessStatusResponse>> CreateRequest(
        [FromBody] CreateContactAccessRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _contactRequestService.CreateRequestAsync(request, cancellationToken);
            return Ok(response);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("status")]
    public async Task<ActionResult<ContactAccessStatusResponse>> GetStatus(
        [FromQuery] string requesterUserId,
        [FromQuery] string postType,
        [FromQuery] int postId,
        CancellationToken cancellationToken)
    {
        var response = await _contactRequestService.GetStatusAsync(
            requesterUserId,
            postType,
            postId,
            cancellationToken);

        return Ok(response);
    }

    [HttpGet("admin/all")]
    public async Task<ActionResult<IReadOnlyList<ContactAccessRequestDto>>> GetAll(
        [FromQuery] string? status,
        CancellationToken cancellationToken)
    {
        var response = await _contactRequestService.GetAllRequestsAsync(status, cancellationToken);
        return Ok(response);
    }

    [HttpPost("admin/review")]
    public async Task<ActionResult> Review(
        [FromBody] ReviewContactRequestInput input,
        CancellationToken cancellationToken)
    {
        var adminPhone = User.Identity?.Name ?? "admin";
        var success = await _contactRequestService.ReviewRequestAsync(
            input.RequestId,
            input.Approve,
            adminPhone,
            input.Reason,
            cancellationToken);

        if (!success)
        {
            return NotFound(new { message = "Request not found." });
        }

        return Ok(new { success = true });
    }
}
