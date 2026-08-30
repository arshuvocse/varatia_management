using Microsoft.Data.SqlClient;
using PromotionWeb.Models;
using System.Data;

namespace PromotionWeb.Services;

public sealed class LoanStore(IConfiguration configuration)
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

            const string schemaSql = """
                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.tbl_Users') AND name = N'OfficeName')
                BEGIN
                    ALTER TABLE dbo.tbl_Users ADD
                        OfficeName NVARCHAR(200) NULL,
                        OfficeAddress NVARCHAR(500) NULL,
                        RoadNo NVARCHAR(100) NULL,
                        AreaName NVARCHAR(150) NULL,
                        Thana NVARCHAR(150) NULL,
                        OfficeHours NVARCHAR(100) NULL,
                        ContactPhone NVARCHAR(50) NULL,
                        Latitude DECIMAL(18, 8) NULL,
                        Longitude DECIMAL(18, 8) NULL;
                END;

                IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_Loans')
                BEGIN
                    CREATE TABLE dbo.tbl_Loans (
                        Id INT IDENTITY(1,1) PRIMARY KEY,
                        UserId INT NOT NULL,
                        UserRole NVARCHAR(50) NOT NULL,
                        CustomerName NVARCHAR(150) NULL,
                        Phone NVARCHAR(50) NOT NULL,
                        LoanAmount DECIMAL(18,2) NOT NULL,
                        InterestRate DECIMAL(5,2) NOT NULL DEFAULT 9.00,
                        TenureMonths INT NOT NULL,
                        MonthlyInstallment DECIMAL(18,2) NOT NULL,
                        ProcessingFee DECIMAL(18,2) NOT NULL DEFAULT 0.00,
                        TotalInterest DECIMAL(18,2) NOT NULL DEFAULT 0.00,
                        TotalPayable DECIMAL(18,2) NOT NULL,
                        RemainingAmount DECIMAL(18,2) NOT NULL,
                        Purpose NVARCHAR(250) NULL,
                        Status NVARCHAR(50) NOT NULL DEFAULT N'Approved',
                        AppliedAt DATETIME NOT NULL DEFAULT GETDATE(),
                        ApprovedAt DATETIME NULL DEFAULT GETDATE(),
                        DisbursedAt DATETIME NULL DEFAULT GETDATE(),
                        CompletedAt DATETIME NULL
                    );
                    CREATE INDEX IX_tbl_Loans_UserId ON dbo.tbl_Loans(UserId);
                END;

                IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_LoanInstallments')
                BEGIN
                    CREATE TABLE dbo.tbl_LoanInstallments (
                        Id INT IDENTITY(1,1) PRIMARY KEY,
                        LoanId INT NOT NULL,
                        InstallmentNumber INT NOT NULL,
                        DueDate DATETIME NOT NULL,
                        Amount DECIMAL(18,2) NOT NULL,
                        PrincipalPortion DECIMAL(18,2) NOT NULL DEFAULT 0.00,
                        InterestPortion DECIMAL(18,2) NOT NULL DEFAULT 0.00,
                        PaidAmount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
                        Status NVARCHAR(50) NOT NULL DEFAULT N'Pending',
                        PaidAt DATETIME NULL,
                        PaymentMethod NVARCHAR(50) NULL,
                        CONSTRAINT FK_tbl_LoanInstallments_LoanId FOREIGN KEY (LoanId) REFERENCES dbo.tbl_Loans(Id) ON DELETE CASCADE
                    );
                    CREATE INDEX IX_tbl_LoanInstallments_LoanId ON dbo.tbl_LoanInstallments(LoanId);
                END;

                IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_DistrictPricingConfig')
                BEGIN
                    CREATE TABLE dbo.tbl_DistrictPricingConfig (
                        Id INT IDENTITY(1,1) PRIMARY KEY,
                        DistrictName NVARCHAR(100) NOT NULL UNIQUE,
                        TransportMultiplier DECIMAL(5,4) NOT NULL DEFAULT 1.0000,
                        DefaultDeliveryCharge DECIMAL(18,2) NOT NULL DEFAULT 40.00,
                        ShopkeeperMarginPercent DECIMAL(5,2) NOT NULL DEFAULT 10.00,
                        CompanyMarginPercent DECIMAL(5,2) NOT NULL DEFAULT 5.00
                    );

                    INSERT INTO dbo.tbl_DistrictPricingConfig (DistrictName, TransportMultiplier, DefaultDeliveryCharge, ShopkeeperMarginPercent, CompanyMarginPercent)
                    VALUES
                    (N'ঢাকা', 1.0000, 30.00, 10.00, 5.00),
                    (N'চট্টগ্রাম', 1.0200, 40.00, 10.00, 5.00),
                    (N'সিলেট', 1.0250, 40.00, 10.00, 5.00),
                    (N'রাজশাহী', 1.0300, 45.00, 10.00, 5.00),
                    (N'খুলনা', 1.0300, 45.00, 10.00, 5.00),
                    (N'বরিশাল', 1.0350, 50.00, 10.00, 5.00),
                    (N'রংপুর', 1.0400, 50.00, 10.00, 5.00),
                    (N'ময়মনসিংহ', 1.0200, 40.00, 10.00, 5.00);
                END;
                """;
            using var command = new SqlCommand(schemaSql, connection);
            command.ExecuteNonQuery();
            _schemaReady = true;
        }
    }

    public LoanCalculationResult CalculateLoan(decimal amount, int tenureMonths)
    {
        amount = Math.Clamp(amount, 5000m, 50000m);
        if (tenureMonths is not (3 or 6 or 9 or 12)) tenureMonths = 6;

        const decimal annualInterestRate = 0.09m; // 9% flat simple annual interest for nano-loans
        var totalInterest = Math.Round(amount * (annualInterestRate / 12m) * tenureMonths, 2);
        var processingFee = Math.Round(amount * 0.005m, 2); // 0.5%
        if (processingFee < 25m) processingFee = 25m;

        var totalPayable = amount + totalInterest + processingFee;
        var monthlyInstallment = Math.Round(totalPayable / tenureMonths, 2);

        return new LoanCalculationResult
        {
            LoanAmount = amount,
            TenureMonths = tenureMonths,
            MonthlyInstallment = monthlyInstallment,
            TotalInterest = totalInterest,
            ProcessingFee = processingFee,
            TotalPayable = totalPayable,
            MonthlyInterestRate = 0.75m,
            FirstInstallmentDate = DateTime.Today.AddMonths(1)
        };
    }

    public LoanEligibilityViewModel GetEligibility(int userId, string role, string phone)
    {
        EnsureSchema();
        var activeLoan = GetActiveLoan(userId);
        if (activeLoan != null)
        {
            return new LoanEligibilityViewModel
            {
                IsEligible = false,
                HasActiveLoan = true,
                AvailableLimit = 0m,
                EligibilityMessage = $"আপনার একটি সক্রিয় লোন চলমান রয়েছে (লোন নং #{activeLoan.Id:D5})। এটি সম্পূর্ণ পরিশোধের পর নতুন লোন পাওয়া যাবে।"
            };
        }

        return new LoanEligibilityViewModel
        {
            IsEligible = true,
            HasActiveLoan = false,
            MaxLoanLimit = 50000m,
            MinLoanLimit = 5000m,
            AvailableLimit = 50000m,
            AnnualInterestRate = 9.00m,
            ProcessingFeeRate = 0.50m,
            AllowedTenures = [3, 6, 9, 12],
            EligibilityMessage = "অভিনন্দন! আপনি বিকাশের মতো তাৎক্ষণিক ডিজিটাল ন্যানো লোনের জন্য যোগ্য।"
        };
    }

    public LoanItemViewModel ApplyLoan(int userId, string userRole, string customerName, string phone, LoanApplicationInputModel input)
    {
        EnsureSchema();
        var calc = CalculateLoan(input.Amount, input.TenureMonths);

        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string insertLoanSql = """
                INSERT INTO dbo.tbl_Loans
                    (UserId, UserRole, CustomerName, Phone, LoanAmount, InterestRate, TenureMonths,
                     MonthlyInstallment, ProcessingFee, TotalInterest, TotalPayable, RemainingAmount,
                     Purpose, Status, AppliedAt, ApprovedAt, DisbursedAt)
                VALUES
                    (@UserId, @UserRole, @CustomerName, @Phone, @LoanAmount, 9.00, @TenureMonths,
                     @MonthlyInstallment, @ProcessingFee, @TotalInterest, @TotalPayable, @RemainingAmount,
                     @Purpose, N'Approved', GETDATE(), GETDATE(), GETDATE());

                SELECT CONVERT(INT, SCOPE_IDENTITY());
                """;

            using var cmdLoan = new SqlCommand(insertLoanSql, connection, transaction);
            cmdLoan.Parameters.AddWithValue("@UserId", userId);
            cmdLoan.Parameters.AddWithValue("@UserRole", userRole);
            cmdLoan.Parameters.AddWithValue("@CustomerName", (object?)customerName ?? DBNull.Value);
            cmdLoan.Parameters.AddWithValue("@Phone", phone);
            cmdLoan.Parameters.AddWithValue("@LoanAmount", calc.LoanAmount);
            cmdLoan.Parameters.AddWithValue("@TenureMonths", calc.TenureMonths);
            cmdLoan.Parameters.AddWithValue("@MonthlyInstallment", calc.MonthlyInstallment);
            cmdLoan.Parameters.AddWithValue("@ProcessingFee", calc.ProcessingFee);
            cmdLoan.Parameters.AddWithValue("@TotalInterest", calc.TotalInterest);
            cmdLoan.Parameters.AddWithValue("@TotalPayable", calc.TotalPayable);
            cmdLoan.Parameters.AddWithValue("@RemainingAmount", calc.TotalPayable);
            cmdLoan.Parameters.AddWithValue("@Purpose", string.IsNullOrWhiteSpace(input.Purpose) ? "ব্যক্তিগত প্রয়োজন" : input.Purpose.Trim());

            var loanId = Convert.ToInt32(cmdLoan.ExecuteScalar());

            // Insert installments
            for (var i = 1; i <= calc.TenureMonths; i++)
            {
                const string insertInstallmentSql = """
                    INSERT INTO dbo.tbl_LoanInstallments
                        (LoanId, InstallmentNumber, DueDate, Amount, PrincipalPortion, InterestPortion, PaidAmount, Status)
                    VALUES
                        (@LoanId, @InstallmentNumber, @DueDate, @Amount, @PrincipalPortion, @InterestPortion, 0.00, N'Pending');
                    """;
                using var cmdInst = new SqlCommand(insertInstallmentSql, connection, transaction);
                cmdInst.Parameters.AddWithValue("@LoanId", loanId);
                cmdInst.Parameters.AddWithValue("@InstallmentNumber", i);
                cmdInst.Parameters.AddWithValue("@DueDate", DateTime.Today.AddMonths(i));
                cmdInst.Parameters.AddWithValue("@Amount", calc.MonthlyInstallment);
                cmdInst.Parameters.AddWithValue("@PrincipalPortion", Math.Round(calc.LoanAmount / calc.TenureMonths, 2));
                cmdInst.Parameters.AddWithValue("@InterestPortion", Math.Round((calc.TotalInterest + calc.ProcessingFee) / calc.TenureMonths, 2));
                cmdInst.ExecuteNonQuery();
            }

            // Optionally credit user wallet
            const string creditWalletSql = """
                IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_Wallets')
                BEGIN
                    UPDATE dbo.tbl_Wallets
                    SET Balance = Balance + @Amount, UpdatedAt = GETDATE()
                    WHERE UserId = @UserId;
                END
                """;
            using var cmdWallet = new SqlCommand(creditWalletSql, connection, transaction);
            cmdWallet.Parameters.AddWithValue("@Amount", calc.LoanAmount);
            cmdWallet.Parameters.AddWithValue("@UserId", userId);
            cmdWallet.ExecuteNonQuery();

            transaction.Commit();
            return GetLoanById(loanId, connection) ?? throw new InvalidOperationException("Loan creation failed.");
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public LoanItemViewModel? GetActiveLoan(int userId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        const string sql = """
            SELECT TOP 1 Id, UserId, UserRole, CustomerName, Phone, LoanAmount, InterestRate,
                         TenureMonths, MonthlyInstallment, ProcessingFee, TotalInterest, TotalPayable,
                         RemainingAmount, Purpose, Status, AppliedAt, ApprovedAt, DisbursedAt, CompletedAt
            FROM dbo.tbl_Loans
            WHERE UserId = @UserId AND Status IN (N'Approved', N'Disbursed') AND RemainingAmount > 0
            ORDER BY Id DESC;
            """;

        using var cmd = new SqlCommand(sql, connection);
        cmd.Parameters.AddWithValue("@UserId", userId);
        using var reader = cmd.ExecuteReader();
        if (!reader.Read()) return null;

        var loan = MapLoan(reader);
        reader.Close();

        return PopulateInstallments(loan, connection);
    }

    public IReadOnlyList<LoanItemViewModel> GetUserLoans(int userId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        const string sql = """
            SELECT Id, UserId, UserRole, CustomerName, Phone, LoanAmount, InterestRate,
                   TenureMonths, MonthlyInstallment, ProcessingFee, TotalInterest, TotalPayable,
                   RemainingAmount, Purpose, Status, AppliedAt, ApprovedAt, DisbursedAt, CompletedAt
            FROM dbo.tbl_Loans
            WHERE UserId = @UserId
            ORDER BY Id DESC;
            """;

        using var cmd = new SqlCommand(sql, connection);
        cmd.Parameters.AddWithValue("@UserId", userId);
        using var reader = cmd.ExecuteReader();
        var loans = new List<LoanItemViewModel>();
        while (reader.Read())
        {
            loans.Add(MapLoan(reader));
        }
        reader.Close();

        return loans.Select(l => PopulateInstallments(l, connection)).ToList();
    }

    public bool PayInstallment(int installmentId, int userId, string paymentMethod = "Wallet")
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            // Verify installment and ownership
            const string getSql = """
                SELECT i.Id, i.LoanId, i.Amount, i.PaidAmount, i.Status, l.UserId, l.RemainingAmount
                FROM dbo.tbl_LoanInstallments i
                INNER JOIN dbo.tbl_Loans l ON l.Id = i.LoanId
                WHERE i.Id = @InstallmentId AND l.UserId = @UserId;
                """;

            using var cmdGet = new SqlCommand(getSql, connection, transaction);
            cmdGet.Parameters.AddWithValue("@InstallmentId", installmentId);
            cmdGet.Parameters.AddWithValue("@UserId", userId);
            using var reader = cmdGet.ExecuteReader();
            if (!reader.Read()) return false;

            var loanId = reader.GetInt32(1);
            var amount = reader.GetDecimal(2);
            var currentStatus = reader.GetString(4);
            var remaining = reader.GetDecimal(6);
            reader.Close();

            if (currentStatus == "Paid") return true;

            // Mark installment paid
            const string updateInstSql = """
                UPDATE dbo.tbl_LoanInstallments
                SET Status = N'Paid', PaidAmount = @Amount, PaidAt = GETDATE(), PaymentMethod = @PaymentMethod
                WHERE Id = @InstallmentId;
                """;
            using var cmdInst = new SqlCommand(updateInstSql, connection, transaction);
            cmdInst.Parameters.AddWithValue("@Amount", amount);
            cmdInst.Parameters.AddWithValue("@PaymentMethod", paymentMethod);
            cmdInst.Parameters.AddWithValue("@InstallmentId", installmentId);
            cmdInst.ExecuteNonQuery();

            // Update remaining in loan
            var newRemaining = Math.Max(0m, remaining - amount);
            var isCompleted = newRemaining <= 0;

            const string updateLoanSql = """
                UPDATE dbo.tbl_Loans
                SET RemainingAmount = @NewRemaining,
                    Status = CASE WHEN @IsCompleted = 1 THEN N'Completed' ELSE Status END,
                    CompletedAt = CASE WHEN @IsCompleted = 1 THEN GETDATE() ELSE CompletedAt END
                WHERE Id = @LoanId;
                """;
            using var cmdLoan = new SqlCommand(updateLoanSql, connection, transaction);
            cmdLoan.Parameters.AddWithValue("@NewRemaining", newRemaining);
            cmdLoan.Parameters.AddWithValue("@IsCompleted", isCompleted ? 1 : 0);
            cmdLoan.Parameters.AddWithValue("@LoanId", loanId);
            cmdLoan.ExecuteNonQuery();

            transaction.Commit();
            return true;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public AgentOfficeLocationViewModel? GetAgentOfficeForDistrict(string districtName)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        const string sql = """
            SELECT TOP 1 u.Id, u.Name, u.Phone, u.OfficeName, u.OfficeAddress, u.RoadNo,
                         u.AreaName, u.Thana, d.Name AS DistrictName, div.Name AS DivisionName,
                         u.OfficeHours, u.ContactPhone, u.Latitude, u.Longitude, u.ProfilePhotoPath
            FROM dbo.tbl_Users u
            LEFT JOIN dbo.tbl_Districts d ON d.Id = u.DistrictId
            LEFT JOIN dbo.tbl_Divisions div ON div.Id = d.DivisionId
            WHERE u.Role = N'Agent' AND u.IsActive = 1
              AND (d.Name = @DistrictName OR @DistrictName IS NULL OR @DistrictName = '')
            ORDER BY CASE WHEN d.Name = @DistrictName THEN 0 ELSE 1 END, u.Id DESC;
            """;

        using var cmd = new SqlCommand(sql, connection);
        cmd.Parameters.AddWithValue("@DistrictName", (object?)districtName ?? DBNull.Value);
        using var reader = cmd.ExecuteReader();
        if (!reader.Read()) return null;

        return new AgentOfficeLocationViewModel
        {
            AgentId = reader.GetInt32(0),
            AgentName = reader.IsDBNull(1) ? "অফিসিয়াল এজেন্ট" : reader.GetString(1),
            AgentPhone = reader.IsDBNull(2) ? "" : reader.GetString(2),
            OfficeName = reader.IsDBNull(3) ? "আমার ঠিকানা এরিয়া অফিস" : reader.GetString(3),
            OfficeAddress = reader.IsDBNull(4) ? "প্রধান বাণিজ্যিক এলাকা" : reader.GetString(4),
            RoadNo = reader.IsDBNull(5) ? null : reader.GetString(5),
            AreaName = reader.IsDBNull(6) ? null : reader.GetString(6),
            Thana = reader.IsDBNull(7) ? null : reader.GetString(7),
            DistrictName = reader.IsDBNull(8) ? districtName : reader.GetString(8),
            DivisionName = reader.IsDBNull(9) ? "ঢাকা" : reader.GetString(9),
            OfficeHours = reader.IsDBNull(10) ? "সকাল ৯:০০ - রাত ৮:০০ (প্রতিদিন)" : reader.GetString(10),
            ContactPhone = reader.IsDBNull(11) ? (reader.IsDBNull(2) ? "09678-123456" : reader.GetString(2)) : reader.GetString(11),
            Latitude = reader.IsDBNull(12) ? 23.8103m : reader.GetDecimal(12),
            Longitude = reader.IsDBNull(13) ? 90.4125m : reader.GetDecimal(13),
            ProfilePictureUrl = reader.IsDBNull(14) ? null : reader.GetString(14)
        };
    }

    public void UpdateAgentOffice(int agentUserId, string officeName, string officeAddress, string? roadNo, string? areaName, string? thana, string? contactPhone, string? officeHours, decimal? lat, decimal? lng)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        const string sql = """
            UPDATE dbo.tbl_Users
            SET OfficeName = @OfficeName,
                OfficeAddress = @OfficeAddress,
                RoadNo = @RoadNo,
                AreaName = @AreaName,
                Thana = @Thana,
                ContactPhone = @ContactPhone,
                OfficeHours = @OfficeHours,
                Latitude = @Latitude,
                Longitude = @Longitude
            WHERE Id = @UserId AND Role = N'Agent';
            """;

        using var cmd = new SqlCommand(sql, connection);
        cmd.Parameters.AddWithValue("@OfficeName", officeName.Trim());
        cmd.Parameters.AddWithValue("@OfficeAddress", officeAddress.Trim());
        cmd.Parameters.AddWithValue("@RoadNo", (object?)roadNo?.Trim() ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@AreaName", (object?)areaName?.Trim() ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@Thana", (object?)thana?.Trim() ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@ContactPhone", (object?)contactPhone?.Trim() ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@OfficeHours", (object?)officeHours?.Trim() ?? "সকাল ৯:০০ - রাত ৮:০০");
        cmd.Parameters.AddWithValue("@Latitude", (object?)lat ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@Longitude", (object?)lng ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@UserId", agentUserId);
        cmd.ExecuteNonQuery();
    }

    private LoanItemViewModel? GetLoanById(int id, SqlConnection connection)
    {
        const string sql = """
            SELECT Id, UserId, UserRole, CustomerName, Phone, LoanAmount, InterestRate,
                   TenureMonths, MonthlyInstallment, ProcessingFee, TotalInterest, TotalPayable,
                   RemainingAmount, Purpose, Status, AppliedAt, ApprovedAt, DisbursedAt, CompletedAt
            FROM dbo.tbl_Loans
            WHERE Id = @Id;
            """;
        using var cmd = new SqlCommand(sql, connection);
        cmd.Parameters.AddWithValue("@Id", id);
        using var reader = cmd.ExecuteReader();
        if (!reader.Read()) return null;
        var loan = MapLoan(reader);
        reader.Close();
        return PopulateInstallments(loan, connection);
    }

    private static LoanItemViewModel MapLoan(SqlDataReader reader)
    {
        return new LoanItemViewModel
        {
            Id = reader.GetInt32(0),
            UserId = reader.GetInt32(1),
            UserRole = reader.GetString(2),
            CustomerName = reader.IsDBNull(3) ? "" : reader.GetString(3),
            Phone = reader.GetString(4),
            LoanAmount = reader.GetDecimal(5),
            InterestRate = reader.GetDecimal(6),
            TenureMonths = reader.GetInt32(7),
            MonthlyInstallment = reader.GetDecimal(8),
            ProcessingFee = reader.GetDecimal(9),
            TotalInterest = reader.GetDecimal(10),
            TotalPayable = reader.GetDecimal(11),
            RemainingAmount = reader.GetDecimal(12),
            Purpose = reader.IsDBNull(13) ? "" : reader.GetString(13),
            Status = reader.GetString(14),
            AppliedAt = reader.GetDateTime(15),
            ApprovedAt = reader.IsDBNull(16) ? null : reader.GetDateTime(16),
            DisbursedAt = reader.IsDBNull(17) ? null : reader.GetDateTime(17),
            CompletedAt = reader.IsDBNull(18) ? null : reader.GetDateTime(18)
        };
    }

    private static LoanItemViewModel PopulateInstallments(LoanItemViewModel loan, SqlConnection connection)
    {
        const string sql = """
            SELECT Id, LoanId, InstallmentNumber, DueDate, Amount, PrincipalPortion, InterestPortion, PaidAmount, Status, PaidAt, PaymentMethod
            FROM dbo.tbl_LoanInstallments
            WHERE LoanId = @LoanId
            ORDER BY InstallmentNumber ASC;
            """;
        using var cmd = new SqlCommand(sql, connection);
        cmd.Parameters.AddWithValue("@LoanId", loan.Id);
        using var reader = cmd.ExecuteReader();
        var installments = new List<LoanInstallmentItemViewModel>();
        while (reader.Read())
        {
            installments.Add(new LoanInstallmentItemViewModel
            {
                Id = reader.GetInt32(0),
                LoanId = reader.GetInt32(1),
                InstallmentNumber = reader.GetInt32(2),
                DueDate = reader.GetDateTime(3),
                Amount = reader.GetDecimal(4),
                PrincipalPortion = reader.GetDecimal(5),
                InterestPortion = reader.GetDecimal(6),
                PaidAmount = reader.GetDecimal(7),
                Status = reader.GetString(8),
                PaidAt = reader.IsDBNull(9) ? null : reader.GetDateTime(9),
                PaymentMethod = reader.IsDBNull(10) ? null : reader.GetString(10)
            });
        }
        reader.Close();

        var nextDue = installments.FirstOrDefault(i => i.Status != "Paid");

        return new LoanItemViewModel
        {
            Id = loan.Id,
            UserId = loan.UserId,
            UserRole = loan.UserRole,
            CustomerName = loan.CustomerName,
            Phone = loan.Phone,
            LoanAmount = loan.LoanAmount,
            InterestRate = loan.InterestRate,
            TenureMonths = loan.TenureMonths,
            MonthlyInstallment = loan.MonthlyInstallment,
            ProcessingFee = loan.ProcessingFee,
            TotalInterest = loan.TotalInterest,
            TotalPayable = loan.TotalPayable,
            RemainingAmount = loan.RemainingAmount,
            Purpose = loan.Purpose,
            Status = loan.Status,
            AppliedAt = loan.AppliedAt,
            ApprovedAt = loan.ApprovedAt,
            DisbursedAt = loan.DisbursedAt,
            CompletedAt = loan.CompletedAt,
            Installments = installments,
            NextDueInstallment = nextDue
        };
    }
}
