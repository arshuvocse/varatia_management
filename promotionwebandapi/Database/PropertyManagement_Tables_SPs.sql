-- Use the correct database (change if needed)
-- USE VaratiaManagementDb;

-- 1. Table: Properties
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Properties')
BEGIN
    CREATE TABLE Properties (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        OwnerUserId UNIQUEIDENTIFIER NOT NULL, -- References Users(Id)
        Name NVARCHAR(255) NOT NULL,
        Address NVARCHAR(500) NULL,
        TotalFloors INT DEFAULT 1,
        TotalUnits INT DEFAULT 1,
        CreatedAt DATETIME2 DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2 DEFAULT SYSUTCDATETIME()
    );
END

-- 2. Table: PropertyUnits
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PropertyUnits')
BEGIN
    CREATE TABLE PropertyUnits (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PropertyId INT NOT NULL FOREIGN KEY REFERENCES Properties(Id) ON DELETE CASCADE,
        UnitName NVARCHAR(100) NOT NULL,
        FloorNumber INT DEFAULT 1,
        RentAmount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
        Status NVARCHAR(50) NOT NULL DEFAULT 'Vacant', -- Vacant, Occupied, Maintenance
        Bedrooms INT DEFAULT 1,
        Bathrooms INT DEFAULT 1,
        CreatedAt DATETIME2 DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2 DEFAULT SYSUTCDATETIME()
    );
END
GO

-- 3. Stored Procedure: sp_AddProperty
CREATE OR ALTER PROCEDURE sp_AddProperty
    @OwnerUserId UNIQUEIDENTIFIER,
    @Name NVARCHAR(255),
    @Address NVARCHAR(500),
    @TotalFloors INT,
    @TotalUnits INT,
    @NewPropertyId INT OUTPUT
AS
BEGIN
    INSERT INTO Properties (OwnerUserId, Name, Address, TotalFloors, TotalUnits, CreatedAt, UpdatedAt)
    VALUES (@OwnerUserId, @Name, @Address, @TotalFloors, @TotalUnits, SYSUTCDATETIME(), SYSUTCDATETIME());

    SET @NewPropertyId = SCOPE_IDENTITY();
END
GO

-- 4. Stored Procedure: sp_GetPropertiesByOwner
CREATE OR ALTER PROCEDURE sp_GetPropertiesByOwner
    @OwnerUserId UNIQUEIDENTIFIER
AS
BEGIN
    SELECT 
        Id,
        OwnerUserId,
        Name,
        Address,
        TotalFloors,
        TotalUnits,
        CreatedAt,
        UpdatedAt
    FROM Properties
    WHERE OwnerUserId = @OwnerUserId
    ORDER BY CreatedAt DESC;
END
GO

-- 5. Stored Procedure: sp_AddPropertyUnit
CREATE OR ALTER PROCEDURE sp_AddPropertyUnit
    @PropertyId INT,
    @UnitName NVARCHAR(100),
    @FloorNumber INT,
    @RentAmount DECIMAL(18,2),
    @Status NVARCHAR(50),
    @Bedrooms INT,
    @Bathrooms INT,
    @NewUnitId INT OUTPUT
AS
BEGIN
    INSERT INTO PropertyUnits (PropertyId, UnitName, FloorNumber, RentAmount, Status, Bedrooms, Bathrooms, CreatedAt, UpdatedAt)
    VALUES (@PropertyId, @UnitName, @FloorNumber, @RentAmount, @Status, @Bedrooms, @Bathrooms, SYSUTCDATETIME(), SYSUTCDATETIME());

    SET @NewUnitId = SCOPE_IDENTITY();
END
GO

-- 6. Stored Procedure: sp_GetUnitsByPropertyId
CREATE OR ALTER PROCEDURE sp_GetUnitsByPropertyId
    @PropertyId INT
AS
BEGIN
    SELECT 
        Id,
        PropertyId,
        UnitName,
        FloorNumber,
        RentAmount,
        Status,
        Bedrooms,
        Bathrooms,
        CreatedAt,
        UpdatedAt
    FROM PropertyUnits
    WHERE PropertyId = @PropertyId
    ORDER BY FloorNumber ASC, UnitName ASC;
END
GO

-- 7. Stored Procedure: sp_UpdateUnitStatus
CREATE OR ALTER PROCEDURE sp_UpdateUnitStatus
    @UnitId INT,
    @Status NVARCHAR(50)
AS
BEGIN
    UPDATE PropertyUnits
    SET Status = @Status,
        UpdatedAt = SYSUTCDATETIME()
    WHERE Id = @UnitId;
END
GO
