using Microsoft.Data.SqlClient;

namespace PromotionWeb.Services;

/// <summary>
/// Credits a shopkeeper's wallet with the net sale proceeds (order total minus discount minus the
/// mandatory platform commission) the moment a customer order reaches the "Delivered" status.
/// Idempotent per order via tbl_CustomerOrders.WalletCreditedAt, so it is safe to call from every
/// code path that can transition an order to Delivered (shopkeeper self-service and the delivery-man app).
/// </summary>
public sealed class ShopkeeperWalletCreditService(IConfiguration configuration)
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");
    private static readonly object SchemaLock = new();
    private static bool _schemaReady;

    public void EnsureSchema()
    {
        if (_schemaReady) return;
        lock (SchemaLock)
        {
            if (_schemaReady) return;
            using var connection = new SqlConnection(_connectionString);
            connection.Open();

            using (var command = new SqlCommand("""
                IF COL_LENGTH(N'dbo.tbl_CustomerOrderProducts', N'CommissionPercentage') IS NULL
                    ALTER TABLE dbo.tbl_CustomerOrderProducts
                    ADD CommissionPercentage DECIMAL(5,2) NOT NULL
                        CONSTRAINT DF_tbl_CustomerOrderProducts_CommissionPercentage DEFAULT (3.0);

                IF COL_LENGTH(N'dbo.tbl_CustomerOrders', N'WalletCreditedAt') IS NULL
                    ALTER TABLE dbo.tbl_CustomerOrders ADD WalletCreditedAt DATETIME2(0) NULL;

                IF OBJECT_ID(N'dbo.tbl_ShopkeeperWalletCreditLogs', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.tbl_ShopkeeperWalletCreditLogs
                    (
                        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_ShopkeeperWalletCreditLogs PRIMARY KEY,
                        OrderId INT NOT NULL,
                        ShopkeeperId INT NOT NULL,
                        GrossAmount DECIMAL(18,2) NOT NULL,
                        DiscountAmount DECIMAL(18,2) NOT NULL,
                        CommissionAmount DECIMAL(18,2) NOT NULL,
                        NetAmount DECIMAL(18,2) NOT NULL,
                        CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_ShopkeeperWalletCreditLogs_CreatedAt DEFAULT (SYSUTCDATETIME()),
                        CONSTRAINT FK_tbl_ShopkeeperWalletCreditLogs_tbl_CustomerOrders FOREIGN KEY (OrderId) REFERENCES dbo.tbl_CustomerOrders(Id),
                        CONSTRAINT FK_tbl_ShopkeeperWalletCreditLogs_tbl_Shopkeepers FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id)
                    );
                END;
                """, connection))
            {
                command.ExecuteNonQuery();
            }

            using (var command = new SqlCommand("""
                CREATE OR ALTER PROCEDURE dbo.sp_ShopkeeperWallet_CreditForOrder
                    @OrderId INT
                AS
                BEGIN
                    SET NOCOUNT ON;
                    SET XACT_ABORT ON;

                    DECLARE @ShopkeeperId INT, @TotalAmount DECIMAL(18,2), @DiscountAmount DECIMAL(18,2);

                    BEGIN TRANSACTION;

                    BEGIN TRY
                        -- Lock the order row and only proceed if it is Delivered and not already credited.
                        -- This is what makes the credit safe to call from more than one status-update path.
                        SELECT @ShopkeeperId = ShopkeeperId, @TotalAmount = TotalAmount, @DiscountAmount = DiscountAmount
                        FROM dbo.tbl_CustomerOrders WITH (UPDLOCK, ROWLOCK)
                        WHERE Id = @OrderId AND Status = N'Delivered' AND WalletCreditedAt IS NULL;

                        IF @ShopkeeperId IS NULL
                        BEGIN
                            COMMIT TRANSACTION;
                            RETURN;
                        END

                        UPDATE dbo.tbl_CustomerOrders SET WalletCreditedAt = SYSUTCDATETIME() WHERE Id = @OrderId;

                        DECLARE @CommissionAmount DECIMAL(18,2);
                        SELECT @CommissionAmount = ISNULL(SUM(ROUND(d.Quantity *
                            CASE WHEN d.UnitPrice > inventory.PurchasePrice THEN d.UnitPrice - inventory.PurchasePrice ELSE 0 END *
                            (COALESCE(companyProduct.CompanyPercentage, 0)
                             + COALESCE(companyProduct.AgentPercentage, 0)
                             + COALESCE(companyProduct.FieldForcePercentage, 0)
                             + COALESCE(companyProduct.CustomerPercentage, 0)) / 100.0, 2)), 0)
                        FROM dbo.tbl_CustomerOrderDetails d
                        INNER JOIN dbo.tbl_CustomerOrders o ON o.Id = d.OrderMasterId
                        INNER JOIN dbo.tbl_Products inventory ON inventory.ShopkeeperId = o.ShopkeeperId AND inventory.Sku = d.Sku
                        INNER JOIN dbo.tbl_CompanyProducts companyProduct ON companyProduct.ProductCode = d.Sku AND companyProduct.IsActive = 1
                        WHERE d.OrderMasterId = @OrderId;

                        DECLARE @NetAmount DECIMAL(18,2) = @TotalAmount - @DiscountAmount - @CommissionAmount;
                        IF @NetAmount < 0 SET @NetAmount = 0;

                        MERGE dbo.tbl_ShopkeeperWallets AS target
                        USING (SELECT @ShopkeeperId AS ShopkeeperId) AS source
                        ON target.ShopkeeperId = source.ShopkeeperId
                        WHEN MATCHED THEN
                            UPDATE SET Balance = Balance + @NetAmount,
                                       WithdrawableBalance = WithdrawableBalance + @NetAmount,
                                       UpdatedAt = SYSUTCDATETIME()
                        WHEN NOT MATCHED THEN
                            INSERT (ShopkeeperId, Balance, WithdrawableBalance, PendingBalance, UpdatedAt)
                            VALUES (@ShopkeeperId, @NetAmount, @NetAmount, 0, SYSUTCDATETIME());

                        INSERT INTO dbo.tbl_ShopkeeperWalletCreditLogs
                            (OrderId, ShopkeeperId, GrossAmount, DiscountAmount, CommissionAmount, NetAmount)
                        VALUES
                            (@OrderId, @ShopkeeperId, @TotalAmount, @DiscountAmount, @CommissionAmount, @NetAmount);

                        COMMIT TRANSACTION;
                    END TRY
                    BEGIN CATCH
                        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
                        THROW;
                    END CATCH
                END
                """, connection))
            {
                command.ExecuteNonQuery();
            }

            using (var command = new SqlCommand("""
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

                    IF @Status = N'Delivered'
                        EXEC dbo.sp_ShopkeeperWallet_CreditForOrder @OrderId = @OrderId;
                END
                """, connection))
            {
                command.ExecuteNonQuery();
            }

            _schemaReady = true;
        }
    }

    public void CreditForOrder(int orderId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("dbo.sp_ShopkeeperWallet_CreditForOrder", connection)
        {
            CommandType = System.Data.CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@OrderId", orderId);
        connection.Open();
        command.ExecuteNonQuery();
    }
}
