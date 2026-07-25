SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.Tenants', N'U') IS NULL
    BEGIN
        THROW 50001, 'dbo.Tenants table was not found. Migration aborted.', 1;
    END;

    IF OBJECT_ID(N'dbo.Properties', N'U') IS NULL
    BEGIN
        THROW 50002, 'dbo.Properties table was not found. Migration aborted.', 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'IX_Tenants_PropertyId'
          AND object_id = OBJECT_ID(N'dbo.Tenants')
    )
    BEGIN
        CREATE INDEX IX_Tenants_PropertyId
        ON dbo.Tenants (PropertyId);
    END;

    IF OBJECT_ID(N'dbo.vw_OwnerTenantList', N'V') IS NOT NULL
    BEGIN
        DROP VIEW dbo.vw_OwnerTenantList;
    END;

    EXEC(N'
CREATE VIEW dbo.vw_OwnerTenantList
AS
SELECT
    t.Id,
    t.Name,
    t.Phone,
    t.Nid,
    COALESCE(p.Name, '''') AS PropertyName
FROM dbo.Tenants t
LEFT JOIN dbo.Properties p ON p.Id = t.PropertyId;
');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
