CREATE OR ALTER PROCEDURE dbo.sp_AdminChat_Open
    @RequesterUserId NVARCHAR(100),
    @AdminUserId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Users
        WHERE Id = TRY_CONVERT(uniqueidentifier, @RequesterUserId)
    )
        THROW 51202, N'Requester user was not found.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Users
        WHERE Id = TRY_CONVERT(uniqueidentifier, @AdminUserId)
    )
        THROW 51203, N'Admin user was not found.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.AdminChatConversations
        WHERE RequesterUserId = @RequesterUserId
          AND AdminUserId = @AdminUserId
    )
    BEGIN
        INSERT INTO dbo.AdminChatConversations
        (
            RequesterUserId,
            AdminUserId,
            CreatedOn
        )
        VALUES
        (
            @RequesterUserId,
            @AdminUserId,
            SYSUTCDATETIME()
        );
    END;

    SELECT Id AS ConversationId
    FROM dbo.AdminChatConversations
    WHERE RequesterUserId = @RequesterUserId
      AND AdminUserId = @AdminUserId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_AdminChat_GetInbox
    @UserId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.Id,
        c.RequesterUserId,
        COALESCE(requester.FullName, N'User') AS RequesterName,
        c.AdminUserId,
        COALESCE(adminUser.FullName, N'Admin') AS AdminName,
        COALESCE(lastMessage.MessageText, N'') AS LastMessage,
        c.LastMessageOn,
        (
            SELECT COUNT(1)
            FROM dbo.AdminChatMessages unread
            WHERE unread.ConversationId = c.Id
              AND unread.SenderUserId <> @UserId
              AND unread.ReadOn IS NULL
        ) AS UnreadCount
    FROM dbo.AdminChatConversations c
    LEFT JOIN dbo.Users requester ON TRY_CONVERT(uniqueidentifier, c.RequesterUserId) = requester.Id
    LEFT JOIN dbo.Users adminUser ON TRY_CONVERT(uniqueidentifier, c.AdminUserId) = adminUser.Id
    OUTER APPLY
    (
        SELECT TOP (1) MessageText
        FROM dbo.AdminChatMessages msg
        WHERE msg.ConversationId = c.Id
        ORDER BY msg.SentOn DESC, msg.Id DESC
    ) lastMessage
    WHERE c.RequesterUserId = @UserId
       OR c.AdminUserId = @UserId
    ORDER BY c.LastMessageOn DESC, c.CreatedOn DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_AdminChat_GetConversation
    @ConversationId INT,
    @UserId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.Id,
        c.RequesterUserId,
        COALESCE(requester.FullName, N'User') AS RequesterName,
        c.AdminUserId,
        COALESCE(adminUser.FullName, N'Admin') AS AdminName,
        COALESCE(lastMessage.MessageText, N'') AS LastMessage,
        c.LastMessageOn,
        (
            SELECT COUNT(1)
            FROM dbo.AdminChatMessages unread
            WHERE unread.ConversationId = c.Id
              AND unread.SenderUserId <> @UserId
              AND unread.ReadOn IS NULL
        ) AS UnreadCount
    FROM dbo.AdminChatConversations c
    LEFT JOIN dbo.Users requester ON TRY_CONVERT(uniqueidentifier, c.RequesterUserId) = requester.Id
    LEFT JOIN dbo.Users adminUser ON TRY_CONVERT(uniqueidentifier, c.AdminUserId) = adminUser.Id
    OUTER APPLY
    (
        SELECT TOP (1) MessageText
        FROM dbo.AdminChatMessages msg
        WHERE msg.ConversationId = c.Id
        ORDER BY msg.SentOn DESC, msg.Id DESC
    ) lastMessage
    WHERE c.Id = @ConversationId
      AND (c.RequesterUserId = @UserId OR c.AdminUserId = @UserId);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_AdminChat_GetMessages
    @ConversationId INT,
    @UserId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.AdminChatConversations
        WHERE Id = @ConversationId
          AND (RequesterUserId = @UserId OR AdminUserId = @UserId)
    )
        THROW 51204, N'Conversation was not found or access is denied.', 1;

    SELECT
        m.Id,
        m.ConversationId,
        m.SenderUserId,
        COALESCE(sender.FullName, N'User') AS SenderName,
        m.MessageText,
        m.SentOn
    FROM dbo.AdminChatMessages m
    LEFT JOIN dbo.Users sender ON TRY_CONVERT(uniqueidentifier, m.SenderUserId) = sender.Id
    WHERE m.ConversationId = @ConversationId
    ORDER BY m.SentOn ASC, m.Id ASC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_AdminChat_SendMessage
    @ConversationId INT,
    @SenderUserId NVARCHAR(100),
    @MessageText NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.AdminChatConversations
        WHERE Id = @ConversationId
          AND (RequesterUserId = @SenderUserId OR AdminUserId = @SenderUserId)
    )
        THROW 51204, N'Conversation was not found or access is denied.', 1;

    DECLARE @NewMessageId BIGINT;
    DECLARE @SentOn DATETIME2 = SYSUTCDATETIME();

    INSERT INTO dbo.AdminChatMessages
    (
        ConversationId,
        SenderUserId,
        MessageText,
        SentOn
    )
    VALUES
    (
        @ConversationId,
        @SenderUserId,
        @MessageText,
        @SentOn
    );

    SET @NewMessageId = SCOPE_IDENTITY();

    UPDATE dbo.AdminChatConversations
    SET LastMessageOn = @SentOn
    WHERE Id = @ConversationId;

    SELECT
        m.Id,
        m.ConversationId,
        m.SenderUserId,
        COALESCE(sender.FullName, N'User') AS SenderName,
        m.MessageText,
        m.SentOn
    FROM dbo.AdminChatMessages m
    LEFT JOIN dbo.Users sender ON TRY_CONVERT(uniqueidentifier, m.SenderUserId) = sender.Id
    WHERE m.Id = @NewMessageId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_AdminChat_MarkRead
    @ConversationId INT,
    @UserId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.AdminChatMessages
    SET ReadOn = SYSUTCDATETIME()
    WHERE ConversationId = @ConversationId
      AND SenderUserId <> @UserId
      AND ReadOn IS NULL;
END;
GO
