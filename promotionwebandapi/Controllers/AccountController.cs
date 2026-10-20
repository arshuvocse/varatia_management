using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using PromotionWeb.Hubs;
using PromotionWeb.Models;
using PromotionWeb.Services;
using OrderProcessAPI.Services;
using System.Security.Claims;
using System.Text;

namespace PromotionWeb.Controllers;

public sealed class AccountController(
    AppStore store,
    ServiceRequestStore serviceRequestStore,
    DeliveryStore deliveryStore,
    ShopkeeperActivationStore activationStore,
    ProductDistributionStore distributionStore,
    ShopkeeperRequestStore requestStore,
    LoanStore loanStore) : Controller
{
    [HttpGet]
    public IActionResult Login()
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            return RedirectForRole(User.FindFirstValue(ClaimTypes.Role));
        }

        return View(new LoginViewModel());
    }

    [HttpPost]
    public async Task<IActionResult> RequestPasswordResetOtp([FromBody] ForgotPasswordInput input, [FromServices] ISmsOtpService smsService)
    {
        if (string.IsNullOrWhiteSpace(input.Phone) || !System.Text.RegularExpressions.Regex.IsMatch(input.Phone.Trim(), @"^01\d{9}$"))
        {
            return Json(new { success = false, message = "দয়া করে ১১ সংখ্যার সঠিক মোবাইল নম্বর দিন।" });
        }

        var user = store.GetUserByPhone(input.Phone.Trim());
        if (user is null)
        {
            return Json(new { success = false, message = "এই মোবাইল নম্বর দিয়ে কোনো অ্যাকাউন্ট পাওয়া যায়নি।" });
        }

        var random = new Random();
        var otp = random.Next(100000, 999999).ToString();
        HttpContext.Session.SetString($"ResetOtp_{input.Phone.Trim()}", otp);

        await smsService.SendOtpAsync(input.Phone.Trim(), otp, CancellationToken.None);
        return Json(new { success = true, message = $"OTP কোড পাঠানো হয়েছে। (Demo OTP: {otp})" });
    }

    [HttpPost]
    public IActionResult ResetPasswordWithOtp([FromBody] ResetPasswordInput input)
    {
        var savedOtp = HttpContext.Session.GetString($"ResetOtp_{input.Phone?.Trim()}");
        if (string.IsNullOrEmpty(savedOtp) || savedOtp != input.Otp?.Trim())
        {
            return Json(new { success = false, message = "ভুল বা মেয়াদউত্তীর্ণ OTP কোড।" });
        }

        if (string.IsNullOrWhiteSpace(input.NewPassword) || input.NewPassword.Length < 4)
        {
            return Json(new { success = false, message = "পাসওয়ার্ড অন্তত ৪ অক্ষরের হতে হবে।" });
        }

        var user = store.GetUserByPhone(input.Phone.Trim());
        if (user is null)
        {
            return Json(new { success = false, message = "ব্যবহারকারী পাওয়া যায়নি।" });
        }

        store.ResetUserPassword(user.Id, input.NewPassword.Trim());
        HttpContext.Session.Remove($"ResetOtp_{input.Phone.Trim()}");
        return Json(new { success = true, message = "পাসওয়ার্ড সফলভাবে পরিবর্তন করা হয়েছে! নতুন পাসওয়ার্ড দিয়ে লগইন করুন।" });
    }

    [HttpGet]
    public IActionResult Register()
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            return RedirectForRole(User.FindFirstValue(ClaimTypes.Role));
        }

        return View(new CustomerRegistrationViewModel());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Register(CustomerRegistrationViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        AppUser user;
        try
        {
            user = store.RegisterCustomer(model);
        }
        catch (InvalidOperationException ex)
        {
            ModelState.AddModelError("", ex.Message);
            return View(model);
        }

        HttpContext.Session.SetString("UserName", user.Name);
        HttpContext.Session.SetString("UserPhone", user.Phone);
        HttpContext.Session.SetString("UserRole", user.Role);
        HttpContext.Session.SetInt32("UserId", user.Id);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Name),
            new Claim(ClaimTypes.Role, user.Role),
            new Claim("phone", user.Phone)
        };
        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity),
            new AuthenticationProperties
            {
                IsPersistent = true,
                AllowRefresh = true,
                ExpiresUtc = DateTimeOffset.UtcNow.AddDays(30)
            });

        return RedirectToAction("PlaceOrder", "Customer");
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var user = store.ValidateUser(model.Phone.Trim(), model.Password);
        if (user is null)
        {
            ModelState.AddModelError("", "মোবাইল নম্বর অথবা পাসওয়ার্ড সঠিক নয়।");
            return View(model);
        }

        HttpContext.Session.SetString("UserName", user.Name);
        HttpContext.Session.SetString("UserPhone", user.Phone);
        HttpContext.Session.SetString("UserRole", user.Role);
        HttpContext.Session.SetInt32("UserId", user.Id);

        if (user.Role == Roles.Shopkeeper)
        {
            var shopkeeper = store.GetShopkeeperByPhone(user.Phone);
            if (shopkeeper is not null)
            {
                HttpContext.Session.SetString("ShopCategory", shopkeeper.ShopType);
            }
        }

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Name),
            new Claim(ClaimTypes.Role, user.Role),
            new Claim("phone", user.Phone)
        };
        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity),
            new AuthenticationProperties
            {
                IsPersistent = true,
                AllowRefresh = true,
                ExpiresUtc = DateTimeOffset.UtcNow.AddDays(30)
            });

        return RedirectForRole(user.Role);
    }

    [HttpGet]
    public IActionResult Dashboard()
    {
        if (string.IsNullOrWhiteSpace(HttpContext.Session.GetString("UserRole")))
        {
            return RedirectToAction(nameof(Login));
        }

        if (HttpContext.Session.GetString("UserRole") == Roles.Company)
        {
            return CompanyPage(nameof(Dashboard));
        }

        return View(new CompanyDashboardViewModel
        {
            CompanyName = HttpContext.Session.GetString("UserName") ?? "",
            CompanyPhone = HttpContext.Session.GetString("UserPhone") ?? ""
        });
    }

    [HttpGet]
    public IActionResult Sales() => CompanyPage(nameof(Sales));

    [HttpGet]
    public IActionResult Withdrawals()
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        ViewBag.Withdrawals = requestStore.GetAllWithdrawals();
        return CompanyPage(nameof(Withdrawals));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult ProcessWithdrawal(WithdrawalProcessInputModel input)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        if (!ModelState.IsValid) TempData["CompanyError"] = "Invalid withdrawal action.";
        else try
        {
            requestStore.ProcessWithdrawal(input.RequestId,input.Status,HttpContext.Session.GetInt32("UserId")??0,input.Note);
            TempData["CompanyMessage"] = $"Withdrawal request marked {input.Status}.";
        }
        catch (InvalidOperationException ex) { TempData["CompanyError"] = ex.Message; }
        return RedirectToAction(nameof(Withdrawals));
    }

    [HttpGet]
    public IActionResult Campaigns() => CompanyPage(nameof(Campaigns));

    [HttpGet]
    public IActionResult Orders() => CompanyPage(nameof(Orders));

    [HttpGet]
    public IActionResult Shopkeepers() => CompanyPage(nameof(Shopkeepers));

    [HttpGet]
    public IActionResult Loans(string? status, string? role)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        var loans = loanStore.GetAllLoans(status, role);
        var model = new AdminLoanManagementViewModel
        {
            Loans = loans,
            FilterStatus = status,
            FilterRole = role,
            Config = loanStore.GetLoanConfigRow(),
            SuccessMessage = TempData["CompanyMessage"] as string,
            ErrorMessage = TempData["CompanyError"] as string
        };
        ViewBag.LoanManagement = model;
        return CompanyPage(nameof(Loans));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult UpdateLoanStatus(int loanId, string status, string? note)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        try
        {
            var adminId = HttpContext.Session.GetInt32("UserId") ?? 0;
            var ok = loanStore.UpdateLoanStatus(loanId, status, note, adminId);
            if (ok)
            {
                TempData["CompanyMessage"] = $"লোন নং #{loanId:D5} সফলভাবে '{status}' করা হয়েছে।";
            }
            else
            {
                TempData["CompanyError"] = "লোন স্ট্যাটাস পরিবর্তন করা যায়নি।";
            }
        }
        catch (Exception ex)
        {
            TempData["CompanyError"] = ex.Message;
        }
        return RedirectToAction(nameof(Loans));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult UpdateLoanConfig(LoanConfigInputModel input)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        if (!ModelState.IsValid)
        {
            TempData["CompanyError"] = string.Join(" ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
            return RedirectToAction(nameof(Loans));
        }
        try
        {
            loanStore.UpdateLoanConfig(input);
            TempData["CompanyMessage"] = "লোন কনফিগারেশন সফলভাবে আপডেট হয়েছে।";
        }
        catch (Exception ex)
        {
            TempData["CompanyError"] = ex.Message;
        }
        return RedirectToAction(nameof(Loans));
    }

    [HttpGet]
    public IActionResult PlatformSettings()
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        var model = new PlatformSettingsViewModel
        {
            DistrictPricing = loanStore.GetDistrictPricingRows(),
            ShopCategories = loanStore.GetShopCategoriesAdmin(),
            SuccessMessage = TempData["CompanyMessage"] as string,
            ErrorMessage = TempData["CompanyError"] as string
        };
        ViewBag.PlatformSettings = model;
        return CompanyPage(nameof(PlatformSettings));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult UpdateDistrictPricing(DistrictPricingConfigInputModel input)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        if (!ModelState.IsValid)
        {
            TempData["CompanyError"] = string.Join(" ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
            return RedirectToAction(nameof(PlatformSettings));
        }
        try
        {
            loanStore.UpdateDistrictPricing(input);
            TempData["CompanyMessage"] = "জেলার মূল্য কনফিগারেশন আপডেট হয়েছে।";
        }
        catch (Exception ex)
        {
            TempData["CompanyError"] = ex.Message;
        }
        return RedirectToAction(nameof(PlatformSettings));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult AddDistrictPricing(DistrictPricingConfigCreateInputModel input)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        if (!ModelState.IsValid)
        {
            TempData["CompanyError"] = string.Join(" ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
            return RedirectToAction(nameof(PlatformSettings));
        }
        try
        {
            loanStore.AddDistrictPricing(input);
            TempData["CompanyMessage"] = $"{input.DistrictName} জেলার মূল্য কনফিগারেশন যোগ হয়েছে।";
        }
        catch (Exception ex)
        {
            TempData["CompanyError"] = ex.Message;
        }
        return RedirectToAction(nameof(PlatformSettings));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult UpdateShopCategory(ShopCategoryInputModel input)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        if (!ModelState.IsValid)
        {
            TempData["CompanyError"] = string.Join(" ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
            return RedirectToAction(nameof(PlatformSettings));
        }
        try
        {
            loanStore.UpdateShopCategory(input);
            TempData["CompanyMessage"] = "ক্যাটাগরি আপডেট হয়েছে।";
        }
        catch (Exception ex)
        {
            TempData["CompanyError"] = ex.Message;
        }
        return RedirectToAction(nameof(PlatformSettings));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult AddShopCategory(ShopCategoryCreateInputModel input)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        if (!ModelState.IsValid)
        {
            TempData["CompanyError"] = string.Join(" ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
            return RedirectToAction(nameof(PlatformSettings));
        }
        try
        {
            loanStore.AddShopCategory(input);
            TempData["CompanyMessage"] = $"{input.BanglaName} ক্যাটাগরি যোগ হয়েছে।";
        }
        catch (Exception ex)
        {
            TempData["CompanyError"] = ex.Message;
        }
        return RedirectToAction(nameof(PlatformSettings));
    }

    [HttpGet]
    public IActionResult Prices() => CompanyPage(nameof(Prices), includeShopsModel: true);

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult UpdateShopPrices(FieldOfficerShopPricingInputModel input)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        try
        {
            var selectedShopIds = input.ShopkeeperIds.Count > 0
                ? input.ShopkeeperIds.Where(id => id > 0).Distinct().ToArray()
                : input.ShopkeeperId > 0 ? [input.ShopkeeperId] : [];
            if (selectedShopIds.Length == 0)
            {
                throw new InvalidOperationException("কমপক্ষে একটি দোকানদার নির্বাচন করুন।");
            }

            var shops = store.GetShopkeepers()
                .Where(item => selectedShopIds.Contains(item.Id))
                .ToList();
            if (shops.Count != selectedShopIds.Length)
            {
                throw new InvalidOperationException("সঠিক দোকানদার নির্বাচন করুন।");
            }

            foreach (var shop in shops)
            {
                distributionStore.UpdateShopProductAssignments(
                    0,
                    shop.Id,
                    shop.ShopType,
                    input.SelectedProductIds,
                    input.ProductPrices);
            }
            TempData["CompanyMessage"] = $"{shops.Count} টি দোকানদারের পণ্যের ক্রয় ও বিক্রি মূল্য সফলভাবে আপডেট করা হয়েছে।";
        }
        catch (InvalidOperationException ex)
        {
            TempData["CompanyError"] = ex.Message;
        }
        return RedirectToAction(nameof(Prices));
    }

    [HttpGet]
    public IActionResult Delivery() => CompanyPage(nameof(Delivery));

    [HttpGet]
    public IActionResult Products() => CompanyPage(nameof(Products), includeDistribution: true);

    [HttpGet]
    public IActionResult ProductDistribution() =>
        IsCompany()
            ? CompanyPage(nameof(ProductDistribution), includeDistribution: true)
            : IsFieldOfficer()
                ? View(nameof(ProductDistribution), BuildProductDistributionPage())
                : RedirectToAction(nameof(Login));

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateDistributionProduct(CompanyDistributionProductInputModel input, [FromServices] IWebHostEnvironment env)
    {
        if (!IsCompanyOrFieldOfficer()) return RedirectToAction(nameof(Login));
        try
        {
            if (input.ImageFile is { Length: > 0 })
            {
                var uploads = Path.Combine(env.ContentRootPath, "uploads", "products");
                Directory.CreateDirectory(uploads);
                var filename = Guid.NewGuid().ToString() + Path.GetExtension(input.ImageFile.FileName);
                var filepath = Path.Combine(uploads, filename);
                using var stream = new FileStream(filepath, FileMode.Create);
                await input.ImageFile.CopyToAsync(stream);
                input.ImageUrl = $"/uploads/products/{filename}";
            }

            var code = distributionStore.CreateProduct(
                HttpContext.Session.GetInt32("UserId") ?? 0,
                input);
            TempData["CompanyMessage"] = $"Product {code} created and distributed to shop catalogs.";
            if (IsFieldOfficer()) TempData["CompanyMessage"] = $"Field force product {code} created and distributed to shop catalogs.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["CompanyError"] = ex.Message;
        }

        return IsFieldOfficer()
            ? Redirect("/FieldForce/ProductDistribution")
            : RedirectToAction(nameof(Products));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SaveProductAllocation(CompanyProductAllocationInputModel input, [FromServices] IWebHostEnvironment env)
    {
        if (!IsCompanyOrFieldOfficer()) return RedirectToAction(nameof(Login));
        try
        {
            if (input.ImageFile is { Length: > 0 })
            {
                var uploads = Path.Combine(env.ContentRootPath, "uploads", "products");
                Directory.CreateDirectory(uploads);
                var filename = Guid.NewGuid().ToString() + Path.GetExtension(input.ImageFile.FileName);
                var filepath = Path.Combine(uploads, filename);
                using var stream = new FileStream(filepath, FileMode.Create);
                await input.ImageFile.CopyToAsync(stream);
                input.ImageUrl = $"/uploads/products/{filename}";
            }

            distributionStore.UpdateProductAllocation(input);
            TempData["CompanyMessage"] = "Product percentage allocation updated.";
            if (IsFieldOfficer()) TempData["CompanyMessage"] = "Field force product percentage allocation updated.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["CompanyError"] = ex.Message;
        }

        return IsFieldOfficer()
            ? Redirect("/FieldForce/ProductDistribution")
            : RedirectToAction(nameof(ProductDistribution));
    }

    [HttpGet]
    public IActionResult Locations() => CompanyPage(nameof(Locations));

    [HttpGet]
    public IActionResult Reports() => CompanyPage(nameof(Reports));

    [HttpGet]
    public IActionResult Notifications() => CompanyPage(nameof(Notifications));

    [HttpGet]
    public IActionResult Users() => CompanyPage(nameof(Users), includeNetwork: true);

    [HttpGet]
    public IActionResult SupportAgents([FromServices] LiveSupportStore supportStore)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        ViewBag.SupportAgents = supportStore.GetSupportAgents();
        return CompanyPage(nameof(SupportAgents));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateSupportAgent(
        [FromForm] string name, 
        [FromForm] string phone, 
        [FromForm] string password,
        [FromForm] IFormFile? photo,
        [FromServices] LiveSupportStore supportStore,
        [FromServices] IWebHostEnvironment environment)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        name = name.Trim();
        phone = phone.Trim();
        if (name.Length is < 2 or > 150
            || !System.Text.RegularExpressions.Regex.IsMatch(phone, @"^01\d{9}$")
            || password.Length is < 6 or > 100)
        {
            TempData["SupportAgentError"] = "সঠিক নাম, ১১ সংখ্যার মোবাইল নম্বর এবং কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড দিন।";
            return RedirectToAction(nameof(SupportAgents));
        }

        if (supportStore.SupportAgentPhoneExists(phone))
        {
            TempData["SupportAgentError"] = "এই মোবাইল নম্বর দিয়ে ইতিমধ্যে একটি অ্যাকাউন্ট আছে।";
            return RedirectToAction(nameof(SupportAgents));
        }

        string? profilePicUrl = null;
        if (photo != null && photo.Length > 0)
        {
            var ext = Path.GetExtension(photo.FileName).ToLowerInvariant();
            if (photo.Length > 5 * 1024 * 1024 || ext is not (".jpg" or ".jpeg" or ".png" or ".webp"))
            {
                TempData["SupportAgentError"] = "প্রোফাইল ছবিটি JPG, PNG বা WEBP হতে হবে এবং সর্বোচ্চ ৫ MB হতে পারবে।";
                return RedirectToAction(nameof(SupportAgents));
            }
            var fileName = $"agent_{DateTime.UtcNow.Ticks}{ext}";
            var uploadDir = Path.Combine(environment.ContentRootPath, "uploads", "profiles");
            Directory.CreateDirectory(uploadDir);
            
            var filePath = Path.Combine(uploadDir, fileName);
            await using var stream = new FileStream(filePath, FileMode.Create);
            await photo.CopyToAsync(stream);
            
            profilePicUrl = $"/uploads/profiles/{fileName}";
        }

        supportStore.CreateSupportAgent(name, phone, password, profilePicUrl);

        TempData["SupportAgentSuccess"] = "সাপোর্ট এজেন্ট সফলভাবে তৈরি হয়েছে।";

        return RedirectToAction(nameof(SupportAgents));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SetSupportAgentStatus(
        [FromForm] int agentId,
        [FromForm] bool isActive,
        [FromServices] LiveSupportStore supportStore,
        [FromServices] IHubContext<LiveSupportHub> liveSupportHub)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        var updated = supportStore.SetSupportAgentActive(agentId, isActive);
        TempData[updated ? "SupportAgentSuccess" : "SupportAgentError"] = updated
            ? (isActive ? "সাপোর্ট এজেন্ট সক্রিয় করা হয়েছে।" : "সাপোর্ট এজেন্ট নিষ্ক্রিয় করা হয়েছে।")
            : "সাপোর্ট এজেন্ট পাওয়া যায়নি।";
        if (updated)
        {
            await liveSupportHub.Clients.Group("Agents").SendAsync("RefreshSessions");
        }
        return RedirectToAction(nameof(SupportAgents));
    }

    [HttpGet]
    public IActionResult Settings() => CompanyPage(nameof(Settings));

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult ChangePassword([FromBody] ChangePasswordInputModel? input)
    {
        if (!IsCompany())
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
            var userId = HttpContext.Session.GetInt32("UserId") ?? 0;
            var success = store.ChangePassword(userId, input.OldPassword.Trim(), input.NewPassword.Trim());
            return success
                ? Json(new { success = true, message = "পাসওয়ার্ড সফলভাবে পরিবর্তন করা হয়েছে।" })
                : BadRequest(new { success = false, message = "বর্তমান পাসওয়ার্ড সঠিক নয়।" });
        }
        catch
        {
            return BadRequest(new { success = false, message = "পাসওয়ার্ড পরিবর্তন করা যায়নি। আবার চেষ্টা করুন।" });
        }
    }

    [HttpGet]
    public IActionResult ServiceRequests() => CompanyPage(nameof(ServiceRequests), includeServiceRequests: true);

    [HttpGet]
    public IActionResult ActivationPayments() => CompanyPage(nameof(ActivationPayments), includeActivationPayments: true);

    [HttpGet]
    public IActionResult Bulletins() => CompanyPage(nameof(Bulletins), includeBulletins: true);

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult CreateCampaign(CompanyCampaignInputModel input)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        try
        {
            store.CreateCompanyCampaign(input);
            TempData["CompanyMessage"] = "Campaign created successfully.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["CompanyError"] = ex.Message;
        }
        return RedirectToAction(nameof(Campaigns));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult CreateBulletin(CompanyBulletinInputModel input)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        try
        {
            store.CreateCompanyBulletin(input);
            TempData["CompanyMessage"] = "Bulletin published successfully.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["CompanyError"] = ex.Message;
        }

        return RedirectToAction(nameof(Bulletins));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult SetBulletinActive(int bulletinId, bool isActive)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        store.SetCompanyBulletinActive(bulletinId, isActive);
        TempData["CompanyMessage"] = isActive ? "Bulletin activated." : "Bulletin deactivated.";
        return RedirectToAction(nameof(Bulletins));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult SaveSettings(CompanySettingsInputModel input)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        store.SaveCompanySettings(input);
        TempData["CompanyMessage"] = "Company settings updated.";
        return RedirectToAction(nameof(Settings));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult SetUserActive(int userId, bool isActive)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        store.SetCompanyUserActive(userId, isActive);
        TempData["CompanyMessage"] = isActive ? "User activated." : "User deactivated.";
        return RedirectToAction(nameof(Users));
    }

    [HttpGet]
    public IActionResult ExportReport()
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));
        deliveryStore.EnsureSchema();
        var model = store.GetCompanyDashboard(
            HttpContext.Session.GetString("UserName") ?? "Company",
            HttpContext.Session.GetString("UserPhone") ?? "");

        var csv = new StringBuilder();
        csv.AppendLine("Metric,Value");
        csv.AppendLine($"Total Sales,{model.TotalSalesAmount:0.00}");
        csv.AppendLine($"Today Sales,{model.TodaySalesAmount:0.00}");
        csv.AppendLine($"Month Sales,{model.MonthSalesAmount:0.00}");
        csv.AppendLine($"Orders,{model.TotalCustomerOrders}");
        csv.AppendLine($"Delivered Orders,{model.DeliveredCustomerOrders}");
        csv.AppendLine($"Shopkeepers,{model.TotalShopkeepers}");
        csv.AppendLine($"Customers,{model.TotalCustomers}");
        csv.AppendLine($"Delivery Men,{model.TotalDeliveryMen}");
        csv.AppendLine();
        csv.AppendLine("District,Shops,Customers,Sales");
        foreach (var district in model.Districts)
        {
            csv.AppendLine($"\"{district.DistrictName.Replace("\"", "\"\"")}\",{district.ShopkeeperCount},{district.CustomerCount},{district.SalesAmount:0.00}");
        }

        return File(
            Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(csv.ToString())).ToArray(),
            "text/csv",
            $"company-report-{DateTime.Today:yyyy-MM-dd}.csv");
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Logout()
    {
        HttpContext.Session.Clear();
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction("Index", "Home");
    }

    private IActionResult RedirectForRole(string? role) => role switch
    {
        Roles.Agent => RedirectToAction("Dashboard", "Agent"),
        Roles.FieldOfficer => Redirect("/FieldForce"),
        Roles.Shopkeeper => RedirectToAction("Dashboard", "Shopkeeper"),
        Roles.Customer => RedirectToAction("PlaceOrder", "Customer"),
        Roles.DeliveryMan => RedirectToAction("Dashboard", "Delivery"),
        Roles.SupportAgent => RedirectToAction("Dashboard", "Support"),
        _ => RedirectToAction(nameof(Dashboard))
    };

    private bool IsCompany() =>
        string.Equals(HttpContext.Session.GetString("UserRole"), Roles.Company, StringComparison.Ordinal);

    private bool IsFieldOfficer() =>
        string.Equals(HttpContext.Session.GetString("UserRole"), Roles.FieldOfficer, StringComparison.Ordinal);

    private bool IsCompanyOrFieldOfficer() => IsCompany() || IsFieldOfficer();

    private FieldOfficerShopsViewModel BuildCompanyShopsModel()
    {
        return new FieldOfficerShopsViewModel
        {
            OfficerName = HttpContext.Session.GetString("UserName") ?? "কোম্পানি পরিচালনা",
            Shops = store.GetShopkeepers(),
            Locations = store.GetLocationCatalog(),
            Products = distributionStore.GetProducts(0).Where(product => product.IsActive).ToList(),
            Assignments = distributionStore.GetShopProductAssignments(0)
        };
    }

    private CompanyDashboardViewModel BuildProductDistributionPage()
    {
        deliveryStore.EnsureSchema();
        return new CompanyDashboardViewModel
        {
            CompanyName = HttpContext.Session.GetString("UserName") ?? "Field Force",
            CompanyPhone = HttpContext.Session.GetString("UserPhone") ?? "",
            DistributionProducts = distributionStore.GetProducts(HttpContext.Session.GetInt32("UserId") ?? 0),
            Locations = store.GetLocationCatalog()
        };
    }

    [HttpGet]
    public async Task<IActionResult> ContactRequests(
        [FromServices] IContactRequestService contactRequestService,
        [FromQuery] string? status = null,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        ViewData["ActivePage"] = "ContactRequests";
        ViewData["PageTitle"] = "যোগাযোগ অনুরোধ ও ফোন নম্বর অনুমোদন";

        var requests = await contactRequestService.GetAllRequestsAsync(status, cancellationToken);
        var model = store.GetCompanyDashboard(
            HttpContext.Session.GetString("UserName") ?? "Company",
            HttpContext.Session.GetString("UserPhone") ?? "");

        ViewBag.ContactRequests = requests;
        ViewBag.SelectedStatus = status;

        return View("ContactRequests", model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ApproveContactRequest(
        int requestId,
        [FromServices] IContactRequestService contactRequestService,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        var adminPhone = HttpContext.Session.GetString("UserPhone") ?? "Admin";
        await contactRequestService.ReviewRequestAsync(requestId, true, adminPhone, null, cancellationToken);

        TempData["CompanyMessage"] = "যোগাযোগ অনুরোধ সফলভাবে অনুমোদন করা হয়েছে। আবেদনকারী এখন নম্বরটি দেখতে পারবেন।";
        return RedirectToAction(nameof(ContactRequests));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> RejectContactRequest(
        int requestId,
        string? reason,
        [FromServices] IContactRequestService contactRequestService,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        var adminPhone = HttpContext.Session.GetString("UserPhone") ?? "Admin";
        await contactRequestService.ReviewRequestAsync(requestId, false, adminPhone, reason, cancellationToken);

        TempData["CompanyMessage"] = "যোগাযোগ অনুরোধ বাতিল করা হয়েছে।";
        return RedirectToAction(nameof(ContactRequests));
    }

    [HttpGet]
    public async Task<IActionResult> TeachAndLearn(
        [FromServices] IVaratiaAdminService varatiaAdminService,
        [FromQuery] string? type = null,
        [FromQuery] string? verification = null,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        ViewData["ActivePage"] = "TeachAndLearn";
        ViewData["PageTitle"] = "টিচ অ্যান্ড লার্ন প্ল্যাটফর্ম পরিচালনা";

        var teachLearnData = await varatiaAdminService.GetTeachLearnDataAsync(
            type, verification, search, cancellationToken);
        var model = store.GetCompanyDashboard(
            HttpContext.Session.GetString("UserName") ?? "Company",
            HttpContext.Session.GetString("UserPhone") ?? "");

        ViewBag.TeachLearn = teachLearnData;
        return View("TeachAndLearn", model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleTutorVerification(
        string postId,
        [FromServices] IVaratiaAdminService varatiaAdminService,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        var success = await varatiaAdminService.ToggleTutorPostVerificationAsync(postId, cancellationToken);
        if (success)
        {
            TempData["CompanyMessage"] = $"পোস্ট #{postId}-এর ভেরিফিকেশন স্ট্যাটাস সফলভাবে পরিবর্তন করা হয়েছে।";
        }
        else
        {
            TempData["CompanyError"] = "ভেরিফিকেশন স্ট্যাটাস পরিবর্তন করা সম্ভব হয়নি।";
        }

        return RedirectToAction(nameof(TeachAndLearn));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteTutorPost(
        string postId,
        [FromServices] IVaratiaAdminService varatiaAdminService,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        var success = await varatiaAdminService.DeleteTutorPostAsync(postId, cancellationToken);
        if (success)
        {
            TempData["CompanyMessage"] = $"পোস্ট #{postId} সফলভাবে মুছে ফেলা হয়েছে।";
        }
        else
        {
            TempData["CompanyError"] = "পোস্টটি মুছে ফেলা সম্ভব হয়নি।";
        }

        return RedirectToAction(nameof(TeachAndLearn));
    }

    [HttpGet]
    public async Task<IActionResult> VaratiaManagement(
        [FromServices] IVaratiaAdminService varatiaAdminService,
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] string? tab = "tenants",
        [FromQuery] string? category = null,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        ViewData["ActivePage"] = "VaratiaManagement";
        ViewData["PageTitle"] = "ভাড়াটিয়া ও প্রোপার্টি পরিচালনা";

        var varatiaData = await varatiaAdminService.GetVaratiaManagementDataAsync(
            search, status, tab, category, cancellationToken);
        var model = store.GetCompanyDashboard(
            HttpContext.Session.GetString("UserName") ?? "Company",
            HttpContext.Session.GetString("UserPhone") ?? "");

        ViewBag.Varatia = varatiaData;
        return View("VaratiaManagement", model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateRegistrationFee(
        [FromServices] IVaratiaAdminService varatiaAdminService,
        [FromForm] decimal registrationFee,
        [FromForm] bool isRegistrationFeeActive,
        [FromQuery] string? returnUrl = null,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        await varatiaAdminService.UpdateRegistrationFeeAsync(
            registrationFee, isRegistrationFeeActive, cancellationToken);

        store.UpdateRegistrationFee(registrationFee, isRegistrationFeeActive);

        TempData["CompanyMessage"] = "ব্যবহারকারী রেজিস্ট্রেশন ফি সফলভাবে আপডেট করা হয়েছে।";

        if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
        {
            return Redirect(returnUrl);
        }

        return RedirectToAction(nameof(VaratiaManagement), new { tab = "settings" });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateSubscriptionPlan(
        [FromServices] ISubscriptionService subscriptionService,
        [FromForm] string serviceCode,
        [FromForm] string title,
        [FromForm] string description,
        [FromForm] decimal fee,
        [FromForm] int deliveryDays,
        [FromForm] bool isActive,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        await subscriptionService.UpdatePlanAsync(new OrderProcessAPI.Contracts.UpdateSubscriptionPlanRequest
        {
            ServiceCode = serviceCode,
            Title = title,
            Description = description,
            Fee = fee,
            DeliveryDays = deliveryDays,
            IsActive = isActive
        }, cancellationToken);

        TempData["CompanyMessage"] = $"সাবস্ক্রিপশন প্যাকেজ '{title}' সফলভাবে আপডেট করা হয়েছে।";
        return RedirectToAction(nameof(VaratiaManagement), new { tab = "subscriptions" });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateSubscriptionStatus(
        [FromServices] ISubscriptionService subscriptionService,
        [FromForm] int subscriptionId,
        [FromForm] string subscriptionStatus,
        [FromForm] string? adminNotes,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        await subscriptionService.UpdateSubscriptionStatusAsync(
            subscriptionId,
            subscriptionStatus,
            adminNotes,
            cancellationToken);

        TempData["CompanyMessage"] = "সাবস্ক্রিপশন ম্যাচমেকিং স্ট্যাটাস সফলভাবে আপডেট করা হয়েছে।";
        return RedirectToAction(nameof(VaratiaManagement), new { tab = "subscriptions" });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleGeneralPostStatus(
        [FromServices] IVaratiaAdminService varatiaAdminService,
        [FromForm] int postId,
        [FromQuery] string? returnUrl = null,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        var success = await varatiaAdminService.ToggleGeneralPostStatusAsync(postId, cancellationToken);
        TempData["CompanyMessage"] = success ? "বিজ্ঞাপনের স্ট্যাটাস সফলভাবে পরিবর্তন করা হয়েছে।" : "বিজ্ঞাপন আপডেট ব্যর্থ হয়েছে।";

        if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
        {
            return Redirect(returnUrl);
        }

        return RedirectToAction(nameof(VaratiaManagement), new { tab = "generalposts" });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleGeneralPostVerification(
        [FromServices] IVaratiaAdminService varatiaAdminService,
        [FromForm] int postId,
        [FromQuery] string? returnUrl = null,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        var success = await varatiaAdminService.ToggleGeneralPostVerificationAsync(postId, cancellationToken);
        TempData["CompanyMessage"] = success ? "বিজ্ঞাপনের ভেরিফিকেশন স্ট্যাটাস সফলভাবে পরিবর্তন করা হয়েছে।" : "ভেরিফিকেশন ব্যর্থ হয়েছে।";

        if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
        {
            return Redirect(returnUrl);
        }

        return RedirectToAction(nameof(VaratiaManagement), new { tab = "generalposts" });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteGeneralPost(
        [FromServices] IVaratiaAdminService varatiaAdminService,
        [FromForm] int postId,
        [FromQuery] string? returnUrl = null,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        var success = await varatiaAdminService.DeleteGeneralPostAsync(postId, cancellationToken);
        TempData["CompanyMessage"] = success ? "বিজ্ঞাপন সফলভাবে মুছে ফেলা হয়েছে।" : "বিজ্ঞাপন মুছতে ব্যর্থ হয়েছে।";

        if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
        {
            return Redirect(returnUrl);
        }

        return RedirectToAction(nameof(VaratiaManagement), new { tab = "generalposts" });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> GrantPostingCredits(
        [FromServices] IVaratiaAdminService varatiaAdminService,
        [FromForm] string userId,
        [FromForm] int credits,
        [FromQuery] string? returnUrl = null,
        CancellationToken cancellationToken = default)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        var success = await varatiaAdminService.GrantPostingCreditsAsync(userId, credits, cancellationToken);
        TempData["CompanyMessage"] = success ? $"ব্যবহারকারীকে {credits} টি পেইড বিজ্ঞাপন ক্রেডিট সফলভাবে যুক্ত করা হয়েছে।" : "ক্রেডিট প্রদান ব্যর্থ হয়েছে।";

        if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
        {
            return Redirect(returnUrl);
        }

        return RedirectToAction(nameof(VaratiaManagement), new { tab = "generalposts" });
    }

    private IActionResult CompanyPage(
        string viewName,
        bool includeServiceRequests = false,
        bool includeBulletins = false,
        bool includeNetwork = false,
        bool includeActivationPayments = false,
        bool includeDistribution = false,
        bool includeShopsModel = false)
    {
        if (!IsCompany()) return RedirectToAction(nameof(Login));

        deliveryStore.EnsureSchema();
        var model = store.GetCompanyDashboard(
            HttpContext.Session.GetString("UserName") ?? "Company",
            HttpContext.Session.GetString("UserPhone") ?? "");

        if (includeServiceRequests)
        {
            model = model with { ServiceRequests = serviceRequestStore.GetRecent() };
        }
        if (includeBulletins)
        {
            model = model with { Bulletins = store.GetCompanyBulletins() };
        }
        if (includeNetwork)
        {
            model = model with { Network = store.GetCompanyNetwork() };
        }
        if (includeActivationPayments)
        {
            model = model with { ShopkeeperPayments = activationStore.GetCompanyPayments() };
        }
        if (includeDistribution)
        {
            model = model with
            {
                DistributionProducts = distributionStore.GetProducts(
                    HttpContext.Session.GetInt32("UserId") ?? 0),
                Locations = store.GetLocationCatalog()
            };
        }
        if (includeShopsModel)
        {
            model = model with { ShopsModel = BuildCompanyShopsModel() };
        }

        return View(viewName, model);
    }
}
