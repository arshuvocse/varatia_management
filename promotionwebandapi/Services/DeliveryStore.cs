using Microsoft.Data.SqlClient;
using PromotionWeb.Models;

namespace PromotionWeb.Services;

public sealed class DeliveryStore(IConfiguration configuration, ShopkeeperWalletCreditService walletCreditService)
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
            using var command = new SqlCommand(SchemaSql, connection);
            command.ExecuteNonQuery();
            _schemaReady = true;
        }
    }

    public DeliveryMan Register(int shopkeeperId, DeliveryManRegistrationInput input,
        string? profilePhotoUrl, string? nidFrontPhotoUrl, string? nidBackPhotoUrl, string? licensePhotoUrl)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string userSql = """
                INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, ParentUserId)
                SELECT @Name, @Phone, @Password, N'DeliveryMan', UserId
                FROM dbo.tbl_Shopkeepers WHERE Id = @ShopkeeperId;
                SELECT CONVERT(INT, SCOPE_IDENTITY());
                """;
            int userId;
            using (var command = new SqlCommand(userSql, connection, transaction))
            {
                command.Parameters.AddWithValue("@Name", input.Name.Trim());
                command.Parameters.AddWithValue("@Phone", input.Phone.Trim());
                command.Parameters.AddWithValue("@Password", input.Password);
                command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
                userId = (int)(command.ExecuteScalar() ?? throw new InvalidOperationException("Shopkeeper was not found."));
            }

            const string deliverySql = """
                INSERT INTO dbo.tbl_DeliveryMen
                    (UserId, ShopkeeperId, AgentUserId, DivisionId, DistrictId, ThanaId, Address, Latitude, Longitude,
                     NidNumber, NidPhotoUrl, NidFrontPhotoUrl, NidBackPhotoUrl, DateOfBirth, EmergencyContact, VehicleType, VehicleNumber,
                     DrivingLicenseNumber, DrivingLicensePhotoUrl, ProfilePhotoUrl)
                SELECT @UserId, @ShopkeeperId, u.ParentUserId, s.DivisionId, s.DistrictId, s.ThanaId, @Address, s.Latitude, s.Longitude,
                    @NidNumber, @NidFrontPhotoUrl, @NidFrontPhotoUrl, @NidBackPhotoUrl, @DateOfBirth, @EmergencyContact, @VehicleType, @VehicleNumber,
                    @LicenseNumber, @LicensePhotoUrl, @ProfilePhotoUrl
                FROM dbo.tbl_Shopkeepers s
                INNER JOIN dbo.tbl_Users u ON u.Id = s.FieldOfficerUserId
                WHERE s.Id = @ShopkeeperId;
                """;
            using (var command = new SqlCommand(deliverySql, connection, transaction))
            {
                command.Parameters.AddWithValue("@UserId", userId);
                command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
                command.Parameters.AddWithValue("@Address", input.Address.Trim());
                AddNullable(command, "@NidNumber", input.NidNumber);
                AddNullable(command, "@NidFrontPhotoUrl", nidFrontPhotoUrl);
                AddNullable(command, "@NidBackPhotoUrl", nidBackPhotoUrl);
                command.Parameters.AddWithValue("@DateOfBirth", (object?)input.DateOfBirth ?? DBNull.Value);
                AddNullable(command, "@EmergencyContact", input.EmergencyContact);
                AddNullable(command, "@VehicleType", input.VehicleType);
                AddNullable(command, "@VehicleNumber", input.VehicleNumber);
                AddNullable(command, "@LicenseNumber", input.DrivingLicenseNumber);
                AddNullable(command, "@LicensePhotoUrl", licensePhotoUrl);
                AddNullable(command, "@ProfilePhotoUrl", profilePhotoUrl);
                command.ExecuteNonQuery();
            }

            transaction.Commit();
            return GetByUserId(userId) ?? throw new InvalidOperationException("Delivery man registration failed.");
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        {
            transaction.Rollback();
            throw new InvalidOperationException("This mobile number already has an account.", ex);
        }
    }

    public DeliveryMan RegisterByAgent(int agentUserId, DeliveryManRegistrationInput input,
        string? profilePhotoUrl, string? nidFrontPhotoUrl, string? nidBackPhotoUrl, string? licensePhotoUrl)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            EnsureAgentOwnsDistrict(connection, transaction, agentUserId, input.DistrictId!.Value);

            const string userSql = """
                INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, ParentUserId)
                VALUES (@Name, @Phone, @Password, N'DeliveryMan', @AgentUserId);
                SELECT CONVERT(INT, SCOPE_IDENTITY());
                """;
            int userId;
            using (var command = new SqlCommand(userSql, connection, transaction))
            {
                command.Parameters.AddWithValue("@Name", input.Name.Trim());
                command.Parameters.AddWithValue("@Phone", input.Phone.Trim());
                command.Parameters.AddWithValue("@Password", input.Password);
                command.Parameters.AddWithValue("@AgentUserId", agentUserId);
                userId = (int)(command.ExecuteScalar() ?? throw new InvalidOperationException("Delivery man registration failed."));
            }

            InsertDeliveryMan(connection, transaction, userId, null, agentUserId, input, profilePhotoUrl, nidFrontPhotoUrl, nidBackPhotoUrl, licensePhotoUrl);
            transaction.Commit();
            return GetByUserId(userId) ?? throw new InvalidOperationException("Delivery man registration failed.");
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627 or 51200 or 51201)
        {
            transaction.Rollback();
            throw new InvalidOperationException(ex.Number is 51200 or 51201 ? ex.Message : "This mobile number already has an account.", ex);
        }
    }

    public IReadOnlyList<DeliveryMan> GetByShopkeeper(int shopkeeperId)
    {
        EnsureSchema();
        return ReadDeliveryMen("WHERE dm.ShopkeeperId = @Id", shopkeeperId);
    }

    public IReadOnlyList<DeliveryMan> GetByAgent(int agentUserId)
    {
        EnsureSchema();
        return ReadDeliveryMen("WHERE dm.AgentUserId = @Id", agentUserId);
    }

    public IReadOnlyList<DeliveryAssignment> GetAssignmentsForAgent(int agentUserId) =>
        ReadAssignments("WHERE dm.AgentUserId = @Id", agentUserId);

    public IReadOnlyList<DeliveryMan> GetAvailableForShopkeeperDistrict(int shopkeeperId)
    {
        EnsureSchema();
        return ReadDeliveryMen("""
            WHERE dm.DistrictId = (SELECT DistrictId FROM dbo.tbl_Shopkeepers WHERE Id = @Id)
              AND (dm.ShopkeeperId IS NULL OR dm.ShopkeeperId = @Id)
            """, shopkeeperId);
    }

    public DeliveryMan? GetByUserId(int userId)
    {
        EnsureSchema();
        return ReadDeliveryMen("WHERE dm.UserId = @Id", userId).FirstOrDefault();
    }

    public void SetActive(int shopkeeperId, int deliveryManId, bool isActive)
    {
        EnsureSchema();
        Execute("""
            UPDATE u SET IsActive = @IsActive
            FROM dbo.tbl_Users u
            INNER JOIN dbo.tbl_DeliveryMen dm ON dm.UserId = u.Id
            WHERE dm.Id = @DeliveryManId AND dm.ShopkeeperId = @ShopkeeperId;
            """, command =>
        {
            command.Parameters.AddWithValue("@IsActive", isActive);
            command.Parameters.AddWithValue("@DeliveryManId", deliveryManId);
            command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        });
    }

    public bool SetActiveByAgent(int agentUserId, int deliveryManId, bool isActive)
    {
        EnsureSchema();
        return Execute("""
            UPDATE u SET IsActive = @IsActive
            FROM dbo.tbl_Users u
            INNER JOIN dbo.tbl_DeliveryMen dm ON dm.UserId = u.Id
            WHERE dm.Id = @DeliveryManId AND dm.AgentUserId = @AgentUserId;
            """, command =>
        {
            command.Parameters.AddWithValue("@IsActive", isActive);
            command.Parameters.AddWithValue("@DeliveryManId", deliveryManId);
            command.Parameters.AddWithValue("@AgentUserId", agentUserId);
        }) == 1;
    }

    public void Assign(int shopkeeperId, int orderId, int deliveryManId)
    {
        EnsureSchema();
        Execute("""
            IF NOT EXISTS (
                SELECT 1 FROM dbo.tbl_CustomerOrders
                WHERE Id = @OrderId AND ShopkeeperId = @ShopkeeperId AND Status IN (N'Approved', N'Assigned')
            ) THROW 51100, N'Only an approved order can be assigned.', 1;
            IF NOT EXISTS (
                SELECT 1 FROM dbo.tbl_DeliveryMen dm
                INNER JOIN dbo.tbl_Users u ON u.Id = dm.UserId
                INNER JOIN dbo.tbl_Shopkeepers s ON s.Id = @ShopkeeperId
                WHERE dm.Id = @DeliveryManId
                  AND u.IsActive = 1
                  AND (dm.ShopkeeperId = @ShopkeeperId OR (dm.ShopkeeperId IS NULL AND dm.DistrictId = s.DistrictId))
            ) THROW 51101, N'Invalid or inactive delivery man.', 1;

            UPDATE dbo.tbl_OrderDeliveryAssignments
            SET IsCurrent = 0, Status = N'Cancelled', UpdatedAt = SYSUTCDATETIME()
            WHERE OrderId = @OrderId AND IsCurrent = 1;

            DECLARE @Otp NVARCHAR(6) = RIGHT(CONCAT(N'000000', ABS(CHECKSUM(NEWID())) % 1000000), 6);
            INSERT INTO dbo.tbl_OrderDeliveryAssignments (OrderId, DeliveryManId, Status, DeliveryOtp)
            VALUES (@OrderId, @DeliveryManId, N'Assigned', @Otp);
            UPDATE dbo.tbl_CustomerOrders SET Status = N'Assigned' WHERE Id = @OrderId;
            INSERT INTO dbo.tbl_OrderStatusHistory (OrderId, Status, ChangedByUserId, Note)
            SELECT @OrderId, N'Assigned', s.UserId, CONCAT(N'Assigned to ', u.Name)
            FROM dbo.tbl_Shopkeepers s
            INNER JOIN dbo.tbl_DeliveryMen dm ON dm.Id = @DeliveryManId
            INNER JOIN dbo.tbl_Users u ON u.Id = dm.UserId
            WHERE s.Id = @ShopkeeperId;
            INSERT INTO dbo.tbl_Notifications (RecipientUserId, Title, Message, ReferenceId)
            SELECT dm.UserId, N'New delivery assignment', CONCAT(N'Order #', @OrderId, N' has been assigned to you.'), @OrderId
            FROM dbo.tbl_DeliveryMen dm WHERE dm.Id = @DeliveryManId;
            """, command =>
        {
            command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
            command.Parameters.AddWithValue("@OrderId", orderId);
            command.Parameters.AddWithValue("@DeliveryManId", deliveryManId);
        });
    }

    public void CancelAssignment(int shopkeeperId, int orderId)
    {
        EnsureSchema();
        Execute("""
            DECLARE @ShopUserId INT;
            SELECT @ShopUserId = UserId FROM dbo.tbl_Shopkeepers WHERE Id = @ShopkeeperId;
            IF NOT EXISTS (
                SELECT 1 FROM dbo.tbl_OrderDeliveryAssignments a
                INNER JOIN dbo.tbl_CustomerOrders o ON o.Id = a.OrderId
                WHERE a.OrderId = @OrderId AND o.ShopkeeperId = @ShopkeeperId AND a.IsCurrent = 1
                  AND a.Status NOT IN (N'Delivered', N'Rejected', N'Failed Delivery', N'Returned')
            ) THROW 51105, N'Active assignment was not found.', 1;
            UPDATE dbo.tbl_OrderDeliveryAssignments
            SET IsCurrent = 0, Status = N'Cancelled', UpdatedAt = SYSUTCDATETIME()
            WHERE OrderId = @OrderId AND IsCurrent = 1;
            UPDATE dbo.tbl_CustomerOrders SET Status = N'Approved' WHERE Id = @OrderId;
            INSERT INTO dbo.tbl_OrderStatusHistory (OrderId, Status, ChangedByUserId, Note)
            VALUES (@OrderId, N'Cancelled', @ShopUserId, N'Delivery assignment cancelled by shopkeeper.');
            """, command =>
        {
            command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
            command.Parameters.AddWithValue("@OrderId", orderId);
        });
    }

    public IReadOnlyList<DeliveryAssignment> GetAssignmentsForShopkeeper(int shopkeeperId) =>
        ReadAssignments("WHERE o.ShopkeeperId = @Id AND a.IsCurrent = 1", shopkeeperId);

    public IReadOnlyList<DeliveryAssignment> GetAssignmentsForCustomer(int customerUserId) =>
        ReadAssignments("WHERE o.CustomerUserId = @Id AND a.IsCurrent = 1", customerUserId);

    public IReadOnlyList<DeliveryAssignment> GetAssignmentsForDeliveryMan(int userId) =>
        ReadAssignments("WHERE dm.UserId = @Id AND a.IsCurrent = 1", userId);

    public string? GetDeliveryOtp(int shopkeeperId, int orderId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT a.DeliveryOtp FROM dbo.tbl_OrderDeliveryAssignments a
            INNER JOIN dbo.tbl_CustomerOrders o ON o.Id = a.OrderId
            WHERE a.OrderId = @OrderId AND o.ShopkeeperId = @ShopkeeperId AND a.IsCurrent = 1;
            """, connection);
        command.Parameters.AddWithValue("@OrderId", orderId);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        connection.Open();
        return command.ExecuteScalar() as string;
    }

    public void UpdateStatus(int userId, int assignmentId, DeliveryStatusUpdateInput input,
        string? proofPhotoUrl, string? signatureUrl)
    {
        EnsureSchema();
        walletCreditService.EnsureSchema();
        if (!DeliveryStatus.DeliveryManUpdates.Contains(input.Status))
            throw new InvalidOperationException("Invalid delivery status.");

        Execute("""
            DECLARE @CurrentStatus NVARCHAR(30), @OrderId INT, @Otp NVARCHAR(6);
            SELECT @CurrentStatus = a.Status, @OrderId = a.OrderId, @Otp = a.DeliveryOtp
            FROM dbo.tbl_OrderDeliveryAssignments a
            INNER JOIN dbo.tbl_DeliveryMen dm ON dm.Id = a.DeliveryManId
            WHERE a.Id = @AssignmentId AND dm.UserId = @UserId AND a.IsCurrent = 1;
            IF @OrderId IS NULL THROW 51102, N'Assignment was not found.', 1;
            IF NOT (
                (@CurrentStatus = N'Assigned' AND @Status IN (N'Accepted', N'Rejected')) OR
                (@CurrentStatus = N'Accepted' AND @Status IN (N'Picked Up', N'Failed Delivery')) OR
                (@CurrentStatus = N'Picked Up' AND @Status IN (N'Out for Delivery', N'Returned', N'Failed Delivery')) OR
                (@CurrentStatus = N'Out for Delivery' AND @Status IN (N'Delivered', N'Returned', N'Failed Delivery'))
            ) THROW 51103, N'This status change is not allowed.', 1;
            IF @Status = N'Delivered'
               AND (@OtpInput IS NULL OR @OtpInput <> @Otp)
               AND @ProofPhotoUrl IS NULL
               AND @SignatureUrl IS NULL
                THROW 51104, N'Provide the correct OTP, delivery photo, or customer signature.', 1;

            UPDATE dbo.tbl_OrderDeliveryAssignments
            SET Status = @Status, CashCollectedAmount = @CashCollectedAmount, DeliveryNote = @DeliveryNote,
                ProofPhotoUrl = COALESCE(@ProofPhotoUrl, ProofPhotoUrl),
                CustomerSignatureUrl = COALESCE(@SignatureUrl, CustomerSignatureUrl),
                CurrentLatitude = @Latitude, CurrentLongitude = @Longitude,
                DeliveredAt = CASE WHEN @Status = N'Delivered' THEN SYSUTCDATETIME() ELSE DeliveredAt END,
                UpdatedAt = SYSUTCDATETIME()
            WHERE Id = @AssignmentId;
            UPDATE dbo.tbl_CustomerOrders SET Status = @Status WHERE Id = @OrderId;
            IF @Status = N'Delivered'
                EXEC dbo.sp_ShopkeeperWallet_CreditForOrder @OrderId = @OrderId;
            INSERT INTO dbo.tbl_OrderStatusHistory (OrderId, Status, ChangedByUserId, Note, Latitude, Longitude)
            VALUES (@OrderId, @Status, @UserId, @DeliveryNote, @Latitude, @Longitude);
            INSERT INTO dbo.tbl_Notifications (RecipientUserId, Title, Message, ReferenceId)
            SELECT s.UserId, N'Delivery status updated', CONCAT(N'Order #', @OrderId, N' is now ', @Status, N'.'), @OrderId
            FROM dbo.tbl_CustomerOrders o INNER JOIN dbo.tbl_Shopkeepers s ON s.Id = o.ShopkeeperId
            WHERE o.Id = @OrderId
            UNION ALL
            SELECT o.CustomerUserId, N'Order status updated', CONCAT(N'Your order #', @OrderId, N' is now ', @Status, N'.'), @OrderId
            FROM dbo.tbl_CustomerOrders o WHERE o.Id = @OrderId;
            UPDATE dm SET Availability =
                CASE WHEN @Status IN (N'Delivered', N'Rejected', N'Failed Delivery', N'Returned') THEN N'Available' ELSE N'Busy' END
            FROM dbo.tbl_DeliveryMen dm
            INNER JOIN dbo.tbl_OrderDeliveryAssignments a ON a.DeliveryManId = dm.Id
            WHERE a.Id = @AssignmentId;
            UPDATE dbo.tbl_DeliveryMen
            SET LastLatitude = COALESCE(@Latitude, LastLatitude),
                LastLongitude = COALESCE(@Longitude, LastLongitude),
                LastLocationAt = CASE WHEN @Latitude IS NULL OR @Longitude IS NULL THEN LastLocationAt ELSE SYSUTCDATETIME() END
            WHERE UserId = @UserId;
            """, command =>
        {
            command.Parameters.AddWithValue("@UserId", userId);
            command.Parameters.AddWithValue("@AssignmentId", assignmentId);
            command.Parameters.AddWithValue("@Status", input.Status);
            AddNullable(command, "@OtpInput", input.Otp);
            command.Parameters.AddWithValue("@CashCollectedAmount", (object?)input.CashCollectedAmount ?? DBNull.Value);
            AddNullable(command, "@DeliveryNote", input.DeliveryNote);
            AddNullable(command, "@ProofPhotoUrl", proofPhotoUrl);
            AddNullable(command, "@SignatureUrl", signatureUrl);
            command.Parameters.AddWithValue("@Latitude", (object?)input.Latitude ?? DBNull.Value);
            command.Parameters.AddWithValue("@Longitude", (object?)input.Longitude ?? DBNull.Value);
        });
    }

    public void UpdateAvailability(int userId, string availability)
    {
        if (availability is not (DeliveryAvailability.Available or DeliveryAvailability.Busy or DeliveryAvailability.Offline))
            throw new InvalidOperationException("Invalid availability.");
        EnsureSchema();
        Execute("UPDATE dbo.tbl_DeliveryMen SET Availability = @Value WHERE UserId = @UserId;", command =>
        {
            command.Parameters.AddWithValue("@Value", availability);
            command.Parameters.AddWithValue("@UserId", userId);
        });
    }

    public void UpdateCurrentLocation(int userId, int assignmentId, decimal latitude, decimal longitude)
    {
        EnsureSchema();
        Execute("""
            UPDATE a
            SET CurrentLatitude = @Latitude,
                CurrentLongitude = @Longitude,
                UpdatedAt = SYSUTCDATETIME()
            FROM dbo.tbl_OrderDeliveryAssignments a
            INNER JOIN dbo.tbl_DeliveryMen dm ON dm.Id = a.DeliveryManId
            WHERE a.Id = @AssignmentId AND dm.UserId = @UserId AND a.IsCurrent = 1;
            IF @@ROWCOUNT = 0 THROW 51102, N'Assignment was not found.', 1;
            """, command =>
        {
            command.Parameters.AddWithValue("@UserId", userId);
            command.Parameters.AddWithValue("@AssignmentId", assignmentId);
            command.Parameters.AddWithValue("@Latitude", latitude);
            command.Parameters.AddWithValue("@Longitude", longitude);
        });
    }

    public void UpdateLiveLocation(int userId, decimal latitude, decimal longitude, int? assignmentId = null)
    {
        EnsureSchema();
        Execute("""
            UPDATE dbo.tbl_DeliveryMen
            SET LastLatitude = @Latitude,
                LastLongitude = @Longitude,
                LastLocationAt = SYSUTCDATETIME(),
                Availability = CASE WHEN Availability = N'Offline' THEN N'Available' ELSE Availability END
            WHERE UserId = @UserId;
            IF @@ROWCOUNT = 0 THROW 51102, N'Delivery profile was not found.', 1;

            IF @AssignmentId IS NOT NULL
            BEGIN
                UPDATE a
                SET CurrentLatitude = @Latitude,
                    CurrentLongitude = @Longitude,
                    UpdatedAt = SYSUTCDATETIME()
                FROM dbo.tbl_OrderDeliveryAssignments a
                INNER JOIN dbo.tbl_DeliveryMen dm ON dm.Id = a.DeliveryManId
                WHERE a.Id = @AssignmentId AND dm.UserId = @UserId AND a.IsCurrent = 1;
                IF @@ROWCOUNT = 0 THROW 51102, N'Assignment was not found.', 1;
            END
            """, command =>
        {
            command.Parameters.AddWithValue("@UserId", userId);
            command.Parameters.AddWithValue("@Latitude", latitude);
            command.Parameters.AddWithValue("@Longitude", longitude);
            command.Parameters.AddWithValue("@AssignmentId", (object?)assignmentId ?? DBNull.Value);
        });
    }

    public IReadOnlyList<NearbyDeliveryMan> GetNearbyDeliveryMenForDeliveryMan(
        int userId, decimal latitude, decimal longitude, decimal radiusKm, int limit)
    {
        EnsureSchema();
        radiusKm = Math.Clamp(radiusKm, 0.1m, 50m);
        limit = Math.Clamp(limit, 1, 100);

        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand($"""
            DECLARE @OriginDistrictId INT;
            SELECT @OriginDistrictId = DistrictId FROM dbo.tbl_DeliveryMen WHERE UserId = @UserId;
            IF @OriginDistrictId IS NULL THROW 51102, N'Delivery profile was not found.', 1;

            SELECT TOP ({limit}) *
            FROM (
                SELECT dm.*, u.Name, u.Phone, u.IsActive, COALESCE(s.ShopName, N'Agent delivery team') AS ShopName,
                    dv.Name AS DivisionName, ds.Name AS DistrictName, th.Name AS ThanaName,
                    CAST(6371.0 * 2.0 * ASIN(SQRT(
                        POWER(SIN(RADIANS((CONVERT(FLOAT, @Latitude) - CONVERT(FLOAT, COALESCE(dm.LastLatitude, dm.Latitude))) / 2.0)), 2.0) +
                        COS(RADIANS(CONVERT(FLOAT, @Latitude))) *
                        COS(RADIANS(CONVERT(FLOAT, COALESCE(dm.LastLatitude, dm.Latitude)))) *
                        POWER(SIN(RADIANS((CONVERT(FLOAT, @Longitude) - CONVERT(FLOAT, COALESCE(dm.LastLongitude, dm.Longitude))) / 2.0)), 2.0)
                    )) AS DECIMAL(10, 3)) AS DistanceKm
                FROM dbo.tbl_DeliveryMen dm
                INNER JOIN dbo.tbl_Users u ON u.Id = dm.UserId
                LEFT JOIN dbo.tbl_Shopkeepers s ON s.Id = dm.ShopkeeperId
                INNER JOIN dbo.tbl_Divisions dv ON dv.Id = dm.DivisionId
                INNER JOIN dbo.tbl_Districts ds ON ds.Id = dm.DistrictId
                INNER JOIN dbo.tbl_Thanas th ON th.Id = dm.ThanaId
                WHERE dm.DistrictId = @OriginDistrictId
                  AND dm.UserId <> @UserId
                  AND u.IsActive = 1
                  AND dm.Availability <> N'Offline'
                  AND COALESCE(dm.LastLatitude, dm.Latitude) IS NOT NULL
                  AND COALESCE(dm.LastLongitude, dm.Longitude) IS NOT NULL
            ) nearby
            WHERE DistanceKm <= @RadiusKm
            ORDER BY DistanceKm, LastLocationAt DESC;
            """, connection);
        command.Parameters.AddWithValue("@UserId", userId);
        command.Parameters.AddWithValue("@Latitude", latitude);
        command.Parameters.AddWithValue("@Longitude", longitude);
        command.Parameters.AddWithValue("@RadiusKm", radiusKm);
        try
        {
            connection.Open();
            using var reader = command.ExecuteReader();
            var result = new List<NearbyDeliveryMan>();
            while (reader.Read())
            {
                result.Add(new NearbyDeliveryMan
                {
                    DeliveryMan = MapDeliveryMan(reader),
                    DistanceKm = reader.GetDecimal(reader.GetOrdinal("DistanceKm"))
                });
            }
            return result;
        }
        catch (SqlException ex) when (ex.Number is >= 51100 and <= 51105)
        {
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    public void UpdateProfile(int userId, DeliveryProfileUpdateInput input,
        string? profilePhotoUrl, string? nidFrontPhotoUrl, string? nidBackPhotoUrl, string? licensePhotoUrl)
    {
        EnsureSchema();
        Execute("""
            UPDATE dm SET Address = @Address, NidNumber = @NidNumber, DateOfBirth = @DateOfBirth,
                EmergencyContact = @EmergencyContact, VehicleType = @VehicleType, VehicleNumber = @VehicleNumber,
                DrivingLicenseNumber = @LicenseNumber,
                ProfilePhotoUrl = COALESCE(@ProfilePhotoUrl, ProfilePhotoUrl),
                NidPhotoUrl = COALESCE(@NidFrontPhotoUrl, NidPhotoUrl),
                NidFrontPhotoUrl = COALESCE(@NidFrontPhotoUrl, NidFrontPhotoUrl),
                NidBackPhotoUrl = COALESCE(@NidBackPhotoUrl, NidBackPhotoUrl),
                DrivingLicensePhotoUrl = COALESCE(@LicensePhotoUrl, DrivingLicensePhotoUrl)
            FROM dbo.tbl_DeliveryMen dm WHERE dm.UserId = @UserId;
            UPDATE dbo.tbl_Users SET Name = @Name WHERE Id = @UserId AND Role = N'DeliveryMan';
            """, command =>
        {
            command.Parameters.AddWithValue("@UserId", userId);
            command.Parameters.AddWithValue("@Name", input.Name.Trim());
            command.Parameters.AddWithValue("@Address", input.Address.Trim());
            AddNullable(command, "@NidNumber", input.NidNumber);
            command.Parameters.AddWithValue("@DateOfBirth", (object?)input.DateOfBirth ?? DBNull.Value);
            AddNullable(command, "@EmergencyContact", input.EmergencyContact);
            AddNullable(command, "@VehicleType", input.VehicleType);
            AddNullable(command, "@VehicleNumber", input.VehicleNumber);
            AddNullable(command, "@LicenseNumber", input.DrivingLicenseNumber);
            AddNullable(command, "@ProfilePhotoUrl", profilePhotoUrl);
            AddNullable(command, "@NidFrontPhotoUrl", nidFrontPhotoUrl);
            AddNullable(command, "@NidBackPhotoUrl", nidBackPhotoUrl);
            AddNullable(command, "@LicensePhotoUrl", licensePhotoUrl);
        });
    }

    private IReadOnlyList<DeliveryMan> ReadDeliveryMen(string where, int id)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand($"""
            SELECT dm.*, u.Name, u.Phone, u.IsActive, COALESCE(s.ShopName, N'Agent delivery team') AS ShopName,
                dv.Name AS DivisionName, ds.Name AS DistrictName, th.Name AS ThanaName
            FROM dbo.tbl_DeliveryMen dm
            INNER JOIN dbo.tbl_Users u ON u.Id = dm.UserId
            LEFT JOIN dbo.tbl_Shopkeepers s ON s.Id = dm.ShopkeeperId
            INNER JOIN dbo.tbl_Divisions dv ON dv.Id = dm.DivisionId
            INNER JOIN dbo.tbl_Districts ds ON ds.Id = dm.DistrictId
            INNER JOIN dbo.tbl_Thanas th ON th.Id = dm.ThanaId
            {where} ORDER BY dm.Id DESC;
            """, connection);
        command.Parameters.AddWithValue("@Id", id);
        connection.Open();
        using var reader = command.ExecuteReader();
        var result = new List<DeliveryMan>();
        while (reader.Read()) result.Add(MapDeliveryMan(reader));
        return result;
    }

    private static void InsertDeliveryMan(SqlConnection connection, SqlTransaction transaction, int userId, int? shopkeeperId,
        int? agentUserId, DeliveryManRegistrationInput input, string? profilePhotoUrl, string? nidFrontPhotoUrl,
        string? nidBackPhotoUrl, string? licensePhotoUrl)
    {
        const string deliverySql = """
            INSERT INTO dbo.tbl_DeliveryMen
                (UserId, ShopkeeperId, AgentUserId, DivisionId, DistrictId, ThanaId, Address, Latitude, Longitude,
                 NidNumber, NidPhotoUrl, NidFrontPhotoUrl, NidBackPhotoUrl, DateOfBirth, EmergencyContact, VehicleType, VehicleNumber,
                 DrivingLicenseNumber, DrivingLicensePhotoUrl, ProfilePhotoUrl)
            VALUES
                (@UserId, @ShopkeeperId, @AgentUserId, @DivisionId, @DistrictId, @ThanaId, @Address, @Latitude, @Longitude,
                 @NidNumber, @NidFrontPhotoUrl, @NidFrontPhotoUrl, @NidBackPhotoUrl, @DateOfBirth, @EmergencyContact, @VehicleType, @VehicleNumber,
                 @LicenseNumber, @LicensePhotoUrl, @ProfilePhotoUrl);
            """;
        using var command = new SqlCommand(deliverySql, connection, transaction);
        command.Parameters.AddWithValue("@UserId", userId);
        command.Parameters.AddWithValue("@ShopkeeperId", (object?)shopkeeperId ?? DBNull.Value);
        command.Parameters.AddWithValue("@AgentUserId", (object?)agentUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("@DivisionId", input.DivisionId!.Value);
        command.Parameters.AddWithValue("@DistrictId", input.DistrictId!.Value);
        command.Parameters.AddWithValue("@ThanaId", input.ThanaId!.Value);
        command.Parameters.AddWithValue("@Address", input.Address.Trim());
        command.Parameters.AddWithValue("@Latitude", input.Latitude!.Value);
        command.Parameters.AddWithValue("@Longitude", input.Longitude!.Value);
        AddNullable(command, "@NidNumber", input.NidNumber);
        AddNullable(command, "@NidFrontPhotoUrl", nidFrontPhotoUrl);
        AddNullable(command, "@NidBackPhotoUrl", nidBackPhotoUrl);
        command.Parameters.AddWithValue("@DateOfBirth", (object?)input.DateOfBirth ?? DBNull.Value);
        AddNullable(command, "@EmergencyContact", input.EmergencyContact);
        AddNullable(command, "@VehicleType", input.VehicleType);
        AddNullable(command, "@VehicleNumber", input.VehicleNumber);
        AddNullable(command, "@LicenseNumber", input.DrivingLicenseNumber);
        AddNullable(command, "@LicensePhotoUrl", licensePhotoUrl);
        AddNullable(command, "@ProfilePhotoUrl", profilePhotoUrl);
        command.ExecuteNonQuery();
    }

    private static void EnsureAgentOwnsDistrict(SqlConnection connection, SqlTransaction transaction, int agentUserId, int districtId)
    {
        using var command = new SqlCommand("""
            IF OBJECT_ID(N'dbo.tbl_AgentDistricts', N'U') IS NULL
            CREATE TABLE dbo.tbl_AgentDistricts (
                AgentUserId INT NOT NULL PRIMARY KEY,
                DistrictId INT NOT NULL CONSTRAINT UQ_tbl_AgentDistricts_District UNIQUE,
                CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_AgentDistricts_CreatedAt DEFAULT SYSUTCDATETIME(),
                CONSTRAINT FK_tbl_AgentDistricts_User FOREIGN KEY (AgentUserId) REFERENCES dbo.tbl_Users(Id),
                CONSTRAINT FK_tbl_AgentDistricts_District FOREIGN KEY (DistrictId) REFERENCES dbo.tbl_Districts(Id)
            );
            IF EXISTS (SELECT 1 FROM dbo.tbl_AgentDistricts WHERE DistrictId = @DistrictId AND AgentUserId <> @AgentUserId)
                THROW 51200, N'This district already has an agent.', 1;
            IF EXISTS (SELECT 1 FROM dbo.tbl_AgentDistricts WHERE AgentUserId = @AgentUserId AND DistrictId <> @DistrictId)
                THROW 51201, N'This agent is already assigned to another district.', 1;
            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_AgentDistricts WHERE AgentUserId = @AgentUserId)
                INSERT INTO dbo.tbl_AgentDistricts (AgentUserId, DistrictId) VALUES (@AgentUserId, @DistrictId);
            """, connection, transaction);
        command.Parameters.AddWithValue("@AgentUserId", agentUserId);
        command.Parameters.AddWithValue("@DistrictId", districtId);
        command.ExecuteNonQuery();
    }

    private IReadOnlyList<DeliveryAssignment> ReadAssignments(string where, int id)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand($"""
            SELECT a.Id AssignmentId, a.OrderId, a.DeliveryManId, u.Name DeliveryManName, u.Phone DeliveryManPhone,
                o.CustomerName, o.CustomerPhone, o.CustomerLatitude, o.CustomerLongitude,
                s.ShopName, s.Phone ShopPhone, o.TotalAmount - o.DiscountAmount CollectionAmount,
                a.Status, a.DeliveryOtp, a.DeliveryNote, a.CashCollectedAmount, a.ProofPhotoUrl, a.CustomerSignatureUrl,
                a.CurrentLatitude, a.CurrentLongitude, a.AssignedAt, a.DeliveredAt
            FROM dbo.tbl_OrderDeliveryAssignments a
            INNER JOIN dbo.tbl_DeliveryMen dm ON dm.Id = a.DeliveryManId
            INNER JOIN dbo.tbl_Users u ON u.Id = dm.UserId
            INNER JOIN dbo.tbl_CustomerOrders o ON o.Id = a.OrderId
            INNER JOIN dbo.tbl_Shopkeepers s ON s.Id = o.ShopkeeperId
            {where}
            ORDER BY CASE WHEN a.Status = N'Assigned' THEN 0 WHEN a.Status = N'Delivered' THEN 2 ELSE 1 END, a.AssignedAt DESC;

            SELECT d.Id, d.OrderMasterId, d.ProductId, d.ProductName, d.Sku, d.Quantity, d.UnitPrice
            FROM dbo.tbl_CustomerOrderDetails d
            INNER JOIN dbo.tbl_OrderDeliveryAssignments a ON a.OrderId = d.OrderMasterId
            INNER JOIN dbo.tbl_DeliveryMen dm ON dm.Id = a.DeliveryManId
            INNER JOIN dbo.tbl_CustomerOrders o ON o.Id = a.OrderId
            {where} ORDER BY d.Id;
            """, connection);
        command.Parameters.AddWithValue("@Id", id);
        connection.Open();
        using var reader = command.ExecuteReader();
        var rows = new List<DeliveryAssignment>();
        while (reader.Read()) rows.Add(MapAssignment(reader));
        reader.NextResult();
        var details = new Dictionary<int, List<CustomerOrderDetail>>();
        while (reader.Read())
        {
            var orderId = reader.GetInt32(reader.GetOrdinal("OrderMasterId"));
            if (!details.TryGetValue(orderId, out var list)) details[orderId] = list = [];
            list.Add(new CustomerOrderDetail
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")), OrderMasterId = orderId,
                ProductId = reader.GetInt32(reader.GetOrdinal("ProductId")),
                ProductName = reader.GetString(reader.GetOrdinal("ProductName")),
                Sku = reader.GetString(reader.GetOrdinal("Sku")),
                Quantity = reader.GetInt32(reader.GetOrdinal("Quantity")),
                UnitPrice = reader.GetDecimal(reader.GetOrdinal("UnitPrice"))
            });
        }
        return rows.Select(x => CopyWithDetails(x, details.GetValueOrDefault(x.OrderId) ?? [])).ToList();
    }

    private int Execute(string sql, Action<SqlCommand> parameters)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(sql, connection);
        parameters(command);
        try { connection.Open(); return command.ExecuteNonQuery(); }
        catch (SqlException ex) when (ex.Number is >= 51100 and <= 51105)
        { throw new InvalidOperationException(ex.Message, ex); }
    }

    private static void AddNullable(SqlCommand command, string name, string? value) =>
        command.Parameters.AddWithValue(name, string.IsNullOrWhiteSpace(value) ? DBNull.Value : value.Trim());
    private static string? NullableString(SqlDataReader reader, string name) =>
        reader.IsDBNull(reader.GetOrdinal(name)) ? null : reader.GetString(reader.GetOrdinal(name));
    private static decimal? NullableDecimal(SqlDataReader reader, string name) =>
        reader.IsDBNull(reader.GetOrdinal(name)) ? null : reader.GetDecimal(reader.GetOrdinal(name));

    private static DeliveryMan MapDeliveryMan(SqlDataReader reader) => new()
    {
        Id = reader.GetInt32(reader.GetOrdinal("Id")), UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
        ShopkeeperId = reader.IsDBNull(reader.GetOrdinal("ShopkeeperId")) ? null : reader.GetInt32(reader.GetOrdinal("ShopkeeperId")),
        AgentUserId = reader.IsDBNull(reader.GetOrdinal("AgentUserId")) ? null : reader.GetInt32(reader.GetOrdinal("AgentUserId")),
        ShopName = reader.GetString(reader.GetOrdinal("ShopName")),
        Name = reader.GetString(reader.GetOrdinal("Name")), Phone = reader.GetString(reader.GetOrdinal("Phone")),
        DivisionId = reader.GetInt32(reader.GetOrdinal("DivisionId")), DivisionName = reader.GetString(reader.GetOrdinal("DivisionName")),
        DistrictId = reader.GetInt32(reader.GetOrdinal("DistrictId")), DistrictName = reader.GetString(reader.GetOrdinal("DistrictName")),
        ThanaId = reader.GetInt32(reader.GetOrdinal("ThanaId")), ThanaName = reader.GetString(reader.GetOrdinal("ThanaName")),
        Address = reader.GetString(reader.GetOrdinal("Address")), NidNumber = NullableString(reader, "NidNumber"),
        Latitude = reader.GetDecimal(reader.GetOrdinal("Latitude")), Longitude = reader.GetDecimal(reader.GetOrdinal("Longitude")),
        LastLatitude = NullableDecimal(reader, "LastLatitude"), LastLongitude = NullableDecimal(reader, "LastLongitude"),
        LastLocationAt = reader.IsDBNull(reader.GetOrdinal("LastLocationAt")) ? null : reader.GetDateTime(reader.GetOrdinal("LastLocationAt")),
        NidPhotoUrl = NullableString(reader, "NidPhotoUrl"),
        NidFrontPhotoUrl = NullableString(reader, "NidFrontPhotoUrl"),
        NidBackPhotoUrl = NullableString(reader, "NidBackPhotoUrl"),
        DateOfBirth = reader.IsDBNull(reader.GetOrdinal("DateOfBirth")) ? null : reader.GetDateTime(reader.GetOrdinal("DateOfBirth")),
        EmergencyContact = NullableString(reader, "EmergencyContact"), VehicleType = NullableString(reader, "VehicleType"),
        VehicleNumber = NullableString(reader, "VehicleNumber"), DrivingLicenseNumber = NullableString(reader, "DrivingLicenseNumber"),
        DrivingLicensePhotoUrl = NullableString(reader, "DrivingLicensePhotoUrl"), ProfilePhotoUrl = NullableString(reader, "ProfilePhotoUrl"),
        Availability = reader.GetString(reader.GetOrdinal("Availability")), IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
        CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt"))
    };

    private static DeliveryAssignment MapAssignment(SqlDataReader reader) => new()
    {
        AssignmentId = reader.GetInt32(reader.GetOrdinal("AssignmentId")), OrderId = reader.GetInt32(reader.GetOrdinal("OrderId")),
        DeliveryManId = reader.GetInt32(reader.GetOrdinal("DeliveryManId")), DeliveryManName = reader.GetString(reader.GetOrdinal("DeliveryManName")),
        DeliveryManPhone = reader.GetString(reader.GetOrdinal("DeliveryManPhone")), CustomerName = reader.GetString(reader.GetOrdinal("CustomerName")),
        CustomerPhone = reader.GetString(reader.GetOrdinal("CustomerPhone")), CustomerLatitude = NullableDecimal(reader, "CustomerLatitude"),
        CustomerLongitude = NullableDecimal(reader, "CustomerLongitude"), ShopName = reader.GetString(reader.GetOrdinal("ShopName")),
        ShopPhone = reader.GetString(reader.GetOrdinal("ShopPhone")), CollectionAmount = reader.GetDecimal(reader.GetOrdinal("CollectionAmount")),
        Status = reader.GetString(reader.GetOrdinal("Status")), DeliveryNote = NullableString(reader, "DeliveryNote"),
        DeliveryOtp = NullableString(reader, "DeliveryOtp"),
        CashCollectedAmount = NullableDecimal(reader, "CashCollectedAmount"), ProofPhotoUrl = NullableString(reader, "ProofPhotoUrl"),
        CustomerSignatureUrl = NullableString(reader, "CustomerSignatureUrl"), CurrentLatitude = NullableDecimal(reader, "CurrentLatitude"),
        CurrentLongitude = NullableDecimal(reader, "CurrentLongitude"), AssignedAt = reader.GetDateTime(reader.GetOrdinal("AssignedAt")),
        DeliveredAt = reader.IsDBNull(reader.GetOrdinal("DeliveredAt")) ? null : reader.GetDateTime(reader.GetOrdinal("DeliveredAt"))
    };

    private static DeliveryAssignment CopyWithDetails(DeliveryAssignment x, IReadOnlyList<CustomerOrderDetail> details) => new()
    {
        AssignmentId = x.AssignmentId, OrderId = x.OrderId, DeliveryManId = x.DeliveryManId,
        DeliveryManName = x.DeliveryManName, DeliveryManPhone = x.DeliveryManPhone,
        CustomerName = x.CustomerName, CustomerPhone = x.CustomerPhone,
        CustomerLatitude = x.CustomerLatitude, CustomerLongitude = x.CustomerLongitude,
        ShopName = x.ShopName, ShopPhone = x.ShopPhone, CollectionAmount = x.CollectionAmount,
        Status = x.Status, DeliveryNote = x.DeliveryNote, CashCollectedAmount = x.CashCollectedAmount,
        DeliveryOtp = x.DeliveryOtp,
        ProofPhotoUrl = x.ProofPhotoUrl, CustomerSignatureUrl = x.CustomerSignatureUrl,
        CurrentLatitude = x.CurrentLatitude, CurrentLongitude = x.CurrentLongitude,
        AssignedAt = x.AssignedAt, DeliveredAt = x.DeliveredAt, Details = details
    };

    public const string SchemaSql = """
        SET ANSI_NULLS ON;
        SET QUOTED_IDENTIFIER ON;
        IF OBJECT_ID(N'dbo.tbl_DeliveryMen', N'U') IS NULL
        CREATE TABLE dbo.tbl_DeliveryMen (
            Id INT IDENTITY(1,1) PRIMARY KEY, UserId INT NOT NULL UNIQUE, ShopkeeperId INT NULL, AgentUserId INT NULL,
            DivisionId INT NOT NULL, DistrictId INT NOT NULL, ThanaId INT NOT NULL,
            Address NVARCHAR(250) NOT NULL, Latitude DECIMAL(9,6) NOT NULL, Longitude DECIMAL(9,6) NOT NULL,
            LastLatitude DECIMAL(9,6) NULL, LastLongitude DECIMAL(9,6) NULL, LastLocationAt DATETIME2(0) NULL,
            NidNumber NVARCHAR(30) NULL, NidPhotoUrl NVARCHAR(500) NULL,
            NidFrontPhotoUrl NVARCHAR(500) NULL, NidBackPhotoUrl NVARCHAR(500) NULL,
            DateOfBirth DATE NULL, EmergencyContact NVARCHAR(20) NULL, VehicleType NVARCHAR(50) NULL,
            VehicleNumber NVARCHAR(50) NULL, DrivingLicenseNumber NVARCHAR(50) NULL,
            DrivingLicensePhotoUrl NVARCHAR(500) NULL, ProfilePhotoUrl NVARCHAR(500) NULL,
            Availability NVARCHAR(20) NOT NULL DEFAULT N'Offline', CreatedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_DeliveryMen_User FOREIGN KEY(UserId) REFERENCES dbo.tbl_Users(Id),
            CONSTRAINT FK_DeliveryMen_Shop FOREIGN KEY(ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id),
            CONSTRAINT FK_DeliveryMen_Agent FOREIGN KEY(AgentUserId) REFERENCES dbo.tbl_Users(Id),
            CONSTRAINT FK_DeliveryMen_Division FOREIGN KEY(DivisionId) REFERENCES dbo.tbl_Divisions(Id),
            CONSTRAINT FK_DeliveryMen_District FOREIGN KEY(DistrictId) REFERENCES dbo.tbl_Districts(Id),
            CONSTRAINT FK_DeliveryMen_Thana FOREIGN KEY(ThanaId) REFERENCES dbo.tbl_Thanas(Id)
        );
        IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'AgentUserId') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD AgentUserId INT NULL;
        IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'DivisionId') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD DivisionId INT NULL;
        IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'DistrictId') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD DistrictId INT NULL;
        IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'ThanaId') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD ThanaId INT NULL;
        IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'Latitude') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD Latitude DECIMAL(9,6) NULL;
        IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'Longitude') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD Longitude DECIMAL(9,6) NULL;
        IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'LastLatitude') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD LastLatitude DECIMAL(9,6) NULL;
        IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'LastLongitude') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD LastLongitude DECIMAL(9,6) NULL;
        IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'LastLocationAt') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD LastLocationAt DATETIME2(0) NULL;
        IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'NidFrontPhotoUrl') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD NidFrontPhotoUrl NVARCHAR(500) NULL;
        IF COL_LENGTH(N'dbo.tbl_DeliveryMen', N'NidBackPhotoUrl') IS NULL ALTER TABLE dbo.tbl_DeliveryMen ADD NidBackPhotoUrl NVARCHAR(500) NULL;
        EXEC sys.sp_executesql N'
            UPDATE dbo.tbl_DeliveryMen SET NidFrontPhotoUrl = NidPhotoUrl
            WHERE NidFrontPhotoUrl IS NULL AND NidPhotoUrl IS NOT NULL;
            UPDATE dm
            SET AgentUserId = COALESCE(dm.AgentUserId, u.ParentUserId),
                DivisionId = COALESCE(dm.DivisionId, s.DivisionId),
                DistrictId = COALESCE(dm.DistrictId, s.DistrictId),
                ThanaId = COALESCE(dm.ThanaId, s.ThanaId),
                Latitude = COALESCE(dm.Latitude, s.Latitude),
                Longitude = COALESCE(dm.Longitude, s.Longitude)
            FROM dbo.tbl_DeliveryMen dm
            LEFT JOIN dbo.tbl_Shopkeepers s ON s.Id = dm.ShopkeeperId
            LEFT JOIN dbo.tbl_Users u ON u.Id = s.FieldOfficerUserId
            WHERE dm.ShopkeeperId IS NOT NULL;';
        IF OBJECT_ID(N'dbo.tbl_OrderDeliveryAssignments', N'U') IS NULL
        CREATE TABLE dbo.tbl_OrderDeliveryAssignments (
            Id INT IDENTITY(1,1) PRIMARY KEY, OrderId INT NOT NULL, DeliveryManId INT NOT NULL,
            Status NVARCHAR(30) NOT NULL DEFAULT N'Assigned', DeliveryOtp NVARCHAR(6) NOT NULL,
            CashCollectedAmount DECIMAL(18,2) NULL, DeliveryNote NVARCHAR(500) NULL,
            ProofPhotoUrl NVARCHAR(500) NULL, CustomerSignatureUrl NVARCHAR(500) NULL,
            CurrentLatitude DECIMAL(9,6) NULL, CurrentLongitude DECIMAL(9,6) NULL,
            AssignedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(), UpdatedAt DATETIME2(0) NULL,
            DeliveredAt DATETIME2(0) NULL, IsCurrent BIT NOT NULL DEFAULT 1,
            CONSTRAINT FK_Assignment_Order FOREIGN KEY(OrderId) REFERENCES dbo.tbl_CustomerOrders(Id),
            CONSTRAINT FK_Assignment_DeliveryMan FOREIGN KEY(DeliveryManId) REFERENCES dbo.tbl_DeliveryMen(Id)
        );
        IF OBJECT_ID(N'dbo.tbl_OrderStatusHistory', N'U') IS NULL
        CREATE TABLE dbo.tbl_OrderStatusHistory (
            Id BIGINT IDENTITY(1,1) PRIMARY KEY, OrderId INT NOT NULL, Status NVARCHAR(30) NOT NULL,
            ChangedByUserId INT NOT NULL, Note NVARCHAR(500) NULL, Latitude DECIMAL(9,6) NULL,
            Longitude DECIMAL(9,6) NULL, ChangedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_OrderHistory_Order FOREIGN KEY(OrderId) REFERENCES dbo.tbl_CustomerOrders(Id),
            CONSTRAINT FK_OrderHistory_User FOREIGN KEY(ChangedByUserId) REFERENCES dbo.tbl_Users(Id)
        );
        IF OBJECT_ID(N'dbo.tbl_Notifications', N'U') IS NULL
        CREATE TABLE dbo.tbl_Notifications (
            Id BIGINT IDENTITY(1,1) PRIMARY KEY, RecipientUserId INT NOT NULL,
            Title NVARCHAR(150) NOT NULL, Message NVARCHAR(500) NOT NULL, ReferenceId INT NULL,
            IsRead BIT NOT NULL DEFAULT 0, CreatedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_Notifications_User FOREIGN KEY(RecipientUserId) REFERENCES dbo.tbl_Users(Id)
        );
        IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Assignment_CurrentOrder')
            CREATE UNIQUE INDEX UX_Assignment_CurrentOrder ON dbo.tbl_OrderDeliveryAssignments(OrderId) WHERE IsCurrent = 1;
        """;
}
