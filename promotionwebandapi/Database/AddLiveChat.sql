USE SmartBazarDb;
GO

IF OBJECT_ID(N'dbo.tbl_ChatConversations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbl_ChatConversations
    (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_ChatConversations PRIMARY KEY,
        CustomerUserId INT NOT NULL,
        ShopkeeperId INT NOT NULL,
        CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_ChatConversations_CreatedAt DEFAULT (SYSUTCDATETIME()),
        LastMessageAt DATETIME2(0) NULL,
        CONSTRAINT FK_tbl_ChatConversations_CustomerUser FOREIGN KEY (CustomerUserId) REFERENCES dbo.tbl_Users(Id),
        CONSTRAINT FK_tbl_ChatConversations_Shopkeeper FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id),
        CONSTRAINT UQ_tbl_ChatConversations_Customer_Shop UNIQUE (CustomerUserId, ShopkeeperId)
    );
END
GO

IF OBJECT_ID(N'dbo.tbl_ChatMessages', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbl_ChatMessages
    (
        Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_ChatMessages PRIMARY KEY,
        ConversationId INT NOT NULL,
        SenderUserId INT NOT NULL,
        MessageType NVARCHAR(20) NOT NULL CONSTRAINT DF_tbl_ChatMessages_MessageType DEFAULT (N'Text'),
        MessageText NVARCHAR(1000) NULL,
        MediaUrl NVARCHAR(500) NULL,
        SentAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_ChatMessages_SentAt DEFAULT (SYSUTCDATETIME()),
        ReadAt DATETIME2(0) NULL,
        CONSTRAINT FK_tbl_ChatMessages_Conversation FOREIGN KEY (ConversationId) REFERENCES dbo.tbl_ChatConversations(Id),
        CONSTRAINT FK_tbl_ChatMessages_SenderUser FOREIGN KEY (SenderUserId) REFERENCES dbo.tbl_Users(Id)
    );
END
GO

IF COL_LENGTH(N'dbo.tbl_ChatMessages', N'MessageType') IS NULL
    ALTER TABLE dbo.tbl_ChatMessages ADD MessageType NVARCHAR(20) NOT NULL
        CONSTRAINT DF_tbl_ChatMessages_MessageType DEFAULT (N'Text');
GO

IF COL_LENGTH(N'dbo.tbl_ChatMessages', N'MediaUrl') IS NULL
    ALTER TABLE dbo.tbl_ChatMessages ADD MediaUrl NVARCHAR(500) NULL;
GO

IF COLUMNPROPERTY(OBJECT_ID(N'dbo.tbl_ChatMessages'), N'MessageText', 'AllowsNull') = 0
    ALTER TABLE dbo.tbl_ChatMessages ALTER COLUMN MessageText NVARCHAR(1000) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tbl_ChatConversations_Shopkeeper_LastMessage')
    CREATE INDEX IX_tbl_ChatConversations_Shopkeeper_LastMessage
        ON dbo.tbl_ChatConversations (ShopkeeperId, LastMessageAt DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tbl_ChatMessages_Conversation_SentAt')
    CREATE INDEX IX_tbl_ChatMessages_Conversation_SentAt
        ON dbo.tbl_ChatMessages (ConversationId, SentAt, Id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tbl_ChatMessages_Unread')
    CREATE INDEX IX_tbl_ChatMessages_Unread
        ON dbo.tbl_ChatMessages (ConversationId, ReadAt, SenderUserId);
GO
