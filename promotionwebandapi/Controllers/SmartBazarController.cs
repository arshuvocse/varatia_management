using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PromotionWeb.Contracts;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class SmartBazarController(
    IConfiguration configuration,
    CustomerOrderStore orderStore,
    LoanStore loanStore) : ControllerBase
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");

    [HttpPost("register")]
    public ActionResult<SmartBazarAuthResponse> Register([FromBody] SmartBazarRegisterRequest request)
    {
        var name = request.FullName.Trim();
        var phone = NormalizePhone(request.PhoneNumber);
        var role = NormalizeRole(request.Role);

        var validationError = ValidateRegistration(request, name, phone, role);
        if (validationError is not null)
        {
            return BadRequest(new { message = validationError });
        }

        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
        {
            using (var duplicateCommand = new SqlCommand(
                "SELECT COUNT(1) FROM dbo.tbl_Users WHERE Phone = @Phone;",
                connection,
                transaction))
            {
                duplicateCommand.Parameters.AddWithValue("@Phone", phone);
                if ((int)duplicateCommand.ExecuteScalar()! > 0)
                {
                    transaction.Rollback();
                    return Conflict(new { message = "This mobile number already has an account." });
                }
            }

            int userId;
            DateTime createdAt;
            using (var insertUserCommand = new SqlCommand(
                """
                INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role)
                OUTPUT INSERTED.Id, INSERTED.CreatedAt
                VALUES (@Name, @Phone, @Password, @Role);
                """,
                connection,
                transaction))
            {
                insertUserCommand.Parameters.AddWithValue("@Name", name);
                insertUserCommand.Parameters.AddWithValue("@Phone", phone);
                insertUserCommand.Parameters.AddWithValue("@Password", request.Password);
                insertUserCommand.Parameters.AddWithValue("@Role", role);

                using var reader = insertUserCommand.ExecuteReader();
                if (!reader.Read())
                {
                    throw new InvalidOperationException("Smart Bazar registration failed.");
                }

                userId = reader.GetInt32(0);
                createdAt = reader.GetDateTime(1);
            }

            if (role == Roles.Customer)
            {
                using var customerCommand = new SqlCommand(
                    """
                    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Customers WHERE Phone = @Phone)
                    BEGIN
                        INSERT INTO dbo.tbl_Customers (Name, Phone)
                        VALUES (@Name, @Phone);
                    END
                    ELSE
                    BEGIN
                        UPDATE dbo.tbl_Customers SET Name = @Name WHERE Phone = @Phone;
                    END
                    """,
                    connection,
                    transaction);
                customerCommand.Parameters.AddWithValue("@Name", name);
                customerCommand.Parameters.AddWithValue("@Phone", phone);
                customerCommand.ExecuteNonQuery();
            }

            transaction.Commit();
            return Ok(new SmartBazarAuthResponse
            {
                UserId = userId.ToString(),
                FullName = name,
                PhoneNumber = phone,
                Role = role,
                CreatedAt = createdAt,
                Message = "Smart Bazar registration successful."
            });
        }
        catch (SqlException exception) when (exception.Number is 2601 or 2627)
        {
            transaction.Rollback();
            return Conflict(new { message = "This mobile number already has an account." });
        }
    }

    [HttpPost("login")]
    public ActionResult<SmartBazarAuthResponse> Login([FromBody] SmartBazarLoginRequest request)
    {
        var phone = NormalizePhone(request.PhoneNumber);
        var role = string.IsNullOrWhiteSpace(request.Role) ? null : NormalizeRole(request.Role);

        if (phone.Length != 11)
        {
            return BadRequest(new { message = "Phone number must be 11 digits." });
        }

        if (string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new { message = "Password is required." });
        }

        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(
            """
            SELECT TOP (1) Id, Name, Phone, Role, ShopCode, CreatedAt
            FROM dbo.tbl_Users
            WHERE Phone = @Phone
              AND PasswordHash = @Password
              AND IsActive = 1
              AND Role IN (N'Customer', N'Shopkeeper')
              AND (@Role IS NULL OR Role = @Role)
            ORDER BY Id DESC;
            """,
            connection);
        command.Parameters.AddWithValue("@Phone", phone);
        command.Parameters.AddWithValue("@Password", request.Password);
        command.Parameters.AddWithValue("@Role", (object?)role ?? DBNull.Value);

        connection.Open();
        using var reader = command.ExecuteReader();
        if (!reader.Read())
        {
            return Unauthorized(new { message = "Invalid phone number, password, or role." });
        }

        return Ok(new SmartBazarAuthResponse
        {
            UserId = reader.GetInt32(reader.GetOrdinal("Id")).ToString(),
            FullName = reader.GetString(reader.GetOrdinal("Name")),
            PhoneNumber = reader.GetString(reader.GetOrdinal("Phone")),
            Role = reader.GetString(reader.GetOrdinal("Role")),
            ShopCode = reader.IsDBNull(reader.GetOrdinal("ShopCode"))
                ? null
                : reader.GetString(reader.GetOrdinal("ShopCode")),
            CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt")),
            Message = "Smart Bazar login successful."
        });
    }

    [HttpGet("categories")]
    public ActionResult<IReadOnlyList<ShopCategoryViewModel>> GetCategories()
    {
        var categories = orderStore.GetCategories();
        return Ok(categories);
    }

    [HttpGet("products")]
    public ActionResult<object> GetProducts(
        [FromQuery] string? district = "Dhaka",
        [FromQuery] string? category = null,
        [FromQuery] string? search = null)
    {
        var products = orderStore.GetProducts(district);

        if (!string.IsNullOrWhiteSpace(category))
        {
            products = products.Where(p => p.Category.Equals(category.Trim(), StringComparison.OrdinalIgnoreCase)).ToList();
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLowerInvariant();
            products = products.Where(p => p.Name.ToLowerInvariant().Contains(term) || p.Sku.ToLowerInvariant().Contains(term)).ToList();
        }

        var pricing = orderStore.GetDistrictPricing(district);

        return Ok(new
        {
            district = pricing.DistrictName,
            pricingConfig = pricing,
            totalCount = products.Count,
            products = products
        });
    }

    [HttpGet("shops/nearby")]
    public ActionResult<IReadOnlyList<CustomerShopkeeperOptionViewModel>> GetNearbyShops(
        [FromQuery] double? lat = null,
        [FromQuery] double? lng = null,
        [FromQuery] string? district = "Dhaka",
        [FromQuery] string? category = null)
    {
        var shops = orderStore.GetNearbyShops(lat, lng, district, category);
        return Ok(shops);
    }

    [HttpGet("agent/location")]
    public ActionResult<AgentOfficeLocationViewModel> GetAgentLocation(
        [FromQuery] string? district = "Dhaka",
        [FromQuery] double? lat = null,
        [FromQuery] double? lng = null)
    {
        var office = loanStore.GetAgentOfficeForDistrict(district ?? "Dhaka", lat, lng);
        if (office is null) return NotFound(new { message = "Agent office not found for this district." });
        return Ok(office);
    }

    [HttpGet("pricing/{districtName}")]
    public ActionResult<DistrictPricingDetailViewModel> GetDistrictPricing(string districtName)
    {
        var pricing = orderStore.GetDistrictPricing(districtName);
        return Ok(pricing);
    }

    [HttpPost("loan/calculate")]
    public ActionResult<LoanCalculationResult> CalculateLoan([FromBody] LoanApplicationInputModel request)
    {
        var result = loanStore.CalculateLoan(request.Amount, request.TenureMonths);
        return Ok(result);
    }

    [HttpGet("loan/eligibility/{userId:int}")]
    public ActionResult<object> GetLoanEligibility(int userId, [FromQuery] string? role = Roles.Customer)
    {
        using var connection = new SqlConnection(_connectionString);
        using var cmd = new SqlCommand("SELECT Phone FROM dbo.tbl_Users WHERE Id = @UserId;", connection);
        cmd.Parameters.AddWithValue("@UserId", userId);
        connection.Open();
        var phone = Convert.ToString(cmd.ExecuteScalar()) ?? "";

        var eligibility = loanStore.GetEligibility(userId, role ?? Roles.Customer, phone);
        var activeLoan = loanStore.GetActiveLoan(userId);
        var history = loanStore.GetUserLoans(userId);

        return Ok(new
        {
            eligibility,
            activeLoan,
            loanHistory = history
        });
    }

    [HttpPost("loan/apply")]
    public ActionResult<LoanItemViewModel> ApplyLoan([FromBody] SmartBazarLoanApplyRequest request)
    {
        if (request.UserId <= 0) return BadRequest(new { message = "Invalid User ID." });
        if (request.Amount < 5000 || request.Amount > 50000) return BadRequest(new { message = "Loan amount must be between 5,000 and 50,000 BDT." });

        using var connection = new SqlConnection(_connectionString);
        using var cmd = new SqlCommand("SELECT Name, Phone, Role FROM dbo.tbl_Users WHERE Id = @UserId;", connection);
        cmd.Parameters.AddWithValue("@UserId", request.UserId);
        connection.Open();
        using var reader = cmd.ExecuteReader();
        if (!reader.Read()) return NotFound(new { message = "User not found." });

        var name = reader.GetString(0);
        var phone = reader.GetString(1);
        var role = reader.GetString(2);
        reader.Close();

        try
        {
            var loan = loanStore.ApplyLoan(request.UserId, role, name, phone, new LoanApplicationInputModel
            {
                Amount = request.Amount,
                TenureMonths = request.TenureMonths,
                Purpose = request.Purpose ?? "ব্যক্তিগত / ব্যবসায়িক জরুরি প্রয়োজন"
            });
            return Ok(loan);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("loan/repay")]
    public ActionResult<object> RepayLoanInstallment([FromBody] SmartBazarLoanRepayRequest request)
    {
        if (request.InstallmentId <= 0 || request.UserId <= 0)
        {
            return BadRequest(new { message = "Invalid Installment ID or User ID." });
        }

        try
        {
            var success = loanStore.PayInstallment(request.InstallmentId, request.UserId, request.PaymentMethod ?? "Wallet");
            return success
                ? Ok(new { success = true, message = "Installment paid successfully." })
                : BadRequest(new { success = false, message = "Could not process installment payment." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    [HttpGet("customer/dashboard/{userId:int}")]
    public ActionResult<object> GetCustomerDashboard(int userId)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(
            """
            SELECT TOP (1) Phone
            FROM dbo.tbl_Users
            WHERE Id = @UserId AND Role = N'Customer' AND IsActive = 1;
            """,
            connection);
        command.Parameters.AddWithValue("@UserId", userId);

        connection.Open();
        var phone = command.ExecuteScalar() as string;
        if (phone is null)
        {
            return NotFound(new { message = "Customer account was not found." });
        }

        using var summaryCommand = new SqlCommand(
            """
            SELECT
                WalletBalance = CONVERT(DECIMAL(18,2), COALESCE(SUM(s.CashbackAmount), 0)),
                TotalCashback = CONVERT(DECIMAL(18,2), COALESCE(SUM(s.CashbackAmount), 0))
            FROM dbo.tbl_Sales AS s
            INNER JOIN dbo.tbl_Customers AS c ON c.Id = s.CustomerId
            WHERE c.Phone = @Phone;
            """,
            connection);
        summaryCommand.Parameters.AddWithValue("@Phone", phone);

        decimal walletBalance = 0;
        decimal totalCashback = 0;
        using (var reader = summaryCommand.ExecuteReader())
        {
            if (reader.Read())
            {
                walletBalance = reader.GetDecimal(reader.GetOrdinal("WalletBalance"));
                totalCashback = reader.GetDecimal(reader.GetOrdinal("TotalCashback"));
            }
        }

        return Ok(new
        {
            walletBalance,
            totalCashback,
            transactions = Array.Empty<object>()
        });
    }

    [HttpGet("shopkeeper/dashboard/{userId:int}")]
    public ActionResult<object> GetShopkeeperDashboard(int userId)
    {
        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        using var walletCommand = new SqlCommand(
            """
            SELECT TOP (1) Balance
            FROM dbo.tbl_UserWallets
            WHERE UserId = @UserId;
            """,
            connection);
        walletCommand.Parameters.AddWithValue("@UserId", userId);
        
        var walletObj = walletCommand.ExecuteScalar();
        var walletBalance = walletObj is not null ? (decimal)walletObj : 0m;

        using var command = new SqlCommand(
            """
            SELECT TOP (1) Id
            FROM dbo.tbl_Shopkeepers
            WHERE UserId = @UserId;
            """,
            connection);
        command.Parameters.AddWithValue("@UserId", userId);

        var shopkeeperId = command.ExecuteScalar();
        if (shopkeeperId is null)
        {
            return Ok(new
            {
                todaySales = 0m,
                monthlySales = 0m,
                customerCashback = 0m,
                companyCommission = 0m,
                walletBalance = walletBalance,
                transactions = Array.Empty<object>()
            });
        }

        using var summaryCommand = new SqlCommand(
            """
            SELECT
                TodaySales = CONVERT(DECIMAL(18,2), COALESCE(SUM(CASE WHEN CONVERT(DATE, SoldAt) = CONVERT(DATE, SYSUTCDATETIME()) THEN GrossAmount ELSE 0 END), 0)),
                MonthlySales = CONVERT(DECIMAL(18,2), COALESCE(SUM(CASE WHEN YEAR(SoldAt) = YEAR(SYSUTCDATETIME()) AND MONTH(SoldAt) = MONTH(SYSUTCDATETIME()) THEN GrossAmount ELSE 0 END), 0)),
                CustomerCashback = CONVERT(DECIMAL(18,2), COALESCE(SUM(CashbackAmount), 0)),
                CompanyCommission = CONVERT(DECIMAL(18,2), COALESCE(SUM(SystemCommission), 0))
            FROM dbo.tbl_Sales
            WHERE ShopkeeperId = @ShopkeeperId;
            """,
            connection);
        summaryCommand.Parameters.AddWithValue("@ShopkeeperId", (int)shopkeeperId);

        using var reader = summaryCommand.ExecuteReader();
        if (!reader.Read())
        {
            return Ok(new { todaySales = 0m, monthlySales = 0m, customerCashback = 0m, companyCommission = 0m, transactions = Array.Empty<object>() });
        }

        return Ok(new
        {
            todaySales = reader.GetDecimal(reader.GetOrdinal("TodaySales")),
            monthlySales = reader.GetDecimal(reader.GetOrdinal("MonthlySales")),
            customerCashback = reader.GetDecimal(reader.GetOrdinal("CustomerCashback")),
            companyCommission = reader.GetDecimal(reader.GetOrdinal("CompanyCommission")),
            walletBalance = walletBalance,
            transactions = Array.Empty<object>()
        });
    }

    [HttpPost("shopkeeper/add-balance")]
    public IActionResult AddShopWalletBalance([FromBody] SmartBazarAddBalanceRequest request)
    {
        if (request.Amount <= 0)
        {
            return BadRequest(new { message = "Amount must be greater than zero." });
        }

        if (!int.TryParse(request.ShopkeeperId, out var userId))
        {
            return BadRequest(new { message = "Invalid Shopkeeper ID." });
        }

        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(
            """
            IF EXISTS (SELECT 1 FROM dbo.tbl_UserWallets WHERE UserId = @UserId)
            BEGIN
                UPDATE dbo.tbl_UserWallets
                SET Balance = Balance + @Amount,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE UserId = @UserId;
            END
            ELSE
            BEGIN
                INSERT INTO dbo.tbl_UserWallets (UserId, Balance, UpdatedAt)
                VALUES (@UserId, @Amount, SYSUTCDATETIME());
            END
            """,
            connection);
        command.Parameters.AddWithValue("@UserId", userId);
        command.Parameters.AddWithValue("@Amount", request.Amount);

        connection.Open();
        command.ExecuteNonQuery();

        return Ok(new { message = "Balance added successfully." });
    }

    [HttpPost("sale")]
    public IActionResult AddSale([FromBody] SmartBazarSaleRequest request)
    {
        if (request.Amount <= 0)
        {
            return BadRequest(new { message = "Amount must be greater than zero." });
        }

        if (!int.TryParse(request.ShopkeeperId, out var userId))
        {
            return BadRequest(new { message = "Invalid Shopkeeper ID." });
        }

        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        using var checkWalletCommand = new SqlCommand(
            """
            SELECT TOP (1) Balance 
            FROM dbo.tbl_UserWallets 
            WHERE UserId = @UserId;
            """, connection);
        checkWalletCommand.Parameters.AddWithValue("@UserId", userId);

        var walletObj = checkWalletCommand.ExecuteScalar();
        var currentBalance = walletObj is not null ? (decimal)walletObj : 0m;

        if (currentBalance < request.CommissionAmount)
        {
            return BadRequest(new { message = "Insufficient wallet balance for this sale." });
        }

        using var transaction = connection.BeginTransaction();
        try
        {
            using var deductWalletCommand = new SqlCommand(
                """
                UPDATE dbo.tbl_UserWallets
                SET Balance = Balance - @CommissionAmount,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE UserId = @UserId;
                """, connection, transaction);
            deductWalletCommand.Parameters.AddWithValue("@CommissionAmount", request.CommissionAmount);
            deductWalletCommand.Parameters.AddWithValue("@UserId", userId);
            deductWalletCommand.ExecuteNonQuery();

            transaction.Commit();
            return Ok(new { message = "Sale request accepted and commission deducted." });
        }
        catch (Exception)
        {
            transaction.Rollback();
            return StatusCode(500, new { message = "An error occurred while processing the sale." });
        }
    }

    private static string? ValidateRegistration(
        SmartBazarRegisterRequest request,
        string name,
        string phone,
        string role)
    {
        if (name.Length < 3)
        {
            return "Full name must contain at least 3 characters.";
        }

        if (phone.Length != 11)
        {
            return "Phone number must be 11 digits.";
        }

        if (role is not (Roles.Customer or Roles.Shopkeeper))
        {
            return "Role must be either customer or shopkeeper.";
        }

        if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 4)
        {
            return "Password must be at least 4 characters long.";
        }

        if (request.Password != request.ConfirmPassword)
        {
            return "Password and confirm password do not match.";
        }

        return null;
    }

    private static string NormalizePhone(string phoneNumber) =>
        new(phoneNumber.Where(char.IsDigit).ToArray());

    private static string NormalizeRole(string? role)
    {
        var normalizedRole = role?.Trim().ToLowerInvariant();
        return normalizedRole switch
        {
            "customer" => Roles.Customer,
            "shopkeeper" or "shop keeper" => Roles.Shopkeeper,
            _ => string.Empty
        };
    }
}

public sealed class SmartBazarLoanApplyRequest
{
    public int UserId { get; set; }
    public decimal Amount { get; set; }
    public int TenureMonths { get; set; }
    public string? Purpose { get; set; }
}

public sealed class SmartBazarLoanRepayRequest
{
    public int InstallmentId { get; set; }
    public int UserId { get; set; }
    public string? PaymentMethod { get; set; }
}
