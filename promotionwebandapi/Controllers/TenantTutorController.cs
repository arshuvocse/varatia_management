using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/tenant/tutor")]
public sealed class TenantTutorController : ControllerBase
{
    private readonly ITenantTutorService _tenantTutorService;

    public TenantTutorController(ITenantTutorService tenantTutorService)
    {
        _tenantTutorService = tenantTutorService;
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
            var response = await _tenantTutorService.CreatePostAsync(
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
