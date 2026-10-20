using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

public sealed class CustomerController(
    AppStore store,
    CustomerOrderStore orderStore,
    ChatStore chatStore,
    DeliveryStore deliveryStore,
    ProductDistributionStore distributionStore,
    ShopkeeperSaleStore saleStore,
    LoanStore loanStore,
    IWebHostEnvironment environment) : Controller
{
    [HttpGet]
    public IActionResult Index() => RedirectToAction(nameof(PlaceOrder));

    [HttpGet]
    public IActionResult Dashboard()
    {
        return CustomerView();
    }

    [HttpGet]
    public IActionResult Dues()
    {
        return CustomerView();
    }

    [HttpGet]
    public IActionResult Loan()
    {
        if (!IsCustomer()) return RedirectToAction("Login", "Account");
        var userId = GetUserId();
        var phone = HttpContext.Session.GetString("UserPhone") ?? "";
        var name = HttpContext.Session.GetString("UserName") ?? "Customer";

        var vm = new CustomerLoanDashboardViewModel
        {
            CustomerName = name,
            CustomerPhone = phone,
            WalletBalance = distributionStore.GetUserWalletBalance(userId),
            Eligibility = loanStore.GetEligibility(userId, Roles.Customer, phone),
            ActiveLoan = loanStore.GetActiveLoan(userId),
            LoanHistory = loanStore.GetUserLoans(userId),
            SuccessMessage = TempData["SuccessMessage"] as string,
            ErrorMessage = TempData["ErrorMessage"] as string
        };
        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult ApplyLoan([FromForm] LoanApplicationInputModel input)
    {
        if (!IsCustomer()) return RedirectToAction("Login", "Account");
        var userId = GetUserId();
        var phone = HttpContext.Session.GetString("UserPhone") ?? "";
        var name = HttpContext.Session.GetString("UserName") ?? "Customer";

        if (!ModelState.IsValid)
        {
            TempData["ErrorMessage"] = "সঠিক তথ্য দিয়ে লোনের ফরম পূরণ করুন।";
            return RedirectToAction(nameof(Loan));
        }

        try
        {
            var loan = loanStore.ApplyLoan(userId, Roles.Customer, name, phone, input);
            TempData["SuccessMessage"] = $"অভিনন্দন! আপনার ৳{loan.LoanAmount:N0} টাকার ডিজিটাল লোন তাৎক্ষণিক অনুমোদন ও ওয়ালেটে জমা হয়েছে।";
            return RedirectToAction(nameof(Loan));
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = ex.Message;
            return RedirectToAction(nameof(Loan));
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult PayLoanInstallment(int installmentId, string paymentMethod = "Wallet")
    {
        if (!IsCustomer()) return RedirectToAction("Login", "Account");
        var userId = GetUserId();
        try
        {
            var success = loanStore.PayInstallment(installmentId, userId, paymentMethod);
            if (success)
            {
                TempData["SuccessMessage"] = "কিস্তি সফলভাবে পরিশোধ করা হয়েছে।";
            }
            else
            {
                TempData["ErrorMessage"] = "কিস্তি পরিশোধ করা যায়নি।";
            }
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = ex.Message;
        }
        return RedirectToAction(nameof(Loan));
    }

    [HttpGet]
    public IActionResult AgentLocation(string? districtName = null, double? lat = null, double? lon = null)
    {
        if (!IsCustomer()) return RedirectToAction("Login", "Account");
        var agent = loanStore.GetAgentOfficeForDistrict(districtName ?? "Dhaka", lat, lon);
        return View(agent);
    }

    [HttpGet]
    public IActionResult PlaceOrder(int? shopkeeperId, string? district = null, double? lat = null, double? lon = null)
    {
        return CustomerView(shopkeeperId is null
            ? null
            : new CustomerOrderInputModel { ShopkeeperId = shopkeeperId, DistrictName = district ?? "Dhaka" },
            district, lat, lon);
    }

    [HttpGet]
    public IActionResult Orders()
    {
        return CustomerView();
    }

    [HttpGet]
    public IActionResult Shops(string? district = null, string? category = null, double? lat = null, double? lon = null)
    {
        var model = BuildDashboard(null, district, lat, lon, category);
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult UpdateLocation([FromBody] CustomerLocationInputModel? input)
    {
        if (!IsCustomer())
        {
            return Unauthorized(new { success = false, message = "Session শেষ হয়েছে। আবার login করুন।" });
        }

        if (input?.Latitude is not { } latitude || latitude is < -90 or > 90
            || input.Longitude is not { } longitude || longitude is < -180 or > 180)
        {
            return BadRequest(new { success = false, message = "সঠিক লোকেশন পাওয়া যায়নি।" });
        }

        var phone = HttpContext.Session.GetString("UserPhone");
        if (string.IsNullOrWhiteSpace(phone)) return RedirectToAction("Login", "Account");

        store.UpdateCustomerLocation(phone, latitude, longitude);
        return Json(new { success = true });
    }

    [HttpGet]
    public IActionResult Chat()
    {
        return CustomerView();
    }

    [HttpGet]
    public IActionResult Wallet()
    {
        return CustomerView();
    }

    [HttpGet]
    public IActionResult Rewards() => RedirectToAction(nameof(Wallet));

    [HttpGet]
    public IActionResult Profile()
    {
        return CustomerView();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateProfilePicture(IFormFile profilePicture)
    {
        if (!IsCustomer()) return RedirectToAction("Login", "Account");

        var phone = HttpContext.Session.GetString("UserPhone");
        if (string.IsNullOrEmpty(phone)) return RedirectToAction("Login", "Account");

        if (profilePicture is { Length: > 0 })
        {
            var ext = Path.GetExtension(profilePicture.FileName).ToLowerInvariant();
            if (profilePicture.Length > 5 * 1024 * 1024 || ext is not (".jpg" or ".jpeg" or ".png" or ".webp"))
            {
                TempData["ErrorMessage"] = "Profile picture must be JPG, PNG or WEBP and at most 5 MB.";
                return RedirectToAction(nameof(Profile));
            }

            var uploads = Path.Combine(environment.ContentRootPath, "uploads", "customers");
            Directory.CreateDirectory(uploads);
            var filename = Guid.NewGuid().ToString() + ext;
            var filepath = Path.Combine(uploads, filename);
            using var stream = new FileStream(filepath, FileMode.Create);
            await profilePicture.CopyToAsync(stream);
            var photoPath = $"/uploads/customers/{filename}";
            
            store.UpdateCustomerProfilePhoto(phone, photoPath);
            TempData["SuccessMessage"] = "Profile picture updated successfully.";
        }
        else
        {
            TempData["ErrorMessage"] = "Please select a valid image.";
        }
        
        return RedirectToAction(nameof(Profile));
    }

    [HttpGet]
    public IActionResult ChangePassword()
    {
        return CustomerView();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult ChangePassword([FromBody] ChangePasswordInputModel? input)
    {
        if (!IsCustomer())
        {
            return Unauthorized(new { success = false, message = "Session শেষ হয়েছে। আবার login করুন।" });
        }

        if (input is null)
        {
            return BadRequest(new { success = false, message = "তথ্য পাওয়া যায়নি।" });
        }

        if (!ModelState.IsValid)
        {
            var message = ModelState.Values
                .SelectMany(value => value.Errors)
                .Select(error => error.ErrorMessage)
                .FirstOrDefault(error => !string.IsNullOrWhiteSpace(error))
                ?? "পাসওয়ার্ড পরিবর্তন ব্যর্থ হয়েছে।";
            return BadRequest(new { success = false, message });
        }

        try
        {
            var success = store.ChangePassword(GetUserId(), input.OldPassword.Trim(), input.NewPassword.Trim());
            return success
                ? Json(new { success = true, message = "পাসওয়ার্ড সফলভাবে পরিবর্তন করা হয়েছে।" })
                : BadRequest(new { success = false, message = "বর্তমান পাসওয়ার্ড সঠিক নয়।" });
        }
        catch
        {
            return BadRequest(new { success = false, message = "পাসওয়ার্ড পরিবর্তন করা যায়নি। আবার চেষ্টা করুন।" });
        }
    }

    [HttpGet]
    public IActionResult Support()
    {
        return CustomerView();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult PlaceOrder(CustomerOrderInputModel order)
    {
        if (!IsCustomer())
        {
            return RedirectToAction("Login", "Account");
        }

        var shops = store.GetShopkeepers();
        var shopkeeper = shops.FirstOrDefault(shop => shop.Id == order.ShopkeeperId);
        if (shopkeeper is null)
        {
            ModelState.AddModelError(nameof(order.ShopkeeperId), "Please select a shopkeeper.");
        }

        if (!ModelState.IsValid || shopkeeper is null)
        {
            return View(nameof(PlaceOrder), BuildDashboard(order, order.DistrictName));
        }

        try
        {
            var createdOrder = orderStore.CreateOrder(
                GetUserId(),
                HttpContext.Session.GetString("UserName") ?? "Customer",
                HttpContext.Session.GetString("UserPhone") ?? "",
                shopkeeper,
                order);

            TempData["SuccessMessage"] = $"Order #{createdOrder.Id} submitted to {createdOrder.ShopkeeperName}.";
            return RedirectToAction(nameof(Orders));
        }
        catch (InvalidOperationException ex)
        {
            ModelState.AddModelError("", ex.Message);
            return View(nameof(PlaceOrder), BuildDashboard(order, order.DistrictName));
        }
    }

    private IActionResult CustomerView(CustomerOrderInputModel? order = null, string? district = null, double? lat = null, double? lon = null)
    {
        if (!IsCustomer())
        {
            return RedirectToAction("Login", "Account");
        }

        return View(BuildDashboard(order, district, lat, lon));
    }

    private CustomerDashboardViewModel BuildDashboard(
        CustomerOrderInputModel? order = null,
        string? district = null,
        double? lat = null,
        double? lon = null,
        string? category = null)
    {
        var activeDistrict = string.IsNullOrWhiteSpace(district) ? "Dhaka" : district.Trim();

        if (lat is null || lon is null)
        {
            var savedPhone = HttpContext.Session.GetString("UserPhone");
            if (!string.IsNullOrWhiteSpace(savedPhone)
                && store.GetCustomerLocation(savedPhone) is { Latitude: { } savedLat, Longitude: { } savedLon })
            {
                lat ??= (double)savedLat;
                lon ??= (double)savedLon;
            }
        }

        var nearbyShops = orderStore.GetNearbyShops(lat, lon, activeDistrict, category);
        var products = orderStore.GetProducts(activeDistrict);
        var categories = orderStore.GetCategories();
        var districtPricing = orderStore.GetDistrictPricing(activeDistrict);

        var input = order ?? new CustomerOrderInputModel
        {
            DistrictName = activeDistrict,
            Items =
            [
                new() { Quantity = 1 },
                new(),
                new()
            ]
        };

        while (input.Items.Count < 3)
        {
            input.Items.Add(new CustomerOrderItemInputModel());
        }

        var phone = HttpContext.Session.GetString("UserPhone") ?? "";
        
        return new CustomerDashboardViewModel
        {
            CustomerName = HttpContext.Session.GetString("UserName") ?? "Customer",
            CustomerPhone = phone,
            ProfilePhotoPath = store.GetCustomerProfilePhotoPath(phone),
            SelectedDistrict = activeDistrict,
            Order = input,
            Shopkeepers = nearbyShops,
            Products = products,
            Categories = categories,
            DistrictPricing = districtPricing,
            Orders = orderStore.GetOrdersByCustomer(GetUserId()),
            DeliveryAssignments = deliveryStore.GetAssignmentsForCustomer(GetUserId()),
            UnreadChatCount = chatStore.GetUnreadCount(GetUserId()),
            WalletBalance = distributionStore.GetUserWalletBalance(GetUserId()),
            Dues = saleStore.GetCustomerDues(phone),
            SuccessMessage = TempData["SuccessMessage"] as string
        };
    }

    private bool IsCustomer() =>
        HttpContext.Session.GetString("UserRole") == Roles.Customer
        && HttpContext.Session.GetInt32("UserId") is not null;

    private int GetUserId() => HttpContext.Session.GetInt32("UserId") ?? 0;
}
