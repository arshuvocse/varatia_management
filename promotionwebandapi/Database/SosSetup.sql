IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SosAlerts' AND xtype='U')
BEGIN
    CREATE TABLE SosAlerts (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        UserId NVARCHAR(64) NOT NULL,
        Latitude FLOAT NULL,
        Longitude FLOAT NULL,
        TriggeredAt DATETIME DEFAULT GETDATE(),
        Status NVARCHAR(50) DEFAULT 'Active'
    )
END
GO

IF COL_LENGTH(N'dbo.SosAlerts', N'UserId') IS NOT NULL
BEGIN
    ALTER TABLE dbo.SosAlerts ALTER COLUMN UserId NVARCHAR(64) NOT NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SosEmergencyContacts' AND xtype='U')
BEGIN
    CREATE TABLE SosEmergencyContacts (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        UserId NVARCHAR(64) NOT NULL,
        Name NVARCHAR(100) NOT NULL,
        Phone NVARCHAR(20) NOT NULL,
        Relation NVARCHAR(50) NULL,
        ImageUrl NVARCHAR(500) NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    )
END
GO

IF COL_LENGTH(N'dbo.SosEmergencyContacts', N'UserId') IS NOT NULL
BEGIN
    ALTER TABLE dbo.SosEmergencyContacts ALTER COLUMN UserId NVARCHAR(64) NOT NULL;
END
GO

-- Stored Procedures
IF OBJECT_ID('sp_Sos_TriggerAlert', 'P') IS NOT NULL DROP PROCEDURE sp_Sos_TriggerAlert;
GO
CREATE PROCEDURE sp_Sos_TriggerAlert
    @UserId NVARCHAR(64),
    @Latitude FLOAT = NULL,
    @Longitude FLOAT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO SosAlerts (UserId, Latitude, Longitude)
    VALUES (@UserId, @Latitude, @Longitude);
    
    SELECT SCOPE_IDENTITY() AS InsertedId;
END
GO

IF OBJECT_ID('sp_Sos_AddContact', 'P') IS NOT NULL DROP PROCEDURE sp_Sos_AddContact;
GO
CREATE PROCEDURE sp_Sos_AddContact
    @UserId NVARCHAR(64),
    @Name NVARCHAR(100),
    @Phone NVARCHAR(20),
    @Relation NVARCHAR(50) = NULL,
    @ImageUrl NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO SosEmergencyContacts (UserId, Name, Phone, Relation, ImageUrl)
    VALUES (@UserId, @Name, @Phone, @Relation, @ImageUrl);
    
    SELECT SCOPE_IDENTITY() AS InsertedId;
END
GO

IF OBJECT_ID('sp_Sos_GetContacts', 'P') IS NOT NULL DROP PROCEDURE sp_Sos_GetContacts;
GO
CREATE PROCEDURE sp_Sos_GetContacts
    @UserId NVARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, UserId, Name, Phone, Relation, ImageUrl, CreatedAt
    FROM SosEmergencyContacts
    WHERE UserId = @UserId
    ORDER BY CreatedAt DESC;
END
GO

IF OBJECT_ID('sp_Sos_RemoveContact', 'P') IS NOT NULL DROP PROCEDURE sp_Sos_RemoveContact;
GO
CREATE PROCEDURE sp_Sos_RemoveContact
    @Id INT,
    @UserId NVARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM SosEmergencyContacts
    WHERE Id = @Id AND UserId = @UserId;
END
GO
