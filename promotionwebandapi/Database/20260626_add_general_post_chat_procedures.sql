CREATE OR ALTER PROCEDURE dbo.sp_GeneralPostChat_Open
    @PostId INT,
    @RequesterUserId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PostOwnerUserId NVARCHAR(100);

    SELECT TOP (1)
        @PostOwnerUserId = UserId
    FROM dbo.GeneralPosts
    WHERE Id = @PostId
      AND Status = N'active';

    IF @PostOwnerUserId IS NULL
        THROW 51200, N'General post was not found.', 1;

    IF @PostOwnerUserId = @RequesterUserId
        THROW 51201, N'You cannot start a chat with your own post.', 1;

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
        WHERE Id = TRY_CONVERT(uniqueidentifier, @PostOwnerUserId)
    )
        THROW 51203, N'Post owner user was not found.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.GeneralPostChatConversations
        WHERE PostId = @PostId
          AND RequesterUserId = @RequesterUserId
          AND PostOwnerUserId = @PostOwnerUserId
    )
    BEGIN
        INSERT INTO dbo.GeneralPostChatConversations
        (
            PostId,
            RequesterUserId,
            PostOwnerUserId,
            CreatedOn
        )
        VALUES
        (
            @PostId,
            @RequesterUserId,
            @PostOwnerUserId,
            SYSUTCDATETIME()
        );
    END;

    SELECT Id AS ConversationId
    FROM dbo.GeneralPostChatConversations
    WHERE PostId = @PostId
      AND RequesterUserId = @RequesterUserId
      AND PostOwnerUserId = @PostOwnerUserId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GeneralPostChat_GetInbox
    @UserId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.Id,
        c.PostId,
        gp.Title AS PostTitle,
        c.RequesterUserId,
        COALESCE(requester.FullName, N'User') AS RequesterName,
        c.PostOwnerUserId,
        COALESCE(ownerUser.FullName, N'Owner') AS PostOwnerName,
        COALESCE(lastMessage.MessageText, N'') AS LastMessage,
        c.LastMessageOn,
        (
            SELECT COUNT(1)
            FROM dbo.GeneralPostChatMessages unread
            WHERE unread.ConversationId = c.Id
              AND unread.SenderUserId <> @UserId
              AND unread.ReadOn IS NULL
        ) AS UnreadCount
    FROM dbo.GeneralPostChatConversations c
    INNER JOIN dbo.GeneralPosts gp ON gp.Id = c.PostId
    LEFT JOIN dbo.Users requester ON TRY_CONVERT(uniqueidentifier, c.RequesterUserId) = requester.Id
    LEFT JOIN dbo.Users ownerUser ON TRY_CONVERT(uniqueidentifier, c.PostOwnerUserId) = ownerUser.Id
    OUTER APPLY
    (
        SELECT TOP (1) MessageText
        FROM dbo.GeneralPostChatMessages
        WHERE ConversationId = c.Id
        ORDER BY SentOn DESC, Id DESC
    ) lastMessage
    WHERE c.RequesterUserId = @UserId
       OR c.PostOwnerUserId = @UserId
    ORDER BY COALESCE(c.LastMessageOn, c.CreatedOn) DESC, c.Id DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GeneralPostChat_GetConversation
    @ConversationId INT,
    @UserId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.Id,
        c.PostId,
        gp.Title AS PostTitle,
        c.RequesterUserId,
        COALESCE(requester.FullName, N'User') AS RequesterName,
        c.PostOwnerUserId,
        COALESCE(ownerUser.FullName, N'Owner') AS PostOwnerName,
        COALESCE(lastMessage.MessageText, N'') AS LastMessage,
        c.LastMessageOn,
        (
            SELECT COUNT(1)
            FROM dbo.GeneralPostChatMessages unread
            WHERE unread.ConversationId = c.Id
              AND unread.SenderUserId <> @UserId
              AND unread.ReadOn IS NULL
        ) AS UnreadCount
    FROM dbo.GeneralPostChatConversations c
    INNER JOIN dbo.GeneralPosts gp ON gp.Id = c.PostId
    LEFT JOIN dbo.Users requester ON TRY_CONVERT(uniqueidentifier, c.RequesterUserId) = requester.Id
    LEFT JOIN dbo.Users ownerUser ON TRY_CONVERT(uniqueidentifier, c.PostOwnerUserId) = ownerUser.Id
    OUTER APPLY
    (
        SELECT TOP (1) MessageText
        FROM dbo.GeneralPostChatMessages
        WHERE ConversationId = c.Id
        ORDER BY SentOn DESC, Id DESC
    ) lastMessage
    WHERE c.Id = @ConversationId
      AND (c.RequesterUserId = @UserId OR c.PostOwnerUserId = @UserId);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GeneralPostChat_GetMessages
    @ConversationId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.Id,
        m.ConversationId,
        m.SenderUserId,
        COALESCE(u.FullName, N'User') AS SenderName,
        COALESCE(u.Role, N'') AS SenderRole,
        m.MessageText,
        m.SentOn,
        m.ReadOn
    FROM dbo.GeneralPostChatMessages m
    LEFT JOIN dbo.Users u ON TRY_CONVERT(uniqueidentifier, m.SenderUserId) = u.Id
    WHERE m.ConversationId = @ConversationId
    ORDER BY m.SentOn, m.Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GeneralPostChat_SendMessage
    @ConversationId INT,
    @SenderUserId NVARCHAR(100),
    @MessageText NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.GeneralPostChatConversations
        WHERE Id = @ConversationId
          AND (RequesterUserId = @SenderUserId OR PostOwnerUserId = @SenderUserId)
    )
        THROW 51204, N'You cannot access this conversation.', 1;

    DECLARE @MessageId BIGINT;

    INSERT INTO dbo.GeneralPostChatMessages
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
        SYSUTCDATETIME()
    );

    SET @MessageId = CONVERT(BIGINT, SCOPE_IDENTITY());

    UPDATE dbo.GeneralPostChatConversations
    SET LastMessageOn = SYSUTCDATETIME()
    WHERE Id = @ConversationId;

    SELECT
        m.Id,
        m.ConversationId,
        m.SenderUserId,
        COALESCE(u.FullName, N'User') AS SenderName,
        COALESCE(u.Role, N'') AS SenderRole,
        m.MessageText,
        m.SentOn,
        m.ReadOn
    FROM dbo.GeneralPostChatMessages m
    LEFT JOIN dbo.Users u ON TRY_CONVERT(uniqueidentifier, m.SenderUserId) = u.Id
    WHERE m.Id = @MessageId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GeneralPostChat_MarkRead
    @ConversationId INT,
    @UserId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.GeneralPostChatConversations
        WHERE Id = @ConversationId
          AND (RequesterUserId = @UserId OR PostOwnerUserId = @UserId)
    )
        THROW 51205, N'You cannot access this conversation.', 1;

    UPDATE dbo.GeneralPostChatMessages
    SET ReadOn = COALESCE(ReadOn, SYSUTCDATETIME())
    WHERE ConversationId = @ConversationId
      AND SenderUserId <> @UserId
      AND ReadOn IS NULL;
END;
GO
