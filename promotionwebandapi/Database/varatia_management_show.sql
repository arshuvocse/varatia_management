USE [VaratiaManagementDb];
GO

SET NOCOUNT ON;
GO

PRINT '=== TABLE LIST ===';
SELECT
    t.TABLE_SCHEMA,
    t.TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES AS t
WHERE t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME;
GO

PRINT '=== COLUMN DETAILS ===';
SELECT
    c.TABLE_SCHEMA,
    c.TABLE_NAME,
    c.ORDINAL_POSITION,
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.CHARACTER_MAXIMUM_LENGTH,
    c.NUMERIC_PRECISION,
    c.NUMERIC_SCALE,
    c.IS_NULLABLE,
    c.COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS AS c
WHERE c.TABLE_SCHEMA = 'dbo'
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;
GO

PRINT '=== PRIMARY / FOREIGN KEY DETAILS ===';
SELECT
    tc.CONSTRAINT_TYPE,
    tc.TABLE_SCHEMA,
    tc.TABLE_NAME,
    tc.CONSTRAINT_NAME,
    kcu.COLUMN_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS kcu
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
   AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
   AND tc.TABLE_NAME = kcu.TABLE_NAME
WHERE tc.TABLE_SCHEMA = 'dbo'
  AND tc.CONSTRAINT_TYPE IN ('PRIMARY KEY', 'FOREIGN KEY')
ORDER BY tc.TABLE_NAME, tc.CONSTRAINT_TYPE, kcu.ORDINAL_POSITION;
GO

PRINT '=== ROW COUNT PER TABLE ===';
IF OBJECT_ID(N'tempdb..#RowCounts', N'U') IS NOT NULL
BEGIN
    DROP TABLE #RowCounts;
END;

CREATE TABLE #RowCounts
(
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    [RowCount] BIGINT NOT NULL
);

DECLARE @RowCountSql NVARCHAR(MAX) = N'';

SELECT
    @RowCountSql = @RowCountSql +
    N'
    INSERT INTO #RowCounts (SchemaName, TableName, [RowCount])
    SELECT N''' + REPLACE(s.name, '''', '''''') + N''',
           N''' + REPLACE(t.name, '''', '''''') + N''',
           COUNT_BIG(*)
    FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N';'
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE s.name = N'dbo'
ORDER BY t.name;

EXEC sp_executesql @RowCountSql;

SELECT
    SchemaName,
    TableName,
    [RowCount]
FROM #RowCounts
ORDER BY TableName;

DROP TABLE #RowCounts;
GO

PRINT '=== DATA: Buildings ===';
IF OBJECT_ID(N'dbo.Buildings', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.Buildings ORDER BY Id;
END;
GO

PRINT '=== DATA: Floors ===';
IF OBJECT_ID(N'dbo.Floors', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.Floors ORDER BY Id;
END;
GO

PRINT '=== DATA: Properties ===';
IF OBJECT_ID(N'dbo.Properties', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.Properties ORDER BY Id;
END;
GO

PRINT '=== DATA: Tenants ===';
IF OBJECT_ID(N'dbo.Tenants', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.Tenants ORDER BY Id;
END;
GO

PRINT '=== DATA: RentPayments ===';
IF OBJECT_ID(N'dbo.RentPayments', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.RentPayments ORDER BY Id;
END;
GO

PRINT '=== DATA: Expenses ===';
IF OBJECT_ID(N'dbo.Expenses', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.Expenses ORDER BY Id;
END;
GO

PRINT '=== DATA: Notifications ===';
IF OBJECT_ID(N'dbo.Notifications', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.Notifications ORDER BY Id;
END;
GO

PRINT '=== DATA: Messages ===';
IF OBJECT_ID(N'dbo.Messages', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.Messages ORDER BY Id;
END;
GO

PRINT '=== DATA: Activities ===';
IF OBJECT_ID(N'dbo.Activities', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.Activities ORDER BY Id;
END;
GO

PRINT '=== DATA: OwnerPosts ===';
IF OBJECT_ID(N'dbo.OwnerPosts', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.OwnerPosts ORDER BY CreatedAt DESC, Id DESC;
END;
GO

PRINT '=== DATA: OwnerPostPhotos ===';
IF OBJECT_ID(N'dbo.OwnerPostPhotos', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.OwnerPostPhotos ORDER BY PostId, DisplayOrder;
END;
GO

PRINT '=== DATA: OwnerPostTenantPreferences ===';
IF OBJECT_ID(N'dbo.OwnerPostTenantPreferences', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.OwnerPostTenantPreferences ORDER BY PostId, DisplayOrder;
END;
GO

PRINT '=== DATA: OwnerPostAmenities ===';
IF OBJECT_ID(N'dbo.OwnerPostAmenities', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.OwnerPostAmenities ORDER BY PostId, DisplayOrder;
END;
GO

PRINT '=== DATA: TenantAreaWards ===';
IF OBJECT_ID(N'dbo.TenantAreaWards', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.TenantAreaWards ORDER BY DisplayOrder, WardNo;
END;
GO

PRINT '=== DATA: TenantAreaWardRules ===';
IF OBJECT_ID(N'dbo.TenantAreaWardRules', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.TenantAreaWardRules ORDER BY WardId, Language, DisplayOrder;
END;
GO

PRINT '=== DATA: TenantAreaPosts ===';
IF OBJECT_ID(N'dbo.TenantAreaPosts', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.TenantAreaPosts ORDER BY CreatedAt DESC, Id DESC;
END;
GO

PRINT '=== DATA: TenantAreaPostAttachments ===';
IF OBJECT_ID(N'dbo.TenantAreaPostAttachments', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.TenantAreaPostAttachments ORDER BY PostId, DisplayOrder;
END;
GO

PRINT '=== DATA: TenantTutorPosts ===';
IF OBJECT_ID(N'dbo.TenantTutorPosts', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.TenantTutorPosts ORDER BY CreatedAt DESC, Id DESC;
END;
GO

PRINT '=== DATA: Metrics ===';
IF OBJECT_ID(N'dbo.Metrics', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.Metrics ORDER BY Id;
END;
GO

PRINT '=== DATA: DhakaDivisions ===';
IF OBJECT_ID(N'dbo.DhakaDivisions', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.DhakaDivisions ORDER BY DisplayOrder;
END;
GO

PRINT '=== DATA: DhakaAreas ===';
IF OBJECT_ID(N'dbo.DhakaAreas', N'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.DhakaAreas ORDER BY DivisionId, DisplayOrder;
END;
GO

PRINT '=== DATA: Users ===';
IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL
BEGIN
    SELECT
        Id,
        FullName,
        PhoneNumber,
        NormalizedPhoneNumber,
        Role,
        FirebaseDeviceToken,
        Imei,
        DeviceUpdatedAt,
        IsPhoneVerified,
        LastOtpCode,
        OtpExpiresAt,
        CreatedAt,
        UpdatedAt
    FROM dbo.Users
    ORDER BY CreatedAt DESC;
END;
GO
