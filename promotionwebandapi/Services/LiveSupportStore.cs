using Microsoft.Data.SqlClient;
using PromotionWeb.Models;

namespace PromotionWeb.Services;

public sealed class LiveSupportStore(IConfiguration configuration)
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");
    private static readonly object SchemaLock = new();
    private static bool _schemaReady;

    public LiveSupportSession CreateSession(string sessionId, string name, string phone)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            MERGE dbo.tbl_LiveSupportSessions AS target
            USING (SELECT @SessionId AS SessionId) AS source
            ON target.SessionId = source.SessionId
            WHEN MATCHED THEN
                UPDATE SET UserName = CASE WHEN target.Status = N'Resolved' THEN target.UserName ELSE @Name END,
                           UserPhone = CASE WHEN target.Status = N'Resolved' THEN target.UserPhone ELSE @Phone END
            WHEN NOT MATCHED THEN
                INSERT (SessionId, UserName, UserPhone)
                VALUES (@SessionId, @Name, @Phone)
            OUTPUT INSERTED.SessionId, INSERTED.UserName, INSERTED.UserPhone, 
                   INSERTED.Status, INSERTED.AssignedAgentId, INSERTED.CreatedAt;
            """, connection);
        command.Parameters.AddWithValue("@SessionId", sessionId);
        command.Parameters.AddWithValue("@Name", name);
        command.Parameters.AddWithValue("@Phone", phone);

        connection.Open();
        using var reader = command.ExecuteReader();
        return reader.Read() ? new LiveSupportSession
        {
            SessionId = reader.GetString(0),
            UserName = reader.GetString(1),
            UserPhone = reader.GetString(2),
            Status = reader.GetString(3),
            AssignedAgentId = reader.IsDBNull(4) ? null : reader.GetInt32(4),
            CreatedAt = reader.GetDateTime(5)
        } : throw new InvalidOperationException("Could not create session.");
    }

    public LiveSupportMessage AddMessage(string sessionId, string senderType, int? senderId, string messageText)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            INSERT INTO dbo.tbl_LiveSupportMessages (SessionId, SenderType, SenderId, MessageText)
            OUTPUT INSERTED.MessageId, INSERTED.SessionId, INSERTED.SenderType, INSERTED.SenderId, INSERTED.MessageText, INSERTED.SentAt
            VALUES (@SessionId, @SenderType, @SenderId, @MessageText);
            """, connection);
        command.Parameters.AddWithValue("@SessionId", sessionId);
        command.Parameters.AddWithValue("@SenderType", senderType);
        command.Parameters.AddWithValue("@SenderId", senderId.HasValue ? senderId.Value : DBNull.Value);
        command.Parameters.AddWithValue("@MessageText", messageText);

        connection.Open();
        using var reader = command.ExecuteReader();
        return reader.Read() ? new LiveSupportMessage
        {
            MessageId = reader.GetInt32(0),
            SessionId = reader.GetString(1),
            SenderType = reader.GetString(2),
            SenderId = reader.IsDBNull(3) ? null : reader.GetInt32(3),
            MessageText = reader.GetString(4),
            SentAt = reader.GetDateTime(5)
        } : throw new InvalidOperationException("Could not save message.");
    }

    public IReadOnlyList<LiveSupportSession> GetActiveSessions()
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT SessionId, UserName, UserPhone, Status, AssignedAgentId, CreatedAt
            FROM dbo.tbl_LiveSupportSessions
            WHERE Status IN ('Active', 'Assigned')
            ORDER BY CreatedAt DESC;
            """, connection);
        var sessions = new List<LiveSupportSession>();
        connection.Open();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            sessions.Add(new LiveSupportSession
            {
                SessionId = reader.GetString(0),
                UserName = reader.GetString(1),
                UserPhone = reader.GetString(2),
                Status = reader.GetString(3),
                AssignedAgentId = reader.IsDBNull(4) ? null : reader.GetInt32(4),
                CreatedAt = reader.GetDateTime(5)
            });
        }
        return sessions;
    }

    public IReadOnlyList<LiveSupportMessage> GetMessages(string sessionId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT m.MessageId, m.SessionId, m.SenderType, m.SenderId, m.MessageText, m.SentAt,
                   u.Name AS AgentName, u.ProfilePictureUrl
            FROM dbo.tbl_LiveSupportMessages m
            LEFT JOIN dbo.tbl_Users u ON u.Id = m.SenderId AND m.SenderType = 'Agent'
            WHERE m.SessionId = @SessionId
            ORDER BY m.SentAt ASC;
            """, connection);
        command.Parameters.AddWithValue("@SessionId", sessionId);
        
        var messages = new List<LiveSupportMessage>();
        connection.Open();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            messages.Add(new LiveSupportMessage
            {
                MessageId = reader.GetInt32(0),
                SessionId = reader.GetString(1),
                SenderType = reader.GetString(2),
                SenderId = reader.IsDBNull(3) ? null : reader.GetInt32(3),
                MessageText = reader.GetString(4),
                SentAt = reader.GetDateTime(5),
                AgentName = reader.IsDBNull(6) ? null : reader.GetString(6),
                AgentProfilePictureUrl = reader.IsDBNull(7) ? null : reader.GetString(7)
            });
        }
        return messages;
    }

    public LiveSupportSession? GetSession(string sessionId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT SessionId, UserName, UserPhone, Status, AssignedAgentId, CreatedAt
            FROM dbo.tbl_LiveSupportSessions
            WHERE SessionId = @SessionId;
            """, connection);
        command.Parameters.AddWithValue("@SessionId", sessionId);
        connection.Open();
        using var reader = command.ExecuteReader();
        return reader.Read() ? new LiveSupportSession
        {
            SessionId = reader.GetString(0),
            UserName = reader.GetString(1),
            UserPhone = reader.GetString(2),
            Status = reader.GetString(3),
            AssignedAgentId = reader.IsDBNull(4) ? null : reader.GetInt32(4),
            CreatedAt = reader.GetDateTime(5)
        } : null;
    }

    public bool AssignSession(string sessionId, int agentId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_LiveSupportSessions
            SET AssignedAgentId = @AgentId, Status = 'Assigned'
            WHERE SessionId = @SessionId
              AND Status IN ('Active', 'Assigned')
              AND (AssignedAgentId IS NULL OR AssignedAgentId = @AgentId);

            SELECT CONVERT(bit, CASE WHEN @@ROWCOUNT = 1 THEN 1 ELSE 0 END);
            """, connection);
        command.Parameters.AddWithValue("@AgentId", agentId);
        command.Parameters.AddWithValue("@SessionId", sessionId);
        connection.Open();
        return Convert.ToBoolean(command.ExecuteScalar());
    }
    
    public void ResolveSession(string sessionId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_LiveSupportSessions
            SET Status = 'Resolved'
            WHERE SessionId = @SessionId;
            """, connection);
        command.Parameters.AddWithValue("@SessionId", sessionId);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public AppUser? GetAgentInfo(int agentId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT Id, Name, ProfilePictureUrl, IsActive
            FROM dbo.tbl_Users 
            WHERE Id = @AgentId
            """, connection);
        command.Parameters.AddWithValue("@AgentId", agentId);
        connection.Open();
        using var reader = command.ExecuteReader();
        if (reader.Read())
        {
            return new AppUser 
            { 
                Id = reader.GetInt32(0),
                Name = reader.GetString(1),
                ProfilePictureUrl = reader.IsDBNull(2) ? null : reader.GetString(2),
                IsActive = reader.GetBoolean(3)
            };
        }
        return null;
    }

    public bool IsUserActive(int userId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("SELECT IsActive FROM dbo.tbl_Users WHERE Id = @UserId;", connection);
        command.Parameters.AddWithValue("@UserId", userId);
        connection.Open();
        return command.ExecuteScalar() is bool isActive && isActive;
    }

    public void UpdateProfilePicture(int agentId, string url)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_Users SET ProfilePictureUrl = @Url WHERE Id = @AgentId
            """, connection);
        command.Parameters.AddWithValue("@Url", url);
        command.Parameters.AddWithValue("@AgentId", agentId);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public IReadOnlyList<AppUser> GetSupportAgents()
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT Id, Name, Phone, ProfilePictureUrl, IsActive
            FROM dbo.tbl_Users
            WHERE Role = 'SupportAgent'
            ORDER BY Id DESC;
            """, connection);
        
        var agents = new List<AppUser>();
        connection.Open();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            agents.Add(new AppUser
            {
                Id = reader.GetInt32(0),
                Name = reader.GetString(1),
                Phone = reader.GetString(2),
                ProfilePictureUrl = reader.IsDBNull(3) ? null : reader.GetString(3),
                IsActive = reader.GetBoolean(4)
            });
        }
        return agents;
    }

    public void CreateSupportAgent(string name, string phone, string passwordHash, string? profilePicUrl)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, ProfilePictureUrl, IsActive)
            VALUES (@Name, @Phone, @PasswordHash, 'SupportAgent', @ProfilePictureUrl, 1);
            """, connection);
        command.Parameters.AddWithValue("@Name", name);
        command.Parameters.AddWithValue("@Phone", phone);
        command.Parameters.AddWithValue("@PasswordHash", passwordHash);
        command.Parameters.AddWithValue("@ProfilePictureUrl", profilePicUrl ?? (object)DBNull.Value);
        
        connection.Open();
        command.ExecuteNonQuery();
    }

    public bool SupportAgentPhoneExists(string phone)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("SELECT CONVERT(bit, CASE WHEN EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = @Phone) THEN 1 ELSE 0 END);", connection);
        command.Parameters.AddWithValue("@Phone", phone);
        connection.Open();
        return Convert.ToBoolean(command.ExecuteScalar());
    }

    public bool SetSupportAgentActive(int agentId, bool isActive)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_Users
            SET IsActive = @IsActive
            WHERE Id = @AgentId AND Role = N'SupportAgent';

            DECLARE @Updated bit = CONVERT(bit, CASE WHEN @@ROWCOUNT = 1 THEN 1 ELSE 0 END);

            IF @Updated = 1 AND @IsActive = 0
            BEGIN
                UPDATE dbo.tbl_LiveSupportSessions
                SET AssignedAgentId = NULL, Status = N'Active'
                WHERE AssignedAgentId = @AgentId AND Status = N'Assigned';
            END;

            SELECT @Updated;
            """, connection, transaction);
        command.Parameters.AddWithValue("@AgentId", agentId);
        command.Parameters.AddWithValue("@IsActive", isActive);
        var updated = Convert.ToBoolean(command.ExecuteScalar());
        transaction.Commit();
        return updated;
    }

    private void EnsureSchema()
    {
        if (_schemaReady) return;
        lock (SchemaLock)
        {
            if (_schemaReady) return;
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("""
                IF COL_LENGTH(N'dbo.tbl_Users', N'ProfilePictureUrl') IS NULL
                    ALTER TABLE dbo.tbl_Users ADD ProfilePictureUrl NVARCHAR(500) NULL;

                IF OBJECT_ID(N'dbo.tbl_LiveSupportSessions', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.tbl_LiveSupportSessions
                    (
                        SessionId NVARCHAR(100) NOT NULL CONSTRAINT PK_tbl_LiveSupportSessions PRIMARY KEY,
                        UserName NVARCHAR(150) NOT NULL,
                        UserPhone NVARCHAR(20) NOT NULL,
                        Status NVARCHAR(20) NOT NULL CONSTRAINT DF_tbl_LiveSupportSessions_Status DEFAULT N'Active',
                        AssignedAgentId INT NULL,
                        CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_LiveSupportSessions_CreatedAt DEFAULT SYSUTCDATETIME()
                    );
                END;

                IF OBJECT_ID(N'dbo.tbl_LiveSupportMessages', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.tbl_LiveSupportMessages
                    (
                        MessageId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_LiveSupportMessages PRIMARY KEY,
                        SessionId NVARCHAR(100) NOT NULL,
                        SenderType NVARCHAR(20) NOT NULL,
                        SenderId INT NULL,
                        MessageText NVARCHAR(MAX) NOT NULL,
                        SentAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_LiveSupportMessages_SentAt DEFAULT SYSUTCDATETIME(),
                        CONSTRAINT FK_LiveSupportMessages_Session FOREIGN KEY (SessionId) REFERENCES dbo.tbl_LiveSupportSessions(SessionId)
                    );
                    CREATE INDEX IX_tbl_LiveSupportMessages_SessionId ON dbo.tbl_LiveSupportMessages (SessionId);
                END;
                """, connection);
            connection.Open();
            command.ExecuteNonQuery();
            _schemaReady = true;
        }
    }
}
