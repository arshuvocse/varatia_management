namespace PromotionWeb.Models;

public sealed class LandingPageViewModel
{
    public IReadOnlyList<DistrictMarketSummary> Districts { get; init; } = [];
    public IReadOnlyList<Shopkeeper> FeaturedShopkeepers { get; init; } = [];
    public int TotalShopkeepers { get; init; }
    public int TotalCustomers { get; init; }
}

public sealed class DistrictMarketSummary
{
    public int DistrictId { get; init; }
    public string DistrictName { get; init; } = "";
    public int ShopkeeperCount { get; init; }
    public int CustomerCount { get; init; }
}

public sealed class LandingNetworkStatsViewModel
{
    public int Customers { get; init; }
    public int Shopkeepers { get; init; }
    public int DeliveryMen { get; init; }
    public int FieldForce { get; init; }
}
