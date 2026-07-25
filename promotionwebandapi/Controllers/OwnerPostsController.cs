using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/owner/post")]
public sealed class OwnerPostsController : ControllerBase
{
    private readonly IOwnerPostService _ownerPostService;

    public OwnerPostsController(IOwnerPostService ownerPostService)
    {
        _ownerPostService = ownerPostService;
    }

    [HttpGet]
    public async Task<ActionResult<OwnerPostListResponse>> GetPosts(
        [FromQuery] string? ownerId,
        [FromQuery] string? status,
        CancellationToken cancellationToken)
    {
        var response = await _ownerPostService.GetPostsAsync(
            ownerId,
            status,
            cancellationToken);

        return Ok(response);
    }

    [HttpPost]
    public async Task<ActionResult<CreateOwnerPostResponse>> CreatePost(
        [FromBody] CreateOwnerPostRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _ownerPostService.CreatePostAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (OwnerPostValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }
}
