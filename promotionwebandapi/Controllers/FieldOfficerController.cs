using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

public sealed class FieldOfficerController(
    AppStore store,
    ProductDistributionStore productStore,
    IWebHostEnvironment environment) : Controller
{
    [HttpGet("/FieldForce")]
    public IActionResult Dashboard()
    {
        if (!IsFieldOfficer())
        {
            return RedirectToAction("Login", "Account");
        }

        return View("Dashboard", BuildDashboard());
    }

    [HttpGet("/FieldForce/Dashboard")]
    public IActionResult FieldForceDashboard()
    {
        return Dashboard();
    }

    [HttpGet("/FieldForce/Shops")]
    public IActionResult Shops()
    {
        if (!IsFieldOfficer())
        {
            return RedirectToAction("Login", "Account");
        }

        return View("Shops", BuildShopsModel());
    }

    [HttpGet("/FieldForce/Products")]
    public IActionResult Products()
    {
        if (!IsFieldOfficer()) return RedirectToAction("Login", "Account");

        var model = new FieldOfficerProductsViewModel
        {
            OfficerName = HttpContext.Session.GetString("UserName") ?? "ফিল্ড ফোর্স",
            Products = productStore.GetProducts(GetUserId())
        };
        return View("Products", model);
    }

    [HttpGet("/FieldForce/ProductDistribution")]
    public IActionResult ProductDistribution()
    {
        if (!IsFieldOfficer()) return RedirectToAction("Login", "Account");

        return View("~/Views/Account/ProductDistribution.cshtml", new CompanyDashboardViewModel
        {
            CompanyName = HttpContext.Session.GetString("UserName") ?? "Field Force",
            CompanyPhone = HttpContext.Session.GetString("UserPhone") ?? "",
            DistributionProducts = productStore.GetProducts(GetUserId()),
            Locations = store.GetLocationCatalog()
        });
    }

    [HttpGet("/FieldForce/Messages")]
    public IActionResult Messages()
    {
        if (!IsFieldOfficer()) return RedirectToAction("Login", "Account");
        return View("Messages", BuildDashboard());
    }

    [HttpGet("/FieldForce/Notifications")]
    public IActionResult Notifications()
    {
        if (!IsFieldOfficer()) return RedirectToAction("Login", "Account");
        return View("Notifications", BuildDashboard());
    }

    [HttpGet("/FieldForce/Profile")]
    public IActionResult Profile()
    {
        if (!IsFieldOfficer()) return RedirectToAction("Login", "Account");
        return View("Profile", BuildDashboard());
    }

    [HttpPost("/FieldForce/UpdateProfilePicture")]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(20 * 1024 * 1024)]
    public async Task<IActionResult> UpdateProfilePicture(IFormFile profilePicture)
    {
        if (!IsFieldOfficer()) return RedirectToAction("Login", "Account");
        var userId = GetUserId();

        if (profilePicture is { Length: > 0 })
        {
            var ext = Path.GetExtension(profilePicture.FileName).ToLowerInvariant();
            if (profilePicture.Length > 5 * 1024 * 1024 || ext is not (".jpg" or ".jpeg" or ".png" or ".webp"))
            {
                TempData["ErrorMessage"] = "প্রোফাইল ছবিটি JPG, PNG বা WEBP হতে হবে এবং সর্বোচ্চ ৫ MB হতে পারবে।";
                return RedirectToAction(nameof(Profile));
            }

            var uploads = Path.Combine(environment.ContentRootPath, "uploads", "profiles");
            Directory.CreateDirectory(uploads);
            var filename = Guid.NewGuid().ToString() + ext;
            var filepath = Path.Combine(uploads, filename);
            using var stream = new FileStream(filepath, FileMode.Create);
            await profilePicture.CopyToAsync(stream);
            var photoPath = $"/uploads/profiles/{filename}";
            
            store.UpdateUserProfilePicture(userId, photoPath);
            TempData["SuccessMessage"] = "প্রোফাইল ছবি সফলভাবে আপডেট হয়েছে।";
        }
        else
        {
            TempData["ErrorMessage"] = "অনুগ্রহ করে একটি ছবি নির্বাচন করুন।";
        }

        return RedirectToAction(nameof(Profile));
    }

    [HttpPost("/FieldForce/ChangePassword")]
    [ValidateAntiForgeryToken]
    public IActionResult ChangePassword([FromBody] ChangePasswordInputModel? input)
    {
        if (!IsFieldOfficer())
        {
            return Unauthorized(new { success = false, message = "Session শেষ হয়েছে। আবার login করুন।" });
        }

        if (input is null)
        {
            return BadRequest(new { success = false, message = "তথ্য পাওয়া যায়নি।" });
        }

        if (!ModelState.IsValid)
        {
            var message = ModelState.Values
                .SelectMany(value => value.Errors)
                .Select(error => error.ErrorMessage)
                .FirstOrDefault(error => !string.IsNullOrWhiteSpace(error))
                ?? "পাসওয়ার্ড পরিবর্তন ব্যর্থ হয়েছে।";
            return BadRequest(new { success = false, message });
        }

        try
        {
            var success = store.ChangePassword(GetUserId(), input.OldPassword.Trim(), input.NewPassword.Trim());
            return success
                ? Json(new { success = true, message = "পাসওয়ার্ড সফলভাবে পরিবর্তন করা হয়েছে।" })
                : BadRequest(new { success = false, message = "বর্তমান পাসওয়ার্ড সঠিক নয়।" });
        }
        catch
        {
            return BadRequest(new { success = false, message = "পাসওয়ার্ড পরিবর্তন করা যায়নি। আবার চেষ্টা করুন।" });
        }
    }

    [HttpGet("/FieldForce/Reports")]
    public IActionResult Reports()
    {
        if (!IsFieldOfficer()) return RedirectToAction("Login", "Account");
        return View("Reports", BuildDashboard());
    }

    [HttpGet("/FieldForce/Orders")]
    public IActionResult Orders()
    {
        if (!IsFieldOfficer()) return RedirectToAction("Login", "Account");
        return View("Reports", BuildDashboard());
    }

    [HttpPost("/FieldForce/Products")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AddProduct(FieldOfficerProductsViewModel model)
    {
        if (!IsFieldOfficer()) return RedirectToAction("Login", "Account");

        if (!ModelState.IsValid)
        {
            model.OfficerName = HttpContext.Session.GetString("UserName") ?? "ফিল্ড ফোর্স";
            model.Products = productStore.GetProducts(GetUserId());
            return View("Products", model);
        }

        if (model.Input.ImageFile is { Length: > 0 })
        {
            var uploads = Path.Combine(environment.ContentRootPath, "uploads", "products");
            Directory.CreateDirectory(uploads);
            var filename = Guid.NewGuid().ToString() + Path.GetExtension(model.Input.ImageFile.FileName);
            var filepath = Path.Combine(uploads, filename);
            using var stream = new FileStream(filepath, FileMode.Create);
            await model.Input.ImageFile.CopyToAsync(stream);
            model.Input.ImageUrl = $"/uploads/products/{filename}";
        }

        try
        {
            productStore.CreateProduct(GetUserId(), model.Input);
            TempData["SuccessMessage"] = "প্রোডাক্ট সফলভাবে এন্ট্রি করা হয়েছে।";
            return RedirectToAction(nameof(Products));
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", "প্রোডাক্ট এন্ট্রি করতে সমস্যা হয়েছে: " + ex.Message);
            model.OfficerName = HttpContext.Session.GetString("UserName") ?? "ফিল্ড ফোর্স";
            model.Products = productStore.GetProducts(GetUserId());
            return View("Products", model);
        }
    }

    [HttpPost("/FieldForce/Products/Edit")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> EditProduct(FieldOfficerProductEditInputModel input)
    {
        if (!IsFieldOfficer()) return RedirectToAction("Login", "Account");
        try
        {
            if (input.ImageFile is { Length: > 0 })
            {
                if (input.ImageFile.Length > 4 * 1024 * 1024)
                    throw new InvalidOperationException("Product image must be 4 MB or smaller.");
                var extension = Path.GetExtension(input.ImageFile.FileName).ToLowerInvariant();
                if (extension is not (".jpg" or ".jpeg" or ".png" or ".webp"))
                    throw new InvalidOperationException("Only JPG, PNG and WebP images are allowed.");
                var uploads = Path.Combine(environment.ContentRootPath, "uploads", "products");
                Directory.CreateDirectory(uploads);
                var filename = $"{Guid.NewGuid():N}{extension}";
                await using var stream = System.IO.File.Create(Path.Combine(uploads, filename));
                await input.ImageFile.CopyToAsync(stream);
                input.ImageUrl = $"/uploads/products/{filename}";
            }
            productStore.UpdateProductForFieldOfficer(GetUserId(), input);
            TempData["SuccessMessage"] = "Product details and percentage allocation updated.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["ErrorMessage"] = ex.Message;
        }
        return RedirectToAction(nameof(Products));
    }

    [HttpPost("/FieldForce/Shops/Edit")]
    [ValidateAntiForgeryToken]
    public IActionResult EditShopkeeper(FieldOfficerShopEditInputModel input)
    {
        if (!IsFieldOfficer()) return RedirectToAction("Login", "Account");
        try
        {
            store.UpdateShopkeeper(GetUserId(), input);
            productStore.UpdateShopProductAssignments(
                GetUserId(),
                input.ShopkeeperId,
                input.ShopType,
                input.SelectedProductIds,
                input.ProductPrices);
            TempData["SuccessMessage"] = "Shopkeeper details, products and prices updated.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["ErrorMessage"] = ex.Message;
        }
        return RedirectToAction(nameof(Shops));
    }


    [HttpPost("/FieldForce/RegisterShopkeeper")]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> RegisterShopkeeper([Bind(Prefix = "Registration")] ShopkeeperRegistrationViewModel registration)
    {
        if (!IsFieldOfficer())
        {
            if (IsAjaxRequest())
            {
                return Unauthorized(new { success = false, message = "সেশন শেষ হয়েছে। আবার লগইন করুন।" });
            }

            return RedirectToAction("Login", "Account");
        }

        var selectedProductIds = registration.SelectedProductIds.Distinct().ToHashSet();
        var validSelectedProductCount = productStore.GetProducts(GetUserId()).Count(product =>
            product.IsActive
            && product.Category == registration.ShopType
            && selectedProductIds.Contains(product.Id));
        if (selectedProductIds.Count == 0 || validSelectedProductCount != selectedProductIds.Count)
        {
            ModelState.AddModelError(
                "Registration.SelectedProductIds",
                "Select at least one valid product from the chosen category.");
        }

        if (!ModelState.IsValid)
        {
            if (IsAjaxRequest())
            {
                return BadRequest(new
                {
                    success = false,
                    message = "ফর্মের তথ্য ঠিক করে আবার চেষ্টা করুন।",
                    errors = GetValidationErrors()
                });
            }

            return View("Dashboard", BuildDashboard(registration));
        }

        string? profilePhotoPath = null;
        string? billboardPhotoPath = null;
        try
        {
            profilePhotoPath = await SaveShopkeeperImage(registration.ProfilePhoto, "profile");
            billboardPhotoPath = await SaveShopkeeperImage(registration.BillboardPhoto, "billboard");
            var shop = store.RegisterShopkeeper(registration, GetUserId(), profilePhotoPath, billboardPhotoPath);
            productStore.AssignProductsToShop(shop.Id, registration.ShopType, registration.SelectedProductIds);
            
            TempData["SuccessMessage"] = $"{shop.ShopName} রেজিস্ট্রেশন সম্পন্ন। এখন দোকানদার {shop.Phone} দিয়ে লগইন করতে পারবেন।";
            
            if (IsAjaxRequest())
            {
                return Json(new
                {
                    success = true,
                    message = TempData["SuccessMessage"],
                    shop = new
                    {
                        shop.ShopName,
                        shop.OwnerName,
                        shop.Phone,
                        shop.ShopCode,
                        shop.ShopType,
                        shop.Area,
                        shop.Address,
                        shop.DistrictName,
                        shop.ThanaName
                    }
                });
            }

            return RedirectToAction(nameof(Dashboard));
        }
        catch (InvalidOperationException ex)
        {
            DeleteUploadedFile(profilePhotoPath);
            DeleteUploadedFile(billboardPhotoPath);
            ModelState.AddModelError("Registration.Phone", ex.Message);
            if (IsAjaxRequest())
            {
                return BadRequest(new
                {
                    success = false,
                    message = ex.Message,
                    errors = GetValidationErrors()
                });
            }

            return View("Dashboard", BuildDashboard(registration));
        }
    }

    private void DeleteUploadedFile(string? relativeUrl)
    {
        if (string.IsNullOrWhiteSpace(relativeUrl)) return;
        var physicalPath = Path.Combine(environment.ContentRootPath, relativeUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
        if (System.IO.File.Exists(physicalPath))
        {
            System.IO.File.Delete(physicalPath);
        }
    }

    private FieldOfficerDashboardViewModel BuildDashboard(ShopkeeperRegistrationViewModel? registration = null)
    {
        var userId = GetUserId();
        var user = store.GetUserById(userId);
        return new FieldOfficerDashboardViewModel
        {
            OfficerName = user?.Name ?? HttpContext.Session.GetString("UserName") ?? "ফিল্ড ফোর্স",
            ProfilePictureUrl = user?.ProfilePictureUrl,
            Registration = registration ?? new ShopkeeperRegistrationViewModel(),
            Shops = store.GetShopkeepers(userId),
            Locations = store.GetLocationCatalog(),
            Products = productStore.GetProducts(userId)
                .Where(product => product.IsActive)
                .OrderBy(product => product.Category)
                .ThenBy(product => product.Name)
                .ToList(),
            SuccessMessage = TempData["SuccessMessage"] as string
        };
    }

    private FieldOfficerShopsViewModel BuildShopsModel()
    {
        var userId = GetUserId();
        return new FieldOfficerShopsViewModel
        {
            OfficerName = HttpContext.Session.GetString("UserName") ?? "Field Force",
            Shops = store.GetShopkeepers(userId),
            Locations = store.GetLocationCatalog(),
            Products = productStore.GetProducts(userId).Where(product => product.IsActive).ToList(),
            Assignments = productStore.GetShopProductAssignments(userId)
        };
    }

    private async Task<string?> SaveShopkeeperImage(IFormFile? file, string category)
    {
        if (file is null || file.Length == 0)
        {
            return null;
        }

        if (file.Length > 4 * 1024 * 1024)
        {
            throw new InvalidOperationException("Each image must be 4 MB or smaller.");
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (extension is not (".jpg" or ".jpeg" or ".png" or ".webp"))
        {
            throw new InvalidOperationException("Only JPG, PNG and WebP images are allowed.");
        }

        var folder = Path.Combine(environment.ContentRootPath, "uploads", "shopkeepers", category);
        Directory.CreateDirectory(folder);
        var fileName = $"{Guid.NewGuid():N}{extension}";
        await using var stream = System.IO.File.Create(Path.Combine(folder, fileName));
        await file.CopyToAsync(stream);
        return $"/uploads/shopkeepers/{category}/{fileName}";
    }

    private bool IsFieldOfficer() =>
        HttpContext.Session.GetString("UserRole") == Roles.FieldOfficer
        && HttpContext.Session.GetInt32("UserId") is not null;

    private int GetUserId() => HttpContext.Session.GetInt32("UserId") ?? 0;

    private bool IsAjaxRequest()
    {
        return string.Equals(Request.Headers["X-Requested-With"], "XMLHttpRequest", StringComparison.OrdinalIgnoreCase);
    }

    private Dictionary<string, string[]> GetValidationErrors()
    {
        return ModelState
            .Where(item => item.Value?.Errors.Count > 0)
            .ToDictionary(
                item => item.Key,
                item => item.Value!.Errors.Select(error => error.ErrorMessage).ToArray());
    }
}
