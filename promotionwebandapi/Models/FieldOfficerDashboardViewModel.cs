namespace PromotionWeb.Models;

public sealed class FieldOfficerDashboardViewModel
{
    public string OfficerName { get; init; } = "";
    public string? ProfilePictureUrl { get; init; }
    public ShopkeeperRegistrationViewModel Registration { get; init; } = new();
    public IReadOnlyList<Shopkeeper> Shops { get; init; } = [];
    public LocationCatalog Locations { get; init; } = new();
    public IReadOnlyList<CompanyDistributionProductViewModel> Products { get; init; } = [];
    public string? SuccessMessage { get; init; }
}

public sealed class FieldOfficerProductsViewModel
{
    public string OfficerName { get; set; } = "";
    public CompanyDistributionProductInputModel Input { get; set; } = new();
    public IReadOnlyList<CompanyDistributionProductViewModel> Products { get; set; } = [];
}

public sealed class FieldOfficerShopsViewModel
{
    public string OfficerName { get; init; } = "";
    public IReadOnlyList<Shopkeeper> Shops { get; init; } = [];
    public LocationCatalog Locations { get; init; } = new();
    public IReadOnlyList<CompanyDistributionProductViewModel> Products { get; init; } = [];
    public IReadOnlyList<ShopProductAssignmentViewModel> Assignments { get; init; } = [];
}

public sealed class FieldOfficerProductEditInputModel
{
    public int ProductId { get; set; }
    public string Name { get; set; } = "";
    public string Category { get; set; } = "";
    public string Uom { get; set; } = "";
    public decimal UnitPrice { get; set; }
    public int OpeningStock { get; set; }
    public decimal ShopkeeperPercentage { get; set; }
    public decimal CompanyPercentage { get; set; }
    public decimal AgentPercentage { get; set; }
    public decimal FieldForcePercentage { get; set; }
    public decimal CustomerPercentage { get; set; }
    public string? ImageUrl { get; set; }
    public Microsoft.AspNetCore.Http.IFormFile? ImageFile { get; set; }
}

public sealed class FieldOfficerShopEditInputModel
{
    public int ShopkeeperId { get; set; }
    public string ShopName { get; set; } = "";
    public string OwnerName { get; set; } = "";
    public string Phone { get; set; } = "";
    public string? NidNumber { get; set; }
    public int DivisionId { get; set; }
    public int DistrictId { get; set; }
    public int ThanaId { get; set; }
    public string Address { get; set; } = "";
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public string Area { get; set; } = "";
    public string ShopType { get; set; } = "";
    public string? NewPassword { get; set; }
    public List<int> SelectedProductIds { get; set; } = [];
    public List<ShopProductPriceInputModel> ProductPrices { get; set; } = [];
}

public sealed class ShopProductPriceInputModel
{
    public int CompanyProductId { get; set; }
    public decimal PurchasePrice { get; set; }
    public decimal SalesPrice { get; set; }
}

public sealed class FieldOfficerShopPricingInputModel
{
    public int ShopkeeperId { get; set; }
    public List<int> ShopkeeperIds { get; set; } = [];
    public List<int> SelectedProductIds { get; set; } = [];
    public List<ShopProductPriceInputModel> ProductPrices { get; set; } = [];
}

public sealed class ShopProductAssignmentViewModel
{
    public int ShopkeeperId { get; init; }
    public int CompanyProductId { get; init; }
    public decimal PurchasePrice { get; init; }
    public decimal SalesPrice { get; init; }
}
