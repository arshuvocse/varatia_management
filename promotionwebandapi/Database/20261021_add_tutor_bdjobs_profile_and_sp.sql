USE [SmartBazarDbmssql];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- 1. Ensure Table Exists
IF OBJECT_ID(N'dbo.TutorBdjobsProfiles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TutorBdjobsProfiles
    (
        Id NVARCHAR(64) NOT NULL PRIMARY KEY CONSTRAINT DF_TutorBdjobsProfiles_Id DEFAULT (NEWID()),
        UserId NVARCHAR(64) NOT NULL CONSTRAINT UQ_TutorBdjobsProfiles_UserId UNIQUE,
        FullName NVARCHAR(150) NOT NULL,
        PhoneNumber NVARCHAR(30) NOT NULL,
        Gender NVARCHAR(20) NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_Gender DEFAULT (N'পুরুষ'),
        City NVARCHAR(50) NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_City DEFAULT (N'Dhaka'),
        CurrentLocation NVARCHAR(100) NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_CurrentLocation DEFAULT (N''),
        UniversityType NVARCHAR(100) NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_UniversityType DEFAULT (N''),
        UniversityName NVARCHAR(150) NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_UniversityName DEFAULT (N''),
        Department NVARCHAR(150) NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_Department DEFAULT (N''),
        SscMedium NVARCHAR(100) NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_SscMedium DEFAULT (N''),
        PreferredLocations NVARCHAR(MAX) NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_PreferredLocations DEFAULT (N'[]'),
        PreferredSubjects NVARCHAR(MAX) NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_PreferredSubjects DEFAULT (N'[]'),
        ClassesToTeach NVARCHAR(MAX) NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_ClassesToTeach DEFAULT (N'[]'),
        ExpectedFee NVARCHAR(50) NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_ExpectedFee DEFAULT (N''),
        DaysPerWeek NVARCHAR(50) NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_DaysPerWeek DEFAULT (N''),
        CompletionScore INT NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_CompletionScore DEFAULT (0),
        CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt DATETIME2 NOT NULL CONSTRAINT DF_TutorBdjobsProfiles_UpdatedAt DEFAULT (SYSUTCDATETIME())
    );
END;
GO

-- Index for fast user lookup
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_TutorBdjobsProfiles_UserId'
      AND object_id = OBJECT_ID(N'dbo.TutorBdjobsProfiles')
)
BEGIN
    CREATE INDEX IX_TutorBdjobsProfiles_UserId
    ON dbo.TutorBdjobsProfiles (UserId);
END;
GO

-- 2. Stored Procedure: sp_UpsertTutorBdjobsProfile
IF OBJECT_ID(N'dbo.sp_UpsertTutorBdjobsProfile', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpsertTutorBdjobsProfile;
GO

CREATE PROCEDURE dbo.sp_UpsertTutorBdjobsProfile
    @UserId NVARCHAR(64),
    @FullName NVARCHAR(150),
    @PhoneNumber NVARCHAR(30),
    @Gender NVARCHAR(20) = N'পুরুষ',
    @City NVARCHAR(50) = N'Dhaka',
    @CurrentLocation NVARCHAR(100) = N'',
    @UniversityType NVARCHAR(100) = N'',
    @UniversityName NVARCHAR(150) = N'',
    @Department NVARCHAR(150) = N'',
    @SscMedium NVARCHAR(100) = N'',
    @PreferredLocations NVARCHAR(MAX) = N'[]',
    @PreferredSubjects NVARCHAR(MAX) = N'[]',
    @ClassesToTeach NVARCHAR(MAX) = N'[]',
    @ExpectedFee NVARCHAR(50) = N'',
    @DaysPerWeek NVARCHAR(50) = N'',
    @CompletionScore INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME2 = SYSUTCDATETIME();
    DECLARE @TargetId NVARCHAR(64);

    SELECT @TargetId = Id
    FROM dbo.TutorBdjobsProfiles
    WHERE UserId = @UserId;

    IF @TargetId IS NOT NULL
    BEGIN
        UPDATE dbo.TutorBdjobsProfiles
        SET FullName = @FullName,
            PhoneNumber = @PhoneNumber,
            Gender = @Gender,
            City = @City,
            CurrentLocation = @CurrentLocation,
            UniversityType = @UniversityType,
            UniversityName = @UniversityName,
            Department = @Department,
            SscMedium = @SscMedium,
            PreferredLocations = @PreferredLocations,
            PreferredSubjects = @PreferredSubjects,
            ClassesToTeach = @ClassesToTeach,
            ExpectedFee = @ExpectedFee,
            DaysPerWeek = @DaysPerWeek,
            CompletionScore = @CompletionScore,
            UpdatedAt = @Now
        WHERE Id = @TargetId;
    END
    ELSE
    BEGIN
        SET @TargetId = LOWER(REPLACE(CONVERT(NVARCHAR(36), NEWID()), '-', ''));

        INSERT INTO dbo.TutorBdjobsProfiles
        (
            Id, UserId, FullName, PhoneNumber, Gender, City, CurrentLocation,
            UniversityType, UniversityName, Department, SscMedium,
            PreferredLocations, PreferredSubjects, ClassesToTeach,
            ExpectedFee, DaysPerWeek, CompletionScore, CreatedAt, UpdatedAt
        )
        VALUES
        (
            @TargetId, @UserId, @FullName, @PhoneNumber, @Gender, @City, @CurrentLocation,
            @UniversityType, @UniversityName, @Department, @SscMedium,
            @PreferredLocations, @PreferredSubjects, @ClassesToTeach,
            @ExpectedFee, @DaysPerWeek, @CompletionScore, @Now, @Now
        );
    END;

    -- Return the upserted record
    SELECT
        Id,
        UserId,
        FullName,
        PhoneNumber,
        Gender,
        City,
        CurrentLocation,
        UniversityType,
        UniversityName,
        Department,
        SscMedium,
        PreferredLocations,
        PreferredSubjects,
        ClassesToTeach,
        ExpectedFee,
        DaysPerWeek,
        CompletionScore,
        CreatedAt,
        UpdatedAt
    FROM dbo.TutorBdjobsProfiles
    WHERE Id = @TargetId;
END;
GO

-- 3. Stored Procedure: sp_GetTutorBdjobsProfile
IF OBJECT_ID(N'dbo.sp_GetTutorBdjobsProfile', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetTutorBdjobsProfile;
GO

CREATE PROCEDURE dbo.sp_GetTutorBdjobsProfile
    @UserId NVARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        UserId,
        FullName,
        PhoneNumber,
        Gender,
        City,
        CurrentLocation,
        UniversityType,
        UniversityName,
        Department,
        SscMedium,
        PreferredLocations,
        PreferredSubjects,
        ClassesToTeach,
        ExpectedFee,
        DaysPerWeek,
        CompletionScore,
        CreatedAt,
        UpdatedAt
    FROM dbo.TutorBdjobsProfiles
    WHERE UserId = @UserId;
END;
GO
