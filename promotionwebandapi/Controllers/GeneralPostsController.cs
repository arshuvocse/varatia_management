using System.IO;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/general-posts")]
public sealed class GeneralPostsController : ControllerBase
{
    private const long MaxUploadBytes = 100L * 1024L * 1024L;

    private static readonly HashSet<string> AllowedUploadExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp",
        ".gif",
        ".mp4",
        ".mov",
        ".webm"
    };

    private readonly IGeneralPostService _generalPostService;
    private readonly IPostingEntitlementService _postingEntitlementService;
    private readonly IWebHostEnvironment _environment;

    public GeneralPostsController(
        IGeneralPostService generalPostService,
        IPostingEntitlementService postingEntitlementService,
        IWebHostEnvironment environment)
    {
        _generalPostService = generalPostService;
        _postingEntitlementService = postingEntitlementService;
        _environment = environment;
    }

    [HttpPost]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(MaxUploadBytes)]
    [RequestFormLimits(MultipartBodyLengthLimit = MaxUploadBytes)]
    public async Task<ActionResult<CreateGeneralPostResponse>> CreateGeneralPost(
        [FromForm] CreateGeneralPostRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.UserId))
        {
            return BadRequest(new { message = "User ID is required." });
        }
        if (string.IsNullOrWhiteSpace(request.Category))
        {
            return BadRequest(new { message = "Category is required." });
        }
        if (string.IsNullOrWhiteSpace(request.Title))
        {
            return BadRequest(new { message = "Title is required." });
        }
        if (string.IsNullOrWhiteSpace(request.DivisionId))
        {
            return BadRequest(new { message = "Division ID is required." });
        }
        if (string.IsNullOrWhiteSpace(request.AreaId))
        {
            return BadRequest(new { message = "Area ID is required." });
        }

        PostingEntitlementDto entitlement;
        try
        {
            entitlement = await _postingEntitlementService.GetEntitlementAsync(
                request.UserId,
                cancellationToken);
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { message = exception.Message });
        }

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
                    minimumPaymentAmount = entitlement.MinimumPaymentAmount,
                });
        }

        var mediaPaths = new List<string>();
        if (request.Files != null && request.Files.Count > 0)
        {
            var uploadsFolder = Path.Combine(_environment.ContentRootPath, "uploads");

            try
            {
                Directory.CreateDirectory(uploadsFolder);
            }
            catch (Exception exception) when (exception is UnauthorizedAccessException or IOException)
            {
                return StatusCode(
                    StatusCodes.Status500InternalServerError,
                    new { message = $"Upload folder is not writable: {uploadsFolder}" });
            }

            foreach (var file in request.Files)
            {
                if (file.Length > 0)
                {
                    if (file.Length > MaxUploadBytes)
                    {
                        return BadRequest(new { message = "Each upload must be 100 MB or smaller." });
                    }

                    var extension = Path.GetExtension(file.FileName);
                    if (!AllowedUploadExtensions.Contains(extension))
                    {
                        return BadRequest(new { message = "Only JPG, PNG, WebP, GIF, MP4, MOV and WebM files are allowed." });
                    }

                    var uniqueFileName = $"{Guid.NewGuid():N}{extension}";
                    var filePath = Path.Combine(uploadsFolder, uniqueFileName);

                    try
                    {
                        await using var stream = new FileStream(filePath, FileMode.CreateNew);
                        await file.CopyToAsync(stream, cancellationToken);
                    }
                    catch (Exception exception) when (exception is UnauthorizedAccessException or IOException)
                    {
                        return StatusCode(
                            StatusCodes.Status500InternalServerError,
                            new { message = $"Could not save upload to: {uploadsFolder}" });
                    }

                    mediaPaths.Add($"/uploads/{uniqueFileName}");
                }
            }
        }

        if (mediaPaths.Count > 0)
        {
            request.MediaInfo = string.Join(", ", mediaPaths);
        }

        var response = await _generalPostService.CreatePostAsync(request, cancellationToken);
        await _postingEntitlementService.ConsumePostingSlotAsync(request.UserId, cancellationToken);
        return Ok(response);
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<GeneralPostDto>>> GetGeneralPosts(
        [FromQuery] string? userId,
        CancellationToken cancellationToken)
    {
        var posts = await _generalPostService.GetActivePostsAsync(
            userId,
            GetPublicBaseUrl(),
            cancellationToken);
        return Ok(posts);
    }

    [HttpGet("{postId:int}")]
    public async Task<ActionResult<GeneralPostDto>> GetGeneralPostDetails(
        int postId,
        [FromQuery] string? userId,
        CancellationToken cancellationToken)
    {
        var post = await _generalPostService.GetPostByIdAsync(
            postId,
            userId,
            GetPublicBaseUrl(),
            cancellationToken);

        if (post is null)
        {
            return NotFound(new { message = "General post was not found." });
        }

        return Ok(post);
    }

    [HttpPost("{postId:int}/likes")]
    public async Task<ActionResult<GeneralPostLikeResponse>> LikeGeneralPost(
        int postId,
        [FromBody] GeneralPostLikeRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _generalPostService.LikePostAsync(
                postId,
                request.UserId,
                cancellationToken);

            return Ok(response);
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (InvalidOperationException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    [HttpDelete("{postId:int}/likes")]
    public async Task<ActionResult<GeneralPostLikeResponse>> UnlikeGeneralPost(
        int postId,
        [FromQuery] string userId,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _generalPostService.UnlikePostAsync(
                postId,
                userId,
                cancellationToken);

            return Ok(response);
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (InvalidOperationException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    [HttpGet("{postId:int}/comments")]
    public async Task<ActionResult<IReadOnlyList<GeneralPostCommentDto>>> GetGeneralPostComments(
        int postId,
        CancellationToken cancellationToken)
    {
        try
        {
            var comments = await _generalPostService.GetCommentsAsync(postId, cancellationToken);
            return Ok(comments);
        }
        catch (InvalidOperationException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    [HttpPost("{postId:int}/comments")]
    public async Task<ActionResult<GeneralPostCommentDto>> AddGeneralPostComment(
        int postId,
        [FromBody] CreateGeneralPostCommentRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var comment = await _generalPostService.AddCommentAsync(
                postId,
                request,
                cancellationToken);

            return Ok(comment);
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (InvalidOperationException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    private string GetPublicBaseUrl()
    {
        var forwardedProto = Request.Headers["X-Forwarded-Proto"].FirstOrDefault();
        var forwardedHost = Request.Headers["X-Forwarded-Host"].FirstOrDefault();
        var scheme = string.IsNullOrWhiteSpace(forwardedProto) ? Request.Scheme : forwardedProto;
        var host = string.IsNullOrWhiteSpace(forwardedHost) ? Request.Host.Value : forwardedHost;

        return $"{scheme}://{host}";
    }
}
