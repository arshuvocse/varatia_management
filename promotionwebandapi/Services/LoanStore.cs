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

                IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_ShopCategories')
                BEGIN
                    CREATE TABLE dbo.tbl_ShopCategories (
                        Id INT IDENTITY(1,1) PRIMARY KEY,
                        Name NVARCHAR(100) NOT NULL UNIQUE,
                        BanglaName NVARCHAR(100) NOT NULL,
                        Icon NVARCHAR(50) NOT NULL DEFAULT '🛍️',
                        Description NVARCHAR(250) NULL,
                        DisplayOrder INT NOT NULL DEFAULT 0,
                        IsActive BIT NOT NULL DEFAULT 1,
                        CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
                    );

                    INSERT INTO dbo.tbl_ShopCategories (Name, BanglaName, Icon, Description, DisplayOrder)
                    VALUES
                    (N'মুদির দোকান', N'মুদি দোকান', N'🛒', N'চাল, ডাল, তেল, চিনি, লবণ, আটা, মসলা ও নিত্যপ্রয়োজনীয় গ্রোসারি', 1),
                    (N'কসমেটিক্স', N'কসমেটিক্স ও রূপচর্চা', N'💄', N'স্কিনকেয়ার, শ্যাম্পু, সাবান, লোশন ও প্রসাধনী সামগ্রী', 2),
                    (N'ফার্মেসি', N'ফার্মেসি ও ঔষধ', N'💊', N'জরুরী ঔষধ, প্রেসক্রিপশন মেডিসিন, ব্যান্ডেজ ও স্বাস্থ্যসেবা পণ্য', 3),
                    (N'জামা-কাপড়', N'পোশাক ও বস্ত্র', N'👕', N'শার্ট, টি-শার্ট, পাঞ্জাবি, শাড়ি, থ্রি-পিস ও ট্রাউজার', 4),
                    (N'জুতার দোকান', N'জুতা ও স্যান্ডেল', N'👟', N'লেদার শু, কেডস, ক্যাজুয়াল শু, স্লিপার ও শিশুদের জুতা', 5),
                    (N'কাঁচা বাজার', N'কাঁচা বাজার ও ফলমূল', N'🥬', N'তাজা শাক-সবজি, মাছ-মাংস, ফলমূল ও কাঁচাবাজার', 6),
                    (N'ইলেকট্রনিক্স শপ', N'ইলেকট্রনিক্স ও হোম অ্যাপ্লায়েন্স', N'⚡', N'ফ্যান, লাইট, ব্লেন্ডার, আয়রন, মাল্টিপ্লাগ ও ইলেকট্রিক যন্ত্রপাতি', 7),
                    (N'মোবাইল ফোনের দোকান', N'মোবাইল ও গ্যাজেট', N'📱', N'স্মার্টফোন, চার্জার, কেবল, হেডফোন, পাওয়ার ব্যাংক ও অ্যাক্সেসরিজ', 8);
                END;

                IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_LoanConfig')
                BEGIN
                    CREATE TABLE dbo.tbl_LoanConfig (
                        Id INT IDENTITY(1,1) PRIMARY KEY,
                        ConfigKey NVARCHAR(50) NOT NULL UNIQUE,
                        MinAmount DECIMAL(18,2) NOT NULL DEFAULT 5000.00,
                        MaxAmount DECIMAL(18,2) NOT NULL DEFAULT 50000.00,
                        AnnualInterestRate DECIMAL(5,2) NOT NULL DEFAULT 9.00,
                        ProcessingFeePercent DECIMAL(5,2) NOT NULL DEFAULT 0.50,
                        MinProcessingFee DECIMAL(18,2) NOT NULL DEFAULT 25.00,
                        AllowedTenures NVARCHAR(50) NOT NULL DEFAULT '3,6,9,12',
                        IsActive BIT NOT NULL DEFAULT 1,
                        UpdatedAt DATETIME NOT NULL DEFAULT GETDATE()
                    );

                    INSERT INTO dbo.tbl_LoanConfig (ConfigKey, MinAmount, MaxAmount, AnnualInterestRate, ProcessingFeePercent, MinProcessingFee, AllowedTenures)
                    VALUES (N'DefaultCustomerLoan', 5000.00, 50000.00, 9.00, 0.50, 25.00, N'3,6,9,12');
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
                        CompletedAt DATETIME NULL,
                        AdminNotes NVARCHAR(500) NULL,
                        ApprovedByUserId INT NULL
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
                        DistrictAdjustmentAmount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
                        DefaultDeliveryCharge DECIMAL(18,2) NOT NULL DEFAULT 40.00,
                        ServiceCharge DECIMAL(18,2) NOT NULL DEFAULT 10.00,
                        PlatformCharge DECIMAL(18,2) NOT NULL DEFAULT 5.00,
                        ShopkeeperMarginPercent DECIMAL(5,2) NOT NULL DEFAULT 10.00,
                        CompanyMarginPercent DECIMAL(5,2) NOT NULL DEFAULT 5.00,
                        IsActive BIT NOT NULL DEFAULT 1
                    );

                    INSERT INTO dbo.tbl_DistrictPricingConfig (DistrictName, TransportMultiplier, DistrictAdjustmentAmount, DefaultDeliveryCharge, ServiceCharge, PlatformCharge, ShopkeeperMarginPercent, CompanyMarginPercent)
                    VALUES
                    (N'Dhaka', 1.0000, 0.00, 30.00, 10.00, 5.00, 10.00, 5.00),
                    (N'Chattogram', 1.0200, 5.00, 40.00, 10.00, 5.00, 10.00, 5.00),
                    (N'Sylhet', 1.0250, 5.00, 40.00, 10.00, 5.00, 10.00, 5.00),
                    (N'Rajshahi', 1.0300, 8.00, 45.00, 10.00, 5.00, 10.00, 5.00),
                    (N'Khulna', 1.0300, 8.00, 45.00, 10.00, 5.00, 10.00, 5.00),
                    (N'Barishal', 1.0350, 10.00, 50.00, 10.00, 5.00, 10.00, 5.00),
                    (N'Rangpur', 1.0400, 10.00, 50.00, 10.00, 5.00, 10.00, 5.00),
                    (N'Mymensingh', 1.0200, 5.00, 40.00, 10.00, 5.00, 10.00, 5.00),
                    (N'Gazipur', 1.0050, 2.00, 35.00, 10.00, 5.00, 10.00, 5.00),
                    (N'Narayanganj', 1.0050, 2.00, 35.00, 10.00, 5.00, 10.00, 5.00),
                    (N'Cumilla', 1.0150, 4.00, 35.00, 10.00, 5.00, 10.00, 5.00),
                    (N'Bogura', 1.0250, 6.00, 40.00, 10.00, 5.00, 10.00, 5.00),
                    (N'Cox''s Bazar', 1.0450, 12.00, 55.00, 10.00, 5.00, 10.00, 5.00);
                END;
                """;
            using (var command = new SqlCommand(schemaSql, connection) { CommandTimeout = 120 })
            {
                command.ExecuteNonQuery();
            }
            RenameLegacyBanglaDistrictNames(connection);
            _schemaReady = true;
        }
    }

    /// <summary>
    /// tbl_DistrictPricingConfig was originally seeded with Bangla district names, which never matched
    /// dbo.tbl_Districts.Name (English) used by real shop/agent records -- so nearby-shop and district-price
    /// lookups silently returned nothing for every district. Idempotent: each UPDATE affects zero rows once
    /// already renamed.
    /// </summary>
    private static void RenameLegacyBanglaDistrictNames(SqlConnection connection)
    {
        var renameMap = new (string Bangla, string English)[]
        {
            ("ঢাকা", "Dhaka"),
            ("চট্টগ্রাম", "Chattogram"),
            ("সিলেট", "Sylhet"),
            ("রাজশাহী", "Rajshahi"),
            ("খুলনা", "Khulna"),
            ("বরিশাল", "Barishal"),
            ("রংপুর", "Rangpur"),
            ("ময়মনসিংহ", "Mymensingh"),
        };

        using var command = new SqlCommand("""
            IF EXISTS (SELECT 1 FROM dbo.tbl_DistrictPricingConfig WHERE DistrictName = @English)
            BEGIN
                DELETE FROM dbo.tbl_DistrictPricingConfig WHERE DistrictName = @Bangla;
            END
            ELSE
            BEGIN
                UPDATE dbo.tbl_DistrictPricingConfig SET DistrictName = @English WHERE DistrictName = @Bangla;
            END
            """,
            connection)
        { CommandTimeout = 120 };
        var banglaParam = command.Parameters.Add("@Bangla", System.Data.SqlDbType.NVarChar, 100);
        var englishParam = command.Parameters.Add("@English", System.Data.SqlDbType.NVarChar, 100);

        foreach (var (bangla, english) in renameMap)
        {
            banglaParam.Value = bangla;
            englishParam.Value = english;
            command.ExecuteNonQuery();
        }
    }

    public LoanCalculationResult CalculateLoan(decimal amount, int tenureMonths)
    {
        EnsureSchema();
        var config = GetLoanConfig();

        amount = Math.Clamp(amount, config.MinAmount, config.MaxAmount);
        var allowedTenures = config.AllowedTenures.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(s => int.TryParse(s, out var v) ? v : 6).ToHashSet();
        if (!allowedTenures.Contains(tenureMonths)) tenureMonths = 6;

        var annualRate = config.AnnualInterestRate / 100.0m;
        var totalInterest = Math.Round(amount * (annualRate / 12.0m) * tenureMonths, 2);
        var processingFee = Math.Round(amount * (config.ProcessingFeePercent / 100.0m), 2);
        if (processingFee < config.MinProcessingFee) processingFee = config.MinProcessingFee;

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
            MonthlyInterestRate = Math.Round((config.AnnualInterestRate / 12.0m), 2),
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

        var config = GetLoanConfig();
        var tenures = config.AllowedTenures.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(s => int.TryParse(s, out var v) ? v : 6).ToArray();

        return new LoanEligibilityViewModel
        {
            IsEligible = true,
            HasActiveLoan = false,
            MaxLoanLimit = config.MaxAmount,
            MinLoanLimit = config.MinAmount,
            AvailableLimit = config.MaxAmount,
            AnnualInterestRate = config.AnnualInterestRate,
            ProcessingFeeRate = config.ProcessingFeePercent,
            AllowedTenures = tenures.Length > 0 ? tenures : [3, 6, 9, 12],
            EligibilityMessage = "অভিনন্দন! আপনি বিকাশের মতো তাৎক্ষণিক ডিজিটাল ন্যানো লোনের জন্য যোগ্য।"
        };
    }

    public LoanItemViewModel ApplyLoan(int userId, string userRole, string customerName, string phone, LoanApplicationInputModel input)
    {
        EnsureSchema();
        var calc = CalculateLoan(input.Amount, input.TenureMonths);
        var config = GetLoanConfig();

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
                    (@UserId, @UserRole, @CustomerName, @Phone, @LoanAmount, @InterestRate, @TenureMonths,
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
            cmdLoan.Parameters.AddWithValue("@InterestRate", config.AnnualInterestRate);
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

            // Credit user wallet
            const string creditWalletSql = """
                IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_UserWallets')
                BEGIN
                    IF EXISTS (SELECT 1 FROM dbo.tbl_UserWallets WHERE UserId = @UserId)
                    BEGIN
                        UPDATE dbo.tbl_UserWallets
                        SET Balance = Balance + @Amount, UpdatedAt = SYSUTCDATETIME()
                        WHERE UserId = @UserId;
                    END
                    ELSE
                    BEGIN
                        INSERT INTO dbo.tbl_UserWallets (UserId, Balance, UpdatedAt)
                        VALUES (@UserId, @Amount, SYSUTCDATETIME());
                    END
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
                         RemainingAmount, Purpose, Status, AppliedAt, ApprovedAt, DisbursedAt, CompletedAt, AdminNotes
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
                   RemainingAmount, Purpose, Status, AppliedAt, ApprovedAt, DisbursedAt, CompletedAt, AdminNotes
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

    public IReadOnlyList<LoanItemViewModel> GetAllLoans(string? status = null, string? role = null)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        const string sql = """
            SELECT Id, UserId, UserRole, CustomerName, Phone, LoanAmount, InterestRate,
                   TenureMonths, MonthlyInstallment, ProcessingFee, TotalInterest, TotalPayable,
                   RemainingAmount, Purpose, Status, AppliedAt, ApprovedAt, DisbursedAt, CompletedAt, AdminNotes
            FROM dbo.tbl_Loans
            WHERE (@Status IS NULL OR Status = @Status)
              AND (@Role IS NULL OR UserRole = @Role)
            ORDER BY Id DESC;
            """;

        using var cmd = new SqlCommand(sql, connection);
        cmd.Parameters.AddWithValue("@Status", (object?)status ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@Role", (object?)role ?? DBNull.Value);
        using var reader = cmd.ExecuteReader();
        var loans = new List<LoanItemViewModel>();
        while (reader.Read())
        {
            loans.Add(MapLoan(reader));
        }
        reader.Close();

        return loans.Select(l => PopulateInstallments(l, connection)).ToList();
    }

    public bool UpdateLoanStatus(int loanId, string status, string? notes, int adminUserId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        const string sql = """
            UPDATE dbo.tbl_Loans
            SET Status = @Status,
                AdminNotes = @Notes,
                ApprovedByUserId = @AdminUserId,
                ApprovedAt = CASE WHEN @Status = N'Approved' AND ApprovedAt IS NULL THEN GETDATE() ELSE ApprovedAt END,
                DisbursedAt = CASE WHEN @Status = N'Disbursed' AND DisbursedAt IS NULL THEN GETDATE() ELSE DisbursedAt END,
                CompletedAt = CASE WHEN @Status = N'Completed' AND CompletedAt IS NULL THEN GETDATE() ELSE CompletedAt END
            WHERE Id = @LoanId;
            """;

        using var cmd = new SqlCommand(sql, connection);
        cmd.Parameters.AddWithValue("@Status", status.Trim());
        cmd.Parameters.AddWithValue("@Notes", (object?)notes?.Trim() ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@AdminUserId", adminUserId);
        cmd.Parameters.AddWithValue("@LoanId", loanId);

        return cmd.ExecuteNonQuery() > 0;
    }

    public bool PayInstallment(int installmentId, int userId, string paymentMethod = "Wallet")
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
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

    public AgentOfficeLocationViewModel? GetAgentOfficeForDistrict(string districtName, double? customerLat = null, double? customerLon = null)
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

        var lat = reader.IsDBNull(12) ? (decimal?)null : reader.GetDecimal(12);
        var lon = reader.IsDBNull(13) ? (decimal?)null : reader.GetDecimal(13);

        double? distance = null;
        if (customerLat.HasValue && customerLon.HasValue && lat.HasValue && lon.HasValue)
        {
            distance = CalculateDistanceKm(customerLat.Value, customerLon.Value, (double)lat.Value, (double)lon.Value);
        }

        return new AgentOfficeLocationViewModel
        {
            AgentId = reader.GetInt32(0),
            AgentName = reader.IsDBNull(1) ? "অফিসিয়াল এজেন্ট" : reader.GetString(1),
            AgentPhone = reader.IsDBNull(2) ? "" : reader.GetString(2),
            OfficeName = reader.IsDBNull(3) ? "স্মার্ট বাজার এরিয়া অফিস" : reader.GetString(3),
            OfficeAddress = reader.IsDBNull(4) ? "প্রধান বাণিজ্যিক কেন্দ্র" : reader.GetString(4),
            RoadNo = reader.IsDBNull(5) ? null : reader.GetString(5),
            AreaName = reader.IsDBNull(6) ? null : reader.GetString(6),
            Thana = reader.IsDBNull(7) ? null : reader.GetString(7),
            DistrictName = reader.IsDBNull(8) ? districtName : reader.GetString(8),
            DivisionName = reader.IsDBNull(9) ? "ঢাকা" : reader.GetString(9),
            OfficeHours = reader.IsDBNull(10) ? "সকাল ৯:০০ - রাত ৮:০০ (প্রতিদিন)" : reader.GetString(10),
            ContactPhone = reader.IsDBNull(11) ? (reader.IsDBNull(2) ? "09678-123456" : reader.GetString(2)) : reader.GetString(11),
            Latitude = lat ?? 23.8103m,
            Longitude = lon ?? 90.4125m,
            ProfilePictureUrl = reader.IsDBNull(14) ? null : reader.GetString(14),
            DistanceKm = distance
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

    public LoanConfigRowViewModel? GetLoanConfigRow()
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        const string sql = """
            SELECT TOP 1 Id, ConfigKey, MinAmount, MaxAmount, AnnualInterestRate, ProcessingFeePercent, MinProcessingFee, AllowedTenures, IsActive
            FROM dbo.tbl_LoanConfig
            WHERE IsActive = 1
            ORDER BY Id DESC;
            """;
        using var cmd = new SqlCommand(sql, connection);
        using var reader = cmd.ExecuteReader();
        if (!reader.Read()) return null;
        return new LoanConfigRowViewModel
        {
            Id = reader.GetInt32(0),
            ConfigKey = reader.GetString(1),
            MinAmount = reader.GetDecimal(2),
            MaxAmount = reader.GetDecimal(3),
            AnnualInterestRate = reader.GetDecimal(4),
            ProcessingFeePercent = reader.GetDecimal(5),
            MinProcessingFee = reader.GetDecimal(6),
            AllowedTenures = reader.GetString(7),
            IsActive = reader.GetBoolean(8)
        };
    }

    public void UpdateLoanConfig(LoanConfigInputModel input)
    {
        EnsureSchema();
        if (input.MinAmount >= input.MaxAmount)
            throw new InvalidOperationException("সর্বনিম্ন পরিমাণ অবশ্যই সর্বোচ্চ পরিমাণের চেয়ে কম হতে হবে।");

        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_LoanConfig
            SET MinAmount = @MinAmount,
                MaxAmount = @MaxAmount,
                AnnualInterestRate = @AnnualInterestRate,
                ProcessingFeePercent = @ProcessingFeePercent,
                MinProcessingFee = @MinProcessingFee,
                AllowedTenures = @AllowedTenures,
                IsActive = @IsActive,
                UpdatedAt = GETDATE()
            WHERE Id = @Id;
            """, connection);
        command.Parameters.AddWithValue("@Id", input.Id);
        command.Parameters.AddWithValue("@MinAmount", input.MinAmount);
        command.Parameters.AddWithValue("@MaxAmount", input.MaxAmount);
        command.Parameters.AddWithValue("@AnnualInterestRate", input.AnnualInterestRate);
        command.Parameters.AddWithValue("@ProcessingFeePercent", input.ProcessingFeePercent);
        command.Parameters.AddWithValue("@MinProcessingFee", input.MinProcessingFee);
        command.Parameters.AddWithValue("@AllowedTenures", input.AllowedTenures.Trim());
        command.Parameters.AddWithValue("@IsActive", input.IsActive);
        connection.Open();
        if (command.ExecuteNonQuery() == 0)
            throw new InvalidOperationException("লোন কনফিগারেশন পাওয়া যায়নি।");
    }

    public IReadOnlyList<DistrictPricingConfigRowViewModel> GetDistrictPricingRows()
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT Id, DistrictName, TransportMultiplier, DistrictAdjustmentAmount, DefaultDeliveryCharge,
                   ServiceCharge, PlatformCharge, ShopkeeperMarginPercent, CompanyMarginPercent, IsActive
            FROM dbo.tbl_DistrictPricingConfig
            ORDER BY DistrictName;
            """, connection);
        connection.Open();
        using var reader = command.ExecuteReader();
        var rows = new List<DistrictPricingConfigRowViewModel>();
        while (reader.Read())
        {
            rows.Add(new DistrictPricingConfigRowViewModel
            {
                Id = reader.GetInt32(0),
                DistrictName = reader.GetString(1),
                TransportMultiplier = reader.GetDecimal(2),
                DistrictAdjustmentAmount = reader.GetDecimal(3),
                DefaultDeliveryCharge = reader.GetDecimal(4),
                ServiceCharge = reader.GetDecimal(5),
                PlatformCharge = reader.GetDecimal(6),
                ShopkeeperMarginPercent = reader.GetDecimal(7),
                CompanyMarginPercent = reader.GetDecimal(8),
                IsActive = reader.GetBoolean(9)
            });
        }
        return rows;
    }

    public void UpdateDistrictPricing(DistrictPricingConfigInputModel input)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_DistrictPricingConfig
            SET DistrictAdjustmentAmount = @DistrictAdjustmentAmount,
                DefaultDeliveryCharge = @DefaultDeliveryCharge,
                ServiceCharge = @ServiceCharge,
                PlatformCharge = @PlatformCharge,
                ShopkeeperMarginPercent = @ShopkeeperMarginPercent,
                CompanyMarginPercent = @CompanyMarginPercent,
                IsActive = @IsActive
            WHERE Id = @Id;
            """, connection);
        command.Parameters.AddWithValue("@Id", input.Id);
        command.Parameters.AddWithValue("@DistrictAdjustmentAmount", input.DistrictAdjustmentAmount);
        command.Parameters.AddWithValue("@DefaultDeliveryCharge", input.DefaultDeliveryCharge);
        command.Parameters.AddWithValue("@ServiceCharge", input.ServiceCharge);
        command.Parameters.AddWithValue("@PlatformCharge", input.PlatformCharge);
        command.Parameters.AddWithValue("@ShopkeeperMarginPercent", input.ShopkeeperMarginPercent);
        command.Parameters.AddWithValue("@CompanyMarginPercent", input.CompanyMarginPercent);
        command.Parameters.AddWithValue("@IsActive", input.IsActive);
        connection.Open();
        if (command.ExecuteNonQuery() == 0)
            throw new InvalidOperationException("জেলা পাওয়া যায়নি।");
    }

    public void AddDistrictPricing(DistrictPricingConfigCreateInputModel input)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            IF EXISTS (SELECT 1 FROM dbo.tbl_DistrictPricingConfig WHERE DistrictName = @DistrictName)
                THROW 51160, N'এই জেলার জন্য ইতিমধ্যে একটি কনফিগারেশন রয়েছে।', 1;

            INSERT INTO dbo.tbl_DistrictPricingConfig
                (DistrictName, TransportMultiplier, DistrictAdjustmentAmount, DefaultDeliveryCharge,
                 ServiceCharge, PlatformCharge, ShopkeeperMarginPercent, CompanyMarginPercent, IsActive)
            VALUES
                (@DistrictName, 1.0000, @DistrictAdjustmentAmount, @DefaultDeliveryCharge,
                 @ServiceCharge, @PlatformCharge, @ShopkeeperMarginPercent, @CompanyMarginPercent, 1);
            """, connection);
        command.Parameters.AddWithValue("@DistrictName", input.DistrictName.Trim());
        command.Parameters.AddWithValue("@DistrictAdjustmentAmount", input.DistrictAdjustmentAmount);
        command.Parameters.AddWithValue("@DefaultDeliveryCharge", input.DefaultDeliveryCharge);
        command.Parameters.AddWithValue("@ServiceCharge", input.ServiceCharge);
        command.Parameters.AddWithValue("@PlatformCharge", input.PlatformCharge);
        command.Parameters.AddWithValue("@ShopkeeperMarginPercent", input.ShopkeeperMarginPercent);
        command.Parameters.AddWithValue("@CompanyMarginPercent", input.CompanyMarginPercent);
        connection.Open();
        try
        {
            command.ExecuteNonQuery();
        }
        catch (SqlException ex) when (ex.Number == 51160)
        {
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    public IReadOnlyList<ShopCategoryAdminRowViewModel> GetShopCategoriesAdmin()
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT c.Id, c.Name, c.BanglaName, c.Icon, c.Description, c.DisplayOrder, c.IsActive,
                   (SELECT COUNT(1) FROM dbo.tbl_CustomerOrderProducts p WHERE p.Category = c.Name AND p.IsActive = 1) AS ProductCount
            FROM dbo.tbl_ShopCategories c
            ORDER BY c.DisplayOrder, c.Id;
            """, connection);
        connection.Open();
        using var reader = command.ExecuteReader();
        var rows = new List<ShopCategoryAdminRowViewModel>();
        while (reader.Read())
        {
            rows.Add(new ShopCategoryAdminRowViewModel
            {
                Id = reader.GetInt32(0),
                Name = reader.GetString(1),
                BanglaName = reader.GetString(2),
                Icon = reader.GetString(3),
                Description = reader.IsDBNull(4) ? null : reader.GetString(4),
                DisplayOrder = reader.GetInt32(5),
                IsActive = reader.GetBoolean(6),
                ProductCount = reader.GetInt32(7)
            });
        }
        return rows;
    }

    public void UpdateShopCategory(ShopCategoryInputModel input)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_ShopCategories
            SET BanglaName = @BanglaName,
                Icon = @Icon,
                Description = @Description,
                DisplayOrder = @DisplayOrder,
                IsActive = @IsActive
            WHERE Id = @Id;
            """, connection);
        command.Parameters.AddWithValue("@Id", input.Id);
        command.Parameters.AddWithValue("@BanglaName", input.BanglaName.Trim());
        command.Parameters.AddWithValue("@Icon", input.Icon.Trim());
        command.Parameters.AddWithValue("@Description", (object?)input.Description?.Trim() ?? DBNull.Value);
        command.Parameters.AddWithValue("@DisplayOrder", input.DisplayOrder);
        command.Parameters.AddWithValue("@IsActive", input.IsActive);
        connection.Open();
        if (command.ExecuteNonQuery() == 0)
            throw new InvalidOperationException("ক্যাটাগরি পাওয়া যায়নি।");
    }

    public void AddShopCategory(ShopCategoryCreateInputModel input)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            IF EXISTS (SELECT 1 FROM dbo.tbl_ShopCategories WHERE Name = @Name)
                THROW 51161, N'এই নামে ইতিমধ্যে একটি ক্যাটাগরি রয়েছে।', 1;

            INSERT INTO dbo.tbl_ShopCategories (Name, BanglaName, Icon, Description, DisplayOrder, IsActive)
            VALUES (@Name, @BanglaName, @Icon, @Description, @DisplayOrder, 1);
            """, connection);
        command.Parameters.AddWithValue("@Name", input.Name.Trim());
        command.Parameters.AddWithValue("@BanglaName", input.BanglaName.Trim());
        command.Parameters.AddWithValue("@Icon", input.Icon.Trim());
        command.Parameters.AddWithValue("@Description", (object?)input.Description?.Trim() ?? DBNull.Value);
        command.Parameters.AddWithValue("@DisplayOrder", input.DisplayOrder);
        connection.Open();
        try
        {
            command.ExecuteNonQuery();
        }
        catch (SqlException ex) when (ex.Number == 51161)
        {
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    private LoanConfigModel GetLoanConfig()
    {
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        const string sql = """
            SELECT TOP 1 MinAmount, MaxAmount, AnnualInterestRate, ProcessingFeePercent, MinProcessingFee, AllowedTenures
            FROM dbo.tbl_LoanConfig
            WHERE IsActive = 1
            ORDER BY Id DESC;
            """;
        using var cmd = new SqlCommand(sql, connection);
        using var reader = cmd.ExecuteReader();
        if (reader.Read())
        {
            return new LoanConfigModel
            {
                MinAmount = reader.GetDecimal(0),
                MaxAmount = reader.GetDecimal(1),
                AnnualInterestRate = reader.GetDecimal(2),
                ProcessingFeePercent = reader.GetDecimal(3),
                MinProcessingFee = reader.GetDecimal(4),
                AllowedTenures = reader.GetString(5)
            };
        }
        return new LoanConfigModel();
    }

    public static double CalculateDistanceKm(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371.0; // Radius of Earth in km
        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return Math.Round(R * c, 2);
    }

    private static double ToRadians(double degrees) => degrees * Math.PI / 180.0;

    private LoanItemViewModel? GetLoanById(int id, SqlConnection connection)
    {
        const string sql = """
            SELECT Id, UserId, UserRole, CustomerName, Phone, LoanAmount, InterestRate,
                   TenureMonths, MonthlyInstallment, ProcessingFee, TotalInterest, TotalPayable,
                   RemainingAmount, Purpose, Status, AppliedAt, ApprovedAt, DisbursedAt, CompletedAt, AdminNotes
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
            CompletedAt = reader.IsDBNull(18) ? null : reader.GetDateTime(18),
            AdminNotes = reader.IsDBNull(19) ? null : reader.GetString(19)
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
            AdminNotes = loan.AdminNotes,
            Installments = installments,
            NextDueInstallment = nextDue
        };
    }

    private sealed class LoanConfigModel
    {
        public decimal MinAmount { get; set; } = 5000.00m;
        public decimal MaxAmount { get; set; } = 50000.00m;
        public decimal AnnualInterestRate { get; set; } = 9.00m;
        public decimal ProcessingFeePercent { get; set; } = 0.50m;
        public decimal MinProcessingFee { get; set; } = 25.00m;
        public string AllowedTenures { get; set; } = "3,6,9,12";
    }
}
