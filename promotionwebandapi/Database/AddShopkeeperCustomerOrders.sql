CREATE OR ALTER PROCEDURE dbo.sp_CustomerOrder_ListByShopkeeper
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

CREATE OR ALTER PROCEDURE dbo.sp_CustomerOrder_UpdateStatus
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
