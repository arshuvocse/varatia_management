using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public sealed class CustomerDashboardViewModel
{
    public string CustomerName { get; init; } = "";
    public string CustomerPhone { get; init; } = "";
    public string? ProfilePhotoPath { get; init; }
    public string SelectedDistrict { get; init; } = "Dhaka";
    public CustomerOrderInputModel Order { get; init; } = new();
    public IReadOnlyList<CustomerShopkeeperOptionViewModel> Shopkeepers { get; init; } = [];
    public IReadOnlyList<CustomerProductOptionViewModel> Products { get; init; } = [];
    public IReadOnlyList<ShopCategoryViewModel> Categories { get; init; } = [];
    public IReadOnlyList<CustomerOrderMaster> Orders { get; init; } = [];
    public IReadOnlyList<DeliveryAssignment> DeliveryAssignments { get; init; } = [];
    public string? SuccessMessage { get; init; }
    public int UnreadChatCount { get; init; }
    public string SupportNumber { get; init; } = "09678-123456";
    public decimal WalletBalance { get; init; }
    public IReadOnlyList<CustomerDueItemViewModel> Dues { get; init; } = [];
    public DistrictPricingDetailViewModel DistrictPricing { get; init; } = new();

    public int TotalOrders => Orders.Count;
    public int PendingOrders => Orders.Count(order => order.Status == CustomerOrderStatus.Pending);
    public int CompletedOrders => Orders.Count(order => order.Status == CustomerOrderStatus.Delivered);
    public decimal TotalPurchaseAmount => Orders.Sum(order => order.TotalAmount);
    public int RewardPoints => (int)Math.Floor(TotalPurchaseAmount / 100);
    public decimal TotalDueAmount => Dues.Sum(due => due.DueAmount);
}

public sealed class ShopCategoryViewModel
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
    public string BanglaName { get; init; } = "";
    public string Icon { get; init; } = "🛍️";
    public string? Description { get; init; }
    public int ProductCount { get; set; }
}

public sealed class DistrictPricingDetailViewModel
{
    public string DistrictName { get; init; } = "Dhaka";
    public decimal TransportMultiplier { get; init; } = 1.0000m;
    public decimal DistrictAdjustmentAmount { get; init; } = 0.00m;
    public decimal DefaultDeliveryCharge { get; init; } = 30.00m;
    public decimal ServiceCharge { get; init; } = 10.00m;
    public decimal PlatformCharge { get; init; } = 5.00m;
    public decimal ShopkeeperMarginPercent { get; init; } = 10.00m;
    public decimal CompanyMarginPercent { get; init; } = 5.00m;
}

public sealed class CustomerDueItemViewModel
{
    public int SaleId { get; init; }
    public string InvoiceNo { get; init; } = "";
    public int ShopkeeperId { get; init; }
    public string ShopName { get; init; } = "";
    public string ShopkeeperPhone { get; init; } = "";
    public decimal GrossAmount { get; init; }
    public decimal PaidAmount { get; init; }
    public decimal DueAmount { get; init; }
    public DateTime SoldAt { get; init; }
    public string PaymentMethod { get; init; } = "";
    public IReadOnlyList<ShopkeeperTransactionItemViewModel> Items { get; init; } = [];
}

public sealed class CustomerShopkeeperOptionViewModel
{
    public int Id { get; init; }
    public string ShopName { get; init; } = "";
    public string OwnerName { get; init; } = "";
    public string Phone { get; init; } = "";
    public string Area { get; init; } = "";
    public string Address { get; init; } = "";
    public string ThanaName { get; init; } = "";
    public string DistrictName { get; init; } = "";
    public decimal Latitude { get; init; }
    public decimal Longitude { get; init; }
    public string ShopType { get; init; } = "";
    public string FieldOfficerName { get; init; } = "";
    public string FieldOfficerPhone { get; init; } = "";
    public double? DistanceKm { get; set; }
    public int AvailableProductCount { get; set; }
}

public sealed class CustomerProductOptionViewModel
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
    public string Sku { get; init; } = "";
    public string Category { get; init; } = "";
    public string Uom { get; init; } = "পিস";
    public decimal BasePrice { get; init; }
    public decimal DistrictAdjustment { get; init; }
    public decimal CompanyMargin { get; init; }
    public decimal ShopkeeperMargin { get; init; }
    public decimal UnitPrice { get; init; } // Final Selling Price = Base + DistrictAdj + CompanyMargin + ShopMargin
    public string? ImageUrl { get; init; }
    public string? Description { get; init; }
    public string DistrictName { get; init; } = "Dhaka";
    public IReadOnlyList<int> AvailableShopkeeperIds { get; init; } = [];
    public bool IsPopular { get; init; }
    public bool IsRecommended { get; init; }
}

public sealed class CustomerOrderInputModel
{
    [Required]
    public int? ShopkeeperId { get; set; }

    public decimal? CustomerLatitude { get; set; }

    public decimal? CustomerLongitude { get; set; }

    public string? DistrictName { get; set; } = "Dhaka";

    public string? Remarks { get; set; }

    public string PaymentMethod { get; set; } = "ক্যাশ";

    public string DeliveryType { get; set; } = "পিকআপ"; // "পিকআপ" or "হোম ডেলিভারি"

    public decimal DeliveryCharge { get; set; } = 0m;

    public decimal ServiceCharge { get; set; } = 0m;

    public decimal PlatformCharge { get; set; } = 0m;

    public List<CustomerOrderItemInputModel> Items { get; set; } = [];
}

public sealed class CustomerLocationInputModel
{
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
}

public sealed class CustomerOrderItemInputModel
{
    public int? ProductId { get; set; }
    public int? Quantity { get; set; }
}

public sealed class CustomerOrderMaster
{
    public int Id { get; init; }
    public int CustomerId { get; init; }
    public string CustomerName { get; init; } = "";
    public string CustomerPhone { get; init; } = "";
    public int ShopkeeperId { get; init; }
    public string ShopkeeperName { get; init; } = "";
    public DateTime OrderDate { get; init; } = DateTime.Now;
    public decimal TotalAmount { get; set; }
    public decimal DiscountAmount { get; set; }
    public string? DistrictName { get; set; }
    public decimal DeliveryCharge { get; set; } = 0m;
    public decimal ServiceCharge { get; set; } = 0m;
    public decimal PlatformCharge { get; set; } = 0m;
    public string DeliveryType { get; set; } = "পিকআপ";
    public decimal NetAmount => TotalAmount - DiscountAmount + DeliveryCharge + ServiceCharge + PlatformCharge;
    public string Status { get; set; } = CustomerOrderStatus.Pending;
    public string? Remarks { get; set; }
    public IReadOnlyList<CustomerOrderDetail> Details { get; set; } = [];
}

public sealed class CustomerOrderDetail
{
    public int Id { get; init; }
    public int OrderMasterId { get; init; }
    public int ProductId { get; init; }
    public string ProductName { get; init; } = "";
    public string Sku { get; init; } = "";
    public int Quantity { get; init; }
    public decimal UnitPrice { get; init; }
    public decimal BasePrice { get; init; }
    public decimal DistrictAdjustment { get; init; }
    public decimal CompanyMargin { get; init; }
    public decimal ShopkeeperMargin { get; init; }
    public decimal TotalPrice => Quantity * UnitPrice;
}

public static class CustomerOrderStatus
{
    public const string Pending = "Pending";
    public const string Approved = "Approved";
    public const string Delivered = "Delivered";
    public const string Rejected = "Rejected";
    public const string Assigned = "Assigned";
    public const string Accepted = "Accepted";
    public const string PickedUp = "Picked Up";
    public const string OutForDelivery = "Out for Delivery";
    public const string Failed = "Failed Delivery";
    public const string Returned = "Returned";
}
