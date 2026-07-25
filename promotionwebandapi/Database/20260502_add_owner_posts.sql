USE [VaratiaManagementDb];
GO

IF OBJECT_ID(N'dbo.OwnerPosts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OwnerPosts
    (
        Id NVARCHAR(40) NOT NULL PRIMARY KEY,
        OwnerId NVARCHAR(100) NOT NULL,
        PostType NVARCHAR(30) NOT NULL,
        Status NVARCHAR(30) NOT NULL,
        PropertyLocation NVARCHAR(200) NOT NULL,
        Latitude DECIMAL(9,6) NULL,
        Longitude DECIMAL(9,6) NULL,
        LatLongAddress NVARCHAR(250) NULL,
        BuildingId NVARCHAR(100) NOT NULL,
        FloorId NVARCHAR(100) NOT NULL,
        PropertyId NVARCHAR(100) NOT NULL,
        PropertyTitle NVARCHAR(150) NOT NULL,
        TotalFloors INT NOT NULL,
        Bedrooms INT NOT NULL,
        Balconies INT NOT NULL,
        Dining INT NOT NULL,
        Drawing INT NOT NULL,
        Bathrooms INT NOT NULL,
        Kitchens INT NOT NULL,
        MonthlyRent INT NOT NULL,
        Advance INT NOT NULL,
        ServiceCharge INT NOT NULL,
        AreaSqft INT NOT NULL,
        ContactNumber NVARCHAR(30) NOT NULL,
        Description NVARCHAR(1000) NULL,
        CreatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_OwnerPosts_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_OwnerPosts_UpdatedAt DEFAULT (SYSUTCDATETIME())
    );
END;
GO

IF COL_LENGTH(N'dbo.OwnerPosts', N'Latitude') IS NULL
BEGIN
    ALTER TABLE dbo.OwnerPosts ADD Latitude DECIMAL(9,6) NULL;
END;
GO

IF COL_LENGTH(N'dbo.OwnerPosts', N'Longitude') IS NULL
BEGIN
    ALTER TABLE dbo.OwnerPosts ADD Longitude DECIMAL(9,6) NULL;
END;
GO

IF COL_LENGTH(N'dbo.OwnerPosts', N'LatLongAddress') IS NULL
BEGIN
    ALTER TABLE dbo.OwnerPosts ADD LatLongAddress NVARCHAR(250) NULL;
END;
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

IF OBJECT_ID(N'dbo.OwnerPostPhotos', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OwnerPostPhotos
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        PostId NVARCHAR(40) NOT NULL,
        FileName NVARCHAR(150) NOT NULL,
        Url NVARCHAR(500) NOT NULL,
        DisplayOrder INT NOT NULL,
        CONSTRAINT FK_OwnerPostPhotos_OwnerPosts
            FOREIGN KEY (PostId) REFERENCES dbo.OwnerPosts (Id)
            ON DELETE CASCADE
    );
END;
GO

IF OBJECT_ID(N'dbo.OwnerPostTenantPreferences', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OwnerPostTenantPreferences
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        PostId NVARCHAR(40) NOT NULL,
        Preference NVARCHAR(50) NOT NULL,
        DisplayOrder INT NOT NULL,
        CONSTRAINT FK_OwnerPostTenantPreferences_OwnerPosts
            FOREIGN KEY (PostId) REFERENCES dbo.OwnerPosts (Id)
            ON DELETE CASCADE
    );
END;
GO

IF OBJECT_ID(N'dbo.OwnerPostAmenities', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OwnerPostAmenities
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        PostId NVARCHAR(40) NOT NULL,
        Amenity NVARCHAR(50) NOT NULL,
        DisplayOrder INT NOT NULL,
        CONSTRAINT FK_OwnerPostAmenities_OwnerPosts
            FOREIGN KEY (PostId) REFERENCES dbo.OwnerPosts (Id)
            ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_OwnerPosts_OwnerId_Status'
      AND object_id = OBJECT_ID(N'dbo.OwnerPosts')
)
BEGIN
    CREATE INDEX IX_OwnerPosts_OwnerId_Status
    ON dbo.OwnerPosts (OwnerId, Status);
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_OwnerPostPhotos_PostId_DisplayOrder'
      AND object_id = OBJECT_ID(N'dbo.OwnerPostPhotos')
)
BEGIN
    CREATE INDEX IX_OwnerPostPhotos_PostId_DisplayOrder
    ON dbo.OwnerPostPhotos (PostId, DisplayOrder);
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_OwnerPostTenantPreferences_PostId_DisplayOrder'
      AND object_id = OBJECT_ID(N'dbo.OwnerPostTenantPreferences')
)
BEGIN
    CREATE INDEX IX_OwnerPostTenantPreferences_PostId_DisplayOrder
    ON dbo.OwnerPostTenantPreferences (PostId, DisplayOrder);
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_OwnerPostAmenities_PostId_DisplayOrder'
      AND object_id = OBJECT_ID(N'dbo.OwnerPostAmenities')
)
BEGIN
    CREATE INDEX IX_OwnerPostAmenities_PostId_DisplayOrder
    ON dbo.OwnerPostAmenities (PostId, DisplayOrder);
END;
GO
