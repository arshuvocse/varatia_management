USE [VaratiaManagementDb];
GO

IF COL_LENGTH(N'dbo.OwnerPosts', N'FulfillmentStatus') IS NULL
BEGIN
    ALTER TABLE dbo.OwnerPosts
    ADD FulfillmentStatus NVARCHAR(30) NOT NULL
        CONSTRAINT DF_OwnerPosts_FulfillmentStatus DEFAULT (N'not_got');
END;
GO

IF COL_LENGTH(N'dbo.OwnerPosts', N'Remarks') IS NULL
BEGIN
    ALTER TABLE dbo.OwnerPosts ADD Remarks NVARCHAR(500) NULL;
END;
GO

IF COL_LENGTH(N'dbo.TenantTutorPosts', N'FulfillmentStatus') IS NULL
BEGIN
    ALTER TABLE dbo.TenantTutorPosts
    ADD FulfillmentStatus NVARCHAR(30) NOT NULL
        CONSTRAINT DF_TenantTutorPosts_FulfillmentStatus DEFAULT (N'not_got');
END;
GO

IF COL_LENGTH(N'dbo.TenantTutorPosts', N'Remarks') IS NULL
BEGIN
    ALTER TABLE dbo.TenantTutorPosts ADD Remarks NVARCHAR(500) NULL;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UpdateOwnerPostFulfillment
    @PostId NVARCHAR(40),
    @OwnerId NVARCHAR(100),
    @FulfillmentStatus NVARCHAR(30),
    @Remarks NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @FulfillmentStatus = LOWER(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(@FulfillmentStatus, N''))), N'-', N'_'), N' ', N'_'));

    IF @FulfillmentStatus IN (N'found', N'rented', N'yes')
    BEGIN
        SET @FulfillmentStatus = N'got';
    END;

    IF @FulfillmentStatus <> N'got'
    BEGIN
        SET @FulfillmentStatus = N'not_got';
    END;

    UPDATE dbo.OwnerPosts
    SET
        FulfillmentStatus = @FulfillmentStatus,
        Remarks = NULLIF(LTRIM(RTRIM(@Remarks)), N''),
        UpdatedAt = SYSUTCDATETIME()
    WHERE Id = @PostId
      AND OwnerId = @OwnerId;

    SELECT @@ROWCOUNT AS AffectedRows;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UpdateTenantTutorPostFulfillment
    @PostId NVARCHAR(50),
    @TenantId NVARCHAR(100),
    @FulfillmentStatus NVARCHAR(30),
    @Remarks NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @FulfillmentStatus = LOWER(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(@FulfillmentStatus, N''))), N'-', N'_'), N' ', N'_'));

    IF @FulfillmentStatus IN (N'found', N'matched', N'yes')
    BEGIN
        SET @FulfillmentStatus = N'got';
    END;

    IF @FulfillmentStatus <> N'got'
    BEGIN
        SET @FulfillmentStatus = N'not_got';
    END;

    UPDATE dbo.TenantTutorPosts
    SET
        FulfillmentStatus = @FulfillmentStatus,
        Remarks = NULLIF(LTRIM(RTRIM(@Remarks)), N''),
        UpdatedAt = SYSUTCDATETIME()
    WHERE Id = @PostId
      AND TenantId = @TenantId;

    SELECT @@ROWCOUNT AS AffectedRows;
END;
GO
