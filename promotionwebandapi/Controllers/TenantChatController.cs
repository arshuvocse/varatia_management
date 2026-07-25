using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Services;
using System.Threading.Tasks;

namespace OrderProcessAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TenantChatController : ControllerBase
    {
        private readonly ITenantChatService _tenantChatService;

        public TenantChatController(ITenantChatService tenantChatService)
        {
            _tenantChatService = tenantChatService;
        }

        [HttpGet("conversations/{userId}")]
        public async Task<IActionResult> GetChatConversations(string userId)
        {
            if (string.IsNullOrEmpty(userId))
            {
                return BadRequest("UserId is required.");
            }

            var result = await _tenantChatService.GetChatConversationsAsync(userId);
            return Ok(result);
        }

        [HttpGet("conversations/{conversationId}/messages")]
        public async Task<IActionResult> GetChatMessages(int conversationId)
        {
            if (conversationId <= 0)
            {
                return BadRequest("Invalid ConversationId.");
            }

            var result = await _tenantChatService.GetChatMessagesAsync(conversationId);
            return Ok(result);
        }

        public class SendMessageRequest
        {
            public int? ConversationId { get; set; }
            public string TenantUserId { get; set; } = string.Empty;
            public string OwnerUserId { get; set; } = string.Empty;
            public string SenderUserId { get; set; } = string.Empty;
            public string MessageText { get; set; } = string.Empty;
        }

        [HttpPost("messages")]
        public async Task<IActionResult> SendMessage([FromBody] SendMessageRequest request)
        {
            if (string.IsNullOrEmpty(request.TenantUserId) || string.IsNullOrEmpty(request.OwnerUserId) || string.IsNullOrEmpty(request.SenderUserId) || string.IsNullOrEmpty(request.MessageText))
            {
                return BadRequest("TenantUserId, OwnerUserId, SenderUserId, and MessageText are required.");
            }

            var result = await _tenantChatService.SendMessageAsync(request.ConversationId, request.TenantUserId, request.OwnerUserId, request.SenderUserId, request.MessageText);
            return Ok(result);
        }
    }
}
