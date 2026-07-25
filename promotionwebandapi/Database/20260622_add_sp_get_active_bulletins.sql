SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.GetActiveCompanyBulletins', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.GetActiveCompanyBulletins;
END;
GO

CREATE PROCEDURE dbo.GetActiveCompanyBulletins
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Message, LinkUrl, IsActive, StartAt, EndAt, CreatedAt
    FROM dbo.tbl_CompanyBulletins
    WHERE IsActive = 1
      AND (StartAt IS NULL OR StartAt <= GETDATE())
      AND (EndAt IS NULL OR EndAt >= GETDATE())
    ORDER BY CreatedAt DESC;
END;
GO
