IF OBJECT_ID(N'dbo.GeneralPostLikes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GeneralPostLikes
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        PostId INT NOT NULL,
        UserId NVARCHAR(100) NOT NULL,
        CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_GeneralPostLikes_CreatedOn DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_GeneralPostLikes_GeneralPosts
            FOREIGN KEY (PostId) REFERENCES dbo.GeneralPosts(Id) ON DELETE CASCADE,
        CONSTRAINT UQ_GeneralPostLikes_Post_User
            UNIQUE (PostId, UserId)
    );
END;
GO

IF OBJECT_ID(N'dbo.GeneralPostComments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GeneralPostComments
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        PostId INT NOT NULL,
        UserId NVARCHAR(100) NOT NULL,
        CommentText NVARCHAR(1000) NOT NULL,
        IsDeleted BIT NOT NULL CONSTRAINT DF_GeneralPostComments_IsDeleted DEFAULT(0),
        CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_GeneralPostComments_CreatedOn DEFAULT (SYSUTCDATETIME()),
        UpdatedOn DATETIME2 NOT NULL CONSTRAINT DF_GeneralPostComments_UpdatedOn DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_GeneralPostComments_GeneralPosts
            FOREIGN KEY (PostId) REFERENCES dbo.GeneralPosts(Id) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_GeneralPostComments_PostId_CreatedOn'
      AND object_id = OBJECT_ID(N'dbo.GeneralPostComments')
)
BEGIN
    CREATE INDEX IX_GeneralPostComments_PostId_CreatedOn
    ON dbo.GeneralPostComments (PostId, CreatedOn DESC)
    INCLUDE (IsDeleted);
END;
GO
