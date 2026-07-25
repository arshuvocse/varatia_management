IF OBJECT_ID(N'dbo.GeneralPosts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GeneralPosts
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserId NVARCHAR(100) NOT NULL,
        Category NVARCHAR(50) NOT NULL, -- 'rent' or 'sale'
        TenantType NVARCHAR(50) NULL, -- 'family', 'bachelor_male', 'bachelor_female'
        Title NVARCHAR(500) NOT NULL,
        Price DECIMAL(18,2) NOT NULL,
        Advance DECIMAL(18,2) NULL,
        UtilityIncluded BIT NOT NULL CONSTRAINT DF_GeneralPosts_UtilityIncluded DEFAULT(0),
        DivisionId NVARCHAR(100) NOT NULL,
        AreaId NVARCHAR(100) NOT NULL,
        FullAddress NVARCHAR(1000) NULL,
        Street NVARCHAR(500) NULL,
        Latitude DECIMAL(18,8) NULL,
        Longitude DECIMAL(18,8) NULL,
        Bedrooms INT NOT NULL CONSTRAINT DF_GeneralPosts_Bedrooms DEFAULT(1),
        Bathrooms INT NOT NULL CONSTRAINT DF_GeneralPosts_Bathrooms DEFAULT(1),
        Kitchens INT NOT NULL CONSTRAINT DF_GeneralPosts_Kitchens DEFAULT(1),
        Balconies INT NOT NULL CONSTRAINT DF_GeneralPosts_Balconies DEFAULT(0),
        HasGas BIT NOT NULL CONSTRAINT DF_GeneralPosts_HasGas DEFAULT(0),
        HasLift BIT NOT NULL CONSTRAINT DF_GeneralPosts_HasLift DEFAULT(0),
        HasGenerator BIT NOT NULL CONSTRAINT DF_GeneralPosts_HasGenerator DEFAULT(0),
        HasParking BIT NOT NULL CONSTRAINT DF_GeneralPosts_HasParking DEFAULT(0),
        Description NVARCHAR(MAX) NULL,
        MediaInfo NVARCHAR(MAX) NULL, -- Stores JSON string or comma separated file names if needed
        Status NVARCHAR(50) NOT NULL CONSTRAINT DF_GeneralPosts_Status DEFAULT('active'),
        CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_GeneralPosts_CreatedOn DEFAULT (SYSUTCDATETIME()),
        UpdatedOn DATETIME2 NOT NULL CONSTRAINT DF_GeneralPosts_UpdatedOn DEFAULT (SYSUTCDATETIME())
    );
END;
GO
