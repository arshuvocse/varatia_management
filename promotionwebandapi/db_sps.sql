CREATE PROCEDURE sp_ToggleSavedPost
    @UserId NVARCHAR(255),
    @PostId INT,
    @PostType NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM SavedPosts WHERE UserId = @UserId AND PostId = @PostId AND PostType = @PostType)
    BEGIN
        DELETE FROM SavedPosts WHERE UserId = @UserId AND PostId = @PostId AND PostType = @PostType;
        SELECT 0 AS IsSaved;
    END
    ELSE
    BEGIN
        INSERT INTO SavedPosts (UserId, PostId, PostType) VALUES (@UserId, @PostId, @PostType);
        SELECT 1 AS IsSaved;
    END
END
GO

CREATE PROCEDURE sp_GetSavedPosts
    @UserId NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, PostId, PostType, SavedAt FROM SavedPosts WHERE UserId = @UserId ORDER BY SavedAt DESC;
END
GO

CREATE PROCEDURE sp_GetChatConversations
    @UserId NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.Id, c.TenantUserId, c.OwnerUserId, c.CreatedAt, c.LastMessageAt,
           u1.FullName AS TenantName, u2.FullName AS OwnerName,
           (SELECT TOP 1 MessageText FROM TenantChatMessages m WHERE m.ConversationId = c.Id ORDER BY SentAt DESC) AS LastMessage
    FROM TenantChatConversations c
    LEFT JOIN Users u1 ON c.TenantUserId = u1.Id
    LEFT JOIN Users u2 ON c.OwnerUserId = u2.Id
    WHERE c.TenantUserId = @UserId OR c.OwnerUserId = @UserId
    ORDER BY c.LastMessageAt DESC;
END
GO

CREATE PROCEDURE sp_GetChatMessages
    @ConversationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, SenderUserId, MessageText, SentAt, ReadAt
    FROM TenantChatMessages
    WHERE ConversationId = @ConversationId
    ORDER BY SentAt ASC;
END
GO

CREATE PROCEDURE sp_SendMessage
    @ConversationId INT = NULL,
    @TenantUserId NVARCHAR(255),
    @OwnerUserId NVARCHAR(255),
    @SenderUserId NVARCHAR(255),
    @MessageText NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @ConversationId IS NULL OR @ConversationId = 0
    BEGIN
        SELECT @ConversationId = Id FROM TenantChatConversations 
        WHERE (TenantUserId = @TenantUserId AND OwnerUserId = @OwnerUserId)
           OR (TenantUserId = @OwnerUserId AND OwnerUserId = @TenantUserId);
           
        IF @ConversationId IS NULL
        BEGIN
            INSERT INTO TenantChatConversations (TenantUserId, OwnerUserId) 
            VALUES (@TenantUserId, @OwnerUserId);
            SET @ConversationId = SCOPE_IDENTITY();
        END
    END
    
    INSERT INTO TenantChatMessages (ConversationId, SenderUserId, MessageText)
    VALUES (@ConversationId, @SenderUserId, @MessageText);
    
    UPDATE TenantChatConversations
    SET LastMessageAt = GETUTCDATE()
    WHERE Id = @ConversationId;
    
    SELECT @ConversationId AS ConversationId;
END
GO
