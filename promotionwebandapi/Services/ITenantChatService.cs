using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace OrderProcessAPI.Services
{
    public class TenantChatConversationDto
    {
        public int Id { get; set; }
        public string TenantUserId { get; set; } = string.Empty;
        public string OwnerUserId { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime LastMessageAt { get; set; }
        public string TenantName { get; set; } = string.Empty;
        public string OwnerName { get; set; } = string.Empty;
        public string LastMessage { get; set; } = string.Empty;
    }

    public class TenantChatMessageDto
    {
        public long Id { get; set; }
        public string SenderUserId { get; set; } = string.Empty;
        public string MessageText { get; set; } = string.Empty;
        public DateTime SentAt { get; set; }
        public DateTime? ReadAt { get; set; }
    }

    public class SendMessageResult
    {
        public int ConversationId { get; set; }
    }

    public interface ITenantChatService
    {
        Task<List<TenantChatConversationDto>> GetChatConversationsAsync(string userId);
        Task<List<TenantChatMessageDto>> GetChatMessagesAsync(int conversationId);
        Task<SendMessageResult> SendMessageAsync(int? conversationId, string tenantUserId, string ownerUserId, string senderUserId, string messageText);
    }
}
