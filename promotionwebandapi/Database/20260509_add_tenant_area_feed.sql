-- Run this migration against VaratiaManagementDb.
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.TenantAreaWards', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.TenantAreaWards
        (
            Id NVARCHAR(40) NOT NULL PRIMARY KEY,
            City NVARCHAR(30) NOT NULL,
            WardNo INT NOT NULL,
            TitleBn NVARCHAR(120) NOT NULL,
            TitleEn NVARCHAR(120) NOT NULL,
            Area NVARCHAR(200) NOT NULL,
            MemberCount INT NOT NULL
                CONSTRAINT DF_TenantAreaWards_MemberCount DEFAULT (0),
            IsVerified BIT NOT NULL
                CONSTRAINT DF_TenantAreaWards_IsVerified DEFAULT (0),
            DisplayOrder INT NOT NULL
        );
    END;

    IF OBJECT_ID(N'dbo.TenantAreaWardRules', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.TenantAreaWardRules
        (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            WardId NVARCHAR(40) NULL,
            Language NVARCHAR(5) NOT NULL,
            RuleText NVARCHAR(250) NOT NULL,
            DisplayOrder INT NOT NULL,
            CONSTRAINT FK_TenantAreaWardRules_TenantAreaWards
                FOREIGN KEY (WardId) REFERENCES dbo.TenantAreaWards (Id)
                ON DELETE CASCADE
        );
    END;

    IF OBJECT_ID(N'dbo.TenantAreaPosts', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.TenantAreaPosts
        (
            Id NVARCHAR(50) NOT NULL PRIMARY KEY,
            TenantId NVARCHAR(100) NOT NULL,
            WardId NVARCHAR(40) NOT NULL,
            PostType NVARCHAR(30) NOT NULL,
            Details NVARCHAR(1000) NOT NULL,
            LocationLabel NVARCHAR(200) NOT NULL,
            Latitude DECIMAL(9,6) NULL,
            Longitude DECIMAL(9,6) NULL,
            Privacy NVARCHAR(30) NOT NULL,
            CreatedAt DATETIME2 NOT NULL
                CONSTRAINT DF_TenantAreaPosts_CreatedAt DEFAULT (SYSUTCDATETIME()),
            UpdatedAt DATETIME2 NOT NULL
                CONSTRAINT DF_TenantAreaPosts_UpdatedAt DEFAULT (SYSUTCDATETIME()),
            CONSTRAINT FK_TenantAreaPosts_TenantAreaWards
                FOREIGN KEY (WardId) REFERENCES dbo.TenantAreaWards (Id)
        );
    END;

    IF OBJECT_ID(N'dbo.TenantAreaPostAttachments', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.TenantAreaPostAttachments
        (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            PostId NVARCHAR(50) NOT NULL,
            FileName NVARCHAR(150) NOT NULL,
            Url NVARCHAR(500) NULL,
            DisplayOrder INT NOT NULL,
            CONSTRAINT FK_TenantAreaPostAttachments_TenantAreaPosts
                FOREIGN KEY (PostId) REFERENCES dbo.TenantAreaPosts (Id)
                ON DELETE CASCADE
        );
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'IX_TenantAreaWards_City_DisplayOrder'
          AND object_id = OBJECT_ID(N'dbo.TenantAreaWards')
    )
    BEGIN
        CREATE INDEX IX_TenantAreaWards_City_DisplayOrder
        ON dbo.TenantAreaWards (City, DisplayOrder);
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'IX_TenantAreaPosts_WardId_PostType_CreatedAt'
          AND object_id = OBJECT_ID(N'dbo.TenantAreaPosts')
    )
    BEGIN
        CREATE INDEX IX_TenantAreaPosts_WardId_PostType_CreatedAt
        ON dbo.TenantAreaPosts (WardId, PostType, CreatedAt DESC);
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'IX_TenantAreaPostAttachments_PostId_DisplayOrder'
          AND object_id = OBJECT_ID(N'dbo.TenantAreaPostAttachments')
    )
    BEGIN
        CREATE INDEX IX_TenantAreaPostAttachments_PostId_DisplayOrder
        ON dbo.TenantAreaPostAttachments (PostId, DisplayOrder);
    END;

    MERGE dbo.TenantAreaWards AS target
    USING
    (
        VALUES
            (N'ward-14', N'dncc', 14, N'ওয়ার্ড ১৪ - মিরপুর', N'Ward 14 - Mirpur', N'Mirpur-10, Dhaka', 2386, 1, 1),
            (N'ward-13', N'dncc', 13, N'ওয়ার্ড ১৩ - পল্লবী', N'Ward 13 - Pallabi', N'Pallabi, Mirpur, Dhaka', 1740, 1, 2),
            (N'ward-15', N'dncc', 15, N'ওয়ার্ড ১৫ - কাফরুল', N'Ward 15 - Kafrul', N'Kafrul, Dhaka', 1298, 1, 3),
            (N'ward-1', N'dncc', 1, N'ওয়ার্ড ১ - উত্তরা', N'Ward 1 - Uttara', N'Uttara, Dhaka', 3100, 1, 4)
    ) AS source (Id, City, WardNo, TitleBn, TitleEn, Area, MemberCount, IsVerified, DisplayOrder)
    ON target.Id = source.Id
    WHEN MATCHED THEN
        UPDATE SET
            City = source.City,
            WardNo = source.WardNo,
            TitleBn = source.TitleBn,
            TitleEn = source.TitleEn,
            Area = source.Area,
            MemberCount = source.MemberCount,
            IsVerified = source.IsVerified,
            DisplayOrder = source.DisplayOrder
    WHEN NOT MATCHED THEN
        INSERT
            (Id, City, WardNo, TitleBn, TitleEn, Area, MemberCount, IsVerified, DisplayOrder)
        VALUES
            (source.Id, source.City, source.WardNo, source.TitleBn, source.TitleEn, source.Area, source.MemberCount, source.IsVerified, source.DisplayOrder);

    MERGE dbo.TenantAreaWardRules AS target
    USING
    (
        VALUES
            (N'ward-14', N'bn', N'স্প্যাম করা যাবে না।', 1),
            (N'ward-14', N'en', N'Do not post spam.', 1)
    ) AS source (WardId, Language, RuleText, DisplayOrder)
    ON target.WardId = source.WardId
       AND target.Language = source.Language
       AND target.DisplayOrder = source.DisplayOrder
    WHEN MATCHED THEN
        UPDATE SET RuleText = source.RuleText
    WHEN NOT MATCHED THEN
        INSERT (WardId, Language, RuleText, DisplayOrder)
        VALUES (source.WardId, source.Language, source.RuleText, source.DisplayOrder);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
GO
