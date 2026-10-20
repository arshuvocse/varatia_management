using Microsoft.Data.SqlClient;
using PromotionWeb.Models;
using System.Data;

namespace PromotionWeb.Services;

public sealed class AppStore(IConfiguration configuration)
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");
    private static readonly object AgentSchemaLock = new();
    private static bool _agentSchemaReady;
    private static readonly object ShopkeeperSchemaLock = new();
    private static bool _shopkeeperSchemaReady;
    private static readonly object CompanyDashboardSchemaLock = new();
    private static bool _companyDashboardSchemaReady;
    private static readonly object CustomerSchemaLock = new();
    private static bool _customerSchemaReady;

    public AppUser? ValidateUser(string phone, string password)
    {
        using var connection = CreateConnection();
        using var command = CreateCommand(connection, "dbo.sp_User_Validate");
        command.Parameters.AddWithValue("@Phone", phone);
        command.Parameters.AddWithValue("@Password", password);

        connection.Open();
        using var reader = command.ExecuteReader();
        return reader.Read() ? MapUser(reader) : null;
    }

    public Shopkeeper RegisterShopkeeper(
        ShopkeeperRegistrationViewModel model,
        int fieldOfficerUserId,
        string? profilePhotoPath,
        string? billboardPhotoPath)
    {
        try
        {
            EnsureShopkeeperRegistrationSchema();
            using var connection = CreateConnection();
            using var command = CreateCommand(connection, "dbo.sp_Shopkeeper_Register");
            command.Parameters.AddWithValue("@ShopName", model.ShopName.Trim());
            command.Parameters.AddWithValue("@OwnerName", model.OwnerName.Trim());
            command.Parameters.AddWithValue("@Phone", model.Phone.Trim());
            command.Parameters.AddWithValue("@NidNumber", (object?)model.NidNumber?.Trim() ?? DBNull.Value);
            command.Parameters.AddWithValue("@ProfilePhotoPath", (object?)profilePhotoPath ?? DBNull.Value);
            command.Parameters.AddWithValue("@BillboardPhotoPath", (object?)billboardPhotoPath ?? DBNull.Value);
            command.Parameters.AddWithValue("@DivisionId", model.DivisionId!.Value);
            command.Parameters.AddWithValue("@DistrictId", model.DistrictId!.Value);
            command.Parameters.AddWithValue("@ThanaId", model.ThanaId!.Value);
            command.Parameters.AddWithValue("@Address", model.Address.Trim());
            command.Parameters.AddWithValue("@Latitude", model.Latitude!.Value);
            command.Parameters.AddWithValue("@Longitude", model.Longitude!.Value);
            command.Parameters.AddWithValue("@Area", model.Area.Trim());
            command.Parameters.AddWithValue("@ShopType", model.ShopType.Trim());
            command.Parameters.AddWithValue("@Password", model.Password);
            command.Parameters.AddWithValue("@FieldOfficerUserId", fieldOfficerUserId);

            connection.Open();
            using var reader = command.ExecuteReader();
            if (!reader.Read())
            {
                throw new InvalidOperationException("Shopkeeper registration failed.");
            }

            return MapShopkeeper(reader);
        }
        catch (SqlException ex) when (ex.Number == 51000 || ex.Number == 51001 || ex.Number == 2627 || ex.Number == 2601)
        {
            throw new InvalidOperationException("এই মোবাইল নম্বর দিয়ে আগে থেকেই অ্যাকাউন্ট আছে।", ex);
        }
    }

    public LocationCatalog GetLocationCatalog()
    {
        using var connection = CreateConnection();
        using var command = CreateCommand(connection, "dbo.sp_Location_List");

        connection.Open();
        using var reader = command.ExecuteReader();

        var divisions = ReadLocations(reader, hasParent: false);
        reader.NextResult();
        var districts = ReadLocations(reader, hasParent: true);
        reader.NextResult();
        var thanas = ReadLocations(reader, hasParent: true);

        return new LocationCatalog
        {
            Divisions = divisions,
            Districts = districts,
            Thanas = thanas
        };
    }

    public LandingNetworkStatsViewModel GetLandingNetworkStats()
    {
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            SELECT
                Customers = (
                    SELECT COUNT(1)
                    FROM (
                        SELECT Phone FROM dbo.tbl_Customers WHERE IsActive = 1
                        UNION
                        SELECT Phone FROM dbo.tbl_Users WHERE Role = N'Customer' AND IsActive = 1
                    ) customers
                ),
                Shopkeepers = (
                    SELECT COUNT(1)
                    FROM dbo.tbl_Shopkeepers shop
                    INNER JOIN dbo.tbl_Users users ON users.Id = shop.UserId
                    WHERE users.IsActive = 1
                ),
                DeliveryMen = (
                    SELECT COUNT(1)
                    FROM dbo.tbl_DeliveryMen delivery
                    INNER JOIN dbo.tbl_Users users ON users.Id = delivery.UserId
                    WHERE users.IsActive = 1
                ),
                FieldForce = (
                    SELECT COUNT(1)
                    FROM dbo.tbl_Users
                    WHERE Role = N'FieldOfficer' AND IsActive = 1
                );
            """, connection);

        connection.Open();
        using var reader = command.ExecuteReader();
        if (!reader.Read())
        {
            return new LandingNetworkStatsViewModel();
        }

        return new LandingNetworkStatsViewModel
        {
            Customers = reader.GetInt32(reader.GetOrdinal("Customers")),
            Shopkeepers = reader.GetInt32(reader.GetOrdinal("Shopkeepers")),
            DeliveryMen = reader.GetInt32(reader.GetOrdinal("DeliveryMen")),
            FieldForce = reader.GetInt32(reader.GetOrdinal("FieldForce"))
        };
    }

    public AppUser RegisterCustomer(CustomerRegistrationViewModel model)
    {
        EnsureCustomerProfileSchema();
        using var connection = CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            int userId;
            using (var command = new SqlCommand("""
                INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role)
                VALUES (@Name, @Phone, @Password, N'Customer');
                SELECT CONVERT(INT, SCOPE_IDENTITY());
                """, connection, transaction))
            {
                command.Parameters.AddWithValue("@Name", model.Name.Trim());
                command.Parameters.AddWithValue("@Phone", model.Phone.Trim());
                command.Parameters.AddWithValue("@Password", model.Password);
                userId = (int)(command.ExecuteScalar() ?? throw new InvalidOperationException("Customer registration failed."));
            }

            using (var command = new SqlCommand("""
                IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Customers WHERE Phone = @Phone)
                BEGIN
                    INSERT INTO dbo.tbl_Customers (Name, Phone, Address, Latitude, Longitude, LocationUpdatedAt)
                    VALUES (@Name, @Phone, @Address, @Latitude, @Longitude,
                        CASE WHEN @Latitude IS NULL THEN NULL ELSE SYSUTCDATETIME() END);
                END
                ELSE
                BEGIN
                    UPDATE dbo.tbl_Customers
                    SET Name = @Name, Address = @Address,
                        Latitude = COALESCE(@Latitude, Latitude),
                        Longitude = COALESCE(@Longitude, Longitude),
                        LocationUpdatedAt = CASE WHEN @Latitude IS NULL THEN LocationUpdatedAt ELSE SYSUTCDATETIME() END
                    WHERE Phone = @Phone;
                END
                """, connection, transaction))
            {
                command.Parameters.AddWithValue("@Name", model.Name.Trim());
                command.Parameters.AddWithValue("@Phone", model.Phone.Trim());
                command.Parameters.AddWithValue("@Address", string.IsNullOrWhiteSpace(model.Address) ? DBNull.Value : model.Address.Trim());
                command.Parameters.AddWithValue("@Latitude", (object?)model.Latitude ?? DBNull.Value);
                command.Parameters.AddWithValue("@Longitude", (object?)model.Longitude ?? DBNull.Value);
                command.ExecuteNonQuery();
            }

            transaction.Commit();
            return new AppUser { Id = userId, Name = model.Name.Trim(), Phone = model.Phone.Trim(), Password = model.Password, Role = Roles.Customer };
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        {
            transaction.Rollback();
            throw new InvalidOperationException("This mobile number already has an account.", ex);
        }
    }

    private void EnsureCustomerProfileSchema()
    {
        if (_customerSchemaReady) return;
        lock (CustomerSchemaLock)
        {
            if (_customerSchemaReady) return;
            using var connection = CreateConnection();
            using var command = new SqlCommand("""
                IF COL_LENGTH(N'dbo.tbl_Customers', N'ProfilePhotoPath') IS NULL
                    ALTER TABLE dbo.tbl_Customers ADD ProfilePhotoPath NVARCHAR(500) NULL;
                IF COL_LENGTH(N'dbo.tbl_Customers', N'Latitude') IS NULL
                    ALTER TABLE dbo.tbl_Customers ADD Latitude DECIMAL(9,6) NULL;
                IF COL_LENGTH(N'dbo.tbl_Customers', N'Longitude') IS NULL
                    ALTER TABLE dbo.tbl_Customers ADD Longitude DECIMAL(9,6) NULL;
                IF COL_LENGTH(N'dbo.tbl_Customers', N'LocationUpdatedAt') IS NULL
                    ALTER TABLE dbo.tbl_Customers ADD LocationUpdatedAt DATETIME2(0) NULL;
                """, connection) { CommandTimeout = 120 };
            connection.Open();
            command.ExecuteNonQuery();
            _customerSchemaReady = true;
        }
    }

    public void UpdateCustomerProfilePhoto(string phone, string photoPath)
    {
        EnsureCustomerProfileSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_Customers
            SET ProfilePhotoPath = @ProfilePhotoPath
            WHERE Phone = @Phone
            """, connection);
        command.Parameters.AddWithValue("@Phone", phone);
        command.Parameters.AddWithValue("@ProfilePhotoPath", photoPath);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public string? GetCustomerProfilePhotoPath(string phone)
    {
        EnsureCustomerProfileSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("SELECT ProfilePhotoPath FROM dbo.tbl_Customers WHERE Phone = @Phone", connection);
        command.Parameters.AddWithValue("@Phone", phone);
        connection.Open();
        var result = command.ExecuteScalar();
        return result != DBNull.Value ? result as string : null;
    }

    public void UpdateCustomerLocation(string phone, decimal latitude, decimal longitude)
    {
        EnsureCustomerProfileSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_Customers
            SET Latitude = @Latitude, Longitude = @Longitude, LocationUpdatedAt = SYSUTCDATETIME()
            WHERE Phone = @Phone
            """, connection);
        command.Parameters.AddWithValue("@Phone", phone.Trim());
        command.Parameters.AddWithValue("@Latitude", latitude);
        command.Parameters.AddWithValue("@Longitude", longitude);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public (decimal? Latitude, decimal? Longitude)? GetCustomerLocation(string phone)
    {
        EnsureCustomerProfileSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand(
            "SELECT Latitude, Longitude FROM dbo.tbl_Customers WHERE Phone = @Phone", connection);
        command.Parameters.AddWithValue("@Phone", phone.Trim());
        connection.Open();
        using var reader = command.ExecuteReader();
        if (!reader.Read()) return null;
        return (
            reader.IsDBNull(0) ? null : reader.GetDecimal(0),
            reader.IsDBNull(1) ? null : reader.GetDecimal(1));
    }

    public IReadOnlyList<Shopkeeper> GetShopkeepers(int? fieldOfficerUserId = null)
    {
        EnsureShopkeeperRegistrationSchema();
        using var connection = CreateConnection();
        using var command = CreateCommand(connection, "dbo.sp_Shopkeeper_List");
        command.Parameters.AddWithValue("@FieldOfficerUserId", (object?)fieldOfficerUserId ?? DBNull.Value);
        var shops = new List<Shopkeeper>();

        connection.Open();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            shops.Add(MapShopkeeper(reader));
        }

        return shops;
    }

    public IReadOnlyList<AppUser> GetFieldOfficersByAgent(int agentUserId)
    {
        EnsureUserProfilePictureSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            SELECT Id, Name, Phone, PasswordHash AS [Password], Role, ShopCode,
                   ParentUserId, IsActive, CreatedAt, ProfilePictureUrl
            FROM dbo.tbl_Users
            WHERE ParentUserId = @AgentUserId AND Role = N'FieldOfficer'
            ORDER BY CreatedAt DESC, Id DESC;
            """, connection);
        command.Parameters.AddWithValue("@AgentUserId", agentUserId);
        var users = new List<AppUser>();

        connection.Open();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            users.Add(MapUser(reader));
        }

        return users;
    }

    public IReadOnlyList<Shopkeeper> GetShopkeepersByAgent(int agentUserId)
    {
        EnsureShopkeeperRegistrationSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            SELECT
                s.Id, s.ShopName, s.OwnerName, s.Phone, s.NidNumber, s.ProfilePhotoPath,
                s.BillboardPhotoPath, s.DivisionId, dv.Name AS DivisionName, s.DistrictId,
                ds.Name AS DistrictName, s.ThanaId, th.Name AS ThanaName, s.Address,
                s.Latitude, s.Longitude, s.Area, s.ShopType, u.PasswordHash AS [Password],
                s.ShopCode, s.FieldOfficerUserId, fo.Name AS FieldOfficerName,
                fo.Phone AS FieldOfficerPhone, s.RegisteredAt
            FROM dbo.tbl_Shopkeepers AS s
            INNER JOIN dbo.tbl_Users AS u ON u.Id = s.UserId
            INNER JOIN dbo.tbl_Users AS fo ON fo.Id = s.FieldOfficerUserId
            INNER JOIN dbo.tbl_Divisions AS dv ON dv.Id = s.DivisionId
            INNER JOIN dbo.tbl_Districts AS ds ON ds.Id = s.DistrictId
            INNER JOIN dbo.tbl_Thanas AS th ON th.Id = s.ThanaId
            WHERE fo.ParentUserId = @AgentUserId AND fo.Role = N'FieldOfficer'
            ORDER BY s.Id DESC;
            """, connection);
        command.Parameters.AddWithValue("@AgentUserId", agentUserId);
        var shops = new List<Shopkeeper>();

        connection.Open();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            shops.Add(MapShopkeeper(reader));
        }

        return shops;
    }

    public bool SetFieldOfficerActive(int agentUserId, int fieldOfficerUserId, bool isActive)
    {
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_Users
            SET IsActive = @IsActive
            WHERE Id = @FieldOfficerUserId
              AND ParentUserId = @AgentUserId
              AND Role = N'FieldOfficer';
            """, connection);
        command.Parameters.AddWithValue("@IsActive", isActive);
        command.Parameters.AddWithValue("@FieldOfficerUserId", fieldOfficerUserId);
        command.Parameters.AddWithValue("@AgentUserId", agentUserId);
        connection.Open();
        return command.ExecuteNonQuery() == 1;
    }

    public bool UpdateAgentProfile(int agentUserId, string name)
    {
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_Users SET Name = @Name
            WHERE Id = @AgentUserId AND Role = N'Agent';
            """, connection);
        command.Parameters.AddWithValue("@Name", name.Trim());
        command.Parameters.AddWithValue("@AgentUserId", agentUserId);
        connection.Open();
        return command.ExecuteNonQuery() == 1;
    }

    public AppUser RegisterFieldOfficer(int agentUserId, FieldOfficerRegistrationInput input, string? profilePhotoUrl = null)
    {
        EnsureAgentSchema();
        EnsureUserProfilePictureSchema();
        using var connection = CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        using var command = new SqlCommand("""
            INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, ParentUserId, ProfilePictureUrl)
            VALUES (@Name, @Phone, @Password, N'FieldOfficer', @AgentUserId, @ProfilePictureUrl);
            SELECT Id, Name, Phone, PasswordHash AS [Password], Role, ShopCode, ParentUserId, CreatedAt, ProfilePictureUrl
            FROM dbo.tbl_Users WHERE Id = CONVERT(INT, SCOPE_IDENTITY());
            """, connection, transaction) { CommandType = CommandType.Text };
        command.Parameters.AddWithValue("@Name", input.Name.Trim());
        command.Parameters.AddWithValue("@Phone", input.Phone.Trim());
        command.Parameters.AddWithValue("@Password", input.Password);
        command.Parameters.AddWithValue("@AgentUserId", agentUserId);
        command.Parameters.AddWithValue("@ProfilePictureUrl", (object?)profilePhotoUrl ?? DBNull.Value);

        try
        {
            EnsureAgentDistrict(connection, transaction, agentUserId, input.DistrictId!.Value);
            using var reader = command.ExecuteReader();
            var user = reader.Read() ? MapUser(reader) : throw new InvalidOperationException("Field force registration failed.");
            reader.Close();
            transaction.Commit();
            return user;
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627 or 51200 or 51201 or 51202)
        {
            transaction.Rollback();
            throw new InvalidOperationException(
                ex.Number is 2601 or 2627 ? "This mobile number already has an account." : ex.Message,
                ex);
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public void AssignAgentDistrict(int agentUserId, int districtId)
    {
        EnsureAgentSchema();
        using var connection = CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            EnsureAgentDistrict(connection, transaction, agentUserId, districtId);
            transaction.Commit();
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627 or 51200 or 51201 or 51202)
        {
            transaction.Rollback();
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    public AgentDistrictInfo? GetAgentDistrict(int agentUserId)
    {
        EnsureAgentSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            SELECT TOP (1) ad.DistrictId, ds.Name AS DistrictName, ds.DivisionId, dv.Name AS DivisionName
            FROM dbo.tbl_AgentDistricts ad
            INNER JOIN dbo.tbl_Districts ds ON ds.Id = ad.DistrictId
            INNER JOIN dbo.tbl_Divisions dv ON dv.Id = ds.DivisionId
            WHERE ad.AgentUserId = @AgentUserId;
            """, connection);
        command.Parameters.AddWithValue("@AgentUserId", agentUserId);
        connection.Open();
        using var reader = command.ExecuteReader();
        return reader.Read()
            ? new AgentDistrictInfo
            {
                DivisionId = reader.GetInt32(reader.GetOrdinal("DivisionId")),
                DivisionName = reader.GetString(reader.GetOrdinal("DivisionName")),
                DistrictId = reader.GetInt32(reader.GetOrdinal("DistrictId")),
                DistrictName = reader.GetString(reader.GetOrdinal("DistrictName"))
            }
            : null;
    }

    public CompanyDashboardViewModel GetCompanyDashboard(string companyName, string companyPhone)
    {
        EnsureCompanyDashboardSchema();
        using var connection = CreateConnection();
        using var command = CreateCommand(connection, "dbo.sp_CompanyDashboard_Get");

        connection.Open();
        using var reader = command.ExecuteReader();

        var model = new CompanyDashboardViewModel
        {
            CompanyName = companyName,
            CompanyPhone = companyPhone
        };

        if (reader.Read())
        {
            model = model with
            {
                TotalAgents = reader.GetInt32(reader.GetOrdinal("TotalAgents")),
                TotalFieldOfficers = reader.GetInt32(reader.GetOrdinal("TotalFieldOfficers")),
                TotalShopkeepers = reader.GetInt32(reader.GetOrdinal("TotalShopkeepers")),
                TotalCustomers = reader.GetInt32(reader.GetOrdinal("TotalCustomers")),
                TotalDeliveryMen = reader.GetInt32(reader.GetOrdinal("TotalDeliveryMen")),
                ActiveDeliveryMen = reader.GetInt32(reader.GetOrdinal("ActiveDeliveryMen")),
                TotalCustomerOrders = reader.GetInt32(reader.GetOrdinal("TotalCustomerOrders")),
                PendingCustomerOrders = reader.GetInt32(reader.GetOrdinal("PendingCustomerOrders")),
                ConfirmedCustomerOrders = reader.GetInt32(reader.GetOrdinal("ConfirmedCustomerOrders")),
                DeliveredCustomerOrders = reader.GetInt32(reader.GetOrdinal("DeliveredCustomerOrders")),
                CancelledCustomerOrders = reader.GetInt32(reader.GetOrdinal("CancelledCustomerOrders")),
                ReturnedCustomerOrders = reader.GetInt32(reader.GetOrdinal("ReturnedCustomerOrders")),
                FailedCustomerOrders = reader.GetInt32(reader.GetOrdinal("FailedCustomerOrders")),
                TotalProducts = reader.GetInt32(reader.GetOrdinal("TotalProducts")),
                LowStockProducts = reader.GetInt32(reader.GetOrdinal("LowStockProducts")),
                ActiveCampaigns = reader.GetInt32(reader.GetOrdinal("ActiveCampaigns")),
                PendingApprovals = reader.GetInt32(reader.GetOrdinal("PendingApprovals")),
                UnreadNotifications = reader.GetInt32(reader.GetOrdinal("UnreadNotifications")),
                TotalSalesAmount = reader.GetDecimal(reader.GetOrdinal("TotalSalesAmount")),
                TodaySalesAmount = reader.GetDecimal(reader.GetOrdinal("TodaySalesAmount")),
                MonthSalesAmount = reader.GetDecimal(reader.GetOrdinal("MonthSalesAmount")),
                TotalCashbackAmount = reader.GetDecimal(reader.GetOrdinal("TotalCashbackAmount")),
                TotalSystemCommission = reader.GetDecimal(reader.GetOrdinal("TotalSystemCommission")),
                WalletBalance = reader.GetDecimal(reader.GetOrdinal("WalletBalance")),
                WalletWithdrawable = reader.GetDecimal(reader.GetOrdinal("WalletWithdrawable")),
                WalletPending = reader.GetDecimal(reader.GetOrdinal("WalletPending"))
            };
        }

        reader.NextResult();
        var recentShops = new List<CompanyRecentShopViewModel>();
        while (reader.Read())
        {
            recentShops.Add(new CompanyRecentShopViewModel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                ShopName = reader.GetString(reader.GetOrdinal("ShopName")),
                OwnerName = reader.GetString(reader.GetOrdinal("OwnerName")),
                Phone = reader.GetString(reader.GetOrdinal("Phone")),
                ShopCode = reader.GetString(reader.GetOrdinal("ShopCode")),
                DistrictName = reader.GetString(reader.GetOrdinal("DistrictName")),
                ThanaName = reader.GetString(reader.GetOrdinal("ThanaName")),
                FieldOfficerName = reader.GetString(reader.GetOrdinal("FieldOfficerName")),
                RegisteredAt = reader.GetDateTime(reader.GetOrdinal("RegisteredAt"))
            });
        }

        reader.NextResult();
        var recentSales = new List<CompanyRecentSaleViewModel>();
        while (reader.Read())
        {
            recentSales.Add(new CompanyRecentSaleViewModel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                InvoiceNo = reader.GetString(reader.GetOrdinal("InvoiceNo")),
                ShopName = reader.GetString(reader.GetOrdinal("ShopName")),
                CustomerName = reader.GetString(reader.GetOrdinal("CustomerName")),
                CustomerPhone = reader.GetString(reader.GetOrdinal("CustomerPhone")),
                GrossAmount = reader.GetDecimal(reader.GetOrdinal("GrossAmount")),
                CashbackAmount = reader.GetDecimal(reader.GetOrdinal("CashbackAmount")),
                SystemCommission = reader.GetDecimal(reader.GetOrdinal("SystemCommission")),
                Status = reader.GetString(reader.GetOrdinal("Status")),
                SoldAt = reader.GetDateTime(reader.GetOrdinal("SoldAt"))
            });
        }

        reader.NextResult();
        var districts = new List<CompanyDistrictPerformanceViewModel>();
        while (reader.Read())
        {
            districts.Add(new CompanyDistrictPerformanceViewModel
            {
                DistrictName = reader.GetString(reader.GetOrdinal("DistrictName")),
                ShopkeeperCount = reader.GetInt32(reader.GetOrdinal("ShopkeeperCount")),
                CustomerCount = reader.GetInt32(reader.GetOrdinal("CustomerCount")),
                SalesAmount = reader.GetDecimal(reader.GetOrdinal("SalesAmount"))
            });
        }

        reader.NextResult();
        var campaigns = new List<CompanyCampaignViewModel>();
        while (reader.Read())
        {
            campaigns.Add(new CompanyCampaignViewModel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                Status = reader.GetString(reader.GetOrdinal("Status")),
                StartDate = reader.GetDateTime(reader.GetOrdinal("StartDate")),
                EndDate = reader.GetDateTime(reader.GetOrdinal("EndDate")),
                Reach = reader.GetInt32(reader.GetOrdinal("Reach")),
                Clicks = reader.GetInt32(reader.GetOrdinal("Clicks")),
                Conversions = reader.GetInt32(reader.GetOrdinal("Conversions")),
                SalesAmount = reader.GetDecimal(reader.GetOrdinal("SalesAmount"))
            });
        }

        reader.NextResult();
        var topProducts = new List<CompanyProductPerformanceViewModel>();
        while (reader.Read())
        {
            topProducts.Add(new CompanyProductPerformanceViewModel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                Category = reader.GetString(reader.GetOrdinal("Category")),
                ShopName = reader.GetString(reader.GetOrdinal("ShopName")),
                StockQuantity = reader.GetInt32(reader.GetOrdinal("StockQuantity")),
                SoldQuantity = reader.GetInt32(reader.GetOrdinal("SoldQuantity")),
                SalesAmount = reader.GetDecimal(reader.GetOrdinal("SalesAmount"))
            });
        }

        reader.NextResult();
        var users = new List<CompanyUserViewModel>();
        while (reader.Read())
        {
            users.Add(new CompanyUserViewModel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                Phone = reader.GetString(reader.GetOrdinal("Phone")),
                Role = reader.GetString(reader.GetOrdinal("Role")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt"))
            });
        }

        reader.NextResult();
        var notifications = new List<CompanyNotificationViewModel>();
        while (reader.Read())
        {
            notifications.Add(new CompanyNotificationViewModel
            {
                Id = reader.GetInt64(reader.GetOrdinal("Id")),
                Title = reader.GetString(reader.GetOrdinal("Title")),
                Message = reader.GetString(reader.GetOrdinal("Message")),
                IsRead = reader.GetBoolean(reader.GetOrdinal("IsRead")),
                CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt"))
            });
        }

        reader.NextResult();
        var activities = new List<CompanyActivityViewModel>();
        while (reader.Read())
        {
            activities.Add(new CompanyActivityViewModel
            {
                Type = reader.GetString(reader.GetOrdinal("Type")),
                Title = reader.GetString(reader.GetOrdinal("Title")),
                Detail = reader.GetString(reader.GetOrdinal("Detail")),
                OccurredAt = reader.GetDateTime(reader.GetOrdinal("OccurredAt"))
            });
        }

        reader.NextResult();
        var settings = reader.Read()
            ? new CompanySettingsViewModel
            {
                CommissionRate = reader.GetDecimal(reader.GetOrdinal("CommissionRate")),
                CashbackRate = reader.GetDecimal(reader.GetOrdinal("CashbackRate")),
                DeliveryCharge = reader.GetDecimal(reader.GetOrdinal("DeliveryCharge")),
                SupportPhone = reader.GetString(reader.GetOrdinal("SupportPhone")),
                PaymentGateway = reader.GetString(reader.GetOrdinal("PaymentGateway")),
                RegistrationFee = HasColumn(reader, "RegistrationFee") && !reader.IsDBNull(reader.GetOrdinal("RegistrationFee"))
                    ? reader.GetDecimal(reader.GetOrdinal("RegistrationFee"))
                    : 50.00m,
                IsRegistrationFeeActive = !HasColumn(reader, "IsRegistrationFeeActive") || reader.GetBoolean(reader.GetOrdinal("IsRegistrationFeeActive"))
            }
            : new CompanySettingsViewModel();

        return model with
        {
            RecentShops = recentShops,
            RecentSales = recentSales,
            Districts = districts,
            Campaigns = campaigns,
            TopProducts = topProducts,
            Users = users,
            Notifications = notifications,
            Activities = activities,
            Settings = settings
        };
    }

    public CompanyNetworkViewModel GetCompanyNetwork()
    {
        EnsureShopkeeperRegistrationSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            SELECT
                agent.Id AS UserId, agent.Name, agent.Phone, agent.IsActive, agent.CreatedAt,
                COALESCE(district.Name, N'District not assigned') AS DistrictName
            FROM dbo.tbl_Users AS agent
            LEFT JOIN dbo.tbl_AgentDistricts AS assignment ON assignment.AgentUserId = agent.Id
            LEFT JOIN dbo.tbl_Districts AS district ON district.Id = assignment.DistrictId
            WHERE agent.Role = N'Agent'
            ORDER BY agent.Name, agent.Id;

            SELECT
                delivery.UserId, delivery.AgentUserId AS ParentUserId,
                users.Name, users.Phone, users.IsActive, users.CreatedAt,
                CONCAT(district.Name, N', ', thana.Name) AS Location,
                CONCAT(COALESCE(delivery.VehicleType, N''), CASE WHEN delivery.VehicleNumber IS NULL THEN N'' ELSE N' - ' + delivery.VehicleNumber END) AS Detail
            FROM dbo.tbl_DeliveryMen AS delivery
            INNER JOIN dbo.tbl_Users AS users ON users.Id = delivery.UserId
            INNER JOIN dbo.tbl_Districts AS district ON district.Id = delivery.DistrictId
            INNER JOIN dbo.tbl_Thanas AS thana ON thana.Id = delivery.ThanaId
            ORDER BY users.Name, delivery.Id;

            SELECT Id AS UserId, ParentUserId, Name, Phone, IsActive, CreatedAt
            FROM dbo.tbl_Users
            WHERE Role = N'FieldOfficer'
            ORDER BY Name, Id;

            SELECT
                shop.UserId, shop.FieldOfficerUserId, shop.ShopName, shop.OwnerName,
                shop.Phone, shop.ShopCode, users.IsActive, shop.RegisteredAt AS CreatedAt,
                CONCAT(district.Name, N', ', thana.Name) AS Location
            FROM dbo.tbl_Shopkeepers AS shop
            INNER JOIN dbo.tbl_Users AS users ON users.Id = shop.UserId
            INNER JOIN dbo.tbl_Districts AS district ON district.Id = shop.DistrictId
            INNER JOIN dbo.tbl_Thanas AS thana ON thana.Id = shop.ThanaId
            ORDER BY shop.ShopName, shop.Id;

            SELECT
                users.Id AS UserId,
                COALESCE(users.Name, customer.Name) AS Name,
                customer.Phone,
                COALESCE(customer.Address, N'') AS Address,
                CONVERT(BIT, CASE WHEN users.Id IS NULL THEN customer.IsActive ELSE users.IsActive END) AS IsActive,
                CASE WHEN users.Id IS NULL THEN customer.CreatedAt ELSE users.CreatedAt END AS CreatedAt
            FROM dbo.tbl_Customers AS customer
            LEFT JOIN dbo.tbl_Users AS users
                ON users.Phone = customer.Phone AND users.Role = N'Customer'
            UNION ALL
            SELECT users.Id, users.Name, users.Phone, N'', users.IsActive, users.CreatedAt
            FROM dbo.tbl_Users AS users
            WHERE users.Role = N'Customer'
              AND NOT EXISTS (SELECT 1 FROM dbo.tbl_Customers AS customer WHERE customer.Phone = users.Phone)
            ORDER BY Name, Phone;
            """, connection);

        connection.Open();
        using var reader = command.ExecuteReader();

        var agents = new List<CompanyAgentNetworkViewModel>();
        while (reader.Read())
        {
            agents.Add(new CompanyAgentNetworkViewModel
            {
                UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                Phone = reader.GetString(reader.GetOrdinal("Phone")),
                DistrictName = reader.GetString(reader.GetOrdinal("DistrictName")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt"))
            });
        }

        reader.NextResult();
        var deliveryMen = new List<CompanyNetworkMemberViewModel>();
        while (reader.Read())
        {
            deliveryMen.Add(new CompanyNetworkMemberViewModel
            {
                UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                ParentUserId = reader.IsDBNull(reader.GetOrdinal("ParentUserId"))
                    ? null
                    : reader.GetInt32(reader.GetOrdinal("ParentUserId")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                Phone = reader.GetString(reader.GetOrdinal("Phone")),
                Location = reader.GetString(reader.GetOrdinal("Location")),
                Detail = reader.GetString(reader.GetOrdinal("Detail")).Trim(' ', '-'),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt"))
            });
        }

        reader.NextResult();
        var fieldForces = new List<(int UserId, int? ParentUserId, string Name, string Phone, bool IsActive, DateTime CreatedAt)>();
        while (reader.Read())
        {
            fieldForces.Add((
                reader.GetInt32(reader.GetOrdinal("UserId")),
                reader.IsDBNull(reader.GetOrdinal("ParentUserId")) ? null : reader.GetInt32(reader.GetOrdinal("ParentUserId")),
                reader.GetString(reader.GetOrdinal("Name")),
                reader.GetString(reader.GetOrdinal("Phone")),
                reader.GetBoolean(reader.GetOrdinal("IsActive")),
                reader.GetDateTime(reader.GetOrdinal("CreatedAt"))));
        }

        reader.NextResult();
        var shops = new List<CompanyShopkeeperNetworkViewModel>();
        while (reader.Read())
        {
            shops.Add(new CompanyShopkeeperNetworkViewModel
            {
                UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                FieldOfficerUserId = reader.GetInt32(reader.GetOrdinal("FieldOfficerUserId")),
                ShopName = reader.GetString(reader.GetOrdinal("ShopName")),
                OwnerName = reader.GetString(reader.GetOrdinal("OwnerName")),
                Phone = reader.GetString(reader.GetOrdinal("Phone")),
                ShopCode = reader.GetString(reader.GetOrdinal("ShopCode")),
                Location = reader.GetString(reader.GetOrdinal("Location")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt"))
            });
        }

        reader.NextResult();
        var customers = new List<CompanyCustomerNetworkViewModel>();
        while (reader.Read())
        {
            customers.Add(new CompanyCustomerNetworkViewModel
            {
                UserId = reader.IsDBNull(reader.GetOrdinal("UserId")) ? null : reader.GetInt32(reader.GetOrdinal("UserId")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                Phone = reader.GetString(reader.GetOrdinal("Phone")),
                Address = reader.GetString(reader.GetOrdinal("Address")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt"))
            });
        }

        var agentIds = agents.Select(agent => agent.UserId).ToHashSet();
        var fieldForceIds = fieldForces.Select(fieldForce => fieldForce.UserId).ToHashSet();
        var unassignedFieldForces = fieldForces
            .Where(person => person.ParentUserId is null || !agentIds.Contains(person.ParentUserId.Value))
            .Select(person => new CompanyFieldForceNetworkViewModel
            {
                UserId = person.UserId,
                Name = person.Name,
                Phone = person.Phone,
                IsActive = person.IsActive,
                CreatedAt = person.CreatedAt,
                Shopkeepers = shops.Where(shop => shop.FieldOfficerUserId == person.UserId).ToList()
            })
            .ToList();
        var populatedAgents = agents.Select(agent => new CompanyAgentNetworkViewModel
        {
            UserId = agent.UserId,
            Name = agent.Name,
            Phone = agent.Phone,
            DistrictName = agent.DistrictName,
            IsActive = agent.IsActive,
            CreatedAt = agent.CreatedAt,
            DeliveryMen = deliveryMen.Where(person => person.ParentUserId == agent.UserId).ToList(),
            FieldForces = fieldForces
                .Where(person => person.ParentUserId == agent.UserId)
                .Select(person => new CompanyFieldForceNetworkViewModel
                {
                    UserId = person.UserId,
                    Name = person.Name,
                    Phone = person.Phone,
                    IsActive = person.IsActive,
                    CreatedAt = person.CreatedAt,
                    Shopkeepers = shops.Where(shop => shop.FieldOfficerUserId == person.UserId).ToList()
                })
                .ToList()
        }).ToList();

        return new CompanyNetworkViewModel
        {
            Agents = populatedAgents,
            UnassignedDeliveryMen = deliveryMen
                .Where(person => person.ParentUserId is null || !agentIds.Contains(person.ParentUserId.Value))
                .ToList(),
            UnassignedFieldForces = unassignedFieldForces,
            UnassignedShopkeepers = shops
                .Where(shop => !fieldForceIds.Contains(shop.FieldOfficerUserId))
                .ToList(),
            Customers = customers
        };
    }

    public void CreateCompanyCampaign(CompanyCampaignInputModel input)
    {
        EnsureCompanyDashboardSchema();
        if (string.IsNullOrWhiteSpace(input.Name) || input.EndDate.Date < input.StartDate.Date)
        {
            throw new InvalidOperationException("Campaign name and date range are required.");
        }

        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            INSERT INTO dbo.tbl_CompanyCampaigns (Name, StartDate, EndDate)
            VALUES (@Name, @StartDate, @EndDate);
            """, connection);
        command.Parameters.AddWithValue("@Name", input.Name.Trim());
        command.Parameters.AddWithValue("@StartDate", input.StartDate.Date);
        command.Parameters.AddWithValue("@EndDate", input.EndDate.Date);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public IReadOnlyList<CompanyBulletinViewModel> GetCompanyBulletins(bool activeOnly = false)
    {
        EnsureCompanyDashboardSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            SELECT Id, Message, LinkUrl, IsActive, StartAt, EndAt, CreatedAt
            FROM dbo.tbl_CompanyBulletins
            WHERE @ActiveOnly = 0
               OR (IsActive = 1
                   AND StartAt <= SYSUTCDATETIME()
                   AND (EndAt IS NULL OR EndAt >= SYSUTCDATETIME()))
            ORDER BY CreatedAt DESC, Id DESC;
            """, connection);
        command.Parameters.AddWithValue("@ActiveOnly", activeOnly);
        connection.Open();
        using var reader = command.ExecuteReader();

        var bulletins = new List<CompanyBulletinViewModel>();
        while (reader.Read())
        {
            bulletins.Add(new CompanyBulletinViewModel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                Message = reader.GetString(reader.GetOrdinal("Message")),
                LinkUrl = reader.IsDBNull(reader.GetOrdinal("LinkUrl")) ? null : reader.GetString(reader.GetOrdinal("LinkUrl")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                StartAt = DateTime.SpecifyKind(reader.GetDateTime(reader.GetOrdinal("StartAt")), DateTimeKind.Utc),
                EndAt = reader.IsDBNull(reader.GetOrdinal("EndAt"))
                    ? null
                    : DateTime.SpecifyKind(reader.GetDateTime(reader.GetOrdinal("EndAt")), DateTimeKind.Utc),
                CreatedAt = DateTime.SpecifyKind(reader.GetDateTime(reader.GetOrdinal("CreatedAt")), DateTimeKind.Utc)
            });
        }

        return bulletins;
    }

    public void CreateCompanyBulletin(CompanyBulletinInputModel input)
    {
        EnsureCompanyDashboardSchema();
        if (string.IsNullOrWhiteSpace(input.Message))
        {
            throw new InvalidOperationException("Bulletin message is required.");
        }

        var startAt = input.StartAt == default ? DateTime.Now : input.StartAt;
        if (input.EndAt is not null && input.EndAt <= startAt)
        {
            throw new InvalidOperationException("Bulletin end time must be after the start time.");
        }
        if (!string.IsNullOrWhiteSpace(input.LinkUrl)
            && (!Uri.TryCreate(input.LinkUrl.Trim(), UriKind.Absolute, out var bulletinLink)
                || (bulletinLink.Scheme != Uri.UriSchemeHttp && bulletinLink.Scheme != Uri.UriSchemeHttps)))
        {
            throw new InvalidOperationException("Bulletin link must be a valid HTTP or HTTPS URL.");
        }

        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            INSERT INTO dbo.tbl_CompanyBulletins (Message, LinkUrl, StartAt, EndAt)
            VALUES (@Message, @LinkUrl, @StartAt, @EndAt);
            """, connection);
        command.Parameters.AddWithValue("@Message", input.Message.Trim());
        command.Parameters.AddWithValue("@LinkUrl", string.IsNullOrWhiteSpace(input.LinkUrl) ? DBNull.Value : input.LinkUrl.Trim());
        command.Parameters.AddWithValue("@StartAt", startAt.ToUniversalTime());
        command.Parameters.AddWithValue("@EndAt", input.EndAt is null ? DBNull.Value : input.EndAt.Value.ToUniversalTime());
        connection.Open();
        command.ExecuteNonQuery();
    }

    public void SetCompanyBulletinActive(int bulletinId, bool isActive)
    {
        EnsureCompanyDashboardSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_CompanyBulletins
            SET IsActive = @IsActive
            WHERE Id = @BulletinId;
            """, connection);
        command.Parameters.AddWithValue("@BulletinId", bulletinId);
        command.Parameters.AddWithValue("@IsActive", isActive);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public void SaveCompanySettings(CompanySettingsInputModel input)
    {
        EnsureCompanyDashboardSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_CompanySettings
            SET CommissionRate = @CommissionRate,
                CashbackRate = @CashbackRate,
                DeliveryCharge = @DeliveryCharge,
                SupportPhone = @SupportPhone,
                PaymentGateway = @PaymentGateway,
                RegistrationFee = @RegistrationFee,
                IsRegistrationFeeActive = @IsRegistrationFeeActive,
                UpdatedAt = SYSUTCDATETIME()
            WHERE Id = 1;
            """, connection);
        command.Parameters.AddWithValue("@CommissionRate", Math.Max(0, input.CommissionRate));
        command.Parameters.AddWithValue("@CashbackRate", Math.Max(0, input.CashbackRate));
        command.Parameters.AddWithValue("@DeliveryCharge", Math.Max(0, input.DeliveryCharge));
        command.Parameters.AddWithValue("@SupportPhone", input.SupportPhone?.Trim() ?? "");
        command.Parameters.AddWithValue("@PaymentGateway", input.PaymentGateway?.Trim() ?? "");
        command.Parameters.AddWithValue("@RegistrationFee", Math.Max(0, input.RegistrationFee));
        command.Parameters.AddWithValue("@IsRegistrationFeeActive", input.IsRegistrationFeeActive);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public void UpdateRegistrationFee(decimal registrationFee, bool isRegistrationFeeActive)
    {
        EnsureCompanyDashboardSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_CompanySettings
            SET RegistrationFee = @RegistrationFee,
                IsRegistrationFeeActive = @IsRegistrationFeeActive,
                UpdatedAt = SYSUTCDATETIME()
            WHERE Id = 1;
            """, connection);
        command.Parameters.AddWithValue("@RegistrationFee", Math.Max(0, registrationFee));
        command.Parameters.AddWithValue("@IsRegistrationFeeActive", isRegistrationFeeActive);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public void SetCompanyUserActive(int userId, bool isActive)
    {
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_Users
            SET IsActive = @IsActive
            WHERE Id = @UserId AND Role <> N'Company';
            """, connection);
        command.Parameters.AddWithValue("@UserId", userId);
        command.Parameters.AddWithValue("@IsActive", isActive);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public Shopkeeper? GetShopkeeperByPhone(string phone)
    {
        EnsureShopkeeperRegistrationSchema();
        using var connection = CreateConnection();
        using var command = CreateCommand(connection, "dbo.sp_Shopkeeper_GetByPhone");
        command.Parameters.AddWithValue("@Phone", phone);

        connection.Open();
        using var reader = command.ExecuteReader();
        return reader.Read() ? MapShopkeeper(reader) : null;
    }

    public void UpdateShopkeeperProfilePhoto(int shopId, string photoPath)
    {
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_Shopkeepers
            SET ProfilePhotoPath = @ProfilePhotoPath
            WHERE Id = @ShopId
            """, connection);
        command.Parameters.AddWithValue("@ShopId", shopId);
        command.Parameters.AddWithValue("@ProfilePhotoPath", photoPath);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public void UpdateShopkeeperBillboardPhoto(int shopId, string photoPath)
    {
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_Shopkeepers
            SET BillboardPhotoPath = @BillboardPhotoPath
            WHERE Id = @ShopId
            """, connection);
        command.Parameters.AddWithValue("@ShopId", shopId);
        command.Parameters.AddWithValue("@BillboardPhotoPath", photoPath);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public void UpdateShopkeeper(int fieldOfficerUserId, FieldOfficerShopEditInputModel input)
    {
        EnsureShopkeeperRegistrationSchema();
        if (input.ShopkeeperId <= 0
            || string.IsNullOrWhiteSpace(input.ShopName)
            || string.IsNullOrWhiteSpace(input.OwnerName)
            || string.IsNullOrWhiteSpace(input.Phone)
            || string.IsNullOrWhiteSpace(input.Address)
            || string.IsNullOrWhiteSpace(input.Area)
            || string.IsNullOrWhiteSpace(input.ShopType))
            throw new InvalidOperationException("Complete all required shopkeeper fields.");
        if (input.Latitude is < -90 or > 90 || input.Longitude is < -180 or > 180)
            throw new InvalidOperationException("Enter a valid latitude and longitude.");
        if (!string.IsNullOrWhiteSpace(input.NewPassword) && input.NewPassword.Trim().Length < 4)
            throw new InvalidOperationException("New password must be at least 4 characters.");

        const string sql = """
            IF NOT EXISTS (
                SELECT 1 FROM dbo.tbl_Shopkeepers
                WHERE Id = @ShopkeeperId AND FieldOfficerUserId = @FieldOfficerUserId
            )
                THROW 51300, N'You can edit only your own shopkeepers.', 1;
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.tbl_Districts district
                INNER JOIN dbo.tbl_Thanas thana ON thana.Id = @ThanaId AND thana.DistrictId = district.Id
                WHERE district.Id = @DistrictId AND district.DivisionId = @DivisionId
            )
                THROW 51301, N'Select a valid division, district and thana.', 1;

            DECLARE @ShopkeeperUserId INT;
            SELECT @ShopkeeperUserId = UserId FROM dbo.tbl_Shopkeepers WHERE Id = @ShopkeeperId;
            IF EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = @Phone AND Id <> @ShopkeeperUserId)
                THROW 51302, N'This mobile number already has another account.', 1;

            BEGIN TRANSACTION;
            UPDATE dbo.tbl_Shopkeepers
            SET ShopName = @ShopName,
                OwnerName = @OwnerName,
                Phone = @Phone,
                NidNumber = NULLIF(@NidNumber, N''),
                DivisionId = @DivisionId,
                DistrictId = @DistrictId,
                ThanaId = @ThanaId,
                Address = @Address,
                Latitude = @Latitude,
                Longitude = @Longitude,
                Area = @Area,
                ShopType = @ShopType
            WHERE Id = @ShopkeeperId;

            UPDATE dbo.tbl_Users
            SET Name = @OwnerName,
                Phone = @Phone,
                PasswordHash = CASE WHEN NULLIF(@NewPassword, N'') IS NULL THEN PasswordHash ELSE @NewPassword END
            WHERE Id = @ShopkeeperUserId;
            COMMIT TRANSACTION;
            """;
        using var connection = CreateConnection();
        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@FieldOfficerUserId", fieldOfficerUserId);
        command.Parameters.AddWithValue("@ShopkeeperId", input.ShopkeeperId);
        command.Parameters.AddWithValue("@ShopName", input.ShopName.Trim());
        command.Parameters.AddWithValue("@OwnerName", input.OwnerName.Trim());
        command.Parameters.AddWithValue("@Phone", input.Phone.Trim());
        command.Parameters.AddWithValue("@NidNumber", input.NidNumber?.Trim() ?? "");
        command.Parameters.AddWithValue("@DivisionId", input.DivisionId);
        command.Parameters.AddWithValue("@DistrictId", input.DistrictId);
        command.Parameters.AddWithValue("@ThanaId", input.ThanaId);
        command.Parameters.AddWithValue("@Address", input.Address.Trim());
        command.Parameters.AddWithValue("@Latitude", input.Latitude);
        command.Parameters.AddWithValue("@Longitude", input.Longitude);
        command.Parameters.AddWithValue("@Area", input.Area.Trim());
        command.Parameters.AddWithValue("@ShopType", input.ShopType.Trim());
        command.Parameters.AddWithValue("@NewPassword", input.NewPassword?.Trim() ?? "");
        try
        {
            connection.Open();
            command.ExecuteNonQuery();
        }
        catch (SqlException ex) when (ex.Number is 51300 or 51301 or 51302 or 2601 or 2627)
        {
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    private static void EnsureAgentDistrict(
        SqlConnection connection,
        SqlTransaction transaction,
        int agentUserId,
        int districtId)
    {
        using var command = new SqlCommand("""
            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Districts WHERE Id = @DistrictId)
                THROW 51202, N'The selected district does not exist.', 1;
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

    private void EnsureShopkeeperRegistrationSchema()
    {
        if (_shopkeeperSchemaReady) return;
        lock (ShopkeeperSchemaLock)
        {
            if (_shopkeeperSchemaReady) return;
            using var connection = CreateConnection();
            using var command = new SqlCommand("""
                IF COL_LENGTH(N'dbo.tbl_Shopkeepers', N'NidNumber') IS NULL
                    ALTER TABLE dbo.tbl_Shopkeepers ADD NidNumber NVARCHAR(30) NULL;
                IF COL_LENGTH(N'dbo.tbl_Shopkeepers', N'ProfilePhotoPath') IS NULL
                    ALTER TABLE dbo.tbl_Shopkeepers ADD ProfilePhotoPath NVARCHAR(500) NULL;
                IF COL_LENGTH(N'dbo.tbl_Shopkeepers', N'BillboardPhotoPath') IS NULL
                    ALTER TABLE dbo.tbl_Shopkeepers ADD BillboardPhotoPath NVARCHAR(500) NULL;

                EXEC(N'
                CREATE OR ALTER PROCEDURE dbo.sp_Shopkeeper_Register
                    @ShopName NVARCHAR(150),
                    @OwnerName NVARCHAR(150),
                    @Phone NVARCHAR(20),
                    @NidNumber NVARCHAR(30) = NULL,
                    @ProfilePhotoPath NVARCHAR(500) = NULL,
                    @BillboardPhotoPath NVARCHAR(500) = NULL,
                    @DivisionId INT,
                    @DistrictId INT,
                    @ThanaId INT,
                    @Address NVARCHAR(250),
                    @Latitude DECIMAL(9,6),
                    @Longitude DECIMAL(9,6),
                    @Area NVARCHAR(150),
                    @ShopType NVARCHAR(100),
                    @Password NVARCHAR(200),
                    @FieldOfficerUserId INT
                AS
                BEGIN
                    SET NOCOUNT ON;
                    SET XACT_ABORT ON;

                    IF EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = @Phone)
                        THROW 51000, N''This mobile number already has an account.'', 1;

                    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Id = @FieldOfficerUserId AND Role = N''FieldOfficer'' AND IsActive = 1)
                        THROW 51001, N''Invalid field force user.'', 1;

                    BEGIN TRANSACTION;

                    INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, ParentUserId)
                    VALUES (@OwnerName, @Phone, @Password, N''Shopkeeper'', @FieldOfficerUserId);

                    DECLARE @UserId INT = SCOPE_IDENTITY();
                    DECLARE @ShopId INT;

                    INSERT INTO dbo.tbl_Shopkeepers
                        (ShopName, OwnerName, Phone, NidNumber, ProfilePhotoPath, BillboardPhotoPath,
                         DivisionId, DistrictId, ThanaId, Address, Latitude, Longitude, Area, ShopType,
                         ShopCode, UserId, FieldOfficerUserId)
                    VALUES
                        (@ShopName, @OwnerName, @Phone, NULLIF(LTRIM(RTRIM(@NidNumber)), N''''),
                         @ProfilePhotoPath, @BillboardPhotoPath, @DivisionId, @DistrictId, @ThanaId,
                         @Address, @Latitude, @Longitude, @Area, @ShopType, N''TEMP'', @UserId, @FieldOfficerUserId);

                    SET @ShopId = SCOPE_IDENTITY();
                    DECLARE @ShopCode NVARCHAR(20) = CONCAT(N''MS'', FORMAT(@ShopId + 1000, N''0000''));

                    UPDATE dbo.tbl_Shopkeepers SET ShopCode = @ShopCode WHERE Id = @ShopId;
                    UPDATE dbo.tbl_Users SET ShopCode = @ShopCode WHERE Id = @UserId;

                    COMMIT TRANSACTION;

                    SELECT s.Id, s.ShopName, s.OwnerName, s.Phone, s.NidNumber, s.ProfilePhotoPath,
                           s.BillboardPhotoPath, s.DivisionId, dv.Name AS DivisionName, s.DistrictId,
                           ds.Name AS DistrictName, s.ThanaId, th.Name AS ThanaName, s.Address,
                           s.Latitude, s.Longitude, s.Area, s.ShopType, @Password AS [Password],
                           s.ShopCode, s.FieldOfficerUserId, fo.Name AS FieldOfficerName,
                           fo.Phone AS FieldOfficerPhone, s.RegisteredAt
                    FROM dbo.tbl_Shopkeepers AS s
                    INNER JOIN dbo.tbl_Divisions AS dv ON dv.Id = s.DivisionId
                    INNER JOIN dbo.tbl_Districts AS ds ON ds.Id = s.DistrictId
                    INNER JOIN dbo.tbl_Thanas AS th ON th.Id = s.ThanaId
                    INNER JOIN dbo.tbl_Users AS fo ON fo.Id = s.FieldOfficerUserId
                    WHERE s.Id = @ShopId;
                END');

                EXEC(N'
                CREATE OR ALTER PROCEDURE dbo.sp_Shopkeeper_List
                    @FieldOfficerUserId INT = NULL
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT
                        s.Id, s.ShopName, s.OwnerName, s.Phone, s.NidNumber, s.ProfilePhotoPath,
                        s.BillboardPhotoPath, s.DivisionId, dv.Name AS DivisionName, s.DistrictId,
                        ds.Name AS DistrictName, s.ThanaId, th.Name AS ThanaName, s.Address,
                        s.Latitude, s.Longitude, s.Area, s.ShopType, u.PasswordHash AS [Password],
                        s.ShopCode, s.FieldOfficerUserId, fo.Name AS FieldOfficerName,
                        fo.Phone AS FieldOfficerPhone, s.RegisteredAt
                    FROM dbo.tbl_Shopkeepers AS s
                    INNER JOIN dbo.tbl_Users AS u ON u.Id = s.UserId
                    INNER JOIN dbo.tbl_Users AS fo ON fo.Id = s.FieldOfficerUserId
                    INNER JOIN dbo.tbl_Divisions AS dv ON dv.Id = s.DivisionId
                    INNER JOIN dbo.tbl_Districts AS ds ON ds.Id = s.DistrictId
                    INNER JOIN dbo.tbl_Thanas AS th ON th.Id = s.ThanaId
                    WHERE @FieldOfficerUserId IS NULL OR s.FieldOfficerUserId = @FieldOfficerUserId
                    ORDER BY s.Id DESC;
                END');

                EXEC(N'
                CREATE OR ALTER PROCEDURE dbo.sp_Shopkeeper_GetByPhone
                    @Phone NVARCHAR(20)
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT TOP (1)
                        s.Id, s.ShopName, s.OwnerName, s.Phone, s.NidNumber, s.ProfilePhotoPath,
                        s.BillboardPhotoPath, s.DivisionId, dv.Name AS DivisionName, s.DistrictId,
                        ds.Name AS DistrictName, s.ThanaId, th.Name AS ThanaName, s.Address,
                        s.Latitude, s.Longitude, s.Area, s.ShopType, u.PasswordHash AS [Password],
                        s.ShopCode, s.FieldOfficerUserId, fo.Name AS FieldOfficerName,
                        fo.Phone AS FieldOfficerPhone, s.RegisteredAt
                    FROM dbo.tbl_Shopkeepers AS s
                    INNER JOIN dbo.tbl_Users AS u ON u.Id = s.UserId
                    INNER JOIN dbo.tbl_Users AS fo ON fo.Id = s.FieldOfficerUserId
                    INNER JOIN dbo.tbl_Divisions AS dv ON dv.Id = s.DivisionId
                    INNER JOIN dbo.tbl_Districts AS ds ON ds.Id = s.DistrictId
                    INNER JOIN dbo.tbl_Thanas AS th ON th.Id = s.ThanaId
                    WHERE s.Phone = @Phone;
                END');
                """, connection);
            connection.Open();
            command.ExecuteNonQuery();
            _shopkeeperSchemaReady = true;
        }
    }

    private void EnsureAgentSchema()
    {
        if (_agentSchemaReady) return;
        lock (AgentSchemaLock)
        {
            if (_agentSchemaReady) return;
            using var connection = CreateConnection();
            using var command = new SqlCommand("""
                IF OBJECT_ID(N'dbo.tbl_AgentDistricts', N'U') IS NULL
                CREATE TABLE dbo.tbl_AgentDistricts (
                    AgentUserId INT NOT NULL PRIMARY KEY,
                    DistrictId INT NOT NULL CONSTRAINT UQ_tbl_AgentDistricts_District UNIQUE,
                    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_AgentDistricts_CreatedAt DEFAULT SYSUTCDATETIME(),
                    CONSTRAINT FK_tbl_AgentDistricts_User FOREIGN KEY (AgentUserId) REFERENCES dbo.tbl_Users(Id),
                    CONSTRAINT FK_tbl_AgentDistricts_District FOREIGN KEY (DistrictId) REFERENCES dbo.tbl_Districts(Id)
                );

                IF COL_LENGTH(N'dbo.tbl_Users', N'ProfilePictureUrl') IS NULL
                    ALTER TABLE dbo.tbl_Users ADD ProfilePictureUrl NVARCHAR(500) NULL;

                EXEC(N'
                CREATE OR ALTER PROCEDURE dbo.sp_FieldOfficer_ListByAgent
                    @AgentUserId INT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT
                        Id, Name, Phone, PasswordHash AS [Password], Role, ShopCode,
                        ParentUserId, CreatedAt, ProfilePictureUrl
                    FROM dbo.tbl_Users
                    WHERE Role = N''FieldOfficer''
                      AND ParentUserId = @AgentUserId
                      AND IsActive = 1
                    ORDER BY Id DESC;
                END');
                """, connection);
            connection.Open();
            command.ExecuteNonQuery();
            _agentSchemaReady = true;
        }
    }

    private void EnsureCompanyDashboardSchema()
    {
        if (_companyDashboardSchemaReady) return;
        lock (CompanyDashboardSchemaLock)
        {
            if (_companyDashboardSchemaReady) return;
            using var connection = CreateConnection();
            connection.Open();
            using (var schemaCommand = new SqlCommand("""
                IF OBJECT_ID(N'dbo.tbl_CompanyCampaigns', N'U') IS NULL
                CREATE TABLE dbo.tbl_CompanyCampaigns (
                    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_CompanyCampaigns PRIMARY KEY,
                    Name NVARCHAR(150) NOT NULL,
                    StartDate DATE NOT NULL,
                    EndDate DATE NOT NULL,
                    Reach INT NOT NULL CONSTRAINT DF_tbl_CompanyCampaigns_Reach DEFAULT (0),
                    Clicks INT NOT NULL CONSTRAINT DF_tbl_CompanyCampaigns_Clicks DEFAULT (0),
                    Conversions INT NOT NULL CONSTRAINT DF_tbl_CompanyCampaigns_Conversions DEFAULT (0),
                    SalesAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_tbl_CompanyCampaigns_Sales DEFAULT (0),
                    IsActive BIT NOT NULL CONSTRAINT DF_tbl_CompanyCampaigns_IsActive DEFAULT (1),
                    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_CompanyCampaigns_CreatedAt DEFAULT SYSUTCDATETIME()
                );

                IF OBJECT_ID(N'dbo.tbl_CompanySettings', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.tbl_CompanySettings (
                        Id INT NOT NULL CONSTRAINT PK_tbl_CompanySettings PRIMARY KEY,
                        CommissionRate DECIMAL(5,2) NOT NULL,
                        CashbackRate DECIMAL(5,2) NOT NULL,
                        DeliveryCharge DECIMAL(18,2) NOT NULL,
                        SupportPhone NVARCHAR(30) NOT NULL,
                        PaymentGateway NVARCHAR(100) NOT NULL,
                        RegistrationFee DECIMAL(18,2) NOT NULL CONSTRAINT DF_tbl_CompanySettings_RegistrationFee DEFAULT (50.00),
                        IsRegistrationFeeActive BIT NOT NULL CONSTRAINT DF_tbl_CompanySettings_IsRegistrationFeeActive DEFAULT (1),
                        UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_CompanySettings_UpdatedAt DEFAULT SYSUTCDATETIME()
                    );
                    EXEC(N'INSERT INTO dbo.tbl_CompanySettings (Id, CommissionRate, CashbackRate, DeliveryCharge, SupportPhone, PaymentGateway, RegistrationFee, IsRegistrationFeeActive) VALUES (1, 1, 2, 60, N''09678-123456'', N''Cash / Manual'', 50.00, 1)');
                END
                ELSE
                BEGIN
                    IF COL_LENGTH(N'dbo.tbl_CompanySettings', N'RegistrationFee') IS NULL
                    BEGIN
                        EXEC(N'ALTER TABLE dbo.tbl_CompanySettings ADD RegistrationFee DECIMAL(18,2) NOT NULL CONSTRAINT DF_tbl_CompanySettings_RegistrationFee DEFAULT (50.00)');
                    END;
                    IF COL_LENGTH(N'dbo.tbl_CompanySettings', N'IsRegistrationFeeActive') IS NULL
                    BEGIN
                        EXEC(N'ALTER TABLE dbo.tbl_CompanySettings ADD IsRegistrationFeeActive BIT NOT NULL CONSTRAINT DF_tbl_CompanySettings_IsRegistrationFeeActive DEFAULT (1)');
                    END;
                END;

                IF OBJECT_ID(N'dbo.tbl_CompanyBulletins', N'U') IS NULL
                CREATE TABLE dbo.tbl_CompanyBulletins (
                    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_CompanyBulletins PRIMARY KEY,
                    Message NVARCHAR(500) NOT NULL,
                    LinkUrl NVARCHAR(500) NULL,
                    IsActive BIT NOT NULL CONSTRAINT DF_tbl_CompanyBulletins_IsActive DEFAULT (1),
                    StartAt DATETIME2(0) NOT NULL,
                    EndAt DATETIME2(0) NULL,
                    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_CompanyBulletins_CreatedAt DEFAULT SYSUTCDATETIME()
                );
                """, connection))
            {
                schemaCommand.ExecuteNonQuery();
            }

            using var command = new SqlCommand("""
                CREATE OR ALTER PROCEDURE dbo.sp_CompanyDashboard_Get
                AS
                BEGIN
                    SET NOCOUNT ON;

                    DECLARE @Today DATE = CONVERT(DATE, SYSUTCDATETIME());
                    DECLARE @MonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);

                    SELECT
                        TotalAgents = CONVERT(INT, COALESCE(SUM(CASE WHEN u.Role = N'Agent' THEN 1 ELSE 0 END), 0)),
                        TotalFieldOfficers = CONVERT(INT, COALESCE(SUM(CASE WHEN u.Role = N'FieldOfficer' THEN 1 ELSE 0 END), 0)),
                        TotalShopkeepers = (SELECT COUNT(1) FROM dbo.tbl_Shopkeepers),
                        TotalCustomers = (
                            SELECT COUNT(1)
                            FROM (
                                SELECT Phone FROM dbo.tbl_Customers WHERE IsActive = 1
                                UNION
                                SELECT Phone FROM dbo.tbl_Users WHERE Role = N'Customer' AND IsActive = 1
                            ) AS customers
                        ),
                        TotalDeliveryMen = (SELECT COUNT(1) FROM dbo.tbl_DeliveryMen),
                        ActiveDeliveryMen = (
                            SELECT COUNT(1) FROM dbo.tbl_DeliveryMen dm
                            INNER JOIN dbo.tbl_Users du ON du.Id = dm.UserId
                            WHERE du.IsActive = 1 AND dm.Availability <> N'Offline'
                        ),
                        TotalCustomerOrders = (SELECT COUNT(1) FROM dbo.tbl_CustomerOrders),
                        PendingCustomerOrders = (SELECT COUNT(1) FROM dbo.tbl_CustomerOrders WHERE Status = N'Pending'),
                        ConfirmedCustomerOrders = (SELECT COUNT(1) FROM dbo.tbl_CustomerOrders WHERE Status IN (N'Approved', N'Assigned', N'Accepted', N'Picked Up', N'Out for Delivery')),
                        DeliveredCustomerOrders = (SELECT COUNT(1) FROM dbo.tbl_CustomerOrders WHERE Status = N'Delivered'),
                        CancelledCustomerOrders = (SELECT COUNT(1) FROM dbo.tbl_CustomerOrders WHERE Status IN (N'Rejected', N'Cancelled')),
                        ReturnedCustomerOrders = (SELECT COUNT(1) FROM dbo.tbl_CustomerOrders WHERE Status = N'Returned'),
                        FailedCustomerOrders = (SELECT COUNT(1) FROM dbo.tbl_CustomerOrders WHERE Status = N'Failed Delivery'),
                        TotalProducts = (SELECT COUNT(1) FROM dbo.tbl_Products WHERE IsActive = 1),
                        LowStockProducts = (SELECT COUNT(1) FROM dbo.tbl_Products WHERE IsActive = 1 AND StockQuantity <= 5),
                        ActiveCampaigns = (SELECT COUNT(1) FROM dbo.tbl_CompanyCampaigns WHERE IsActive = 1 AND @Today BETWEEN StartDate AND EndDate),
                        PendingApprovals = (SELECT COUNT(1) FROM dbo.tbl_Users WHERE IsActive = 0 AND Role <> N'Company'),
                        UnreadNotifications = (SELECT COUNT(1) FROM dbo.tbl_Notifications WHERE IsRead = 0),
                        TotalSalesAmount = COALESCE((SELECT SUM(GrossAmount) FROM dbo.tbl_Sales), 0),
                        TodaySalesAmount = COALESCE((SELECT SUM(GrossAmount) FROM dbo.tbl_Sales WHERE CONVERT(DATE, SoldAt) = @Today), 0),
                        MonthSalesAmount = COALESCE((SELECT SUM(GrossAmount) FROM dbo.tbl_Sales WHERE SoldAt >= @MonthStart), 0),
                        TotalCashbackAmount = COALESCE((SELECT SUM(CashbackAmount) FROM dbo.tbl_Sales), 0),
                        TotalSystemCommission = COALESCE((SELECT SUM(SystemCommission) FROM dbo.tbl_Sales), 0),
                        WalletBalance = COALESCE((SELECT SUM(Balance) FROM dbo.tbl_ShopkeeperWallets), 0),
                        WalletWithdrawable = COALESCE((SELECT SUM(WithdrawableBalance) FROM dbo.tbl_ShopkeeperWallets), 0),
                        WalletPending = COALESCE((SELECT SUM(PendingBalance) FROM dbo.tbl_ShopkeeperWallets), 0)
                    FROM dbo.tbl_Users AS u
                    WHERE u.IsActive = 1;

                    SELECT TOP (8)
                        s.Id, s.ShopName, s.OwnerName, s.Phone, s.ShopCode,
                        ds.Name AS DistrictName, th.Name AS ThanaName,
                        fo.Name AS FieldOfficerName, s.RegisteredAt
                    FROM dbo.tbl_Shopkeepers AS s
                    INNER JOIN dbo.tbl_Districts AS ds ON ds.Id = s.DistrictId
                    INNER JOIN dbo.tbl_Thanas AS th ON th.Id = s.ThanaId
                    INNER JOIN dbo.tbl_Users AS fo ON fo.Id = s.FieldOfficerUserId
                    ORDER BY s.RegisteredAt DESC, s.Id DESC;

                    SELECT TOP (8)
                        sale.Id, sale.InvoiceNo, shop.ShopName,
                        customer.Name AS CustomerName, customer.Phone AS CustomerPhone,
                        sale.GrossAmount, sale.CashbackAmount, sale.SystemCommission,
                        sale.Status, sale.SoldAt
                    FROM dbo.tbl_Sales AS sale
                    INNER JOIN dbo.tbl_Shopkeepers AS shop ON shop.Id = sale.ShopkeeperId
                    INNER JOIN dbo.tbl_Customers AS customer ON customer.Id = sale.CustomerId
                    ORDER BY sale.SoldAt DESC, sale.Id DESC;

                    SELECT TOP (8)
                        ds.Name AS DistrictName,
                        COUNT(DISTINCT shop.Id) AS ShopkeeperCount,
                        COUNT(DISTINCT sale.CustomerId) AS CustomerCount,
                        COALESCE(SUM(sale.GrossAmount), 0) AS SalesAmount
                    FROM dbo.tbl_Districts AS ds
                    LEFT JOIN dbo.tbl_Shopkeepers AS shop ON shop.DistrictId = ds.Id
                    LEFT JOIN dbo.tbl_Sales AS sale ON sale.ShopkeeperId = shop.Id
                    WHERE ds.IsActive = 1
                    GROUP BY ds.Id, ds.Name
                    ORDER BY SalesAmount DESC, ShopkeeperCount DESC, ds.Name;

                    SELECT TOP (8)
                        Id, Name,
                        Status = CASE
                            WHEN IsActive = 0 THEN N'Paused'
                            WHEN @Today < StartDate THEN N'Upcoming'
                            WHEN @Today > EndDate THEN N'Completed'
                            ELSE N'Running'
                        END,
                        StartDate, EndDate, Reach, Clicks, Conversions, SalesAmount
                    FROM dbo.tbl_CompanyCampaigns
                    ORDER BY CreatedAt DESC, Id DESC;

                    SELECT TOP (8)
                        p.Id, p.Name, p.Category, s.ShopName, p.StockQuantity,
                        SoldQuantity = COALESCE(SUM(sd.Quantity), 0),
                        SalesAmount = COALESCE(SUM(sd.LineTotal), 0)
                    FROM dbo.tbl_Products p
                    INNER JOIN dbo.tbl_Shopkeepers s ON s.Id = p.ShopkeeperId
                    LEFT JOIN dbo.tbl_SaleDetails sd ON sd.ProductId = p.Id
                    WHERE p.IsActive = 1
                    GROUP BY p.Id, p.Name, p.Category, s.ShopName, p.StockQuantity
                    ORDER BY SoldQuantity DESC, SalesAmount DESC, p.Name;

                    SELECT TOP (12) Id, Name, Phone, Role, IsActive, CreatedAt
                    FROM dbo.tbl_Users
                    WHERE Role <> N'Company'
                    ORDER BY CreatedAt DESC, Id DESC;

                    SELECT TOP (8) Id, Title, Message, IsRead, CreatedAt
                    FROM dbo.tbl_Notifications
                    ORDER BY CreatedAt DESC, Id DESC;

                    SELECT TOP (12) Type, Title, Detail, OccurredAt
                    FROM (
                        SELECT N'Sale' AS Type, sale.InvoiceNo AS Title,
                            CONCAT(shop.ShopName, N' · ', customer.Name, N' · Tk ', CONVERT(NVARCHAR(30), sale.GrossAmount)) AS Detail,
                            sale.SoldAt AS OccurredAt
                        FROM dbo.tbl_Sales sale
                        INNER JOIN dbo.tbl_Shopkeepers shop ON shop.Id = sale.ShopkeeperId
                        INNER JOIN dbo.tbl_Customers customer ON customer.Id = sale.CustomerId
                        UNION ALL
                        SELECT N'Order', CONCAT(N'Order #', orders.Id),
                            CONCAT(orders.CustomerName, N' · ', orders.Status), orders.OrderDate
                        FROM dbo.tbl_CustomerOrders orders
                        UNION ALL
                        SELECT N'Shop', shop.ShopName,
                            CONCAT(shop.OwnerName, N' · ', shop.ShopCode), shop.RegisteredAt
                        FROM dbo.tbl_Shopkeepers shop
                    ) activity
                    ORDER BY OccurredAt DESC;

                    SELECT CommissionRate, CashbackRate, DeliveryCharge, SupportPhone, PaymentGateway, RegistrationFee, IsRegistrationFeeActive
                    FROM dbo.tbl_CompanySettings
                    WHERE Id = 1;
                END
                """, connection);
            command.ExecuteNonQuery();
            _companyDashboardSchemaReady = true;
        }
    }

    private static SqlCommand CreateCommand(SqlConnection connection, string procedureName)
    {
        return new SqlCommand(procedureName, connection)
        {
            CommandType = CommandType.StoredProcedure
        };
    }

    private static AppUser MapUser(SqlDataReader reader)
    {
        return new AppUser
        {
            Id = reader.GetInt32(reader.GetOrdinal("Id")),
            Name = reader.GetString(reader.GetOrdinal("Name")),
            Phone = reader.GetString(reader.GetOrdinal("Phone")),
            Password = reader.GetString(reader.GetOrdinal("Password")),
            Role = reader.GetString(reader.GetOrdinal("Role")),
            ShopCode = reader.IsDBNull(reader.GetOrdinal("ShopCode")) ? null : reader.GetString(reader.GetOrdinal("ShopCode")),
            ParentUserId = HasColumn(reader, "ParentUserId") && !reader.IsDBNull(reader.GetOrdinal("ParentUserId"))
                ? reader.GetInt32(reader.GetOrdinal("ParentUserId"))
                : null,
            IsActive = !HasColumn(reader, "IsActive") || reader.GetBoolean(reader.GetOrdinal("IsActive")),
            CreatedAt = HasColumn(reader, "CreatedAt") && !reader.IsDBNull(reader.GetOrdinal("CreatedAt"))
                ? reader.GetDateTime(reader.GetOrdinal("CreatedAt"))
                : DateTime.Now,
            ProfilePictureUrl = HasColumn(reader, "ProfilePictureUrl") && !reader.IsDBNull(reader.GetOrdinal("ProfilePictureUrl"))
                ? reader.GetString(reader.GetOrdinal("ProfilePictureUrl"))
                : null
        };
    }

    private static Shopkeeper MapShopkeeper(SqlDataReader reader)
    {
        return new Shopkeeper
        {
            Id = reader.GetInt32(reader.GetOrdinal("Id")),
            ShopName = reader.GetString(reader.GetOrdinal("ShopName")),
            OwnerName = reader.GetString(reader.GetOrdinal("OwnerName")),
            Phone = reader.GetString(reader.GetOrdinal("Phone")),
            NidNumber = GetNullableString(reader, "NidNumber"),
            ProfilePhotoPath = GetNullableString(reader, "ProfilePhotoPath"),
            BillboardPhotoPath = GetNullableString(reader, "BillboardPhotoPath"),
            DivisionId = reader.GetInt32(reader.GetOrdinal("DivisionId")),
            DivisionName = reader.GetString(reader.GetOrdinal("DivisionName")),
            DistrictId = reader.GetInt32(reader.GetOrdinal("DistrictId")),
            DistrictName = reader.GetString(reader.GetOrdinal("DistrictName")),
            ThanaId = reader.GetInt32(reader.GetOrdinal("ThanaId")),
            ThanaName = reader.GetString(reader.GetOrdinal("ThanaName")),
            Address = reader.GetString(reader.GetOrdinal("Address")),
            Latitude = reader.GetDecimal(reader.GetOrdinal("Latitude")),
            Longitude = reader.GetDecimal(reader.GetOrdinal("Longitude")),
            Area = reader.GetString(reader.GetOrdinal("Area")),
            ShopType = reader.GetString(reader.GetOrdinal("ShopType")),
            Password = reader.GetString(reader.GetOrdinal("Password")),
            ShopCode = reader.GetString(reader.GetOrdinal("ShopCode")),
            FieldOfficerUserId = reader.GetInt32(reader.GetOrdinal("FieldOfficerUserId")),
            FieldOfficerName = reader.GetString(reader.GetOrdinal("FieldOfficerName")),
            FieldOfficerPhone = reader.GetString(reader.GetOrdinal("FieldOfficerPhone")),
            RegisteredAt = reader.GetDateTime(reader.GetOrdinal("RegisteredAt"))
        };
    }

    private static bool HasColumn(SqlDataReader reader, string columnName)
    {
        for (var i = 0; i < reader.FieldCount; i++)
        {
            if (string.Equals(reader.GetName(i), columnName, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        return false;
    }

    private static string? GetNullableString(SqlDataReader reader, string columnName)
    {
        if (!HasColumn(reader, columnName))
        {
            return null;
        }

        var ordinal = reader.GetOrdinal(columnName);
        return reader.IsDBNull(ordinal) ? null : reader.GetString(ordinal);
    }

    private static List<LocationOption> ReadLocations(SqlDataReader reader, bool hasParent)
    {
        var locations = new List<LocationOption>();
        while (reader.Read())
        {
            locations.Add(new LocationOption
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                ParentId = hasParent ? reader.GetInt32(reader.GetOrdinal("ParentId")) : null
            });
        }

        return locations;
    }

    public AppUser? GetUserByPhone(string phone)
    {
        EnsureUserProfilePictureSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("SELECT TOP (1) Id, Name, Phone, PasswordHash AS Password, Role, ShopCode, ParentUserId, IsActive, CreatedAt, ProfilePictureUrl FROM dbo.tbl_Users WHERE Phone = @Phone;", connection);
        command.Parameters.AddWithValue("@Phone", phone.Trim());

        connection.Open();
        using var reader = command.ExecuteReader();
        return reader.Read() ? MapUser(reader) : null;
    }

    public AppUser? GetUserById(int id)
    {
        EnsureUserProfilePictureSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("SELECT TOP (1) Id, Name, Phone, PasswordHash AS Password, Role, ShopCode, ParentUserId, IsActive, CreatedAt, ProfilePictureUrl FROM dbo.tbl_Users WHERE Id = @Id;", connection);
        command.Parameters.AddWithValue("@Id", id);

        connection.Open();
        using var reader = command.ExecuteReader();
        return reader.Read() ? MapUser(reader) : null;
    }

    public void UpdateUserProfilePicture(int userId, string photoPath)
    {
        EnsureUserProfilePictureSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("UPDATE dbo.tbl_Users SET ProfilePictureUrl = @PhotoPath WHERE Id = @UserId;", connection);
        command.Parameters.AddWithValue("@UserId", userId);
        command.Parameters.AddWithValue("@PhotoPath", photoPath);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public void ResetUserPassword(int userId, string newPassword)
    {
        using var connection = CreateConnection();
        using var command = new SqlCommand("UPDATE dbo.tbl_Users SET PasswordHash = @Password WHERE Id = @UserId;", connection);
        command.Parameters.AddWithValue("@UserId", userId);
        command.Parameters.AddWithValue("@Password", newPassword.Trim());

        connection.Open();
        command.ExecuteNonQuery();
    }

    public bool ChangePassword(int userId, string oldPassword, string newPassword)
    {
        using var connection = CreateConnection();
        const string checkSql = "SELECT COUNT(1) FROM dbo.tbl_Users WHERE Id = @UserId AND PasswordHash = @Password;";
        using (var checkCmd = new SqlCommand(checkSql, connection))
        {
            checkCmd.Parameters.AddWithValue("@UserId", userId);
            checkCmd.Parameters.AddWithValue("@Password", oldPassword);
            connection.Open();
            var count = (int)(checkCmd.ExecuteScalar() ?? 0);
            if (count == 0)
            {
                return false;
            }
        }

        const string updateSql = "UPDATE dbo.tbl_Users SET PasswordHash = @NewPassword WHERE Id = @UserId;";
        using (var updateCmd = new SqlCommand(updateSql, connection))
        {
            updateCmd.Parameters.AddWithValue("@UserId", userId);
            updateCmd.Parameters.AddWithValue("@NewPassword", newPassword);
            updateCmd.ExecuteNonQuery();
        }
        return true;
    }

    private static bool _userProfileSchemaReady;
    private static readonly object UserProfileSchemaLock = new();

    public void EnsureUserProfilePictureSchema()
    {
        if (_userProfileSchemaReady) return;
        lock (UserProfileSchemaLock)
        {
            if (_userProfileSchemaReady) return;
            try
            {
                using var connection = CreateConnection();
                using var command = new SqlCommand("""
                    IF COL_LENGTH(N'dbo.tbl_Users', N'ProfilePictureUrl') IS NULL
                        ALTER TABLE dbo.tbl_Users ADD ProfilePictureUrl NVARCHAR(500) NULL;
                """, connection);
                connection.Open();
                command.ExecuteNonQuery();
                _userProfileSchemaReady = true;
            }
            catch
            {
                // Ignore if schema already updated
            }
        }
    }

    private static bool _teamSeedReady;
    private static readonly object TeamSeedLock = new();

    public void EnsureSeedTeamMembers()
    {
        if (_teamSeedReady) return;
        lock (TeamSeedLock)
        {
            if (_teamSeedReady) return;
            try
            {
                EnsureAgentSchema();
                EnsureUserProfilePictureSchema();
                using var connection = CreateConnection();
                connection.Open();

                using var checkCmd = new SqlCommand("SELECT COUNT(1) FROM dbo.tbl_Users WHERE Role IN (N'Agent', N'FieldOfficer');", connection);
                var count = Convert.ToInt32(checkCmd.ExecuteScalar() ?? 0);
                if (count == 0)
                {
                    using var seedCmd = new SqlCommand("""
                        DECLARE @DhakaId INT, @CtgId INT, @SylhetId INT, @RajshahiId INT;
                        SELECT TOP 1 @DhakaId = Id FROM dbo.tbl_Districts WHERE Name LIKE N'%Dhaka%' OR Name LIKE N'%ঢাকা%' ORDER BY Id;
                        SELECT TOP 1 @CtgId = Id FROM dbo.tbl_Districts WHERE Name LIKE N'%Chatto%' OR Name LIKE N'%Chittagong%' OR Name LIKE N'%চট্টগ্রাম%' ORDER BY Id;
                        SELECT TOP 1 @SylhetId = Id FROM dbo.tbl_Districts WHERE Name LIKE N'%Sylhet%' OR Name LIKE N'%সিলেট%' ORDER BY Id;
                        SELECT TOP 1 @RajshahiId = Id FROM dbo.tbl_Districts WHERE Name LIKE N'%Rajshahi%' OR Name LIKE N'%রাজশাহী%' ORDER BY Id;

                        IF @DhakaId IS NULL SELECT TOP 1 @DhakaId = Id FROM dbo.tbl_Districts;
                        IF @CtgId IS NULL SELECT TOP 1 @CtgId = Id FROM dbo.tbl_Districts WHERE Id <> @DhakaId;
                        IF @CtgId IS NULL SET @CtgId = @DhakaId;
                        IF @SylhetId IS NULL SELECT TOP 1 @SylhetId = Id FROM dbo.tbl_Districts WHERE Id NOT IN (@DhakaId, @CtgId);
                        IF @SylhetId IS NULL SET @SylhetId = @DhakaId;
                        IF @RajshahiId IS NULL SELECT TOP 1 @RajshahiId = Id FROM dbo.tbl_Districts WHERE Id NOT IN (@DhakaId, @CtgId, @SylhetId);
                        IF @RajshahiId IS NULL SET @RajshahiId = @DhakaId;

                        -- 1. Agent: মোঃ রফিকুল ইসলাম (Dhaka)
                        DECLARE @Agent1Id INT;
                        IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01711000101')
                        BEGIN
                            INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, IsActive, CreatedAt, ProfilePictureUrl)
                            VALUES (N'মোঃ রফিকুল ইসলাম', '01711000101', '1234', N'Agent', 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80');
                            SET @Agent1Id = SCOPE_IDENTITY();
                        END
                        ELSE
                        BEGIN
                            SELECT @Agent1Id = Id FROM dbo.tbl_Users WHERE Phone = '01711000101';
                        END

                        IF @Agent1Id IS NOT NULL AND @DhakaId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.tbl_AgentDistricts WHERE AgentUserId = @Agent1Id)
                        BEGIN
                            INSERT INTO dbo.tbl_AgentDistricts (AgentUserId, DistrictId) VALUES (@Agent1Id, @DhakaId);
                        END

                        -- 2. FieldOfficer: তানভীর আহমেদ (under Agent 1)
                        IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01812000202')
                        BEGIN
                            INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, ParentUserId, IsActive, CreatedAt, ProfilePictureUrl)
                            VALUES (N'তানভীর আহমেদ', '01812000202', '1234', N'FieldOfficer', @Agent1Id, 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80');
                        END

                        -- 3. Agent: আব্দুল কাদের (Chittagong)
                        DECLARE @Agent2Id INT;
                        IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01913000303')
                        BEGIN
                            INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, IsActive, CreatedAt, ProfilePictureUrl)
                            VALUES (N'আব্দুল কাদের', '01913000303', '1234', N'Agent', 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&auto=format&fit=crop&q=80');
                            SET @Agent2Id = SCOPE_IDENTITY();
                        END
                        ELSE
                        BEGIN
                            SELECT @Agent2Id = Id FROM dbo.tbl_Users WHERE Phone = '01913000303';
                        END

                        IF @Agent2Id IS NOT NULL AND @CtgId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.tbl_AgentDistricts WHERE AgentUserId = @Agent2Id)
                        BEGIN
                            INSERT INTO dbo.tbl_AgentDistricts (AgentUserId, DistrictId) VALUES (@Agent2Id, @CtgId);
                        END

                        -- 4. FieldOfficer: মাহমুদুল হাসান (under Agent 2)
                        IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01714000404')
                        BEGIN
                            INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, ParentUserId, IsActive, CreatedAt, ProfilePictureUrl)
                            VALUES (N'মাহমুদুল হাসান', '01714000404', '1234', N'FieldOfficer', @Agent2Id, 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200&auto=format&fit=crop&q=80');
                        END

                        -- 5. Agent: সাইফুল ইসলাম (Sylhet)
                        DECLARE @Agent3Id INT;
                        IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01515000505')
                        BEGIN
                            INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, IsActive, CreatedAt, ProfilePictureUrl)
                            VALUES (N'সাইফুল ইসলাম', '01515000505', '1234', N'Agent', 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&auto=format&fit=crop&q=80');
                            SET @Agent3Id = SCOPE_IDENTITY();
                        END
                        ELSE
                        BEGIN
                            SELECT @Agent3Id = Id FROM dbo.tbl_Users WHERE Phone = '01515000505';
                        END

                        IF @Agent3Id IS NOT NULL AND @SylhetId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.tbl_AgentDistricts WHERE AgentUserId = @Agent3Id)
                        BEGIN
                            INSERT INTO dbo.tbl_AgentDistricts (AgentUserId, DistrictId) VALUES (@Agent3Id, @SylhetId);
                        END

                        -- 6. FieldOfficer: মেহেদী হাসান রনি (under Agent 3)
                        IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01616000606')
                        BEGIN
                            INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, ParentUserId, IsActive, CreatedAt, ProfilePictureUrl)
                            VALUES (N'মেহেদী হাসান রনি', '01616000606', '1234', N'FieldOfficer', @Agent3Id, 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=200&auto=format&fit=crop&q=80');
                        END

                        -- 7. Agent: আরিফুল হক (Rajshahi)
                        DECLARE @Agent4Id INT;
                        IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01817000707')
                        BEGIN
                            INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, IsActive, CreatedAt, ProfilePictureUrl)
                            VALUES (N'আরিফুল হক', '01817000707', '1234', N'Agent', 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80');
                            SET @Agent4Id = SCOPE_IDENTITY();
                        END
                        ELSE
                        BEGIN
                            SELECT @Agent4Id = Id FROM dbo.tbl_Users WHERE Phone = '01817000707';
                        END

                        IF @Agent4Id IS NOT NULL AND @RajshahiId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.tbl_AgentDistricts WHERE AgentUserId = @Agent4Id)
                        BEGIN
                            INSERT INTO dbo.tbl_AgentDistricts (AgentUserId, DistrictId) VALUES (@Agent4Id, @RajshahiId);
                        END
                    """, connection);
                    seedCmd.ExecuteNonQuery();
                }
                _teamSeedReady = true;
            }
            catch
            {
                // Ignore if already seeded or temporary db issue
            }
        }
    }

    public IReadOnlyList<TeamMemberDirectoryItem> GetTeamDirectory(int? districtId = null, string? role = null)
    {
        EnsureAgentSchema();
        EnsureShopkeeperRegistrationSchema();
        EnsureUserProfilePictureSchema();
        EnsureSeedTeamMembers();
        var list = new List<TeamMemberDirectoryItem>();

        try
        {
            using var connection = CreateConnection();
            using var command = new SqlCommand("""
                -- 1. Agents
                SELECT 
                    u.Id,
                    u.Name,
                    u.Phone,
                    u.ProfilePictureUrl,
                    u.IsActive,
                    u.CreatedAt,
                    d.Id AS DistrictId,
                    COALESCE(d.Name, N'সারাদেশ / অল ডিস্ট্রিক্ট') AS DistrictName,
                    (SELECT COUNT(1) FROM dbo.tbl_Users fo WHERE fo.ParentUserId = u.Id AND fo.Role = N'FieldOfficer' AND fo.IsActive = 1) AS FieldOfficerCount,
                    (SELECT COUNT(1) FROM dbo.tbl_Shopkeepers s INNER JOIN dbo.tbl_Users fo ON fo.Id = s.FieldOfficerUserId WHERE fo.ParentUserId = u.Id) AS ShopCount
                FROM dbo.tbl_Users u
                LEFT JOIN dbo.tbl_AgentDistricts ad ON ad.AgentUserId = u.Id
                LEFT JOIN dbo.tbl_Districts d ON d.Id = ad.DistrictId
                WHERE u.Role = N'Agent' AND u.IsActive = 1;

                -- 2. Field Officers
                SELECT 
                    fo.Id,
                    fo.Name,
                    fo.Phone,
                    fo.ProfilePictureUrl,
                    fo.IsActive,
                    fo.CreatedAt,
                    fo.ParentUserId,
                    parent.Name AS ParentAgentName,
                    COALESCE(d.DistrictId, parentDist.Id) AS DistrictId,
                    COALESCE(d.Name, parentDist.Name, N'এলাকা নির্ধারিত') AS DistrictName,
                    (SELECT COUNT(1) FROM dbo.tbl_Shopkeepers s WHERE s.FieldOfficerUserId = fo.Id) AS ShopCount
                FROM dbo.tbl_Users fo
                LEFT JOIN dbo.tbl_Users parent ON parent.Id = fo.ParentUserId
                LEFT JOIN dbo.tbl_AgentDistricts parentAd ON parentAd.AgentUserId = parent.Id
                LEFT JOIN dbo.tbl_Districts parentDist ON parentDist.Id = parentAd.DistrictId
                OUTER APPLY (
                    SELECT TOP (1) s.DistrictId, dist.Name
                    FROM dbo.tbl_Shopkeepers s
                    INNER JOIN dbo.tbl_Districts dist ON dist.Id = s.DistrictId
                    WHERE s.FieldOfficerUserId = fo.Id
                    ORDER BY s.Id DESC
                ) d
                WHERE fo.Role = N'FieldOfficer' AND fo.IsActive = 1;
            """, connection);

            connection.Open();
            using var reader = command.ExecuteReader();

            while (reader.Read())
            {
                var id = reader.GetInt32(0);
                var name = reader.IsDBNull(1) ? "এরিয়া এজেন্ট" : reader.GetString(1);
                var phone = reader.IsDBNull(2) ? "" : reader.GetString(2);
                var pic = reader.IsDBNull(3) ? null : reader.GetString(3);
                var isActive = reader.IsDBNull(4) || reader.GetBoolean(4);
                var createdAt = reader.IsDBNull(5) ? DateTime.UtcNow : reader.GetDateTime(5);
                var distId = reader.IsDBNull(6) ? (int?)null : reader.GetInt32(6);
                var distName = reader.IsDBNull(7) ? "সারাদেশ / অল ডিস্ট্রিক্ট" : reader.GetString(7);
                var foCount = reader.IsDBNull(8) ? 0 : reader.GetInt32(8);
                var shopCount = reader.IsDBNull(9) ? 0 : reader.GetInt32(9);

                list.Add(new TeamMemberDirectoryItem
                {
                    Id = id,
                    Name = name,
                    Phone = phone,
                    Role = "Agent",
                    RoleTitle = "এরিয়া এজেন্ট",
                    ProfilePictureUrl = pic,
                    DistrictId = distId,
                    DistrictName = distName,
                    ConnectedCount = shopCount > 0 ? shopCount : foCount,
                    ConnectedLabel = foCount > 0 ? $"{foCount} জন ফিল্ড কর্মী" : (shopCount > 0 ? $"{shopCount}+ টি শপ কানেক্টেড" : "সক্রিয় এরিয়া লিডার"),
                    IsActive = isActive,
                    Rating = 4.9,
                    CreatedAt = createdAt
                });
            }

            if (reader.NextResult())
            {
                while (reader.Read())
                {
                    var id = reader.GetInt32(0);
                    var name = reader.IsDBNull(1) ? "ফিল্ড অফিসার" : reader.GetString(1);
                    var phone = reader.IsDBNull(2) ? "" : reader.GetString(2);
                    var pic = reader.IsDBNull(3) ? null : reader.GetString(3);
                    var isActive = reader.IsDBNull(4) || reader.GetBoolean(4);
                    var createdAt = reader.IsDBNull(5) ? DateTime.UtcNow : reader.GetDateTime(5);
                    var parentName = reader.IsDBNull(7) ? null : reader.GetString(7);
                    var distId = reader.IsDBNull(8) ? (int?)null : reader.GetInt32(8);
                    var distName = reader.IsDBNull(9) ? "এলাকা নির্ধারিত" : reader.GetString(9);
                    var shopCount = reader.IsDBNull(10) ? 0 : reader.GetInt32(10);

                    list.Add(new TeamMemberDirectoryItem
                    {
                        Id = id,
                        Name = name,
                        Phone = phone,
                        Role = "FieldOfficer",
                        RoleTitle = "ফিল্ড অফিসার",
                        ProfilePictureUrl = pic,
                        DistrictId = distId,
                        DistrictName = distName,
                        ConnectedCount = shopCount,
                        ConnectedLabel = shopCount > 0 ? $"{shopCount}+ টি ভেরিফাইড শপ" : "মাঠ প্রতিনিধি",
                        ParentName = !string.IsNullOrWhiteSpace(parentName) ? $"এজেন্ট: {parentName}" : null,
                        IsActive = isActive,
                        Rating = 4.8,
                        CreatedAt = createdAt
                    });
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[GetTeamDirectory Error] {ex}");
            throw;
        }

        var query = list.AsEnumerable();
        if (districtId.HasValue && districtId.Value > 0)
        {
            query = query.Where(x => x.DistrictId == districtId.Value);
        }
        if (!string.IsNullOrWhiteSpace(role) && !string.Equals(role, "all", StringComparison.OrdinalIgnoreCase))
        {
            query = query.Where(x => string.Equals(x.Role, role, StringComparison.OrdinalIgnoreCase));
        }

        return query.ToList();
    }
}
