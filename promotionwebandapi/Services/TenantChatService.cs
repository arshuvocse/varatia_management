using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;

namespace OrderProcessAPI.Services
{
    public class TenantChatService : ITenantChatService
    {
        private readonly string _connectionString;

        public TenantChatService(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");
        }

        public async Task<List<TenantChatConversationDto>> GetChatConversationsAsync(string userId)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                var parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);

                var result = await connection.QueryAsync<TenantChatConversationDto>(
                    "sp_GetChatConversations", 
                    parameters, 
                    commandType: CommandType.StoredProcedure);

                return result.ToList();
            }
        }

        public async Task<List<TenantChatMessageDto>> GetChatMessagesAsync(int conversationId)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                var parameters = new DynamicParameters();
                parameters.Add("@ConversationId", conversationId);

                var result = await connection.QueryAsync<TenantChatMessageDto>(
                    "sp_GetChatMessages", 
                    parameters, 
                    commandType: CommandType.StoredProcedure);

                return result.ToList();
            }
        }

        public async Task<SendMessageResult> SendMessageAsync(int? conversationId, string tenantUserId, string ownerUserId, string senderUserId, string messageText)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                var parameters = new DynamicParameters();
                parameters.Add("@ConversationId", conversationId);
                parameters.Add("@TenantUserId", tenantUserId);
                parameters.Add("@OwnerUserId", ownerUserId);
                parameters.Add("@SenderUserId", senderUserId);
                parameters.Add("@MessageText", messageText);

                var newConversationId = await connection.QuerySingleOrDefaultAsync<int>(
                    "sp_SendMessage", 
                    parameters, 
                    commandType: CommandType.StoredProcedure);

                return new SendMessageResult { ConversationId = newConversationId };
            }
        }
    }
}
