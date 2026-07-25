USE [VaratiaManagementDb];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.TenantTutorPosts', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.TenantTutorPosts
        (
            Id NVARCHAR(50) NOT NULL PRIMARY KEY,
            TenantId NVARCHAR(100) NOT NULL,
            PostType NVARCHAR(30) NOT NULL,
            Name NVARCHAR(150) NOT NULL,
            RoleBn NVARCHAR(150) NOT NULL,
            RoleEn NVARCHAR(150) NOT NULL,
            SubjectBn NVARCHAR(150) NOT NULL,
            SubjectEn NVARCHAR(150) NOT NULL,
            AreaBn NVARCHAR(150) NOT NULL,
            AreaEn NVARCHAR(150) NOT NULL,
            PriceBn NVARCHAR(150) NOT NULL
                CONSTRAINT DF_TenantTutorPosts_PriceBn DEFAULT (N''),
            PriceEn NVARCHAR(150) NOT NULL
                CONSTRAINT DF_TenantTutorPosts_PriceEn DEFAULT (N''),
            AvailabilityBn NVARCHAR(150) NOT NULL
                CONSTRAINT DF_TenantTutorPosts_AvailabilityBn DEFAULT (N''),
            AvailabilityEn NVARCHAR(150) NOT NULL
                CONSTRAINT DF_TenantTutorPosts_AvailabilityEn DEFAULT (N''),
            BadgeBn NVARCHAR(150) NOT NULL,
            BadgeEn NVARCHAR(150) NOT NULL,
            Rating NVARCHAR(20) NOT NULL
                CONSTRAINT DF_TenantTutorPosts_Rating DEFAULT (N'5.0'),
            Phone NVARCHAR(30) NOT NULL,
            DescriptionBn NVARCHAR(1000) NOT NULL,
            DescriptionEn NVARCHAR(1000) NOT NULL,
            ExperienceBn NVARCHAR(150) NOT NULL
                CONSTRAINT DF_TenantTutorPosts_ExperienceBn DEFAULT (N''),
            ExperienceEn NVARCHAR(150) NOT NULL
                CONSTRAINT DF_TenantTutorPosts_ExperienceEn DEFAULT (N''),
            FulfillmentStatus NVARCHAR(30) NOT NULL
                CONSTRAINT DF_TenantTutorPosts_FulfillmentStatus DEFAULT (N'not_got'),
            Remarks NVARCHAR(500) NULL,
            IsVerified BIT NOT NULL
                CONSTRAINT DF_TenantTutorPosts_IsVerified DEFAULT (1),
            CreatedAt DATETIME2 NOT NULL
                CONSTRAINT DF_TenantTutorPosts_CreatedAt DEFAULT (SYSUTCDATETIME()),
            UpdatedAt DATETIME2 NOT NULL
                CONSTRAINT DF_TenantTutorPosts_UpdatedAt DEFAULT (SYSUTCDATETIME())
        );
    END;

    IF COL_LENGTH(N'dbo.TenantTutorPosts', N'FulfillmentStatus') IS NULL
    BEGIN
        ALTER TABLE dbo.TenantTutorPosts
        ADD FulfillmentStatus NVARCHAR(30) NOT NULL
            CONSTRAINT DF_TenantTutorPosts_FulfillmentStatus DEFAULT (N'not_got');
    END;

    IF COL_LENGTH(N'dbo.TenantTutorPosts', N'Remarks') IS NULL
    BEGIN
        ALTER TABLE dbo.TenantTutorPosts ADD Remarks NVARCHAR(500) NULL;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'IX_TenantTutorPosts_Filters_CreatedAt'
          AND object_id = OBJECT_ID(N'dbo.TenantTutorPosts')
    )
    BEGIN
        CREATE INDEX IX_TenantTutorPosts_Filters_CreatedAt
        ON dbo.TenantTutorPosts
            (TenantId, PostType, SubjectEn, AreaEn, IsVerified, CreatedAt DESC);
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'IX_TenantTutorPosts_PostType_CreatedAt'
          AND object_id = OBJECT_ID(N'dbo.TenantTutorPosts')
    )
    BEGIN
        CREATE INDEX IX_TenantTutorPosts_PostType_CreatedAt
        ON dbo.TenantTutorPosts (PostType, CreatedAt DESC);
    END;

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
