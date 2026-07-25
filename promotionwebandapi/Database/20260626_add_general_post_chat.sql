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
GO

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
GO

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
GO

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
GO
