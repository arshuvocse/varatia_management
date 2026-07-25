IF COL_LENGTH(N'dbo.tbl_Shopkeepers', N'NidNumber') IS NULL
    ALTER TABLE dbo.tbl_Shopkeepers ADD NidNumber NVARCHAR(30) NULL;
GO

IF COL_LENGTH(N'dbo.tbl_Shopkeepers', N'ProfilePhotoPath') IS NULL
    ALTER TABLE dbo.tbl_Shopkeepers ADD ProfilePhotoPath NVARCHAR(500) NULL;
GO

IF COL_LENGTH(N'dbo.tbl_Shopkeepers', N'BillboardPhotoPath') IS NULL
    ALTER TABLE dbo.tbl_Shopkeepers ADD BillboardPhotoPath NVARCHAR(500) NULL;
GO
