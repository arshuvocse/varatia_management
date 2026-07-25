IF OBJECT_ID(N'dbo.AdminChatConversations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AdminChatConversations
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        RequesterUserId NVARCHAR(100) NOT NULL,
        AdminUserId NVARCHAR(100) NOT NULL,
        CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_AdminChatConversations_CreatedOn DEFAULT (SYSUTCDATETIME()),
        LastMessageOn DATETIME2 NULL,
        CONSTRAINT UQ_AdminChatConversations_Requester_Admin
            UNIQUE (RequesterUserId, AdminUserId)
    );
END;
GO

IF OBJECT_ID(N'dbo.AdminChatMessages', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AdminChatMessages
    (
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ConversationId INT NOT NULL,
        SenderUserId NVARCHAR(100) NOT NULL,
        MessageText NVARCHAR(1000) NOT NULL,
        SentOn DATETIME2 NOT NULL CONSTRAINT DF_AdminChatMessages_SentOn DEFAULT (SYSUTCDATETIME()),
        ReadOn DATETIME2 NULL,
        CONSTRAINT FK_AdminChatMessages_Conversation
            FOREIGN KEY (ConversationId) REFERENCES dbo.AdminChatConversations(Id) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_AdminChatConversations_User_LastMessage'
      AND object_id = OBJECT_ID(N'dbo.AdminChatConversations')
)
BEGIN
    CREATE INDEX IX_AdminChatConversations_User_LastMessage
    ON dbo.AdminChatConversations (RequesterUserId, AdminUserId, LastMessageOn DESC);
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_AdminChatMessages_Conversation_SentOn'
      AND object_id = OBJECT_ID(N'dbo.AdminChatMessages')
)
BEGIN
    CREATE INDEX IX_AdminChatMessages_Conversation_SentOn
    ON dbo.AdminChatMessages (ConversationId, SentOn, Id);
END;
GO
