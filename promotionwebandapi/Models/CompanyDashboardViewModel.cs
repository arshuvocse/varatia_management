using Microsoft.AspNetCore.Http;
namespace PromotionWeb.Models;

public sealed record CompanyDashboardViewModel
{
    public string CompanyName { get; init; } = "";
    public string CompanyPhone { get; init; } = "";
    public int TotalAgents { get; init; }
    public int TotalFieldOfficers { get; init; }
    public int TotalShopkeepers { get; init; }
    public int TotalCustomers { get; init; }
    public int TotalDeliveryMen { get; init; }
    public int ActiveDeliveryMen { get; init; }
    public int TotalCustomerOrders { get; init; }
    public int PendingCustomerOrders { get; init; }
    public int ConfirmedCustomerOrders { get; init; }
    public int DeliveredCustomerOrders { get; init; }
    public int CancelledCustomerOrders { get; init; }
    public int ReturnedCustomerOrders { get; init; }
    public int FailedCustomerOrders { get; init; }
    public int TotalProducts { get; init; }
    public int LowStockProducts { get; init; }
    public int ActiveCampaigns { get; init; }
    public int PendingApprovals { get; init; }
    public int UnreadNotifications { get; init; }
    public decimal TotalSalesAmount { get; init; }
    public decimal TodaySalesAmount { get; init; }
    public decimal MonthSalesAmount { get; init; }
    public decimal TotalCashbackAmount { get; init; }
    public decimal TotalSystemCommission { get; init; }
    public decimal WalletBalance { get; init; }
    public decimal WalletWithdrawable { get; init; }
    public decimal WalletPending { get; init; }
    public IReadOnlyList<CompanyRecentShopViewModel> RecentShops { get; init; } = [];
    public IReadOnlyList<CompanyRecentSaleViewModel> RecentSales { get; init; } = [];
    public IReadOnlyList<CompanyDistrictPerformanceViewModel> Districts { get; init; } = [];
    public IReadOnlyList<CompanyCampaignViewModel> Campaigns { get; init; } = [];
    public IReadOnlyList<CompanyProductPerformanceViewModel> TopProducts { get; init; } = [];
    public IReadOnlyList<CompanyDistributionProductViewModel> DistributionProducts { get; init; } = [];
    public IReadOnlyList<CompanyUserViewModel> Users { get; init; } = [];
    public IReadOnlyList<CompanyNotificationViewModel> Notifications { get; init; } = [];
    public IReadOnlyList<CompanyActivityViewModel> Activities { get; init; } = [];
    public IReadOnlyList<CompanyBulletinViewModel> Bulletins { get; init; } = [];
    public IReadOnlyList<ServiceRequest> ServiceRequests { get; init; } = [];
    public IReadOnlyList<CompanyShopkeeperPaymentViewModel> ShopkeeperPayments { get; init; } = [];
    public LocationCatalog Locations { get; init; } = new();
    public CompanyNetworkViewModel Network { get; init; } = new();
    public CompanySettingsViewModel Settings { get; init; } = new();
    public FieldOfficerShopsViewModel ShopsModel { get; init; } = new();
}

public sealed class CompanyDistributionProductViewModel
{
    public int Id { get; init; }
    public string ProductCode { get; init; } = "";
    public string Name { get; init; } = "";
    public string Category { get; init; } = "";
    public string Uom { get; init; } = "";
    public decimal UnitPrice { get; init; }
    public int OpeningStock { get; init; }
    public decimal ShopkeeperPercentage { get; init; }
    public decimal CompanyPercentage { get; init; }
    public decimal AgentPercentage { get; init; }
    public decimal FieldForcePercentage { get; init; }
    public decimal CustomerPercentage { get; init; }
    public decimal Percentage =>
        ShopkeeperPercentage + CompanyPercentage + AgentPercentage + FieldForcePercentage + CustomerPercentage;
    public bool IsActive { get; init; }
    public string? ImageUrl { get; init; }
    public DateTime CreatedAt { get; init; }
}

public sealed class CompanyDistributionProductInputModel
{
    public string Name { get; set; } = "";
    public string Category { get; set; } = "";
    public string Uom { get; set; } = "";
    public decimal UnitPrice { get; set; }
    public int OpeningStock { get; set; }
    public string? ImageUrl { get; set; }
    public IFormFile? ImageFile { get; set; }
}

public sealed class CompanyProductAllocationInputModel
{
    public int ProductId { get; set; }
    public decimal TotalPercentage { get; set; }
    public decimal ShopkeeperPercentage { get; set; }
    public decimal CompanyPercentage { get; set; }
    public decimal AgentPercentage { get; set; }
    public decimal FieldForcePercentage { get; set; }
    public decimal CustomerPercentage { get; set; }
    public string? ImageUrl { get; set; }
    public IFormFile? ImageFile { get; set; }
}

public sealed class ShopkeeperWalletFundingInputModel
{
    [System.ComponentModel.DataAnnotations.Range(typeof(decimal), "10", "9999999999.99", ErrorMessage = "কমপক্ষে ৳১০ যোগ করুন।")]
    public decimal Amount { get; set; }
    public string? Note { get; set; }
}

public sealed class CompanyShopkeeperPaymentViewModel
{
    public int Id { get; init; }
    public int ShopkeeperId { get; init; }
    public string ShopName { get; init; } = "";
    public string ShopCode { get; init; } = "";
    public string OwnerName { get; init; } = "";
    public string Phone { get; init; } = "";
    public string DistrictName { get; init; } = "";
    public string TransactionId { get; init; } = "";
    public string? BankTransactionId { get; init; }
    public string? CardType { get; init; }
    public decimal Amount { get; init; }
    public string Currency { get; init; } = "BDT";
    public string Status { get; init; } = "";
    public DateTime CreatedAt { get; init; }
    public DateTime? PaidAt { get; init; }
}

public sealed class CompanyRecentShopViewModel
{
    public int Id { get; init; }
    public string ShopName { get; init; } = "";
    public string OwnerName { get; init; } = "";
    public string Phone { get; init; } = "";
    public string ShopCode { get; init; } = "";
    public string DistrictName { get; init; } = "";
    public string ThanaName { get; init; } = "";
    public string FieldOfficerName { get; init; } = "";
    public DateTime RegisteredAt { get; init; }
}

public sealed class CompanyRecentSaleViewModel
{
    public int Id { get; init; }
    public string InvoiceNo { get; init; } = "";
    public string ShopName { get; init; } = "";
    public string CustomerName { get; init; } = "";
    public string CustomerPhone { get; init; } = "";
    public decimal GrossAmount { get; init; }
    public decimal CashbackAmount { get; init; }
    public decimal SystemCommission { get; init; }
    public string Status { get; init; } = "";
    public DateTime SoldAt { get; init; }
}

public sealed class CompanyDistrictPerformanceViewModel
{
    public string DistrictName { get; init; } = "";
    public int ShopkeeperCount { get; init; }
    public int CustomerCount { get; init; }
    public decimal SalesAmount { get; init; }
}

public sealed class CompanyCampaignViewModel
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
    public string Status { get; init; } = "";
    public DateTime StartDate { get; init; }
    public DateTime EndDate { get; init; }
    public int Reach { get; init; }
    public int Clicks { get; init; }
    public int Conversions { get; init; }
    public decimal SalesAmount { get; init; }
}

public sealed class CompanyProductPerformanceViewModel
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
    public string Category { get; init; } = "";
    public string ShopName { get; init; } = "";
    public int StockQuantity { get; init; }
    public int SoldQuantity { get; init; }
    public decimal SalesAmount { get; init; }
}

public sealed class CompanyUserViewModel
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
    public string Phone { get; init; } = "";
    public string Role { get; init; } = "";
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
}

public sealed class CompanyNetworkViewModel
{
    public IReadOnlyList<CompanyAgentNetworkViewModel> Agents { get; init; } = [];
    public IReadOnlyList<CompanyNetworkMemberViewModel> UnassignedDeliveryMen { get; init; } = [];
    public IReadOnlyList<CompanyFieldForceNetworkViewModel> UnassignedFieldForces { get; init; } = [];
    public IReadOnlyList<CompanyShopkeeperNetworkViewModel> UnassignedShopkeepers { get; init; } = [];
    public IReadOnlyList<CompanyCustomerNetworkViewModel> Customers { get; init; } = [];
}

public sealed class CompanyAgentNetworkViewModel
{
    public int UserId { get; init; }
    public string Name { get; init; } = "";
    public string Phone { get; init; } = "";
    public string DistrictName { get; init; } = "District not assigned";
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
    public IReadOnlyList<CompanyNetworkMemberViewModel> DeliveryMen { get; init; } = [];
    public IReadOnlyList<CompanyFieldForceNetworkViewModel> FieldForces { get; init; } = [];
}

public sealed class CompanyFieldForceNetworkViewModel
{
    public int UserId { get; init; }
    public string Name { get; init; } = "";
    public string Phone { get; init; } = "";
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
    public IReadOnlyList<CompanyShopkeeperNetworkViewModel> Shopkeepers { get; init; } = [];
}

public sealed class CompanyNetworkMemberViewModel
{
    public int UserId { get; init; }
    public int? ParentUserId { get; init; }
    public string Name { get; init; } = "";
    public string Phone { get; init; } = "";
    public string Location { get; init; } = "";
    public string Detail { get; init; } = "";
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
}

public sealed class CompanyShopkeeperNetworkViewModel
{
    public int UserId { get; init; }
    public int FieldOfficerUserId { get; init; }
    public string ShopName { get; init; } = "";
    public string OwnerName { get; init; } = "";
    public string Phone { get; init; } = "";
    public string ShopCode { get; init; } = "";
    public string Location { get; init; } = "";
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
}

public sealed class CompanyCustomerNetworkViewModel
{
    public int? UserId { get; init; }
    public string Name { get; init; } = "";
    public string Phone { get; init; } = "";
    public string Address { get; init; } = "";
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
}

public sealed class CompanyNotificationViewModel
{
    public long Id { get; init; }
    public string Title { get; init; } = "";
    public string Message { get; init; } = "";
    public bool IsRead { get; init; }
    public DateTime CreatedAt { get; init; }
}

public sealed class CompanyActivityViewModel
{
    public string Type { get; init; } = "";
    public string Title { get; init; } = "";
    public string Detail { get; init; } = "";
    public DateTime OccurredAt { get; init; }
}

public sealed class CompanySettingsViewModel
{
    public decimal CommissionRate { get; init; } = 1;
    public decimal CashbackRate { get; init; } = 2;
    public decimal DeliveryCharge { get; init; } = 60;
    public string SupportPhone { get; init; } = "09678-123456";
    public string PaymentGateway { get; init; } = "Cash / Manual";
}

public sealed class CompanyCampaignInputModel
{
    public string Name { get; set; } = "";
    public DateTime StartDate { get; set; } = DateTime.Today;
    public DateTime EndDate { get; set; } = DateTime.Today.AddDays(30);
}

public sealed class CompanySettingsInputModel
{
    public decimal CommissionRate { get; set; }
    public decimal CashbackRate { get; set; }
    public decimal DeliveryCharge { get; set; }
    public string SupportPhone { get; set; } = "";
    public string PaymentGateway { get; set; } = "";
}

public sealed class CompanyBulletinViewModel
{
    public int Id { get; init; }
    public string Message { get; init; } = "";
    public string? LinkUrl { get; init; }
    public bool IsActive { get; init; }
    public DateTime StartAt { get; init; }
    public DateTime? EndAt { get; init; }
    public DateTime CreatedAt { get; init; }
}

public sealed class CompanyBulletinInputModel
{
    public string Message { get; set; } = "";
    public string? LinkUrl { get; set; }
    public DateTime StartAt { get; set; } = DateTime.Now;
    public DateTime? EndAt { get; set; }
}
