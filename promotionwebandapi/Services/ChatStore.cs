using Microsoft.Data.SqlClient;
using PromotionWeb.Models;
using System.Data;

namespace PromotionWeb.Services;

public sealed class ChatStore(IConfiguration configuration)
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");

    public ChatConversationViewModel OpenForCustomer(int customerUserId, int shopkeeperId)
    {
        using var connection = CreateConnection();
        connection.Open();

        using (var command = new SqlCommand("""
            IF NOT EXISTS (
                SELECT 1 FROM dbo.tbl_Users
                WHERE Id = @CustomerUserId AND Role = N'Customer' AND IsActive = 1
            )
                THROW 51100, N'Invalid customer.', 1;

            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Shopkeepers WHERE Id = @ShopkeeperId)
                THROW 51101, N'Invalid shopkeeper.', 1;

            IF NOT EXISTS (
                SELECT 1 FROM dbo.tbl_ChatConversations
                WHERE CustomerUserId = @CustomerUserId AND ShopkeeperId = @ShopkeeperId
            )
            BEGIN
                INSERT INTO dbo.tbl_ChatConversations (CustomerUserId, ShopkeeperId)
                VALUES (@CustomerUserId, @ShopkeeperId);
            END;

            SELECT Id
            FROM dbo.tbl_ChatConversations
            WHERE CustomerUserId = @CustomerUserId AND ShopkeeperId = @ShopkeeperId;
            """, connection))
        {
            command.Parameters.AddWithValue("@CustomerUserId", customerUserId);
            command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
            var conversationId = Convert.ToInt32(command.ExecuteScalar());
            return GetConversation(connection, conversationId, customerUserId);
        }
    }

    public ChatConversationViewModel OpenForUser(int conversationId, int userId)
    {
        using var connection = CreateConnection();
        connection.Open();
        return GetConversation(connection, conversationId, userId);
    }

    public IReadOnlyList<ChatConversationViewModel> GetInbox(int userId)
    {
        using var connection = CreateConnection();
        using var command = new SqlCommand(ConversationSelect("""
            WHERE c.CustomerUserId = @UserId OR s.UserId = @UserId
            ORDER BY COALESCE(c.LastMessageAt, c.CreatedAt) DESC
            """), connection);
        command.Parameters.AddWithValue("@UserId", userId);

        connection.Open();
        using var reader = command.ExecuteReader();
        return ReadConversations(reader);
    }

    public int GetUnreadCount(int userId)
    {
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            SELECT COUNT(1)
            FROM dbo.tbl_ChatMessages AS m
            INNER JOIN dbo.tbl_ChatConversations AS c ON c.Id = m.ConversationId
            INNER JOIN dbo.tbl_Shopkeepers AS s ON s.Id = c.ShopkeeperId
            WHERE (c.CustomerUserId = @UserId OR s.UserId = @UserId)
              AND m.SenderUserId <> @UserId
              AND m.ReadAt IS NULL;
            """, connection);
        command.Parameters.AddWithValue("@UserId", userId);

        connection.Open();
        return Convert.ToInt32(command.ExecuteScalar());
    }

    public ChatMessageViewModel SendMessage(int conversationId, int senderUserId, string messageText)
    {
        var text = messageText.Trim();
        if (text.Length is < 1 or > 1000)
        {
            throw new InvalidOperationException("Message must be between 1 and 1000 characters.");
        }

        using var connection = CreateConnection();
        connection.Open();
        EnsureMember(connection, conversationId, senderUserId);

        using var transaction = connection.BeginTransaction();
        long messageId;
        using (var command = new SqlCommand("""
            INSERT INTO dbo.tbl_ChatMessages (ConversationId, SenderUserId, MessageType, MessageText)
            VALUES (@ConversationId, @SenderUserId, N'Text', @MessageText);

            SELECT CONVERT(BIGINT, SCOPE_IDENTITY());
            """, connection, transaction))
        {
            command.Parameters.AddWithValue("@ConversationId", conversationId);
            command.Parameters.AddWithValue("@SenderUserId", senderUserId);
            command.Parameters.Add("@MessageText", SqlDbType.NVarChar, 1000).Value = text;
            messageId = Convert.ToInt64(command.ExecuteScalar());
        }

        using (var command = new SqlCommand("""
            UPDATE dbo.tbl_ChatConversations
            SET LastMessageAt = SYSUTCDATETIME()
            WHERE Id = @ConversationId;
            """, connection, transaction))
        {
            command.Parameters.AddWithValue("@ConversationId", conversationId);
            command.ExecuteNonQuery();
        }

        transaction.Commit();

        using var readCommand = new SqlCommand("""
            SELECT m.Id, m.ConversationId, m.SenderUserId, u.Name AS SenderName,
                   u.Role AS SenderRole, m.MessageType, m.MessageText, m.MediaUrl, m.SentAt
            FROM dbo.tbl_ChatMessages AS m
            INNER JOIN dbo.tbl_Users AS u ON u.Id = m.SenderUserId
            WHERE m.Id = @MessageId;
            """, connection);
        readCommand.Parameters.AddWithValue("@MessageId", messageId);
        using var reader = readCommand.ExecuteReader();
        reader.Read();
        return MapMessage(reader);
    }

    public ChatMessageViewModel SendImage(int conversationId, int senderUserId, string mediaUrl)
    {
        using var connection = CreateConnection();
        connection.Open();
        EnsureMember(connection, conversationId, senderUserId);

        using var command = new SqlCommand("""
            INSERT INTO dbo.tbl_ChatMessages (ConversationId, SenderUserId, MessageType, MediaUrl)
            VALUES (@ConversationId, @SenderUserId, N'Image', @MediaUrl);

            DECLARE @MessageId BIGINT = CONVERT(BIGINT, SCOPE_IDENTITY());

            UPDATE dbo.tbl_ChatConversations
            SET LastMessageAt = SYSUTCDATETIME()
            WHERE Id = @ConversationId;

            SELECT m.Id, m.ConversationId, m.SenderUserId, u.Name AS SenderName,
                   u.Role AS SenderRole, m.MessageType, m.MessageText, m.MediaUrl, m.SentAt
            FROM dbo.tbl_ChatMessages AS m
            INNER JOIN dbo.tbl_Users AS u ON u.Id = m.SenderUserId
            WHERE m.Id = @MessageId;
            """, connection);
        command.Parameters.Add("@MediaUrl", SqlDbType.NVarChar, 500).Value = mediaUrl;
        command.Parameters.AddWithValue("@ConversationId", conversationId);
        command.Parameters.AddWithValue("@SenderUserId", senderUserId);
        using var reader = command.ExecuteReader();
        reader.Read();
        return MapMessage(reader);
    }

    public void MarkRead(int conversationId, int userId)
    {
        using var connection = CreateConnection();
        connection.Open();
        EnsureMember(connection, conversationId, userId);

        using var command = new SqlCommand("""
            UPDATE dbo.tbl_ChatMessages
            SET ReadAt = COALESCE(ReadAt, SYSUTCDATETIME())
            WHERE ConversationId = @ConversationId
              AND SenderUserId <> @UserId
              AND ReadAt IS NULL;
            """, connection);
        command.Parameters.AddWithValue("@ConversationId", conversationId);
        command.Parameters.AddWithValue("@UserId", userId);
        command.ExecuteNonQuery();
    }

    private ChatConversationViewModel GetConversation(SqlConnection connection, int conversationId, int userId)
    {
        using var command = new SqlCommand(ConversationSelect("""
            WHERE c.Id = @ConversationId
              AND (c.CustomerUserId = @UserId OR s.UserId = @UserId)
            """), connection);
        command.Parameters.AddWithValue("@ConversationId", conversationId);
        command.Parameters.AddWithValue("@UserId", userId);

        ChatConversationViewModel conversation;
        using (var reader = command.ExecuteReader())
        {
            conversation = ReadConversations(reader).SingleOrDefault()
                ?? throw new InvalidOperationException("Conversation not found.");
        }

        using var messageCommand = new SqlCommand("""
            SELECT m.Id, m.ConversationId, m.SenderUserId, u.Name AS SenderName,
                   u.Role AS SenderRole, m.MessageType, m.MessageText, m.MediaUrl, m.SentAt
            FROM dbo.tbl_ChatMessages AS m
            INNER JOIN dbo.tbl_Users AS u ON u.Id = m.SenderUserId
            WHERE m.ConversationId = @ConversationId
            ORDER BY m.SentAt, m.Id;
            """, connection);
        messageCommand.Parameters.AddWithValue("@ConversationId", conversationId);
        using var messageReader = messageCommand.ExecuteReader();
        var messages = new List<ChatMessageViewModel>();
        while (messageReader.Read())
        {
            messages.Add(MapMessage(messageReader));
        }

        return new ChatConversationViewModel
        {
            Id = conversation.Id,
            CustomerUserId = conversation.CustomerUserId,
            ShopkeeperUserId = conversation.ShopkeeperUserId,
            ShopkeeperId = conversation.ShopkeeperId,
            CustomerName = conversation.CustomerName,
            CustomerPhone = conversation.CustomerPhone,
            ShopName = conversation.ShopName,
            ShopkeeperPhone = conversation.ShopkeeperPhone,
            LastMessage = conversation.LastMessage,
            LastMessageAt = conversation.LastMessageAt,
            UnreadCount = conversation.UnreadCount,
            Messages = messages
        };
    }

    private static string ConversationSelect(string suffix) => $"""
        SELECT c.Id, c.CustomerUserId, s.UserId AS ShopkeeperUserId, c.ShopkeeperId,
               customer.Name AS CustomerName, customer.Phone AS CustomerPhone,
               s.ShopName, s.Phone AS ShopkeeperPhone, c.LastMessageAt,
               COALESCE(lastMessage.MessageText, CASE WHEN lastMessage.MessageType = N'Image' THEN N'Image' ELSE N'' END) AS LastMessage,
               (
                   SELECT COUNT(1)
                   FROM dbo.tbl_ChatMessages AS unread
                   WHERE unread.ConversationId = c.Id
                     AND unread.SenderUserId <> @UserId
                     AND unread.ReadAt IS NULL
               ) AS UnreadCount
        FROM dbo.tbl_ChatConversations AS c
        INNER JOIN dbo.tbl_Users AS customer ON customer.Id = c.CustomerUserId
        INNER JOIN dbo.tbl_Shopkeepers AS s ON s.Id = c.ShopkeeperId
        OUTER APPLY (
            SELECT TOP (1) MessageText, MessageType
            FROM dbo.tbl_ChatMessages
            WHERE ConversationId = c.Id
            ORDER BY SentAt DESC, Id DESC
        ) AS lastMessage
        {suffix}
        """;

    private static List<ChatConversationViewModel> ReadConversations(SqlDataReader reader)
    {
        var conversations = new List<ChatConversationViewModel>();
        while (reader.Read())
        {
            conversations.Add(new ChatConversationViewModel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                CustomerUserId = reader.GetInt32(reader.GetOrdinal("CustomerUserId")),
                ShopkeeperUserId = reader.GetInt32(reader.GetOrdinal("ShopkeeperUserId")),
                ShopkeeperId = reader.GetInt32(reader.GetOrdinal("ShopkeeperId")),
                CustomerName = reader.GetString(reader.GetOrdinal("CustomerName")),
                CustomerPhone = reader.GetString(reader.GetOrdinal("CustomerPhone")),
                ShopName = reader.GetString(reader.GetOrdinal("ShopName")),
                ShopkeeperPhone = reader.GetString(reader.GetOrdinal("ShopkeeperPhone")),
                LastMessage = reader.GetString(reader.GetOrdinal("LastMessage")),
                LastMessageAt = reader.IsDBNull(reader.GetOrdinal("LastMessageAt"))
                    ? null
                    : reader.GetDateTime(reader.GetOrdinal("LastMessageAt")),
                UnreadCount = reader.GetInt32(reader.GetOrdinal("UnreadCount"))
            });
        }

        return conversations;
    }

    private static ChatMessageViewModel MapMessage(SqlDataReader reader) => new()
    {
        Id = reader.GetInt64(reader.GetOrdinal("Id")),
        ConversationId = reader.GetInt32(reader.GetOrdinal("ConversationId")),
        SenderUserId = reader.GetInt32(reader.GetOrdinal("SenderUserId")),
        SenderName = reader.GetString(reader.GetOrdinal("SenderName")),
        SenderRole = reader.GetString(reader.GetOrdinal("SenderRole")),
        MessageType = reader.GetString(reader.GetOrdinal("MessageType")),
        MessageText = reader.IsDBNull(reader.GetOrdinal("MessageText")) ? "" : reader.GetString(reader.GetOrdinal("MessageText")),
        MediaUrl = reader.IsDBNull(reader.GetOrdinal("MediaUrl")) ? null : reader.GetString(reader.GetOrdinal("MediaUrl")),
        SentAt = reader.GetDateTime(reader.GetOrdinal("SentAt"))
    };

    private static void EnsureMember(SqlConnection connection, int conversationId, int userId)
    {
        using var command = new SqlCommand("""
            SELECT COUNT(1)
            FROM dbo.tbl_ChatConversations AS c
            INNER JOIN dbo.tbl_Shopkeepers AS s ON s.Id = c.ShopkeeperId
            WHERE c.Id = @ConversationId
              AND (c.CustomerUserId = @UserId OR s.UserId = @UserId);
            """, connection);
        command.Parameters.AddWithValue("@ConversationId", conversationId);
        command.Parameters.AddWithValue("@UserId", userId);
        if (Convert.ToInt32(command.ExecuteScalar()) == 0)
        {
            throw new InvalidOperationException("You cannot access this conversation.");
        }
    }

    private SqlConnection CreateConnection() => new(_connectionString);
}
