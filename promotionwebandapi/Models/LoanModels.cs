using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public sealed class LoanEligibilityViewModel
{
    public bool IsEligible { get; init; } = true;
    public decimal MaxLoanLimit { get; init; } = 50000m;
    public decimal MinLoanLimit { get; init; } = 5000m;
    public decimal AvailableLimit { get; init; } = 50000m;
    public decimal AnnualInterestRate { get; init; } = 9.00m; // 9% annual interest
    public decimal ProcessingFeeRate { get; init; } = 0.50m; // 0.5% processing fee
    public int[] AllowedTenures { get; init; } = [3, 6, 9, 12];
    public string EligibilityMessage { get; init; } = "আপনি তাৎক্ষণিক ডিজিটাল ন্যানো লোনের জন্য যোগ্য!";
    public bool HasActiveLoan { get; init; }
}

public sealed class LoanApplicationInputModel
{
    [Required(ErrorMessage = "লোনের পরিমাণ নির্বাচন করুন।")]
    [Range(5000, 50000, ErrorMessage = "লোনের পরিমাণ ৫,০০০ থেকে ৫০,০০০ টাকার মধ্যে হতে হবে।")]
    public decimal Amount { get; set; } = 10000m;

    [Required(ErrorMessage = "কিস্তির মেয়াদ নির্বাচন করুন।")]
    [Range(3, 12, ErrorMessage = "মেয়াদ ৩, ৬, ৯ অথবা ১২ মাস হতে হবে।")]
    public int TenureMonths { get; set; } = 6;

    [Required(ErrorMessage = "লোনের উদ্দেশ্য লিখুন বা নির্বাচন করুন।")]
    [MaxLength(200)]
    public string Purpose { get; set; } = "ব্যক্তিগত / ব্যবসায়িক জরুরি প্রয়োজন";

    public bool AgreeTerms { get; set; } = true;
}

public sealed class LoanCalculationResult
{
    public decimal LoanAmount { get; set; }
    public int TenureMonths { get; set; }
    public decimal MonthlyInstallment { get; set; }
    public decimal TotalInterest { get; set; }
    public decimal ProcessingFee { get; set; }
    public decimal TotalPayable { get; set; }
    public decimal MonthlyInterestRate { get; set; }
    public DateTime FirstInstallmentDate { get; set; }
}

public sealed class LoanItemViewModel
{
    public int Id { get; init; }
    public int UserId { get; init; }
    public string UserRole { get; init; } = "";
    public string CustomerName { get; init; } = "";
    public string Phone { get; init; } = "";
    public decimal LoanAmount { get; init; }
    public decimal InterestRate { get; init; }
    public int TenureMonths { get; init; }
    public decimal MonthlyInstallment { get; init; }
    public decimal ProcessingFee { get; init; }
    public decimal TotalInterest { get; init; }
    public decimal TotalPayable { get; init; }
    public decimal RemainingAmount { get; init; }
    public decimal PaidAmount => TotalPayable - RemainingAmount;
    public double ProgressPercent => TotalPayable > 0 ? (double)(PaidAmount / TotalPayable * 100m) : 0;
    public double ProgressPercentage => ProgressPercent;
    public string Purpose { get; init; } = "";
    public string Status { get; init; } = "Approved"; // Pending, Approved, Disbursed, Completed, Rejected
    public DateTime AppliedAt { get; init; }
    public DateTime? ApprovedAt { get; init; }
    public DateTime? DisbursedAt { get; init; }
    public DateTime? CompletedAt { get; init; }
    public string? AdminNotes { get; init; }

    public LoanInstallmentItemViewModel? NextDueInstallment { get; init; }
    public IReadOnlyList<LoanInstallmentItemViewModel> Installments { get; init; } = [];
}

public sealed class LoanInstallmentItemViewModel
{
    public int Id { get; init; }
    public int LoanId { get; init; }
    public int InstallmentNumber { get; init; }
    public DateTime DueDate { get; init; }
    public decimal Amount { get; init; }
    public decimal PrincipalPortion { get; init; }
    public decimal InterestPortion { get; init; }
    public decimal PaidAmount { get; init; }
    public string Status { get; init; } = "Pending"; // Pending, Paid, Overdue
    public DateTime? PaidAt { get; init; }
    public string? PaymentMethod { get; init; }
    public bool IsOverdue => Status != "Paid" && DueDate < DateTime.Today;
    public int DaysRemaining => (DueDate.Date - DateTime.Today).Days;
}

public sealed class CustomerLoanDashboardViewModel
{
    public string CustomerName { get; init; } = "";
    public string CustomerPhone { get; init; } = "";
    public decimal WalletBalance { get; init; }
    public LoanEligibilityViewModel Eligibility { get; init; } = new();
    public LoanItemViewModel? ActiveLoan { get; init; }
    public IReadOnlyList<LoanItemViewModel> LoanHistory { get; init; } = [];
    public LoanApplicationInputModel ApplicationInput { get; init; } = new();
    public string? SuccessMessage { get; init; }
    public string? ErrorMessage { get; init; }
}

public sealed class ShopkeeperLoanDashboardViewModel
{
    public string ShopName { get; init; } = "";
    public string OwnerName { get; init; } = "";
    public string Phone { get; init; } = "";
    public decimal WalletBalance { get; init; }
    public LoanEligibilityViewModel Eligibility { get; init; } = new();
    public LoanItemViewModel? ActiveLoan { get; init; }
    public IReadOnlyList<LoanItemViewModel> LoanHistory { get; init; } = [];
    public LoanApplicationInputModel ApplicationInput { get; init; } = new();
    public string? SuccessMessage { get; init; }
    public string? ErrorMessage { get; init; }
}

public sealed class AdminLoanManagementViewModel
{
    public IReadOnlyList<LoanItemViewModel> Loans { get; init; } = [];
    public string? FilterStatus { get; init; }
    public string? FilterRole { get; init; }
    public decimal TotalDisbursed => Loans.Where(l => l.Status is "Approved" or "Disbursed" or "Completed").Sum(l => l.LoanAmount);
    public decimal TotalOutstanding => Loans.Where(l => l.Status is "Approved" or "Disbursed").Sum(l => l.RemainingAmount);
    public int ActiveLoanCount => Loans.Count(l => l.Status is "Approved" or "Disbursed");
    public LoanConfigRowViewModel? Config { get; init; }
    public string? SuccessMessage { get; init; }
    public string? ErrorMessage { get; init; }
}

public sealed class LoanConfigRowViewModel
{
    public int Id { get; init; }
    public string ConfigKey { get; init; } = "";
    public decimal MinAmount { get; init; }
    public decimal MaxAmount { get; init; }
    public decimal AnnualInterestRate { get; init; }
    public decimal ProcessingFeePercent { get; init; }
    public decimal MinProcessingFee { get; init; }
    public string AllowedTenures { get; init; } = "3,6,9,12";
    public bool IsActive { get; init; }
}

public sealed class LoanConfigInputModel
{
    [Required]
    public int Id { get; set; }

    [Required, Range(500, 1_000_000)]
    public decimal MinAmount { get; set; }

    [Required, Range(500, 1_000_000)]
    public decimal MaxAmount { get; set; }

    [Required, Range(0, 100)]
    public decimal AnnualInterestRate { get; set; }

    [Required, Range(0, 100)]
    public decimal ProcessingFeePercent { get; set; }

    [Required, Range(0, 100_000)]
    public decimal MinProcessingFee { get; set; }

    [Required, RegularExpression(@"^\d+(,\d+)*$", ErrorMessage = "কমা দিয়ে আলাদা মাসের সংখ্যা দিন, যেমন 3,6,9,12")]
    public string AllowedTenures { get; set; } = "3,6,9,12";

    public bool IsActive { get; set; } = true;
}

public sealed class DistrictPricingConfigRowViewModel
{
    public int Id { get; init; }
    public string DistrictName { get; init; } = "";
    public decimal TransportMultiplier { get; init; }
    public decimal DistrictAdjustmentAmount { get; init; }
    public decimal DefaultDeliveryCharge { get; init; }
    public decimal ServiceCharge { get; init; }
    public decimal PlatformCharge { get; init; }
    public decimal ShopkeeperMarginPercent { get; init; }
    public decimal CompanyMarginPercent { get; init; }
    public bool IsActive { get; init; }
}

public sealed class DistrictPricingConfigInputModel
{
    [Required]
    public int Id { get; set; }

    [Required, Range(0, 1000)]
    public decimal DistrictAdjustmentAmount { get; set; }

    [Required, Range(0, 100_000)]
    public decimal DefaultDeliveryCharge { get; set; }

    [Required, Range(0, 10_000)]
    public decimal ServiceCharge { get; set; }

    [Required, Range(0, 10_000)]
    public decimal PlatformCharge { get; set; }

    [Required, Range(0, 100)]
    public decimal ShopkeeperMarginPercent { get; set; }

    [Required, Range(0, 100)]
    public decimal CompanyMarginPercent { get; set; }

    public bool IsActive { get; set; } = true;
}

public sealed class DistrictPricingConfigCreateInputModel
{
    [Required, MaxLength(100)]
    public string DistrictName { get; set; } = "";

    [Required, Range(0, 1000)]
    public decimal DistrictAdjustmentAmount { get; set; }

    [Required, Range(0, 100_000)]
    public decimal DefaultDeliveryCharge { get; set; } = 40m;

    [Required, Range(0, 10_000)]
    public decimal ServiceCharge { get; set; } = 10m;

    [Required, Range(0, 10_000)]
    public decimal PlatformCharge { get; set; } = 5m;

    [Required, Range(0, 100)]
    public decimal ShopkeeperMarginPercent { get; set; } = 10m;

    [Required, Range(0, 100)]
    public decimal CompanyMarginPercent { get; set; } = 5m;
}

public sealed class ShopCategoryAdminRowViewModel
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
    public string BanglaName { get; init; } = "";
    public string Icon { get; init; } = "🛍️";
    public string? Description { get; init; }
    public int DisplayOrder { get; init; }
    public bool IsActive { get; init; }
    public int ProductCount { get; init; }
}

public sealed class ShopCategoryInputModel
{
    [Required]
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string BanglaName { get; set; } = "";

    [Required, MaxLength(50)]
    public string Icon { get; set; } = "🛍️";

    [MaxLength(250)]
    public string? Description { get; set; }

    [Required, Range(0, 999)]
    public int DisplayOrder { get; set; }

    public bool IsActive { get; set; } = true;
}

public sealed class ShopCategoryCreateInputModel
{
    [Required, MaxLength(100)]
    public string Name { get; set; } = "";

    [Required, MaxLength(100)]
    public string BanglaName { get; set; } = "";

    [Required, MaxLength(50)]
    public string Icon { get; set; } = "🛍️";

    [MaxLength(250)]
    public string? Description { get; set; }

    [Range(0, 999)]
    public int DisplayOrder { get; set; }
}

public sealed class PlatformSettingsViewModel
{
    public IReadOnlyList<DistrictPricingConfigRowViewModel> DistrictPricing { get; init; } = [];
    public IReadOnlyList<ShopCategoryAdminRowViewModel> ShopCategories { get; init; } = [];
    public string? SuccessMessage { get; init; }
    public string? ErrorMessage { get; init; }
}

public sealed class AgentOfficeLocationViewModel
{
    public int AgentId { get; init; }
    public string AgentName { get; init; } = "";
    public string AgentPhone { get; init; } = "";
    public string? OfficeName { get; init; }
    public string? OfficeAddress { get; init; }
    public string? RoadNo { get; init; }
    public string? AreaName { get; init; }
    public string? Thana { get; init; }
    public string? DistrictName { get; init; }
    public string? DivisionName { get; init; }
    public string? OfficeHours { get; init; }
    public string? ContactPhone { get; init; }
    public decimal? Latitude { get; init; }
    public decimal? Longitude { get; init; }
    public string? ProfilePictureUrl { get; init; }
    public double? DistanceKm { get; set; }

    public string FullDisplayAddress => string.Join(", ",
        new[] { OfficeName, OfficeAddress, RoadNo, AreaName, Thana, DistrictName }
        .Where(s => !string.IsNullOrWhiteSpace(s)));
}
