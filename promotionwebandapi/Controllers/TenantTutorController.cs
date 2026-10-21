using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/tenant/tutor")]
public sealed class TenantTutorController : ControllerBase
{
    private readonly ITenantTutorService _tenantTutorService;
    private readonly IPostingEntitlementService _postingEntitlementService;

    public TenantTutorController(
        ITenantTutorService tenantTutorService,
        IPostingEntitlementService postingEntitlementService)
    {
        _tenantTutorService = tenantTutorService;
        _postingEntitlementService = postingEntitlementService;
    }

    [HttpGet("posts")]
    public async Task<ActionResult<TenantTutorPostListResponse>> GetPosts(
        [FromQuery] string? tenantId,
        [FromQuery] string? type,
        [FromQuery] string? subject,
        [FromQuery] string? area,
        [FromQuery] bool verifiedOnly,
        [FromQuery] int page,
        [FromQuery] int limit,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _tenantTutorService.GetPostsAsync(
                tenantId,
                type,
                subject,
                area,
                verifiedOnly,
                page,
                limit,
                cancellationToken);

            return Ok(response);
        }
        catch (TenantTutorValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpPost("posts")]
    public async Task<ActionResult<CreateTenantTutorPostResponse>> CreatePost(
        [FromBody] CreateTenantTutorPostRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var userId = request.TenantId;
            if (!string.IsNullOrWhiteSpace(userId))
            {
                var entitlement = await _postingEntitlementService.GetEntitlementAsync(userId, cancellationToken);
                if (!entitlement.CanPost)
                {
                    return StatusCode(
                        StatusCodes.Status402PaymentRequired,
                        new
                        {
                            message = "You have exhausted your 4 free posts. A payment of at least BDT 100 is required to post.",
                            requiresPayment = true,
                            freePostsAllowed = entitlement.FreePostsAllowed,
                            freePostsUsed = entitlement.FreePostsUsed,
                            minimumPaymentAmount = entitlement.MinimumPaymentAmount
                        });
                }
            }

            var response = await _tenantTutorService.CreatePostAsync(
                request,
                cancellationToken);

            if (!string.IsNullOrWhiteSpace(userId))
            {
                await _postingEntitlementService.ConsumePostingSlotAsync(userId, cancellationToken);
            }

            return Ok(response);
        }
        catch (TenantTutorValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpGet("profile/{userId}")]
    public async Task<ActionResult<TutorBdjobsProfileDto>> GetProfile(
        string userId,
        CancellationToken cancellationToken)
    {
        try
        {
            var profile = await _tenantTutorService.GetTutorProfileAsync(
                userId,
                cancellationToken);

            if (profile == null)
            {
                return NotFound(new { message = "Tutor profile not found." });
            }

            return Ok(profile);
        }
        catch (TenantTutorValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpPost("profile")]
    public async Task<ActionResult<TutorBdjobsProfileResponse>> SaveProfile(
        [FromBody] SaveTutorBdjobsProfileRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _tenantTutorService.SaveTutorProfileAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (TenantTutorValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }
}
