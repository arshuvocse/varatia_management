using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/tenant/area")]
public sealed class TenantAreaController : ControllerBase
{
    private readonly ITenantAreaService _tenantAreaService;

    public TenantAreaController(ITenantAreaService tenantAreaService)
    {
        _tenantAreaService = tenantAreaService;
    }

    [HttpGet("home")]
    public async Task<ActionResult<TenantAreaHomeResponse>> GetHome(
        [FromQuery] string? tenantId,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _tenantAreaService.GetHomeAsync(
                tenantId,
                cancellationToken);

            return Ok(response);
        }
        catch (TenantAreaValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpGet("wards")]
    public async Task<ActionResult<TenantAreaWardsResponse>> GetWards(
        [FromQuery] string? tenantId,
        [FromQuery] string? city,
        [FromQuery] string? search,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _tenantAreaService.GetWardsAsync(
                tenantId,
                city,
                search,
                cancellationToken);

            return Ok(response);
        }
        catch (TenantAreaValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpGet("posts")]
    public async Task<ActionResult<TenantAreaPostsResponse>> GetPosts(
        [FromQuery] string? tenantId,
        [FromQuery] string? wardId,
        [FromQuery] string? category,
        [FromQuery] int page,
        [FromQuery] int limit,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _tenantAreaService.GetPostsAsync(
                tenantId,
                wardId,
                category,
                page,
                limit,
                cancellationToken);

            return Ok(response);
        }
        catch (TenantAreaValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpPost("posts")]
    public async Task<ActionResult<CreateTenantAreaPostResponse>> CreatePost(
        [FromBody] CreateTenantAreaPostRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _tenantAreaService.CreatePostAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (TenantAreaValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (TenantAreaNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }
}
