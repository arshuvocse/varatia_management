IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SosLocationTracking' AND xtype='U')
BEGIN
    CREATE TABLE SosLocationTracking (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        UserId NVARCHAR(64) NOT NULL,
        Latitude FLOAT NOT NULL,
        Longitude FLOAT NOT NULL,
        Timestamp DATETIME DEFAULT GETDATE()
    )
END
GO

IF COL_LENGTH(N'dbo.SosLocationTracking', N'UserId') IS NOT NULL
BEGIN
    ALTER TABLE dbo.SosLocationTracking ALTER COLUMN UserId NVARCHAR(64) NOT NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SosEmergencyServices' AND xtype='U')
BEGIN
    CREATE TABLE SosEmergencyServices (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Title NVARCHAR(100) NOT NULL,
        Phone NVARCHAR(50) NOT NULL,
        Type NVARCHAR(50) NOT NULL, -- e.g., Police, Ambulance, Fire
        CreatedAt DATETIME DEFAULT GETDATE()
    )
    
    -- Insert Default Data
    INSERT INTO SosEmergencyServices (Title, Phone, Type) VALUES 
    ('National Emergency', '999', 'Police'),
    ('Police (DMP)', '01320-143999', 'Police'),
    ('Ambulance', '199', 'Ambulance'),
    ('Fire Service', '16163', 'Fire');
END
GO

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SosSafetyTips' AND xtype='U')
BEGIN
    CREATE TABLE SosSafetyTips (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Title NVARCHAR(255) NOT NULL,
        Description NVARCHAR(MAX) NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    )

    -- Insert Default Data
    INSERT INTO SosSafetyTips (Title, Description) VALUES 
    ('Stay Calm in Emergencies', 'Always try to stay calm. Panic can make situations worse.'),
    ('Know Your Surroundings', 'Be aware of exits and safe zones in your building.'),
    ('Keep Important Numbers Handy', 'Memorize or keep a written copy of close contacts.');
END
GO

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SosEvidence' AND xtype='U')
BEGIN
    CREATE TABLE SosEvidence (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        UserId NVARCHAR(64) NOT NULL,
        FileUrl NVARCHAR(1000) NOT NULL,
        FileType NVARCHAR(50) NOT NULL, -- Image, Audio, Video
        CreatedAt DATETIME DEFAULT GETDATE()
    )
END
GO

IF COL_LENGTH(N'dbo.SosEvidence', N'UserId') IS NOT NULL
BEGIN
    ALTER TABLE dbo.SosEvidence ALTER COLUMN UserId NVARCHAR(64) NOT NULL;
END
GO

-- Stored Procedures
IF OBJECT_ID('sp_Sos_UpdateLocation', 'P') IS NOT NULL DROP PROCEDURE sp_Sos_UpdateLocation;
GO
CREATE PROCEDURE sp_Sos_UpdateLocation
    @UserId NVARCHAR(64),
    @Latitude FLOAT,
    @Longitude FLOAT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO SosLocationTracking (UserId, Latitude, Longitude)
    VALUES (@UserId, @Latitude, @Longitude);
END
GO

IF OBJECT_ID('sp_Sos_GetEmergencyServices', 'P') IS NOT NULL DROP PROCEDURE sp_Sos_GetEmergencyServices;
GO
CREATE PROCEDURE sp_Sos_GetEmergencyServices
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Title, Phone, Type FROM SosEmergencyServices ORDER BY Type;
END
GO

IF OBJECT_ID('sp_Sos_GetSafetyTips', 'P') IS NOT NULL DROP PROCEDURE sp_Sos_GetSafetyTips;
GO
CREATE PROCEDURE sp_Sos_GetSafetyTips
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Title, Description, CreatedAt FROM SosSafetyTips ORDER BY CreatedAt DESC;
END
GO

IF OBJECT_ID('sp_Sos_SaveEvidence', 'P') IS NOT NULL DROP PROCEDURE sp_Sos_SaveEvidence;
GO
CREATE PROCEDURE sp_Sos_SaveEvidence
    @UserId NVARCHAR(64),
    @FileUrl NVARCHAR(1000),
    @FileType NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO SosEvidence (UserId, FileUrl, FileType)
    VALUES (@UserId, @FileUrl, @FileType);
END
GO
