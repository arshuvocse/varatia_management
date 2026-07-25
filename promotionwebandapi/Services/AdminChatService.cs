using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;
using System.Data;

namespace OrderProcessAPI.Services;

public sealed class AdminChatService : IAdminChatService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public AdminChatService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<AdminContactDto> GetDefaultAdminAsync(
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var admin = await connection.QuerySingleOrDefaultAsync<AdminContactDto>(
            new CommandDefinition(
                """
                SELECT TOP (1)
                    CONVERT(NVARCHAR(100), Id) AS UserId,
                    COALESCE(NULLIF(FullName, N''), N'Admin') AS FullName,
                    COALESCE(NULLIF(PhoneNumber, N''), NormalizedPhoneNumber, N'') AS PhoneNumber
                FROM dbo.Users
                WHERE LOWER(COALESCE(Role, N'')) = N'admin'
                   OR NormalizedPhoneNumber IN (N'+8801711111111', N'8801711111111', N'01711111111')
                   OR PhoneNumber IN (N'+8801711111111', N'8801711111111', N'01711111111')
                ORDER BY
                    CASE WHEN LOWER(COALESCE(Role, N'')) = N'admin' THEN 0 ELSE 1 END,
                    UpdatedAt DESC,
                    CreatedAt DESC;
                """,
                cancellationToken: cancellationToken));

        if (admin is null)
            throw new InvalidOperationException("Admin user was not found.");

        return admin;
    }

    public async Task<AdminChatConversationDto> OpenChatAsync(
        string requesterUserId,
        string adminUserId,
        CancellationToken cancellationToken = default)
    {
        var normalizedRequesterUserId = RequireUserId(requesterUserId);
        var normalizedAdminUserId = RequireUserId(adminUserId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var conversationId = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                "dbo.sp_AdminChat_Open",
                new { RequesterUserId = normalizedRequesterUserId, AdminUserId = normalizedAdminUserId },
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

        return await GetConversationAsync(conversationId, normalizedRequesterUserId, cancellationToken);
    }

    public async Task<IReadOnlyList<AdminChatConversationDto>> GetInboxAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        var normalizedUserId = RequireUserId(userId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var conversations = await connection.QueryAsync<AdminChatConversationDto>(
            new CommandDefinition(
                "dbo.sp_AdminChat_GetInbox",
                new { UserId = normalizedUserId },
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

        return conversations.ToList();
    }

    public async Task<AdminChatConversationDto> GetConversationAsync(
        int conversationId,
        string userId,
        CancellationToken cancellationToken = default)
    {
        var normalizedUserId = RequireUserId(userId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var conversation = await connection.QuerySingleOrDefaultAsync<AdminChatConversationDto>(
            new CommandDefinition(
                "dbo.sp_AdminChat_GetConversation",
                new { ConversationId = conversationId, UserId = normalizedUserId },
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

        if (conversation is null)
            throw new InvalidOperationException("Conversation not found or access denied.");

        return conversation;
    }

    public async Task<AdminChatMessageDto> SendMessageAsync(
        int conversationId,
        string senderUserId,
        string messageText,
        CancellationToken cancellationToken = default)
    {
        var normalizedSenderUserId = RequireUserId(senderUserId);
        if (string.IsNullOrWhiteSpace(messageText))
            throw new ArgumentException("Message text cannot be empty.", nameof(messageText));

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var message = await connection.QuerySingleOrDefaultAsync<AdminChatMessageDto>(
            new CommandDefinition(
                "dbo.sp_AdminChat_SendMessage",
                new { ConversationId = conversationId, SenderUserId = normalizedSenderUserId, MessageText = messageText },
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

        if (message is null)
            throw new InvalidOperationException("Failed to send message.");

        return message;
    }

    public async Task MarkReadAsync(
        int conversationId,
        string userId,
        CancellationToken cancellationToken = default)
    {
        var normalizedUserId = RequireUserId(userId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await connection.ExecuteAsync(
            new CommandDefinition(
                "dbo.sp_AdminChat_MarkRead",
                new { ConversationId = conversationId, UserId = normalizedUserId },
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken));
    }

    private static string RequireUserId(string? userId)
    {
        var normalized = userId?.Trim();
        if (string.IsNullOrEmpty(normalized))
            throw new ArgumentException("User ID is required.");
        return normalized;
    }
}
