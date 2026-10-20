IF DB_ID(N'SmartBazarDb') IS NULL
BEGIN
    CREATE DATABASE SmartBazarDb;
END
GO

USE SmartBazarDb;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.sp_Sale_Create', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Sale_Create;
GO

IF OBJECT_ID(N'dbo.sp_CompanyDashboard_Get', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CompanyDashboard_Get;
GO

IF OBJECT_ID(N'dbo.sp_CustomerOrder_ListByCustomer', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CustomerOrder_ListByCustomer;
GO
IF OBJECT_ID(N'dbo.sp_CustomerOrder_ListByShopkeeper', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CustomerOrder_ListByShopkeeper;
GO
IF OBJECT_ID(N'dbo.sp_CustomerOrder_UpdateStatus', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CustomerOrder_UpdateStatus;
GO

IF OBJECT_ID(N'dbo.sp_CustomerOrder_Create', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CustomerOrder_Create;
GO

IF OBJECT_ID(N'dbo.sp_CustomerProduct_List', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CustomerProduct_List;
GO

IF OBJECT_ID(N'dbo.sp_Product_ListByShop', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Product_ListByShop;
GO

IF TYPE_ID(N'dbo.CustomerOrderDetailInput') IS NOT NULL
    DROP TYPE dbo.CustomerOrderDetailInput;
GO

IF TYPE_ID(N'dbo.SaleDetailInput') IS NOT NULL
    DROP TYPE dbo.SaleDetailInput;
GO

IF OBJECT_ID(N'dbo.tbl_OrderStatusHistory', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_OrderStatusHistory;
GO

IF OBJECT_ID(N'dbo.tbl_Notifications', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_Notifications;
GO

IF OBJECT_ID(N'dbo.tbl_OrderDeliveryAssignments', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_OrderDeliveryAssignments;
GO

IF OBJECT_ID(N'dbo.tbl_DeliveryMen', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_DeliveryMen;
GO

IF OBJECT_ID(N'dbo.tbl_CustomerOrderDetails', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_CustomerOrderDetails;
GO

IF OBJECT_ID(N'dbo.tbl_ChatMessages', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_ChatMessages;
GO

IF OBJECT_ID(N'dbo.tbl_ChatConversations', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_ChatConversations;
GO

IF OBJECT_ID(N'dbo.tbl_CustomerOrders', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_CustomerOrders;
GO

IF OBJECT_ID(N'dbo.tbl_SaleDetails', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_SaleDetails;
GO

IF OBJECT_ID(N'dbo.tbl_Sales', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_Sales;
GO

IF OBJECT_ID(N'dbo.tbl_ShopkeeperWallets', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_ShopkeeperWallets;
GO

IF OBJECT_ID(N'dbo.tbl_Products', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_Products;
GO

IF OBJECT_ID(N'dbo.tbl_CustomerOrderProducts', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_CustomerOrderProducts;
GO

IF OBJECT_ID(N'dbo.tbl_Customers', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_Customers;
GO

IF OBJECT_ID(N'dbo.tbl_Shopkeepers', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_Shopkeepers;
GO

IF OBJECT_ID(N'dbo.tbl_AgentDistricts', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_AgentDistricts;
GO

IF OBJECT_ID(N'dbo.tbl_Thanas', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_Thanas;
GO

IF OBJECT_ID(N'dbo.tbl_Districts', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_Districts;
GO

IF OBJECT_ID(N'dbo.tbl_Divisions', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_Divisions;
GO

IF OBJECT_ID(N'dbo.tbl_Users', N'U') IS NOT NULL
    DROP TABLE dbo.tbl_Users;
GO

CREATE TABLE dbo.tbl_Users
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_Users PRIMARY KEY,
    Name NVARCHAR(150) NOT NULL,
    Phone NVARCHAR(20) NOT NULL CONSTRAINT UQ_tbl_Users_Phone UNIQUE,
    PasswordHash NVARCHAR(200) NOT NULL,
    Role NVARCHAR(30) NOT NULL,
    ShopCode NVARCHAR(20) NULL,
    ParentUserId INT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_tbl_Users_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_tbl_Users_ParentUser FOREIGN KEY (ParentUserId) REFERENCES dbo.tbl_Users(Id)
);
GO

CREATE TABLE dbo.tbl_Divisions
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_Divisions PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL CONSTRAINT UQ_tbl_Divisions_Name UNIQUE,
    IsActive BIT NOT NULL CONSTRAINT DF_tbl_Divisions_IsActive DEFAULT (1)
);
GO

CREATE TABLE dbo.tbl_Districts
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_Districts PRIMARY KEY,
    DivisionId INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_tbl_Districts_IsActive DEFAULT (1),
    CONSTRAINT FK_tbl_Districts_tbl_Divisions FOREIGN KEY (DivisionId) REFERENCES dbo.tbl_Divisions(Id),
    CONSTRAINT UQ_tbl_Districts_Division_Name UNIQUE (DivisionId, Name)
);
GO

CREATE TABLE dbo.tbl_Thanas
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_Thanas PRIMARY KEY,
    DistrictId INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_tbl_Thanas_IsActive DEFAULT (1),
    CONSTRAINT FK_tbl_Thanas_tbl_Districts FOREIGN KEY (DistrictId) REFERENCES dbo.tbl_Districts(Id),
    CONSTRAINT UQ_tbl_Thanas_District_Name UNIQUE (DistrictId, Name)
);
GO

CREATE TABLE dbo.tbl_AgentDistricts
(
    AgentUserId INT NOT NULL CONSTRAINT PK_tbl_AgentDistricts PRIMARY KEY,
    DistrictId INT NOT NULL CONSTRAINT UQ_tbl_AgentDistricts_District UNIQUE,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_AgentDistricts_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_tbl_AgentDistricts_tbl_Users FOREIGN KEY (AgentUserId) REFERENCES dbo.tbl_Users(Id),
    CONSTRAINT FK_tbl_AgentDistricts_tbl_Districts FOREIGN KEY (DistrictId) REFERENCES dbo.tbl_Districts(Id)
);
GO

CREATE TABLE dbo.tbl_Shopkeepers
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_Shopkeepers PRIMARY KEY,
    ShopName NVARCHAR(150) NOT NULL,
    OwnerName NVARCHAR(150) NOT NULL,
    Phone NVARCHAR(20) NOT NULL CONSTRAINT UQ_tbl_Shopkeepers_Phone UNIQUE,
    NidNumber NVARCHAR(30) NULL,
    ProfilePhotoPath NVARCHAR(500) NULL,
    BillboardPhotoPath NVARCHAR(500) NULL,
    DivisionId INT NOT NULL,
    DistrictId INT NOT NULL,
    ThanaId INT NOT NULL,
    Address NVARCHAR(250) NOT NULL,
    Latitude DECIMAL(9,6) NOT NULL,
    Longitude DECIMAL(9,6) NOT NULL,
    Area NVARCHAR(150) NOT NULL,
    ShopType NVARCHAR(100) NOT NULL,
    ShopCode NVARCHAR(20) NOT NULL CONSTRAINT UQ_tbl_Shopkeepers_ShopCode UNIQUE,
    UserId INT NOT NULL,
    FieldOfficerUserId INT NOT NULL,
    RegisteredAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_Shopkeepers_RegisteredAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_tbl_Shopkeepers_tbl_Divisions FOREIGN KEY (DivisionId) REFERENCES dbo.tbl_Divisions(Id),
    CONSTRAINT FK_tbl_Shopkeepers_tbl_Districts FOREIGN KEY (DistrictId) REFERENCES dbo.tbl_Districts(Id),
    CONSTRAINT FK_tbl_Shopkeepers_tbl_Thanas FOREIGN KEY (ThanaId) REFERENCES dbo.tbl_Thanas(Id),
    CONSTRAINT FK_tbl_Shopkeepers_tbl_Users FOREIGN KEY (UserId) REFERENCES dbo.tbl_Users(Id),
    CONSTRAINT FK_tbl_Shopkeepers_FieldOfficerUser FOREIGN KEY (FieldOfficerUserId) REFERENCES dbo.tbl_Users(Id)
);
GO

CREATE TABLE dbo.tbl_Customers
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_Customers PRIMARY KEY,
    Name NVARCHAR(150) NOT NULL,
    Phone NVARCHAR(20) NOT NULL CONSTRAINT UQ_tbl_Customers_Phone UNIQUE,
    Address NVARCHAR(250) NULL,
    ProfilePhotoPath NVARCHAR(500) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_tbl_Customers_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_Customers_CreatedAt DEFAULT (SYSUTCDATETIME())
);
GO

CREATE TABLE dbo.tbl_ChatConversations
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_ChatConversations PRIMARY KEY,
    CustomerUserId INT NOT NULL,
    ShopkeeperId INT NOT NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_ChatConversations_CreatedAt DEFAULT (SYSUTCDATETIME()),
    LastMessageAt DATETIME2(0) NULL,
    CONSTRAINT FK_tbl_ChatConversations_CustomerUser FOREIGN KEY (CustomerUserId) REFERENCES dbo.tbl_Users(Id),
    CONSTRAINT FK_tbl_ChatConversations_Shopkeeper FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id),
    CONSTRAINT UQ_tbl_ChatConversations_Customer_Shop UNIQUE (CustomerUserId, ShopkeeperId)
);
GO

CREATE TABLE dbo.tbl_ChatMessages
(
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_ChatMessages PRIMARY KEY,
    ConversationId INT NOT NULL,
    SenderUserId INT NOT NULL,
    MessageType NVARCHAR(20) NOT NULL CONSTRAINT DF_tbl_ChatMessages_MessageType DEFAULT (N'Text'),
    MessageText NVARCHAR(1000) NULL,
    MediaUrl NVARCHAR(500) NULL,
    SentAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_ChatMessages_SentAt DEFAULT (SYSUTCDATETIME()),
    ReadAt DATETIME2(0) NULL,
    CONSTRAINT FK_tbl_ChatMessages_Conversation FOREIGN KEY (ConversationId) REFERENCES dbo.tbl_ChatConversations(Id),
    CONSTRAINT FK_tbl_ChatMessages_SenderUser FOREIGN KEY (SenderUserId) REFERENCES dbo.tbl_Users(Id)
);
GO

CREATE INDEX IX_tbl_ChatConversations_Shopkeeper_LastMessage
    ON dbo.tbl_ChatConversations (ShopkeeperId, LastMessageAt DESC);
GO

CREATE INDEX IX_tbl_ChatMessages_Conversation_SentAt
    ON dbo.tbl_ChatMessages (ConversationId, SentAt, Id);
GO

CREATE INDEX IX_tbl_ChatMessages_Unread
    ON dbo.tbl_ChatMessages (ConversationId, ReadAt, SenderUserId);
GO

CREATE TABLE dbo.tbl_Products
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_Products PRIMARY KEY,
    ShopkeeperId INT NOT NULL,
    Name NVARCHAR(150) NOT NULL,
    Sku NVARCHAR(50) NOT NULL,
    Category NVARCHAR(100) NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    StockQuantity INT NOT NULL CONSTRAINT DF_tbl_Products_StockQuantity DEFAULT (0),
    CommissionPercentage DECIMAL(5,2) NOT NULL CONSTRAINT DF_tbl_Products_CommissionPercentage DEFAULT (3.0),
    IsActive BIT NOT NULL CONSTRAINT DF_tbl_Products_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_Products_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_tbl_Products_tbl_Shopkeepers FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id),
    CONSTRAINT UQ_tbl_Products_Shopkeeper_Sku UNIQUE (ShopkeeperId, Sku)
);
GO

CREATE TABLE dbo.tbl_CustomerOrderProducts
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_CustomerOrderProducts PRIMARY KEY,
    Name NVARCHAR(150) NOT NULL,
    Sku NVARCHAR(50) NOT NULL CONSTRAINT UQ_tbl_CustomerOrderProducts_Sku UNIQUE,
    Category NVARCHAR(100) NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_tbl_CustomerOrderProducts_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_CustomerOrderProducts_CreatedAt DEFAULT (SYSUTCDATETIME())
);
GO

CREATE TABLE dbo.tbl_ShopkeeperWallets
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_ShopkeeperWallets PRIMARY KEY,
    ShopkeeperId INT NOT NULL CONSTRAINT UQ_tbl_ShopkeeperWallets_Shopkeeper UNIQUE,
    Balance DECIMAL(18,2) NOT NULL CONSTRAINT DF_tbl_ShopkeeperWallets_Balance DEFAULT (0),
    WithdrawableBalance DECIMAL(18,2) NOT NULL CONSTRAINT DF_tbl_ShopkeeperWallets_Withdrawable DEFAULT (0),
    PendingBalance DECIMAL(18,2) NOT NULL CONSTRAINT DF_tbl_ShopkeeperWallets_Pending DEFAULT (0),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_ShopkeeperWallets_UpdatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_tbl_ShopkeeperWallets_tbl_Shopkeepers FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id)
);
GO

CREATE TABLE dbo.tbl_ShopkeeperWalletDeductionLogs
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_ShopkeeperWalletDeductionLogs PRIMARY KEY,
    ShopkeeperId INT NOT NULL,
    SaleId INT NOT NULL,
    ProductId INT NOT NULL,
    AmountDeducted DECIMAL(18,2) NOT NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_ShopkeeperWalletDeductionLogs_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_tbl_ShopkeeperWalletDeductionLogs_tbl_Shopkeepers FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id)
);
GO

CREATE TABLE dbo.tbl_Sales
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_Sales PRIMARY KEY,
    InvoiceNo NVARCHAR(30) NOT NULL CONSTRAINT UQ_tbl_Sales_InvoiceNo UNIQUE,
    ShopkeeperId INT NOT NULL,
    CustomerId INT NOT NULL,
    PaymentMethod NVARCHAR(30) NOT NULL,
    GrossAmount DECIMAL(18,2) NOT NULL,
    CashbackAmount DECIMAL(18,2) NOT NULL,
    SystemCommission DECIMAL(18,2) NOT NULL,
    Status NVARCHAR(30) NOT NULL CONSTRAINT DF_tbl_Sales_Status DEFAULT (N'Pending'),
    SoldAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_Sales_SoldAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_tbl_Sales_tbl_Shopkeepers FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id),
    CONSTRAINT FK_tbl_Sales_tbl_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.tbl_Customers(Id)
);
GO

CREATE TABLE dbo.tbl_SaleDetails
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_SaleDetails PRIMARY KEY,
    SaleId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    LineTotal AS (CONVERT(DECIMAL(18,2), Quantity * UnitPrice)) PERSISTED,
    CONSTRAINT FK_tbl_SaleDetails_tbl_Sales FOREIGN KEY (SaleId) REFERENCES dbo.tbl_Sales(Id),
    CONSTRAINT FK_tbl_SaleDetails_tbl_Products FOREIGN KEY (ProductId) REFERENCES dbo.tbl_Products(Id)
);
GO

CREATE TABLE dbo.tbl_CustomerOrders
(
    Id INT IDENTITY(1001,1) NOT NULL CONSTRAINT PK_tbl_CustomerOrders PRIMARY KEY,
    CustomerUserId INT NOT NULL,
    CustomerName NVARCHAR(150) NOT NULL,
    CustomerPhone NVARCHAR(20) NOT NULL,
    ShopkeeperId INT NOT NULL,
    CustomerLatitude DECIMAL(9,6) NULL,
    CustomerLongitude DECIMAL(9,6) NULL,
    TotalAmount DECIMAL(18,2) NOT NULL,
    DiscountAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_tbl_CustomerOrders_DiscountAmount DEFAULT (0),
    Status NVARCHAR(30) NOT NULL CONSTRAINT DF_tbl_CustomerOrders_Status DEFAULT (N'Pending'),
    Remarks NVARCHAR(500) NULL,
    OrderDate DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_CustomerOrders_OrderDate DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_tbl_CustomerOrders_CustomerUser FOREIGN KEY (CustomerUserId) REFERENCES dbo.tbl_Users(Id),
    CONSTRAINT FK_tbl_CustomerOrders_tbl_Shopkeepers FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id)
);
GO

CREATE TABLE dbo.tbl_CustomerOrderDetails
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_CustomerOrderDetails PRIMARY KEY,
    OrderMasterId INT NOT NULL,
    ProductId INT NOT NULL,
    ProductName NVARCHAR(150) NOT NULL,
    Sku NVARCHAR(50) NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    TotalPrice AS (CONVERT(DECIMAL(18,2), Quantity * UnitPrice)) PERSISTED,
    CONSTRAINT FK_tbl_CustomerOrderDetails_tbl_CustomerOrders FOREIGN KEY (OrderMasterId) REFERENCES dbo.tbl_CustomerOrders(Id),
    CONSTRAINT FK_tbl_CustomerOrderDetails_tbl_CustomerOrderProducts FOREIGN KEY (ProductId) REFERENCES dbo.tbl_CustomerOrderProducts(Id)
);
GO

CREATE TYPE dbo.SaleDetailInput AS TABLE
(
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL
);
GO

CREATE TYPE dbo.CustomerOrderDetailInput AS TABLE
(
    ProductId INT NOT NULL,
    Quantity INT NOT NULL
);
GO

INSERT INTO dbo.tbl_Divisions (Name)
VALUES (N'Dhaka'), (N'Chattogram'), (N'Rajshahi'), (N'Khulna'), (N'Barishal'), (N'Sylhet'), (N'Rangpur'), (N'Mymensingh');
GO

INSERT INTO dbo.tbl_Districts (DivisionId, Name)
SELECT d.Id, v.Name
FROM dbo.tbl_Divisions AS d
INNER JOIN (VALUES
    (N'Dhaka', N'Dhaka'), (N'Dhaka', N'Gazipur'), (N'Dhaka', N'Narayanganj'),
    (N'Chattogram', N'Chattogram'), (N'Chattogram', N'Cumilla'), (N'Chattogram', N'Cox''s Bazar'),
    (N'Rajshahi', N'Rajshahi'), (N'Rajshahi', N'Bogura'),
    (N'Khulna', N'Khulna'), (N'Khulna', N'Jashore'),
    (N'Barishal', N'Barishal'), (N'Sylhet', N'Sylhet'),
    (N'Rangpur', N'Rangpur'), (N'Mymensingh', N'Mymensingh')
) AS v(DivisionName, Name) ON v.DivisionName = d.Name;
GO

INSERT INTO dbo.tbl_Thanas (DistrictId, Name)
SELECT dis.Id, v.Name
FROM dbo.tbl_Districts AS dis
INNER JOIN dbo.tbl_Divisions AS div ON div.Id = dis.DivisionId
INNER JOIN (VALUES
    (N'Dhaka', N'Dhaka', N'Dhanmondi'), (N'Dhaka', N'Dhaka', N'Mirpur'), (N'Dhaka', N'Dhaka', N'Uttara'),
    (N'Dhaka', N'Gazipur', N'Gazipur Sadar'), (N'Dhaka', N'Gazipur', N'Tongi'),
    (N'Dhaka', N'Narayanganj', N'Narayanganj Sadar'), (N'Dhaka', N'Narayanganj', N'Sonargaon'),
    (N'Chattogram', N'Chattogram', N'Kotwali'), (N'Chattogram', N'Chattogram', N'Panchlaish'),
    (N'Chattogram', N'Cumilla', N'Cumilla Sadar'), (N'Chattogram', N'Cox''s Bazar', N'Cox''s Bazar Sadar'),
    (N'Rajshahi', N'Rajshahi', N'Boalia'), (N'Rajshahi', N'Bogura', N'Bogura Sadar'),
    (N'Khulna', N'Khulna', N'Khulna Sadar'), (N'Khulna', N'Jashore', N'Jashore Sadar'),
    (N'Barishal', N'Barishal', N'Barishal Sadar'),
    (N'Sylhet', N'Sylhet', N'Sylhet Sadar'),
    (N'Rangpur', N'Rangpur', N'Rangpur Sadar'),
    (N'Mymensingh', N'Mymensingh', N'Mymensingh Sadar')
) AS v(DivisionName, DistrictName, Name) ON v.DivisionName = div.Name AND v.DistrictName = dis.Name;
GO

INSERT INTO dbo.tbl_CustomerOrderProducts (Name, Sku, Category, UnitPrice)
VALUES
    (N'Rice 5kg', N'RICE-5KG', N'Grocery', 420),
    (N'Soybean Oil 1L', N'OIL-1L', N'Grocery', 175),
    (N'Milk Powder 500g', N'MILK-500', N'Dairy', 390),
    (N'Soap 100g', N'SOAP-100', N'Personal Care', 55),
    (N'Tea 200g', N'TEA-200', N'Grocery', 160),
    (N'Biscuits Pack', N'BISC-PACK', N'Snacks', 70);
GO

IF OBJECT_ID(N'dbo.sp_Location_List', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Location_List;
GO

CREATE PROCEDURE dbo.sp_Location_List
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Name
    FROM dbo.tbl_Divisions
    WHERE IsActive = 1
    ORDER BY Name;

    SELECT Id, Name, DivisionId AS ParentId
    FROM dbo.tbl_Districts
    WHERE IsActive = 1
    ORDER BY Name;

    SELECT Id, Name, DistrictId AS ParentId
    FROM dbo.tbl_Thanas
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

IF OBJECT_ID(N'dbo.sp_User_Validate', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_User_Validate;
GO

CREATE PROCEDURE dbo.sp_User_Validate
    @Phone NVARCHAR(20),
    @Password NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
        Id,
        Name,
        Phone,
        PasswordHash AS [Password],
        Role,
        ShopCode,
        ParentUserId,
        CreatedAt
    FROM dbo.tbl_Users
    WHERE Phone = @Phone
      AND PasswordHash = @Password
      AND IsActive = 1;
END
GO

IF OBJECT_ID(N'dbo.sp_Shopkeeper_Register', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Shopkeeper_Register;
GO

CREATE PROCEDURE dbo.sp_Shopkeeper_Register
    @ShopName NVARCHAR(150),
    @OwnerName NVARCHAR(150),
    @Phone NVARCHAR(20),
    @NidNumber NVARCHAR(30) = NULL,
    @ProfilePhotoPath NVARCHAR(500) = NULL,
    @BillboardPhotoPath NVARCHAR(500) = NULL,
    @DivisionId INT,
    @DistrictId INT,
    @ThanaId INT,
    @Address NVARCHAR(250),
    @Latitude DECIMAL(9,6),
    @Longitude DECIMAL(9,6),
    @Area NVARCHAR(150),
    @ShopType NVARCHAR(100),
    @Password NVARCHAR(200),
    @FieldOfficerUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = @Phone)
    BEGIN
        THROW 51000, N'This mobile number already has an account.', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Id = @FieldOfficerUserId AND Role = N'FieldOfficer' AND IsActive = 1)
    BEGIN
        THROW 51001, N'Invalid field force user.', 1;
    END

    BEGIN TRANSACTION;

    INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, ParentUserId)
    VALUES (@OwnerName, @Phone, @Password, N'Shopkeeper', @FieldOfficerUserId);

    DECLARE @UserId INT = SCOPE_IDENTITY();
    DECLARE @ShopId INT;

    INSERT INTO dbo.tbl_Shopkeepers
        (ShopName, OwnerName, Phone, NidNumber, ProfilePhotoPath, BillboardPhotoPath, DivisionId, DistrictId, ThanaId, Address, Latitude, Longitude, Area, ShopType, ShopCode, UserId, FieldOfficerUserId)
    VALUES
        (@ShopName, @OwnerName, @Phone, NULLIF(LTRIM(RTRIM(@NidNumber)), N''), @ProfilePhotoPath, @BillboardPhotoPath, @DivisionId, @DistrictId, @ThanaId, @Address, @Latitude, @Longitude, @Area, @ShopType, N'TEMP', @UserId, @FieldOfficerUserId);

    SET @ShopId = SCOPE_IDENTITY();

    DECLARE @ShopCode NVARCHAR(20) = CONCAT(N'MS', FORMAT(@ShopId + 1000, N'0000'));

    UPDATE dbo.tbl_Shopkeepers
    SET ShopCode = @ShopCode
    WHERE Id = @ShopId;

    UPDATE dbo.tbl_Users
    SET ShopCode = @ShopCode
    WHERE Id = @UserId;

    COMMIT TRANSACTION;

    SELECT
        s.Id,
        s.ShopName,
        s.OwnerName,
        s.Phone,
        s.NidNumber,
        s.ProfilePhotoPath,
        s.BillboardPhotoPath,
        s.DivisionId,
        dv.Name AS DivisionName,
        s.DistrictId,
        ds.Name AS DistrictName,
        s.ThanaId,
        th.Name AS ThanaName,
        s.Address,
        s.Latitude,
        s.Longitude,
        s.Area,
        s.ShopType,
        @Password AS [Password],
        s.ShopCode,
        s.FieldOfficerUserId,
        fo.Name AS FieldOfficerName,
        fo.Phone AS FieldOfficerPhone,
        s.RegisteredAt
    FROM dbo.tbl_Shopkeepers AS s
    INNER JOIN dbo.tbl_Divisions AS dv ON dv.Id = s.DivisionId
    INNER JOIN dbo.tbl_Districts AS ds ON ds.Id = s.DistrictId
    INNER JOIN dbo.tbl_Thanas AS th ON th.Id = s.ThanaId
    INNER JOIN dbo.tbl_Users AS fo ON fo.Id = s.FieldOfficerUserId
    WHERE s.Id = @ShopId;
END
GO

IF OBJECT_ID(N'dbo.sp_Shopkeeper_List', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Shopkeeper_List;
GO

CREATE PROCEDURE dbo.sp_Shopkeeper_List
    @FieldOfficerUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.Id,
        s.ShopName,
        s.OwnerName,
        s.Phone,
        s.NidNumber,
        s.ProfilePhotoPath,
        s.BillboardPhotoPath,
        s.DivisionId,
        dv.Name AS DivisionName,
        s.DistrictId,
        ds.Name AS DistrictName,
        s.ThanaId,
        th.Name AS ThanaName,
        s.Address,
        s.Latitude,
        s.Longitude,
        s.Area,
        s.ShopType,
        u.PasswordHash AS [Password],
        s.ShopCode,
        s.FieldOfficerUserId,
        fo.Name AS FieldOfficerName,
        fo.Phone AS FieldOfficerPhone,
        s.RegisteredAt
    FROM dbo.tbl_Shopkeepers AS s
    INNER JOIN dbo.tbl_Users AS u ON u.Id = s.UserId
    INNER JOIN dbo.tbl_Users AS fo ON fo.Id = s.FieldOfficerUserId
    INNER JOIN dbo.tbl_Divisions AS dv ON dv.Id = s.DivisionId
    INNER JOIN dbo.tbl_Districts AS ds ON ds.Id = s.DistrictId
    INNER JOIN dbo.tbl_Thanas AS th ON th.Id = s.ThanaId
    WHERE @FieldOfficerUserId IS NULL OR s.FieldOfficerUserId = @FieldOfficerUserId
    ORDER BY s.Id DESC;
END
GO

IF OBJECT_ID(N'dbo.sp_Shopkeeper_GetByPhone', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Shopkeeper_GetByPhone;
GO

CREATE PROCEDURE dbo.sp_Shopkeeper_GetByPhone
    @Phone NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
        s.Id,
        s.ShopName,
        s.OwnerName,
        s.Phone,
        s.NidNumber,
        s.ProfilePhotoPath,
        s.BillboardPhotoPath,
        s.DivisionId,
        dv.Name AS DivisionName,
        s.DistrictId,
        ds.Name AS DistrictName,
        s.ThanaId,
        th.Name AS ThanaName,
        s.Address,
        s.Latitude,
        s.Longitude,
        s.Area,
        s.ShopType,
        u.PasswordHash AS [Password],
        s.ShopCode,
        s.FieldOfficerUserId,
        fo.Name AS FieldOfficerName,
        fo.Phone AS FieldOfficerPhone,
        s.RegisteredAt
    FROM dbo.tbl_Shopkeepers AS s
    INNER JOIN dbo.tbl_Users AS u ON u.Id = s.UserId
    INNER JOIN dbo.tbl_Users AS fo ON fo.Id = s.FieldOfficerUserId
    INNER JOIN dbo.tbl_Divisions AS dv ON dv.Id = s.DivisionId
    INNER JOIN dbo.tbl_Districts AS ds ON ds.Id = s.DistrictId
    INNER JOIN dbo.tbl_Thanas AS th ON th.Id = s.ThanaId
    WHERE s.Phone = @Phone;
END
GO

IF OBJECT_ID(N'dbo.sp_FieldOfficer_ListByAgent', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_FieldOfficer_ListByAgent;
GO

CREATE PROCEDURE dbo.sp_FieldOfficer_ListByAgent
    @AgentUserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Name,
        Phone,
        PasswordHash AS [Password],
        Role,
        ShopCode,
        ParentUserId,
        CreatedAt,
        ProfilePictureUrl
    FROM dbo.tbl_Users
    WHERE Role = N'FieldOfficer'
      AND ParentUserId = @AgentUserId
      AND IsActive = 1
    ORDER BY Id DESC;
END
GO

CREATE PROCEDURE dbo.sp_Product_ListByShop
    @ShopkeeperId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Name,
        Sku,
        Category,
        UnitPrice,
        StockQuantity,
        CommissionPercentage
    FROM dbo.tbl_Products
    WHERE ShopkeeperId = @ShopkeeperId
      AND IsActive = 1
    ORDER BY Name;
END
GO

IF OBJECT_ID(N'dbo.sp_Product_Add', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Product_Add;
GO

CREATE PROCEDURE dbo.sp_Product_Add
    @ShopkeeperId INT,
    @Name NVARCHAR(150),
    @Sku NVARCHAR(50),
    @Category NVARCHAR(100),
    @UnitPrice DECIMAL(10, 2),
    @StockQuantity INT,
    @CommissionPercentage DECIMAL(5, 2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (SELECT 1 FROM dbo.tbl_Products WHERE ShopkeeperId = @ShopkeeperId AND Sku = @Sku)
    BEGIN
        THROW 51010, N'এই SKU কোডটি ইতিমধ্যে বিদ্যমান।', 1;
    END

    INSERT INTO dbo.tbl_Products (ShopkeeperId, Name, Sku, Category, UnitPrice, StockQuantity, CommissionPercentage)
    VALUES (@ShopkeeperId, @Name, @Sku, @Category, @UnitPrice, @StockQuantity, @CommissionPercentage);
END
GO

CREATE PROCEDURE dbo.sp_CustomerProduct_List
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Name,
        Sku,
        Category,
        UnitPrice
    FROM dbo.tbl_CustomerOrderProducts
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

CREATE PROCEDURE dbo.sp_CustomerOrder_Create
    @CustomerUserId INT,
    @CustomerName NVARCHAR(150),
    @CustomerPhone NVARCHAR(20),
    @ShopkeeperId INT,
    @CustomerLatitude DECIMAL(9,6) = NULL,
    @CustomerLongitude DECIMAL(9,6) = NULL,
    @Remarks NVARCHAR(500) = NULL,
    @Items dbo.CustomerOrderDetailInput READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Id = @CustomerUserId AND Role = N'Customer' AND IsActive = 1)
    BEGIN
        THROW 51020, N'Invalid customer.', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Shopkeepers WHERE Id = @ShopkeeperId)
    BEGIN
        THROW 51021, N'Invalid shopkeeper.', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM @Items)
    BEGIN
        THROW 51022, N'At least one product is required.', 1;
    END

    IF EXISTS (
        SELECT 1
        FROM @Items AS i
        LEFT JOIN dbo.tbl_CustomerOrderProducts AS p ON p.Id = i.ProductId AND p.IsActive = 1
        WHERE p.Id IS NULL OR i.Quantity <= 0
    )
    BEGIN
        THROW 51023, N'Valid product selection is required.', 1;
    END

    DECLARE @OrderId INT;
    DECLARE @TotalAmount DECIMAL(18,2);
    DECLARE @DiscountAmount DECIMAL(18,2);

    SELECT @TotalAmount = SUM(i.Quantity * p.UnitPrice)
    FROM @Items AS i
    INNER JOIN dbo.tbl_CustomerOrderProducts AS p ON p.Id = i.ProductId;

    SET @DiscountAmount = CASE WHEN @TotalAmount >= 1000 THEN ROUND(@TotalAmount * 0.03, 2) ELSE 0 END;

    BEGIN TRANSACTION;

    INSERT INTO dbo.tbl_CustomerOrders
        (CustomerUserId, CustomerName, CustomerPhone, ShopkeeperId, CustomerLatitude, CustomerLongitude, TotalAmount, DiscountAmount, Status, Remarks)
    VALUES
        (@CustomerUserId, @CustomerName, @CustomerPhone, @ShopkeeperId, @CustomerLatitude, @CustomerLongitude, @TotalAmount, @DiscountAmount, N'Pending', @Remarks);

    SET @OrderId = SCOPE_IDENTITY();

    INSERT INTO dbo.tbl_CustomerOrderDetails
        (OrderMasterId, ProductId, ProductName, Sku, Quantity, UnitPrice)
    SELECT
        @OrderId,
        p.Id,
        p.Name,
        p.Sku,
        i.Quantity,
        p.UnitPrice
    FROM @Items AS i
    INNER JOIN dbo.tbl_CustomerOrderProducts AS p ON p.Id = i.ProductId;

    COMMIT TRANSACTION;

    EXEC dbo.sp_CustomerOrder_ListByCustomer @CustomerUserId = @CustomerUserId, @OrderId = @OrderId;
END
GO

CREATE PROCEDURE dbo.sp_CustomerOrder_ListByCustomer
    @CustomerUserId INT,
    @OrderId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.Id,
        o.CustomerUserId AS CustomerId,
        o.CustomerName,
        o.CustomerPhone,
        o.ShopkeeperId,
        s.ShopName AS ShopkeeperName,
        o.OrderDate,
        o.TotalAmount,
        o.DiscountAmount,
        o.Status,
        o.Remarks
    FROM dbo.tbl_CustomerOrders AS o
    INNER JOIN dbo.tbl_Shopkeepers AS s ON s.Id = o.ShopkeeperId
    WHERE o.CustomerUserId = @CustomerUserId
      AND (@OrderId IS NULL OR o.Id = @OrderId)
    ORDER BY o.OrderDate DESC, o.Id DESC;

    SELECT
        d.Id,
        d.OrderMasterId,
        d.ProductId,
        d.ProductName,
        d.Sku,
        d.Quantity,
        d.UnitPrice
    FROM dbo.tbl_CustomerOrderDetails AS d
    INNER JOIN dbo.tbl_CustomerOrders AS o ON o.Id = d.OrderMasterId
    WHERE o.CustomerUserId = @CustomerUserId
      AND (@OrderId IS NULL OR o.Id = @OrderId)
    ORDER BY d.Id;
END
GO

CREATE PROCEDURE dbo.sp_CustomerOrder_ListByShopkeeper
    @ShopkeeperId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.Id,
        o.CustomerUserId AS CustomerId,
        o.CustomerName,
        o.CustomerPhone,
        o.ShopkeeperId,
        s.ShopName AS ShopkeeperName,
        o.OrderDate,
        o.TotalAmount,
        o.DiscountAmount,
        o.Status,
        o.Remarks
    FROM dbo.tbl_CustomerOrders AS o
    INNER JOIN dbo.tbl_Shopkeepers AS s ON s.Id = o.ShopkeeperId
    WHERE o.ShopkeeperId = @ShopkeeperId
    ORDER BY CASE WHEN o.Status = N'Pending' THEN 0 ELSE 1 END, o.OrderDate DESC, o.Id DESC;

    SELECT
        d.Id,
        d.OrderMasterId,
        d.ProductId,
        d.ProductName,
        d.Sku,
        d.Quantity,
        d.UnitPrice
    FROM dbo.tbl_CustomerOrderDetails AS d
    INNER JOIN dbo.tbl_CustomerOrders AS o ON o.Id = d.OrderMasterId
    WHERE o.ShopkeeperId = @ShopkeeperId
    ORDER BY d.Id;
END
GO

CREATE PROCEDURE dbo.sp_CustomerOrder_UpdateStatus
    @ShopkeeperId INT,
    @OrderId INT,
    @Status NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Status NOT IN (N'Approved', N'Delivered', N'Rejected')
    BEGIN
        THROW 51024, N'Invalid order status.', 1;
    END

    UPDATE dbo.tbl_CustomerOrders
    SET Status = @Status
    WHERE Id = @OrderId
      AND ShopkeeperId = @ShopkeeperId
      AND (
          (Status = N'Pending' AND @Status IN (N'Approved', N'Rejected'))
          OR (Status = N'Approved' AND @Status = N'Delivered')
      );

    IF @@ROWCOUNT = 0
    BEGIN
        THROW 51025, N'Order was not found or its status cannot be changed.', 1;
    END
END
GO

CREATE PROCEDURE dbo.sp_Sale_Create
    @ShopkeeperId INT,
    @CustomerName NVARCHAR(150),
    @CustomerPhone NVARCHAR(20),
    @PaymentMethod NVARCHAR(30),
    @Items dbo.SaleDetailInput READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Shopkeepers WHERE Id = @ShopkeeperId)
    BEGIN
        THROW 51010, N'Invalid shopkeeper.', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM @Items)
    BEGIN
        THROW 51011, N'At least one product is required.', 1;
    END

    IF EXISTS (
        SELECT 1
        FROM @Items AS i
        LEFT JOIN dbo.tbl_Products AS p ON p.Id = i.ProductId AND p.ShopkeeperId = @ShopkeeperId AND p.IsActive = 1
        WHERE p.Id IS NULL OR i.Quantity <= 0 OR i.UnitPrice <= 0
    )
    BEGIN
        THROW 51012, N'Invalid product details.', 1;
    END

    IF EXISTS (
        SELECT 1
        FROM @Items AS i
        INNER JOIN dbo.tbl_Products AS p ON p.Id = i.ProductId
        WHERE p.StockQuantity < i.Quantity
    )
    BEGIN
        THROW 51013, N'Product stock is not available.', 1;
    END

    DECLARE @CustomerId INT;
    DECLARE @SaleId INT;
    DECLARE @GrossAmount DECIMAL(18,2);
    DECLARE @CashbackAmount DECIMAL(18,2);
    DECLARE @SystemCommission DECIMAL(18,2);

    SELECT @GrossAmount = SUM(Quantity * UnitPrice)
    FROM @Items;

    SET @CashbackAmount = ROUND(@GrossAmount * 0.02, 2);
    
    SELECT @SystemCommission = ISNULL(SUM(ROUND(i.Quantity * i.UnitPrice * (p.CommissionPercentage / 100.0), 2)), 0)
    FROM @Items AS i
    INNER JOIN dbo.tbl_Products AS p ON p.Id = i.ProductId;

    DECLARE @CurrentWalletBalance DECIMAL(18,2) = 0;
    SELECT @CurrentWalletBalance = Balance FROM dbo.tbl_ShopkeeperWallets WHERE ShopkeeperId = @ShopkeeperId;

    IF @CurrentWalletBalance < @SystemCommission
    BEGIN
        THROW 51014, N'Insufficient wallet balance. Please add funds via SSL Commerz.', 1;
    END

    BEGIN TRANSACTION;

    SELECT @CustomerId = Id
    FROM dbo.tbl_Customers
    WHERE Phone = @CustomerPhone;

    IF @CustomerId IS NULL
    BEGIN
        INSERT INTO dbo.tbl_Customers (Name, Phone)
        VALUES (@CustomerName, @CustomerPhone);

        SET @CustomerId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.tbl_Customers
        SET Name = @CustomerName
        WHERE Id = @CustomerId;
    END

    DECLARE @PaidAmount DECIMAL(18,2) = CASE WHEN @PaymentMethod = N'বকেয়া' THEN 0 ELSE @GrossAmount END;

    INSERT INTO dbo.tbl_Sales
        (InvoiceNo, ShopkeeperId, CustomerId, PaymentMethod, GrossAmount, CashbackAmount, SystemCommission, Status, PaidAmount)
    VALUES
        (N'TEMP', @ShopkeeperId, @CustomerId, @PaymentMethod, @GrossAmount, @CashbackAmount, @SystemCommission, N'Paid', @PaidAmount);

    SET @SaleId = SCOPE_IDENTITY();

    UPDATE dbo.tbl_Sales
    SET InvoiceNo = CONCAT(N'INV', FORMAT(@SaleId + 100000, N'000000'))
    WHERE Id = @SaleId;

    INSERT INTO dbo.tbl_SaleDetails (SaleId, ProductId, Quantity, UnitPrice)
    SELECT @SaleId, ProductId, Quantity, UnitPrice
    FROM @Items;

    UPDATE p
    SET p.StockQuantity = p.StockQuantity - i.Quantity
    FROM dbo.tbl_Products AS p
    INNER JOIN @Items AS i ON i.ProductId = p.Id;

    MERGE dbo.tbl_ShopkeeperWallets AS target
    USING (SELECT @ShopkeeperId AS ShopkeeperId) AS source
        ON target.ShopkeeperId = source.ShopkeeperId
    WHEN MATCHED THEN
        UPDATE SET
            Balance = Balance - @SystemCommission,
            PendingBalance = PendingBalance - @SystemCommission,
            UpdatedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (ShopkeeperId, Balance, PendingBalance)
        VALUES (@ShopkeeperId, -@SystemCommission, -@SystemCommission);

    INSERT INTO dbo.tbl_ShopkeeperWalletDeductionLogs (ShopkeeperId, SaleId, ProductId, AmountDeducted)
    SELECT @ShopkeeperId, @SaleId, i.ProductId, ROUND(i.Quantity * i.UnitPrice * (p.CommissionPercentage / 100.0), 2)
    FROM @Items AS i
    INNER JOIN dbo.tbl_Products AS p ON p.Id = i.ProductId;

    COMMIT TRANSACTION;

    SELECT
        s.Id,
        s.InvoiceNo,
        c.Name AS CustomerName,
        c.Phone AS CustomerPhone,
        s.PaymentMethod,
        s.GrossAmount,
        s.CashbackAmount,
        s.SystemCommission,
        s.Status,
        s.SoldAt
    FROM dbo.tbl_Sales AS s
    INNER JOIN dbo.tbl_Customers AS c ON c.Id = s.CustomerId
    WHERE s.Id = @SaleId;

    SELECT
        d.ProductId,
        p.Name AS ProductName,
        d.Quantity,
        d.UnitPrice,
        d.LineTotal
    FROM dbo.tbl_SaleDetails AS d
    INNER JOIN dbo.tbl_Products AS p ON p.Id = d.ProductId
    WHERE d.SaleId = @SaleId;
END
GO

CREATE PROCEDURE dbo.sp_CompanyDashboard_Get
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Today DATE = CONVERT(DATE, SYSUTCDATETIME());
    DECLARE @MonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);

    SELECT
        TotalAgents = CONVERT(INT, COALESCE(SUM(CASE WHEN u.Role = N'Agent' THEN 1 ELSE 0 END), 0)),
        TotalFieldOfficers = CONVERT(INT, COALESCE(SUM(CASE WHEN u.Role = N'FieldOfficer' THEN 1 ELSE 0 END), 0)),
        TotalShopkeepers = (SELECT COUNT(1) FROM dbo.tbl_Shopkeepers),
        TotalCustomers = (
            SELECT COUNT(1)
            FROM (
                SELECT Phone FROM dbo.tbl_Customers WHERE IsActive = 1
                UNION
                SELECT Phone FROM dbo.tbl_Users WHERE Role = N'Customer' AND IsActive = 1
            ) AS customers
        ),
        TotalCustomerOrders = (SELECT COUNT(1) FROM dbo.tbl_CustomerOrders),
        PendingCustomerOrders = (SELECT COUNT(1) FROM dbo.tbl_CustomerOrders WHERE Status = N'Pending'),
        DeliveredCustomerOrders = (SELECT COUNT(1) FROM dbo.tbl_CustomerOrders WHERE Status = N'Delivered'),
        TotalSalesAmount = COALESCE((SELECT SUM(GrossAmount) FROM dbo.tbl_Sales), 0),
        TodaySalesAmount = COALESCE((SELECT SUM(GrossAmount) FROM dbo.tbl_Sales WHERE CONVERT(DATE, SoldAt) = @Today), 0),
        MonthSalesAmount = COALESCE((SELECT SUM(GrossAmount) FROM dbo.tbl_Sales WHERE SoldAt >= @MonthStart), 0),
        TotalCashbackAmount = COALESCE((SELECT SUM(CashbackAmount) FROM dbo.tbl_Sales), 0),
        TotalSystemCommission = COALESCE((SELECT SUM(SystemCommission) FROM dbo.tbl_Sales), 0),
        WalletBalance = COALESCE((SELECT SUM(Balance) FROM dbo.tbl_ShopkeeperWallets), 0),
        WalletWithdrawable = COALESCE((SELECT SUM(WithdrawableBalance) FROM dbo.tbl_ShopkeeperWallets), 0),
        WalletPending = COALESCE((SELECT SUM(PendingBalance) FROM dbo.tbl_ShopkeeperWallets), 0)
    FROM dbo.tbl_Users AS u
    WHERE u.IsActive = 1;

    SELECT TOP (8)
        s.Id,
        s.ShopName,
        s.OwnerName,
        s.Phone,
        s.ShopCode,
        ds.Name AS DistrictName,
        th.Name AS ThanaName,
        fo.Name AS FieldOfficerName,
        s.RegisteredAt
    FROM dbo.tbl_Shopkeepers AS s
    INNER JOIN dbo.tbl_Districts AS ds ON ds.Id = s.DistrictId
    INNER JOIN dbo.tbl_Thanas AS th ON th.Id = s.ThanaId
    INNER JOIN dbo.tbl_Users AS fo ON fo.Id = s.FieldOfficerUserId
    ORDER BY s.RegisteredAt DESC, s.Id DESC;

    SELECT TOP (8)
        sale.Id,
        sale.InvoiceNo,
        shop.ShopName,
        customer.Name AS CustomerName,
        customer.Phone AS CustomerPhone,
        sale.GrossAmount,
        sale.CashbackAmount,
        sale.SystemCommission,
        sale.Status,
        sale.SoldAt
    FROM dbo.tbl_Sales AS sale
    INNER JOIN dbo.tbl_Shopkeepers AS shop ON shop.Id = sale.ShopkeeperId
    INNER JOIN dbo.tbl_Customers AS customer ON customer.Id = sale.CustomerId
    ORDER BY sale.SoldAt DESC, sale.Id DESC;

    SELECT TOP (8)
        ds.Name AS DistrictName,
        COUNT(DISTINCT shop.Id) AS ShopkeeperCount,
        COUNT(DISTINCT sale.CustomerId) AS CustomerCount,
        COALESCE(SUM(sale.GrossAmount), 0) AS SalesAmount
    FROM dbo.tbl_Districts AS ds
    LEFT JOIN dbo.tbl_Shopkeepers AS shop ON shop.DistrictId = ds.Id
    LEFT JOIN dbo.tbl_Sales AS sale ON sale.ShopkeeperId = shop.Id
    WHERE ds.IsActive = 1
    GROUP BY ds.Id, ds.Name
    ORDER BY SalesAmount DESC, ShopkeeperCount DESC, ds.Name;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = N'01700000002')
BEGIN
    INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role)
    VALUES (N'Agent Demo', N'01700000002', N'1234', N'Agent');
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = N'01700000000')
BEGIN
    INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, ParentUserId)
    SELECT N'Field Officer', N'01700000000', N'1234', N'FieldOfficer', Id
    FROM dbo.tbl_Users
    WHERE Phone = N'01700000002';
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = N'01700000001')
BEGIN
    INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role)
    VALUES (N'SmartBazar Company', N'01700000001', N'1234', N'Company');
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = N'01700000003')
BEGIN
    INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role)
    VALUES (N'Customer Demo', N'01700000003', N'1234', N'Customer');
END
GO
A L T E R   P R O C E D U R E   d b o . s p _ S a l e _ C r e a t e  
         @ S h o p k e e p e r I d   I N T ,  
         @ C u s t o m e r N a m e   N V A R C H A R ( 1 5 0 ) ,  
         @ C u s t o m e r P h o n e   N V A R C H A R ( 2 0 ) ,  
         @ P a y m e n t M e t h o d   N V A R C H A R ( 3 0 ) ,  
         @ I t e m s   d b o . S a l e D e t a i l I n p u t   R E A D O N L Y  
 A S  
 B E G I N  
         S E T   N O C O U N T   O N ;  
         S E T   X A C T _ A B O R T   O N ;  
  
         I F   N O T   E X I S T S   ( S E L E C T   1   F R O M   d b o . t b l _ S h o p k e e p e r s   W H E R E   I d   =   @ S h o p k e e p e r I d )  
         B E G I N  
                 T H R O W   5 1 0 1 0 ,   N ' I n v a l i d   s h o p k e e p e r . ' ,   1 ;  
         E N D  
  
         I F   N O T   E X I S T S   ( S E L E C T   1   F R O M   @ I t e m s )  
         B E G I N  
                 T H R O W   5 1 0 1 1 ,   N ' A t   l e a s t   o n e   p r o d u c t   i s   r e q u i r e d . ' ,   1 ;  
         E N D  
  
         I F   E X I S T S   (  
                 S E L E C T   1  
                 F R O M   @ I t e m s   A S   i  
                 L E F T   J O I N   d b o . t b l _ P r o d u c t s   A S   p   O N   p . I d   =   i . P r o d u c t I d   A N D   p . S h o p k e e p e r I d   =   @ S h o p k e e p e r I d   A N D   p . I s A c t i v e   =   1  
                 W H E R E   p . I d   I S   N U L L   O R   i . Q u a n t i t y   < =   0   O R   i . U n i t P r i c e   < =   0  
         )  
         B E G I N  
                 T H R O W   5 1 0 1 2 ,   N ' I n v a l i d   p r o d u c t   d e t a i l s . ' ,   1 ;  
         E N D  
  
         I F   E X I S T S   (  
                 S E L E C T   1  
                 F R O M   @ I t e m s   A S   i  
                 I N N E R   J O I N   d b o . t b l _ P r o d u c t s   A S   p   O N   p . I d   =   i . P r o d u c t I d  
                 W H E R E   p . S t o c k Q u a n t i t y   <   i . Q u a n t i t y  
         )  
         B E G I N  
                 T H R O W   5 1 0 1 3 ,   N ' P r o d u c t   s t o c k   i s   n o t   a v a i l a b l e . ' ,   1 ;  
         E N D  
  
         D E C L A R E   @ C u s t o m e r I d   I N T ;  
         D E C L A R E   @ S a l e I d   I N T ;  
         D E C L A R E   @ G r o s s A m o u n t   D E C I M A L ( 1 8 , 2 ) ;  
         D E C L A R E   @ C a s h b a c k A m o u n t   D E C I M A L ( 1 8 , 2 ) ;  
         D E C L A R E   @ S y s t e m C o m m i s s i o n   D E C I M A L ( 1 8 , 2 ) ;  
  
         S E L E C T   @ G r o s s A m o u n t   =   S U M ( Q u a n t i t y   *   U n i t P r i c e )  
         F R O M   @ I t e m s ;  
  
         S E T   @ C a s h b a c k A m o u n t   =   R O U N D ( @ G r o s s A m o u n t   *   0 . 0 2 ,   2 ) ;  
          
         S E L E C T   @ S y s t e m C o m m i s s i o n   =   I S N U L L ( S U M ( R O U N D ( i . Q u a n t i t y   *   i . U n i t P r i c e   *   ( p . C o m m i s s i o n P e r c e n t a g e   /   1 0 0 . 0 ) ,   2 ) ) ,   0 )  
         F R O M   @ I t e m s   A S   i  
         I N N E R   J O I N   d b o . t b l _ P r o d u c t s   A S   p   O N   p . I d   =   i . P r o d u c t I d ;  
  
         D E C L A R E   @ C u r r e n t W a l l e t B a l a n c e   D E C I M A L ( 1 8 , 2 )   =   0 ;  
         S E L E C T   @ C u r r e n t W a l l e t B a l a n c e   =   B a l a n c e   F R O M   d b o . t b l _ S h o p k e e p e r W a l l e t s   W H E R E   S h o p k e e p e r I d   =   @ S h o p k e e p e r I d ;  
  
         I F   @ C u r r e n t W a l l e t B a l a n c e   <   @ S y s t e m C o m m i s s i o n  
         B E G I N  
                 T H R O W   5 1 0 1 4 ,   N ' I n s u f f i c i e n t   w a l l e t   b a l a n c e .   P l e a s e   a d d   f u n d s   v i a   S S L   C o m m e r z . ' ,   1 ;  
         E N D  
  
         B E G I N   T R A N S A C T I O N ;  
  
         S E L E C T   @ C u s t o m e r I d   =   I d  
         F R O M   d b o . t b l _ C u s t o m e r s  
         W H E R E   P h o n e   =   @ C u s t o m e r P h o n e ;  
  
         I F   @ C u s t o m e r I d   I S   N U L L  
         B E G I N  
                 I N S E R T   I N T O   d b o . t b l _ C u s t o m e r s   ( N a m e ,   P h o n e )  
                 V A L U E S   ( @ C u s t o m e r N a m e ,   @ C u s t o m e r P h o n e ) ;  
  
                 S E T   @ C u s t o m e r I d   =   S C O P E _ I D E N T I T Y ( ) ;  
         E N D  
  
         I N S E R T   I N T O   d b o . t b l _ S a l e s  
                 ( I n v o i c e N o ,   S h o p k e e p e r I d ,   C u s t o m e r I d ,   P a y m e n t M e t h o d ,   G r o s s A m o u n t ,   C a s h b a c k A m o u n t ,   S y s t e m C o m m i s s i o n ,   S t a t u s )  
         V A L U E S  
                 ( N ' T E M P ' ,   @ S h o p k e e p e r I d ,   @ C u s t o m e r I d ,   @ P a y m e n t M e t h o d ,   @ G r o s s A m o u n t ,   @ C a s h b a c k A m o u n t ,   @ S y s t e m C o m m i s s i o n ,   N ' P a i d ' ) ;  
  
         S E T   @ S a l e I d   =   S C O P E _ I D E N T I T Y ( ) ;  
  
         U P D A T E   d b o . t b l _ S a l e s  
         S E T   I n v o i c e N o   =   C O N C A T ( N ' I N V ' ,   F O R M A T ( @ S a l e I d   +   1 0 0 0 0 0 ,   N ' 0 0 0 0 0 0 ' ) )  
         W H E R E   I d   =   @ S a l e I d ;  
  
         I N S E R T   I N T O   d b o . t b l _ S a l e D e t a i l s   ( S a l e I d ,   P r o d u c t I d ,   Q u a n t i t y ,   U n i t P r i c e )  
         S E L E C T   @ S a l e I d ,   P r o d u c t I d ,   Q u a n t i t y ,   U n i t P r i c e  
         F R O M   @ I t e m s ;  
  
         U P D A T E   p  
         S E T   p . S t o c k Q u a n t i t y   =   p . S t o c k Q u a n t i t y   -   i . Q u a n t i t y  
         F R O M   d b o . t b l _ P r o d u c t s   A S   p  
         I N N E R   J O I N   @ I t e m s   A S   i   O N   i . P r o d u c t I d   =   p . I d  
         W H E R E   p . S h o p k e e p e r I d   =   @ S h o p k e e p e r I d ;  
          
         - -   I M P O R T A N T :   F i x   f o r   R e q u i r e m e n t   7   &   8 :   A c t u a l l y   d e d u c t   t h e   c o m m i s s i o n   f r o m   t h e   w a l l e t  
         I F   @ S y s t e m C o m m i s s i o n   >   0  
         B E G I N  
                 U P D A T E   d b o . t b l _ S h o p k e e p e r W a l l e t s  
                 S E T   B a l a n c e   =   B a l a n c e   -   @ S y s t e m C o m m i s s i o n ,  
                         U p d a t e d A t   =   S Y S U T C D A T E T I M E ( )  
                 W H E R E   S h o p k e e p e r I d   =   @ S h o p k e e p e r I d ;  
                  
                 - -   A n d   i n s e r t   l o g   i f   p o s s i b l e ,   o r   j u s t   s k i p   l o g   i f   t a b l e   i s n ' t   e a s i l y   m a p p e d .   W e   h a v e   t b l _ S h o p k e e p e r W a l l e t D e d u c t i o n L o g s  
                 - -   b u t   i t   r e q u i r e s   P r o d u c t I d   w h i c h   w e   h a v e   m u l t i p l e .   L e t ' s   i n s e r t   p e r   p r o d u c t .  
                 I N S E R T   I N T O   d b o . t b l _ S h o p k e e p e r W a l l e t D e d u c t i o n L o g s   ( S h o p k e e p e r I d ,   S a l e I d ,   P r o d u c t I d ,   A m o u n t D e d u c t e d )  
                 S E L E C T   @ S h o p k e e p e r I d ,   @ S a l e I d ,   i . P r o d u c t I d ,   R O U N D ( i . Q u a n t i t y   *   i . U n i t P r i c e   *   ( p . C o m m i s s i o n P e r c e n t a g e   /   1 0 0 . 0 ) ,   2 )  
                 F R O M   @ I t e m s   A S   i  
                 I N N E R   J O I N   d b o . t b l _ P r o d u c t s   A S   p   O N   p . I d   =   i . P r o d u c t I d ;  
         E N D  
  
         C O M M I T   T R A N S A C T I O N ;  
  
         S E L E C T  
                 s . I d ,  
                 s . I n v o i c e N o ,  
                 s . S h o p k e e p e r I d ,  
                 s h . S h o p N a m e ,  
                 s . C u s t o m e r I d ,  
                 c . N a m e   A S   C u s t o m e r N a m e ,  
                 c . P h o n e   A S   C u s t o m e r P h o n e ,  
                 s . P a y m e n t M e t h o d ,  
                 s . G r o s s A m o u n t ,  
                 s . C a s h b a c k A m o u n t ,  
                 s . S y s t e m C o m m i s s i o n ,  
                 s . S t a t u s ,  
                 s . S o l d A t  
         F R O M   d b o . t b l _ S a l e s   A S   s  
         I N N E R   J O I N   d b o . t b l _ S h o p k e e p e r s   A S   s h   O N   s h . I d   =   s . S h o p k e e p e r I d  
         I N N E R   J O I N   d b o . t b l _ C u s t o m e r s   A S   c   O N   c . I d   =   s . C u s t o m e r I d  
         W H E R E   s . I d   =   @ S a l e I d ;  
 E N D  
 G O  
  
 I F   O B J E C T _ I D ( N ' d b o . s p _ L e a d e r b o a r d _ G e t T o p 5 0 ' ,   N ' P ' )   I S   N O T   N U L L  
         D R O P   P R O C E D U R E   d b o . s p _ L e a d e r b o a r d _ G e t T o p 5 0 ;  
 G O  
  
 C R E A T E   P R O C E D U R E   d b o . s p _ L e a d e r b o a r d _ G e t T o p 5 0  
         @ D i s t r i c t I d   I N T  
 A S  
 B E G I N  
         S E T   N O C O U N T   O N ;  
  
         - -   T o p   5 0   C u s t o m e r s   i n   t h i s   D i s t r i c t   ( B a s e d   o n   T o t a l A m o u n t   f r o m   t b l _ C u s t o m e r O r d e r s )  
         S E L E C T   T O P   5 0  
                 c . I d   A S   C u s t o m e r I d ,  
                 c . N a m e   A S   C u s t o m e r N a m e ,  
                 I S N U L L ( S U M ( o . T o t a l A m o u n t ) ,   0 )   A S   T o t a l A m o u n t  
         F R O M   d b o . t b l _ C u s t o m e r s   c  
         I N N E R   J O I N   d b o . t b l _ C u s t o m e r O r d e r s   o   O N   c . I d   =   o . C u s t o m e r U s e r I d  
         I N N E R   J O I N   d b o . t b l _ S h o p k e e p e r s   s   O N   o . S h o p k e e p e r I d   =   s . I d  
         W H E R E   s . D i s t r i c t I d   =   @ D i s t r i c t I d   A N D   o . S t a t u s   I N   ( N ' D e l i v e r e d ' ,   N ' C o m p l e t e d ' ,   N ' A p p r o v e d ' )  
         G R O U P   B Y   c . I d ,   c . N a m e  
         O R D E R   B Y   T o t a l A m o u n t   D E S C ;  
  
         - -   T o p   5 0   S h o p k e e p e r s   i n   t h i s   D i s t r i c t   ( B a s e d   o n   G r o s s A m o u n t   f r o m   t b l _ S a l e s )  
         S E L E C T   T O P   5 0  
                 s h . I d   A S   S h o p k e e p e r I d ,  
                 s h . S h o p N a m e   A S   S h o p N a m e ,  
                 s h . O w n e r N a m e   A S   O w n e r N a m e ,  
                 I S N U L L ( S U M ( s . G r o s s A m o u n t ) ,   0 )   A S   T o t a l S a l e s  
         F R O M   d b o . t b l _ S h o p k e e p e r s   s h  
         I N N E R   J O I N   d b o . t b l _ S a l e s   s   O N   s h . I d   =   s . S h o p k e e p e r I d  
         W H E R E   s h . D i s t r i c t I d   =   @ D i s t r i c t I d   A N D   s . S t a t u s   =   N ' P a i d '  
         G R O U P   B Y   s h . I d ,   s h . S h o p N a m e ,   s h . O w n e r N a m e  
         O R D E R   B Y   T o t a l S a l e s   D E S C ;  
 E N D  
 G O  
 