-- Run this migration against VaratiaManagementDb.
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH(N'dbo.Buildings', N'UserId') IS NULL
    BEGIN
        ALTER TABLE dbo.Buildings ADD UserId NVARCHAR(100) NULL;
    END;

    IF COL_LENGTH(N'dbo.Buildings', N'Address') IS NULL
    BEGIN
        ALTER TABLE dbo.Buildings ADD Address NVARCHAR(250) NULL;
    END;

    IF COL_LENGTH(N'dbo.Buildings', N'Latitude') IS NULL
    BEGIN
        ALTER TABLE dbo.Buildings ADD Latitude DECIMAL(9,6) NULL;
    END;

    IF COL_LENGTH(N'dbo.Buildings', N'Longitude') IS NULL
    BEGIN
        ALTER TABLE dbo.Buildings ADD Longitude DECIMAL(9,6) NULL;
    END;

    IF COL_LENGTH(N'dbo.Buildings', N'ZoneId') IS NULL
    BEGIN
        ALTER TABLE dbo.Buildings ADD ZoneId NVARCHAR(30) NULL;
    END;

    IF COL_LENGTH(N'dbo.Buildings', N'StationId') IS NULL
    BEGIN
        ALTER TABLE dbo.Buildings ADD StationId NVARCHAR(60) NULL;
    END;

    IF COL_LENGTH(N'dbo.Buildings', N'WardId') IS NULL
    BEGIN
        ALTER TABLE dbo.Buildings ADD WardId INT NULL;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'IX_Buildings_UserId'
          AND object_id = OBJECT_ID(N'dbo.Buildings')
    )
    BEGIN
        CREATE INDEX IX_Buildings_UserId
        ON dbo.Buildings (UserId);
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'IX_Buildings_ZoneId_StationId_WardId'
          AND object_id = OBJECT_ID(N'dbo.Buildings')
    )
    BEGIN
        CREATE INDEX IX_Buildings_ZoneId_StationId_WardId
        ON dbo.Buildings (ZoneId, StationId, WardId);
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
