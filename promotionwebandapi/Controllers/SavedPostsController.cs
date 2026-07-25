using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Services;
using System.Security.Claims;
using System.Threading.Tasks;

namespace OrderProcessAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SavedPostsController : ControllerBase
    {
        private readonly ISavedPostsService _savedPostsService;

        public SavedPostsController(ISavedPostsService savedPostsService)
        {
            _savedPostsService = savedPostsService;
        }

        public class ToggleSavedPostRequest
        {
            public string UserId { get; set; } = string.Empty;
            public int PostId { get; set; }
            public string PostType { get; set; } = string.Empty;
        }

        [HttpPost("toggle")]
        public async Task<IActionResult> ToggleSavedPost([FromBody] ToggleSavedPostRequest request)
        {
            if (string.IsNullOrEmpty(request.UserId))
            {
                return BadRequest("UserId is required.");
            }

            var result = await _savedPostsService.ToggleSavedPostAsync(request.UserId, request.PostId, request.PostType);
            return Ok(result);
        }

        [HttpGet("{userId}")]
        public async Task<IActionResult> GetSavedPosts(string userId)
        {
            if (string.IsNullOrEmpty(userId))
            {
                return BadRequest("UserId is required.");
            }

            var result = await _savedPostsService.GetSavedPostsAsync(userId);
            return Ok(result);
        }
    }
}
