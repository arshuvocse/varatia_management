USE SmartBazarDbmssql;
GO

-- sp_GetRentPaymentsByOwner
CREATE OR ALTER PROCEDURE sp_GetRentPaymentsByOwner
    @UserId NVARCHAR(255)
AS
BEGIN
    SELECT 
        rp.Id,
        rp.PropertyId,
        p.Name AS PropertyName,
        rp.TenantName,
        rp.MonthLabel,
        rp.Amount,
        rp.Status,
        rp.PaidOn
    FROM dbo.RentPayments rp
    INNER JOIN dbo.Properties p ON rp.PropertyId = p.Id
    INNER JOIN dbo.Buildings b ON p.BuildingId = b.Id
    WHERE b.UserId = @UserId
    ORDER BY rp.MonthLabel DESC, rp.Id DESC;
END
GO
