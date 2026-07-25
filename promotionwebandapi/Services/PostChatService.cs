using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;
using System.Data;

namespace OrderProcessAPI.Services;

public sealed class PostChatService : IPostChatService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public PostChatService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<PostChatConversationDto> OpenForPostAsync(
        int postId,
        string requesterUserId,
        CancellationToken cancellationToken = default)
    {
        var normalizedRequesterUserId = RequireUserId(requesterUserId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureTablesAsync(connection, cancellationToken);
        await EnsureUserExistsAsync(connection, normalizedRequesterUserId, cancellationToken);

        var conversationId = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                "dbo.sp_GeneralPostChat_Open",
                new { PostId = postId, RequesterUserId = normalizedRequesterUserId },
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

        return await GetConversationAsync(conversationId, normalizedRequesterUserId, cancellationToken);
    }

    public async Task<IReadOnlyList<PostChatConversationDto>> GetInboxAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        var normalizedUserId = RequireUserId(userId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureTablesAsync(connection, cancellationToken);

        var conversations = await connection.QueryAsync<PostChatConversationDto>(
            new CommandDefinition(
                "dbo.sp_GeneralPostChat_GetInbox",
                new { UserId = normalizedUserId },
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

        return conversations.ToList();
    }

    public async Task<PostChatConversationDto> GetConversationAsync(
        int conversationId,
        string userId,
        CancellationToken cancellationToken = default)
    {
        var normalizedUserId = RequireUserId(userId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureTablesAsync(connection, cancellationToken);

        var conversation = await connection.QuerySingleOrDefaultAsync<PostChatConversationDto>(
            new CommandDefinition(
                "dbo.sp_GeneralPostChat_GetConversation",
                new { ConversationId = conversationId, UserId = normalizedUserId },
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

        if (conversation is null)
        {
            throw new InvalidOperationException("Conversation was not found.");
        }

        var messages = await connection.QueryAsync<PostChatMessageDto>(
            new CommandDefinition(
                "dbo.sp_GeneralPostChat_GetMessages",
                new { ConversationId = conversationId },
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

        conversation.Messages = messages.ToList();
        return conversation;
    }

    public async Task<PostChatMessageDto> SendMessageAsync(
        int conversationId,
        string senderUserId,
        string messageText,
        CancellationToken cancellationToken = default)
    {
        var normalizedSenderUserId = RequireUserId(senderUserId);
        var normalizedMessageText = messageText?.Trim();
        if (string.IsNullOrWhiteSpace(normalizedMessageText))
        {
            throw new ArgumentException("Message text is required.", nameof(messageText));
        }

        if (normalizedMessageText.Length > 1000)
        {
            throw new ArgumentException("Message text must be 1000 characters or shorter.", nameof(messageText));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureTablesAsync(connection, cancellationToken);
        await EnsureMemberAsync(connection, conversationId, normalizedSenderUserId, cancellationToken);

        var message = await connection.QuerySingleAsync<PostChatMessageDto>(
            new CommandDefinition(
                "dbo.sp_GeneralPostChat_SendMessage",
                new
                {
                    ConversationId = conversationId,
                    SenderUserId = normalizedSenderUserId,
                    MessageText = normalizedMessageText
                },
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

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
        await EnsureTablesAsync(connection, cancellationToken);
        await EnsureMemberAsync(connection, conversationId, normalizedUserId, cancellationToken);

        await connection.ExecuteAsync(
            new CommandDefinition(
                "dbo.sp_GeneralPostChat_MarkRead",
                new { ConversationId = conversationId, UserId = normalizedUserId },
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken));
    }

    private static string RequireUserId(string? userId)
    {
        var normalizedUserId = userId?.Trim();
        if (string.IsNullOrWhiteSpace(normalizedUserId))
        {
            throw new ArgumentException("User ID is required.", nameof(userId));
        }

        if (!Guid.TryParse(normalizedUserId, out _))
        {
            throw new ArgumentException("Valid user ID is required.", nameof(userId));
        }

        return normalizedUserId;
    }

    private static async Task EnsureUserExistsAsync(
        System.Data.IDbConnection connection,
        string userId,
        CancellationToken cancellationToken)
    {
        var exists = await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(
                """
                SELECT CAST(CASE WHEN EXISTS
                (
                    SELECT 1
                    FROM dbo.Users
                    WHERE Id = TRY_CONVERT(uniqueidentifier, @UserId)
                ) THEN 1 ELSE 0 END AS bit);
                """,
                new { UserId = userId },
                cancellationToken: cancellationToken));

        if (!exists)
        {
            throw new InvalidOperationException("User was not found.");
        }
    }

    private static async Task EnsureMemberAsync(
        System.Data.IDbConnection connection,
        int conversationId,
        string userId,
        CancellationToken cancellationToken)
    {
        var exists = await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(
                """
                SELECT CAST(CASE WHEN EXISTS
                (
                    SELECT 1
                    FROM dbo.GeneralPostChatConversations
                    WHERE Id = @ConversationId
                      AND (RequesterUserId = @UserId OR PostOwnerUserId = @UserId)
                ) THEN 1 ELSE 0 END AS bit);
                """,
                new { ConversationId = conversationId, UserId = userId },
                cancellationToken: cancellationToken));

        if (!exists)
        {
            throw new InvalidOperationException("You cannot access this conversation.");
        }
    }

    private static Task EnsureTablesAsync(
        System.Data.IDbConnection connection,
        CancellationToken cancellationToken)
    {
        const string sql = """
            IF OBJECT_ID(N'dbo.GeneralPostChatConversations', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.GeneralPostChatConversations
                (
                    Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                    PostId INT NOT NULL,
                    RequesterUserId NVARCHAR(100) NOT NULL,
                    PostOwnerUserId NVARCHAR(100) NOT NULL,
                    CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_GeneralPostChatConversations_CreatedOn DEFAULT (SYSUTCDATETIME()),
                    LastMessageOn DATETIME2 NULL,
                    CONSTRAINT FK_GeneralPostChatConversations_Post
                        FOREIGN KEY (PostId) REFERENCES dbo.GeneralPosts(Id) ON DELETE CASCADE,
                    CONSTRAINT UQ_GeneralPostChatConversations_Post_Requester_Owner
                        UNIQUE (PostId, RequesterUserId, PostOwnerUserId)
                );
            END;

            IF OBJECT_ID(N'dbo.GeneralPostChatMessages', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.GeneralPostChatMessages
                (
                    Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                    ConversationId INT NOT NULL,
                    SenderUserId NVARCHAR(100) NOT NULL,
                    MessageText NVARCHAR(1000) NOT NULL,
                    SentOn DATETIME2 NOT NULL CONSTRAINT DF_GeneralPostChatMessages_SentOn DEFAULT (SYSUTCDATETIME()),
                    ReadOn DATETIME2 NULL,
                    CONSTRAINT FK_GeneralPostChatMessages_Conversation
                        FOREIGN KEY (ConversationId) REFERENCES dbo.GeneralPostChatConversations(Id) ON DELETE CASCADE
                );
            END;

            IF NOT EXISTS
            (
                SELECT 1
                FROM sys.indexes
                WHERE name = N'IX_GeneralPostChatConversations_User_LastMessage'
                  AND object_id = OBJECT_ID(N'dbo.GeneralPostChatConversations')
            )
            BEGIN
                CREATE INDEX IX_GeneralPostChatConversations_User_LastMessage
                ON dbo.GeneralPostChatConversations (RequesterUserId, PostOwnerUserId, LastMessageOn DESC);
            END;

            IF NOT EXISTS
            (
                SELECT 1
                FROM sys.indexes
                WHERE name = N'IX_GeneralPostChatMessages_Conversation_SentOn'
                  AND object_id = OBJECT_ID(N'dbo.GeneralPostChatMessages')
            )
            BEGIN
                CREATE INDEX IX_GeneralPostChatMessages_Conversation_SentOn
                ON dbo.GeneralPostChatMessages (ConversationId, SentOn, Id);
            END;
            """;

        return connection.ExecuteAsync(new CommandDefinition(sql, cancellationToken: cancellationToken));
    }
}
