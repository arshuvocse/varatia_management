using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

public sealed class HomeController(AppStore store, DeliveryStore deliveryStore, DistrictLeaderboardService leaderboardService, CustomerOrderStore orderStore) : Controller
{
    [HttpGet]
    public IActionResult Index() => Redirect("/landing.html");

    [HttpGet("landing.aspx")]
    public IActionResult LandingAspx() => PhysicalFile(System.IO.Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "landing.aspx"), "text/html");

    [HttpGet("track-order")]
    public IActionResult TrackOrder(int? orderId, string? phone)
    {
        if (!orderId.HasValue || string.IsNullOrWhiteSpace(phone))
        {
            return View();
        }

        var order = orderStore.GetOrderByIdAndPhone(orderId.Value, phone);
        if (order is null)
        {
            ViewBag.ErrorMessage = "অর্ডার পাওয়া যায়নি। অনুগ্রহ করে সঠিক Order ID এবং ফোন নম্বর দিন।";
            return View();
        }

        var assignment = deliveryStore.GetAssignmentsForShopkeeper(order.ShopkeeperId)
            .FirstOrDefault(x => x.OrderId == order.Id);

        ViewBag.Order = order;
        ViewBag.Assignment = assignment;
        return View();
    }

    [HttpGet]
    public IActionResult NetworkStats()
    {
        try
        {
            deliveryStore.EnsureSchema();
            return Json(store.GetLandingNetworkStats());
        }
        catch
        {
            return Json(new { TotalShops = 50, TotalCustomers = 120, TotalOrders = 350, TotalDeliveryMen = 15 });
        }
    }

    [HttpGet]
    public IActionResult Bulletins()
    {
        try
        {
            return Json(store.GetCompanyBulletins(activeOnly: true));
        }
        catch
        {
            return Json(Array.Empty<object>());
        }
    }

    [HttpGet]
    public IActionResult Districts()
    {
        try
        {
            var catalog = store.GetLocationCatalog();
            return Json(catalog.Districts
                .OrderBy(d => d.Name)
                .Select(d => new { d.Id, d.Name }));
        }
        catch
        {
            return Json(Array.Empty<object>());
        }
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

    [HttpGet]
    public IActionResult TeamDirectory(int? districtId = null, string? role = null)
    {
        try
        {
            return Json(store.GetTeamDirectory(districtId, role));
        }
        catch
        {
            return Json(Array.Empty<object>());
        }
    }

    [Route("payment/success")]
    public IActionResult PaymentSuccess() => View();

    [HttpGet("Home/Error")]
    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = System.Diagnostics.Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }

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
