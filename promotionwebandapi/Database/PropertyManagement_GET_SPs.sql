USE SmartBazarDbmssql;
GO

-- 1. sp_GetBuildingsByOwner
CREATE OR ALTER PROCEDURE sp_GetBuildingsByOwner
    @UserId NVARCHAR(255)
AS
BEGIN
    SELECT 
        Id,
        UserId,
        Name,
        TotalFloors,
        Location,
        Address,
        Latitude,
        Longitude,
        ZoneId,
        StationId,
        WardId
    FROM dbo.Buildings
    WHERE UserId = @UserId
    ORDER BY Id ASC;
END
GO

-- 2. sp_GetFloorsByBuildingId
CREATE OR ALTER PROCEDURE sp_GetFloorsByBuildingId
    @BuildingId NVARCHAR(50)
AS
BEGIN
    SELECT 
        Id,
        BuildingId,
        Label,
        TotalUnits
    FROM dbo.Floors
    WHERE BuildingId = @BuildingId
    ORDER BY Id ASC;
END
GO

-- 3. sp_GetPropertiesByOwner
CREATE OR ALTER PROCEDURE sp_GetPropertiesByOwner
    @UserId NVARCHAR(255)
AS
BEGIN
    SELECT 
        p.Id,
        p.Name,
        p.Location,
        p.MonthlyRent,
        p.Status,
        p.TenantName,
        p.DueAmount,
        p.BuildingId,
        p.FloorId,
        b.Name AS BuildingName,
        f.Label AS FloorLabel
    FROM dbo.Properties p
    INNER JOIN dbo.Buildings b ON p.BuildingId = b.Id
    LEFT JOIN dbo.Floors f ON p.FloorId = f.Id
    WHERE b.UserId = @UserId
    ORDER BY p.BuildingId ASC, p.FloorId ASC, p.Name ASC;
END
GO
