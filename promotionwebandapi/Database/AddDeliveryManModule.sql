USE SmartBazarDb;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- The application also executes this schema idempotently on first use.
IF OBJECT_ID(N'dbo.tbl_DeliveryMen', N'U') IS NULL
CREATE TABLE dbo.tbl_DeliveryMen (
    Id INT IDENTITY(1,1) PRIMARY KEY, UserId INT NOT NULL UNIQUE, ShopkeeperId INT NULL, AgentUserId INT NULL,
    DivisionId INT NOT NULL, DistrictId INT NOT NULL, ThanaId INT NOT NULL,
    Address NVARCHAR(250) NOT NULL, Latitude DECIMAL(9,6) NOT NULL, Longitude DECIMAL(9,6) NOT NULL,
    LastLatitude DECIMAL(9,6) NULL, LastLongitude DECIMAL(9,6) NULL, LastLocationAt DATETIME2(0) NULL,
    NidNumber NVARCHAR(30) NULL, NidPhotoUrl NVARCHAR(500) NULL,
    NidFrontPhotoUrl NVARCHAR(500) NULL, NidBackPhotoUrl NVARCHAR(500) NULL,
    DateOfBirth DATE NULL, EmergencyContact NVARCHAR(20) NULL, VehicleType NVARCHAR(50) NULL,
    VehicleNumber NVARCHAR(50) NULL, DrivingLicenseNumber NVARCHAR(50) NULL,
    DrivingLicensePhotoUrl NVARCHAR(500) NULL, ProfilePhotoUrl NVARCHAR(500) NULL,
    Availability NVARCHAR(20) NOT NULL DEFAULT N'Offline', CreatedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_DeliveryMen_User FOREIGN KEY(UserId) REFERENCES dbo.tbl_Users(Id),
    CONSTRAINT FK_DeliveryMen_Shop FOREIGN KEY(ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id),
    CONSTRAINT FK_DeliveryMen_Agent FOREIGN KEY(AgentUserId) REFERENCES dbo.tbl_Users(Id),
    CONSTRAINT FK_DeliveryMen_Division FOREIGN KEY(DivisionId) REFERENCES dbo.tbl_Divisions(Id),
    CONSTRAINT FK_DeliveryMen_District FOREIGN KEY(DistrictId) REFERENCES dbo.tbl_Districts(Id),
    CONSTRAINT FK_DeliveryMen_Thana FOREIGN KEY(ThanaId) REFERENCES dbo.tbl_Thanas(Id)
);
GO
IF OBJECT_ID(N'dbo.tbl_AgentDistricts', N'U') IS NULL
CREATE TABLE dbo.tbl_AgentDistricts (
    AgentUserId INT NOT NULL PRIMARY KEY,
    DistrictId INT NOT NULL CONSTRAINT UQ_tbl_AgentDistricts_District UNIQUE,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_AgentDistricts_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_tbl_AgentDistricts_User FOREIGN KEY (AgentUserId) REFERENCES dbo.tbl_Users(Id),
    CONSTRAINT FK_tbl_AgentDistricts_District FOREIGN KEY (DistrictId) REFERENCES dbo.tbl_Districts(Id)
);
GO
IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'AgentUserId') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD AgentUserId INT NULL;
IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'DivisionId') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD DivisionId INT NULL;
IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'DistrictId') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD DistrictId INT NULL;
IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'ThanaId') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD ThanaId INT NULL;
IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'Latitude') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD Latitude DECIMAL(9,6) NULL;
IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'Longitude') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD Longitude DECIMAL(9,6) NULL;
IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'LastLatitude') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD LastLatitude DECIMAL(9,6) NULL;
IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'LastLongitude') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD LastLongitude DECIMAL(9,6) NULL;
IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'LastLocationAt') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD LastLocationAt DATETIME2(0) NULL;
IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'NidFrontPhotoUrl') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD NidFrontPhotoUrl NVARCHAR(500) NULL;
IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'NidBackPhotoUrl') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD NidBackPhotoUrl NVARCHAR(500) NULL;
GO
UPDATE dbo.tbl_DeliveryMen SET NidFrontPhotoUrl = NidPhotoUrl
WHERE NidFrontPhotoUrl IS NULL AND NidPhotoUrl IS NOT NULL;
GO
IF OBJECT_ID(N'dbo.tbl_OrderDeliveryAssignments', N'U') IS NULL
CREATE TABLE dbo.tbl_OrderDeliveryAssignments (
    Id INT IDENTITY(1,1) PRIMARY KEY, OrderId INT NOT NULL, DeliveryManId INT NOT NULL,
    Status NVARCHAR(30) NOT NULL DEFAULT N'Assigned', DeliveryOtp NVARCHAR(6) NOT NULL,
    CashCollectedAmount DECIMAL(18,2) NULL, DeliveryNote NVARCHAR(500) NULL,
    ProofPhotoUrl NVARCHAR(500) NULL, CustomerSignatureUrl NVARCHAR(500) NULL,
    CurrentLatitude DECIMAL(9,6) NULL, CurrentLongitude DECIMAL(9,6) NULL,
    AssignedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(), UpdatedAt DATETIME2(0) NULL,
    DeliveredAt DATETIME2(0) NULL, IsCurrent BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Assignment_Order FOREIGN KEY(OrderId) REFERENCES dbo.tbl_CustomerOrders(Id),
    CONSTRAINT FK_Assignment_DeliveryMan FOREIGN KEY(DeliveryManId) REFERENCES dbo.tbl_DeliveryMen(Id)
);
GO
IF OBJECT_ID(N'dbo.tbl_OrderStatusHistory', N'U') IS NULL
CREATE TABLE dbo.tbl_OrderStatusHistory (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY, OrderId INT NOT NULL, Status NVARCHAR(30) NOT NULL,
    ChangedByUserId INT NOT NULL, Note NVARCHAR(500) NULL, Latitude DECIMAL(9,6) NULL,
    Longitude DECIMAL(9,6) NULL, ChangedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_OrderHistory_Order FOREIGN KEY(OrderId) REFERENCES dbo.tbl_CustomerOrders(Id),
    CONSTRAINT FK_OrderHistory_User FOREIGN KEY(ChangedByUserId) REFERENCES dbo.tbl_Users(Id)
);
GO
IF OBJECT_ID(N'dbo.tbl_Notifications', N'U') IS NULL
CREATE TABLE dbo.tbl_Notifications (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY, RecipientUserId INT NOT NULL,
    Title NVARCHAR(150) NOT NULL, Message NVARCHAR(500) NOT NULL, ReferenceId INT NULL,
    IsRead BIT NOT NULL DEFAULT 0, CreatedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Notifications_User FOREIGN KEY(RecipientUserId) REFERENCES dbo.tbl_Users(Id)
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Assignment_CurrentOrder')
    CREATE UNIQUE INDEX UX_Assignment_CurrentOrder ON dbo.tbl_OrderDeliveryAssignments(OrderId) WHERE IsCurrent = 1;
GO
