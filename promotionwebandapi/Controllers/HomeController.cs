using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

public sealed class HomeController(AppStore store, DeliveryStore deliveryStore, DistrictLeaderboardService leaderboardService) : Controller
{
    [HttpGet]
    public IActionResult Index() => Redirect("/landing.html");

    [HttpGet]
    public IActionResult NetworkStats()
    {
        deliveryStore.EnsureSchema();
        return Json(store.GetLandingNetworkStats());
    }

    [HttpGet]
    public IActionResult Bulletins()
    {
        return Json(store.GetCompanyBulletins(activeOnly: true));
    }

    [HttpGet]
    public IActionResult Districts()
    {
        var catalog = store.GetLocationCatalog();
        return Json(catalog.Districts
            .OrderBy(d => d.Name)
            .Select(d => new { d.Id, d.Name }));
    }

    [HttpGet]
    public IActionResult TopBuyers(int districtId)
    {
        return Json(leaderboardService.GetTopBuyers(districtId));
    }

    [HttpGet]
    public IActionResult TopShopkeepers(int districtId)
    {
        return Json(leaderboardService.GetTopShopkeepers(districtId));
    }

    [Route("payment/success")]
    public IActionResult PaymentSuccess() => View();

    private LandingPageViewModel BuildLandingPage()
    {
        try
        {
            var shopkeepers = store.GetShopkeepers()
                .Take(50)
                .ToList();

            var districts = shopkeepers
                .GroupBy(shop => new { shop.DistrictId, shop.DistrictName })
                .Select(group => new DistrictMarketSummary
                {
                    DistrictId = group.Key.DistrictId,
                    DistrictName = group.Key.DistrictName,
                    ShopkeeperCount = Math.Min(group.Count(), 50),
                    CustomerCount = EstimateCustomers(group.Count())
                })
                .OrderByDescending(item => item.ShopkeeperCount)
                .ThenBy(item => item.DistrictName)
                .Take(12)
                .ToList();

            if (districts.Count == 0)
            {
                districts = GetFallbackDistricts();
            }

            return new LandingPageViewModel
            {
                Districts = districts,
                FeaturedShopkeepers = shopkeepers,
                TotalShopkeepers = shopkeepers.Count,
                TotalCustomers = districts.Sum(item => item.CustomerCount)
            };
        }
        catch
        {
            var districts = GetFallbackDistricts();
            return new LandingPageViewModel
            {
                Districts = districts,
                TotalShopkeepers = districts.Sum(item => item.ShopkeeperCount),
                TotalCustomers = districts.Sum(item => item.CustomerCount)
            };
        }
    }

    private static int EstimateCustomers(int shopkeeperCount)
    {
        return Math.Min(50, Math.Max(shopkeeperCount * 12, shopkeeperCount == 0 ? 0 : 18));
    }

    private static List<DistrictMarketSummary> GetFallbackDistricts()
    {
        var districtNames = new[] { "Dhaka", "Gazipur", "Narayanganj", "Chattogram", "Cumilla", "Rajshahi", "Khulna", "Sylhet" };
        return districtNames.Select((name, index) => new DistrictMarketSummary
        {
            DistrictId = index + 1,
            DistrictName = name,
            ShopkeeperCount = Math.Max(18, 50 - (index * 4)),
            CustomerCount = Math.Max(24, 50 - (index * 3))
        }).ToList();
    }
}
