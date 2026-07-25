using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using PromotionWeb.Hubs;
using PromotionWeb.Models;
using PromotionWeb.Services;
using System.Security.Claims;
using System.Text;

namespace PromotionWeb.Controllers;

public sealed class AccountController(
    AppStore store,
    ServiceRequestStore serviceRequestStore,
    DeliveryStore deliveryStore,
    ShopkeeperActivationStore activationStore,
    ProductDistributionStore distributionStore,
    ShopkeeperRequestStore requestStore) : Controller
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

    private IActionResult CompanyPage(
        string viewName,
        bool includeServiceRequests = false,
        bool includeBulletins = false,
        bool includeNetwork = false,
        bool includeActivationPayments = false,
        bool includeDistribution = false)
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

        return View(viewName, model);
    }
}
