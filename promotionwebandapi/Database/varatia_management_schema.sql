IF DB_ID(N'VaratiaManagementDb') IS NULL
BEGIN
    CREATE DATABASE [VaratiaManagementDb];
END;
GO

USE [VaratiaManagementDb];
GO

IF OBJECT_ID(N'dbo.Buildings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Buildings
    (
        Id NVARCHAR(20) NOT NULL PRIMARY KEY,
        UserId NVARCHAR(100) NULL,
        Name NVARCHAR(100) NOT NULL,
        TotalFloors INT NOT NULL,
        Location NVARCHAR(200) NOT NULL,
        Address NVARCHAR(250) NULL,
        Latitude DECIMAL(9,6) NULL,
        Longitude DECIMAL(9,6) NULL,
        ZoneId NVARCHAR(30) NULL,
        StationId NVARCHAR(60) NULL,
        WardId INT NULL
    );
END;
GO

IF COL_LENGTH(N'dbo.Buildings', N'UserId') IS NULL
BEGIN
    ALTER TABLE dbo.Buildings ADD UserId NVARCHAR(100) NULL;
END;
GO

IF COL_LENGTH(N'dbo.Buildings', N'Address') IS NULL
BEGIN
    ALTER TABLE dbo.Buildings ADD Address NVARCHAR(250) NULL;
END;
GO

IF COL_LENGTH(N'dbo.Buildings', N'Latitude') IS NULL
BEGIN
    ALTER TABLE dbo.Buildings ADD Latitude DECIMAL(9,6) NULL;
END;
GO

IF COL_LENGTH(N'dbo.Buildings', N'Longitude') IS NULL
BEGIN
    ALTER TABLE dbo.Buildings ADD Longitude DECIMAL(9,6) NULL;
END;
GO

IF COL_LENGTH(N'dbo.Buildings', N'ZoneId') IS NULL
BEGIN
    ALTER TABLE dbo.Buildings ADD ZoneId NVARCHAR(30) NULL;
END;
GO

IF COL_LENGTH(N'dbo.Buildings', N'StationId') IS NULL
BEGIN
    ALTER TABLE dbo.Buildings ADD StationId NVARCHAR(60) NULL;
END;
GO

IF COL_LENGTH(N'dbo.Buildings', N'WardId') IS NULL
BEGIN
    ALTER TABLE dbo.Buildings ADD WardId INT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Floors', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Floors
    (
        Id NVARCHAR(20) NOT NULL PRIMARY KEY,
        BuildingId NVARCHAR(20) NOT NULL,
        Label NVARCHAR(50) NOT NULL,
        TotalUnits INT NOT NULL,
        CONSTRAINT FK_Floors_Buildings
            FOREIGN KEY (BuildingId) REFERENCES dbo.Buildings (Id)
    );
END;
GO

IF OBJECT_ID(N'dbo.Properties', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Properties
    (
        Id NVARCHAR(20) NOT NULL PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Location NVARCHAR(200) NOT NULL,
        MonthlyRent INT NOT NULL,
        Status NVARCHAR(20) NOT NULL,
        TenantName NVARCHAR(100) NULL,
        DueAmount INT NOT NULL CONSTRAINT DF_Properties_DueAmount DEFAULT (0),
        BuildingId NVARCHAR(20) NULL,
        FloorId NVARCHAR(20) NULL,
        CONSTRAINT FK_Properties_Buildings
            FOREIGN KEY (BuildingId) REFERENCES dbo.Buildings (Id),
        CONSTRAINT FK_Properties_Floors
            FOREIGN KEY (FloorId) REFERENCES dbo.Floors (Id)
    );
END;
GO

IF OBJECT_ID(N'dbo.Tenants', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Tenants
    (
        Id NVARCHAR(20) NOT NULL PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Phone NVARCHAR(30) NOT NULL,
        Nid NVARCHAR(50) NOT NULL,
        PropertyId NVARCHAR(20) NULL,
        CONSTRAINT FK_Tenants_Properties
            FOREIGN KEY (PropertyId) REFERENCES dbo.Properties (Id)
    );
END;
GO

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
GO

IF OBJECT_ID(N'dbo.vw_OwnerTenantList', N'V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_OwnerTenantList;
END;
GO

CREATE VIEW dbo.vw_OwnerTenantList
AS
SELECT
    t.Id,
    t.Name,
    t.Phone,
    t.Nid,
    COALESCE(p.Name, N'') AS PropertyName
FROM dbo.Tenants t
LEFT JOIN dbo.Properties p ON p.Id = t.PropertyId;
GO

IF OBJECT_ID(N'dbo.RentPayments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RentPayments
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        PropertyId NVARCHAR(20) NOT NULL,
        TenantName NVARCHAR(100) NULL,
        MonthLabel NVARCHAR(50) NOT NULL,
        Amount INT NOT NULL,
        Status NVARCHAR(20) NOT NULL,
        PaidOn DATETIME2 NULL,
        CONSTRAINT FK_RentPayments_Properties
            FOREIGN KEY (PropertyId) REFERENCES dbo.Properties (Id)
    );
END;
GO

IF OBJECT_ID(N'dbo.Expenses', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Expenses
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Title NVARCHAR(100) NOT NULL,
        Category NVARCHAR(50) NOT NULL,
        Amount INT NOT NULL,
        MonthLabel NVARCHAR(50) NOT NULL
    );
END;
GO

IF OBJECT_ID(N'dbo.Notifications', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Notifications
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Title NVARCHAR(150) NOT NULL,
        Subtitle NVARCHAR(250) NOT NULL,
        CreatedAt DATETIME2 NOT NULL,
        IsUnread BIT NOT NULL CONSTRAINT DF_Notifications_IsUnread DEFAULT (0)
    );
END;
GO

IF OBJECT_ID(N'dbo.Messages', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Messages
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Sender NVARCHAR(100) NOT NULL,
        Message NVARCHAR(250) NOT NULL,
        PropertyName NVARCHAR(100) NOT NULL,
        TimeLabel NVARCHAR(30) NOT NULL
    );
END;
GO

IF OBJECT_ID(N'dbo.Activities', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Activities
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Title NVARCHAR(150) NOT NULL,
        Subtitle NVARCHAR(250) NOT NULL,
        TimeLabel NVARCHAR(30) NOT NULL
    );
END;
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
GO

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
GO

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
GO

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
GO

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
GO

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
GO

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
GO

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
GO

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
GO

IF OBJECT_ID(N'dbo.Metrics', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Metrics
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        MetricType NVARCHAR(20) NOT NULL,
        Label NVARCHAR(20) NOT NULL,
        Value DECIMAL(18,2) NOT NULL
    );
END;
GO

IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users
    (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        FullName NVARCHAR(150) NOT NULL,
        PhoneNumber NVARCHAR(30) NOT NULL,
        NormalizedPhoneNumber NVARCHAR(30) NOT NULL,
        PasswordHash NVARCHAR(256) NOT NULL,
        PasswordSalt NVARCHAR(128) NOT NULL,
        Role NVARCHAR(20) NULL,
        FirebaseDeviceToken NVARCHAR(500) NULL,
        Imei NVARCHAR(120) NULL,
        DeviceUpdatedAt DATETIME2 NULL,
        IsPhoneVerified BIT NOT NULL CONSTRAINT DF_Users_IsPhoneVerified DEFAULT (0),
        LastOtpCode NVARCHAR(10) NULL,
        OtpExpiresAt DATETIME2 NULL,
        CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt DATETIME2 NOT NULL CONSTRAINT DF_Users_UpdatedAt DEFAULT (SYSUTCDATETIME())
    );
END;
GO

IF COL_LENGTH(N'dbo.Users', N'FirebaseDeviceToken') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD FirebaseDeviceToken NVARCHAR(500) NULL;
END;
GO

IF COL_LENGTH(N'dbo.Users', N'Imei') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD Imei NVARCHAR(120) NULL;
END;
GO

IF COL_LENGTH(N'dbo.Users', N'DeviceUpdatedAt') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD DeviceUpdatedAt DATETIME2 NULL;
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_Users_NormalizedPhoneNumber'
      AND object_id = OBJECT_ID(N'dbo.Users')
)
BEGIN
    CREATE UNIQUE INDEX UX_Users_NormalizedPhoneNumber
        ON dbo.Users (NormalizedPhoneNumber);
END;
GO

DELETE FROM dbo.Metrics;
DELETE FROM dbo.Activities;
DELETE FROM dbo.Messages;
DELETE FROM dbo.Notifications;
DELETE FROM dbo.Expenses;
DELETE FROM dbo.TenantAreaPostAttachments;
DELETE FROM dbo.TenantAreaPosts;
DELETE FROM dbo.TenantAreaWardRules;
DELETE FROM dbo.TenantAreaWards;
DELETE FROM dbo.TenantTutorPosts;
DELETE FROM dbo.OwnerPostPhotos;
DELETE FROM dbo.OwnerPostTenantPreferences;
DELETE FROM dbo.OwnerPostAmenities;
DELETE FROM dbo.OwnerPosts;
DELETE FROM dbo.RentPayments;
DELETE FROM dbo.Tenants;
DELETE FROM dbo.Properties;
DELETE FROM dbo.Floors;
DELETE FROM dbo.Buildings;
GO

INSERT INTO dbo.TenantAreaWards
    (Id, City, WardNo, TitleBn, TitleEn, Area, MemberCount, IsVerified, DisplayOrder)
VALUES
    (N'ward-14', N'dncc', 14, N'ওয়ার্ড ১৪ - মিরপুর', N'Ward 14 - Mirpur', N'Mirpur-10, Dhaka', 2386, 1, 1),
    (N'ward-13', N'dncc', 13, N'ওয়ার্ড ১৩ - পল্লবী', N'Ward 13 - Pallabi', N'Pallabi, Mirpur, Dhaka', 1740, 1, 2),
    (N'ward-15', N'dncc', 15, N'ওয়ার্ড ১৫ - কাফরুল', N'Ward 15 - Kafrul', N'Kafrul, Dhaka', 1298, 1, 3),
    (N'ward-1', N'dncc', 1, N'ওয়ার্ড ১ - উত্তরা', N'Ward 1 - Uttara', N'Uttara, Dhaka', 3100, 1, 4);
GO

INSERT INTO dbo.TenantAreaWardRules
    (WardId, Language, RuleText, DisplayOrder)
VALUES
    (N'ward-14', N'bn', N'স্প্যাম করা যাবে না।', 1),
    (N'ward-14', N'en', N'Do not post spam.', 1);
GO

INSERT INTO dbo.Buildings (Id, Name, TotalFloors, Location)
VALUES
    (N'B-01', N'Building A', 5, N'Dhanmondi, Dhaka'),
    (N'B-02', N'Building B', 3, N'Mirpur, Dhaka');
GO

INSERT INTO dbo.Floors (Id, BuildingId, Label, TotalUnits)
VALUES
    (N'F-01', N'B-01', N'Floor 1', 2),
    (N'F-02', N'B-01', N'Floor 2', 2),
    (N'F-03', N'B-01', N'Floor 3', 1),
    (N'F-04', N'B-01', N'Floor 4', 1),
    (N'F-05', N'B-01', N'Floor 5', 1),
    (N'F-06', N'B-02', N'Floor 1', 1),
    (N'F-07', N'B-02', N'Floor 2', 1),
    (N'F-08', N'B-02', N'Floor 3', 1);
GO

INSERT INTO dbo.Properties
    (Id, Name, Location, MonthlyRent, Status, TenantName, DueAmount, BuildingId, FloorId)
VALUES
    (N'P-01', N'Flat A', N'Dhanmondi, Dhaka', 5000, N'rented', N'Rahim', 0, N'B-01', N'F-01'),
    (N'P-02', N'Flat B', N'Dhanmondi, Dhaka', 4500, N'available', NULL, 4500, N'B-01', N'F-01'),
    (N'P-03', N'Flat C', N'Dhanmondi, Dhaka', 6000, N'rented', N'Nusrat', 0, N'B-01', N'F-02'),
    (N'P-04', N'Flat D', N'Dhanmondi, Dhaka', 5500, N'rented', N'Karim', 0, N'B-01', N'F-02'),
    (N'P-05', N'Flat E', N'Dhanmondi, Dhaka', 4800, N'rented', N'Salma', 0, N'B-01', N'F-03'),
    (N'P-06', N'Flat F', N'Dhanmondi, Dhaka', 5200, N'rented', N'Hasan', 0, N'B-01', N'F-04'),
    (N'P-07', N'Flat G', N'Dhanmondi, Dhaka', 6200, N'rented', N'Mitu', 0, N'B-01', N'F-05'),
    (N'P-08', N'Flat H', N'Mirpur, Dhaka', 5300, N'rented', N'Joy', 0, N'B-02', N'F-06'),
    (N'P-09', N'Flat I', N'Mirpur, Dhaka', 4000, N'rented', N'Mehedi', 0, N'B-02', N'F-07'),
    (N'P-10', N'Flat J', N'Mirpur, Dhaka', 3500, N'available', NULL, 3500, N'B-02', N'F-08');
GO

INSERT INTO dbo.Tenants (Id, Name, Phone, Nid, PropertyId)
VALUES
    (N'T-01', N'Rahim', N'01711111111', N'1991234567890', N'P-01'),
    (N'T-02', N'Karim', N'01811111111', N'1987654321234', N'P-04'),
    (N'T-03', N'Nusrat', N'01911111111', N'2001123412341', N'P-03'),
    (N'T-04', N'Salma', N'01611111111', N'1998765432198', N'P-05'),
    (N'T-05', N'Hasan', N'01722222222', N'1994321012345', N'P-06'),
    (N'T-06', N'Mitu', N'01822222222', N'2000234512345', N'P-07'),
    (N'T-07', N'Joy', N'01922222222', N'1995567812345', N'P-08'),
    (N'T-08', N'Mehedi', N'01622222222', N'1996678912345', N'P-09');
GO

INSERT INTO dbo.RentPayments (PropertyId, TenantName, MonthLabel, Amount, Status, PaidOn)
VALUES
    (N'P-01', N'Rahim', N'April 2026', 5000, N'paid', '2026-04-03T00:00:00'),
    (N'P-02', NULL, N'April 2026', 4500, N'due', NULL),
    (N'P-03', N'Nusrat', N'April 2026', 6000, N'paid', '2026-04-05T00:00:00'),
    (N'P-04', N'Karim', N'April 2026', 5500, N'paid', '2026-04-07T00:00:00'),
    (N'P-10', NULL, N'April 2026', 3500, N'due', NULL);
GO

INSERT INTO dbo.Expenses (Title, Category, Amount, MonthLabel)
VALUES
    (N'Electricity Bill', N'Utility', 2000, N'April 2026'),
    (N'Gas Bill', N'Utility', 1000, N'April 2026'),
    (N'Security', N'Service', 1500, N'April 2026'),
    (N'Cleaning', N'Maintenance', 800, N'April 2026');
GO

INSERT INTO dbo.Notifications (Title, Subtitle, CreatedAt, IsUnread)
VALUES
    (N'Due rent reminder sent', N'Automatic reminder was sent for Flat B.', '2026-04-14T09:15:00', 1),
    (N'Payment received alert', N'April payment for Flat A was confirmed.', '2026-04-14T08:30:00', 0),
    (N'New tenant profile completed', N'Nusrat profile verification is complete.', '2026-04-13T16:20:00', 0);
GO

INSERT INTO dbo.Messages (Sender, Message, PropertyName, TimeLabel)
VALUES
    (N'Rahim', N'Rent payment completed. Please check.', N'Flat A', N'10:15 AM'),
    (N'Karim', N'Kitchen tap needs maintenance.', N'Flat D', N'09:40 AM'),
    (N'Salma', N'Can you send the gas bill copy?', N'Flat E', N'Yesterday');
GO

INSERT INTO dbo.Activities (Title, Subtitle, TimeLabel)
VALUES
    (N'Rent payment received', N'April rent for Flat A has been deposited.', N'Today'),
    (N'New tenant added', N'Nusrat profile was assigned to Flat C.', N'Today'),
    (N'Due rent reminder sent', N'Reminders were sent for Flat B and Flat J.', N'Yesterday');
GO

INSERT INTO dbo.Metrics (MetricType, Label, Value)
VALUES
    (N'income', N'Nov', 42000),
    (N'income', N'Dec', 44000),
    (N'income', N'Jan', 46000),
    (N'income', N'Feb', 47500),
    (N'income', N'Mar', 49000),
    (N'income', N'Apr', 50000),
    (N'expense', N'Nov', 3200),
    (N'expense', N'Dec', 3600),
    (N'expense', N'Jan', 4100),
    (N'expense', N'Feb', 3900),
    (N'expense', N'Mar', 4500),
    (N'expense', N'Apr', 5300);
GO
