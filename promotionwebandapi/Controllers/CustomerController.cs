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
    public IActionResult PlaceOrder(int? shopkeeperId)
    {
        return CustomerView(shopkeeperId is null
            ? null
            : new CustomerOrderInputModel { ShopkeeperId = shopkeeperId });
    }

    [HttpGet]
    public IActionResult Orders()
    {
        return CustomerView();
    }

    [HttpGet]
    public IActionResult Shops()
    {
        return CustomerView();
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
            var uploads = Path.Combine(environment.ContentRootPath, "uploads", "customers");
            Directory.CreateDirectory(uploads);
            var filename = Guid.NewGuid().ToString() + Path.GetExtension(profilePicture.FileName);
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
            return View(nameof(PlaceOrder), BuildDashboard(order));
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
            return View(nameof(PlaceOrder), BuildDashboard(order));
        }
    }

    private IActionResult CustomerView(CustomerOrderInputModel? order = null)
    {
        if (!IsCustomer())
        {
            return RedirectToAction("Login", "Account");
        }

        return View(BuildDashboard(order));
    }

    private CustomerDashboardViewModel BuildDashboard(CustomerOrderInputModel? order = null)
    {
        var shops = store.GetShopkeepers()
            .Select(shop => new CustomerShopkeeperOptionViewModel
            {
                Id = shop.Id,
                ShopName = shop.ShopName,
                OwnerName = shop.OwnerName,
                Phone = shop.Phone,
                Area = shop.Area,
                Address = shop.Address,
                ThanaName = shop.ThanaName,
                DistrictName = shop.DistrictName,
                Latitude = shop.Latitude,
                Longitude = shop.Longitude,
                ShopType = shop.ShopType,
                FieldOfficerName = shop.FieldOfficerName,
                FieldOfficerPhone = shop.FieldOfficerPhone
            })
            .ToList();

        var input = order ?? new CustomerOrderInputModel
        {
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
            Order = input,
            Shopkeepers = shops,
            Products = orderStore.GetProducts(),
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
