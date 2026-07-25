SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
    BEGIN
        THROW 50001, 'dbo.Users table was not found. Migration aborted.', 1;
    END;

    IF COL_LENGTH(N'dbo.Users', N'FirebaseDeviceToken') IS NULL
    BEGIN
        ALTER TABLE dbo.Users
        ADD FirebaseDeviceToken NVARCHAR(500) NULL;
    END;

    IF COL_LENGTH(N'dbo.Users', N'Imei') IS NULL
    BEGIN
        ALTER TABLE dbo.Users
        ADD Imei NVARCHAR(120) NULL;
    END;

    IF COL_LENGTH(N'dbo.Users', N'DeviceUpdatedAt') IS NULL
    BEGIN
        ALTER TABLE dbo.Users
        ADD DeviceUpdatedAt DATETIME2 NULL;
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
