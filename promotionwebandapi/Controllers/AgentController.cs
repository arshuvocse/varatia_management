using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

public sealed class AgentController(
    AppStore store,
    DeliveryStore deliveryStore,
    ServiceRequestStore serviceRequestStore,
    LoanStore loanStore,
    IWebHostEnvironment environment) : Controller
{
    [HttpGet]
    public IActionResult Index() => RedirectToAction(nameof(Dashboard));

    [HttpGet]
    public IActionResult Dashboard() => AgentView("Dashboard");

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult UpdateOfficeLocation(
        string officeName,
        string officeAddress,
        string? roadNo,
        string? areaName,
        string? thana,
        string? contactPhone,
        string? officeHours,
        decimal? latitude,
        decimal? longitude)
    {
        var agentUserId = GetAgentUserId();
        if (agentUserId is null) return LoginRedirect();

        if (string.IsNullOrWhiteSpace(officeName) || string.IsNullOrWhiteSpace(officeAddress))
        {
            TempData["AgentError"] = "অফিসের নাম এবং ঠিকানা দেওয়া আবশ্যক।";
            return RedirectToAction(nameof(Profile));
        }

        try
        {
            loanStore.UpdateAgentOffice(agentUserId.Value, officeName, officeAddress, roadNo, areaName, thana, contactPhone, officeHours, latitude, longitude);
            TempData["AgentSuccess"] = "অফিসের বিস্তারিত ঠিকানা ও লোকেশন সফলভাবে আপডেট হয়েছে।";
        }
        catch (Exception ex)
        {
            TempData["AgentError"] = ex.Message;
        }

        return RedirectToAction(nameof(Profile));
    }

    [HttpGet]
    public IActionResult FieldForce() => AgentView("FieldForce");

    [HttpGet]
    public IActionResult Shopkeepers() => AgentView("Shopkeepers");

    [HttpGet]
    public IActionResult DeliveryTeam() => AgentView("DeliveryTeam");

    [HttpGet]
    public IActionResult LiveTracking() => AgentView("LiveTracking");

    [HttpGet]
    public IActionResult Orders() => AgentView("Orders");

    [HttpGet]
    public IActionResult ServiceRequests() => AgentView("ServiceRequests");

    [HttpGet]
    public IActionResult Reports() => AgentView("Reports");

    [HttpGet]
    public IActionResult Profile() => AgentView("Profile");

    [HttpPost]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(20 * 1024 * 1024)]
    public async Task<IActionResult> RegisterFieldOfficer([Bind(Prefix = "FieldOfficerRegistration")] FieldOfficerRegistrationInput input)
    {
        var agentUserId = GetAgentUserId();
        if (agentUserId is null) return LoginRedirect();
        if (!ModelState.IsValid)
        {
            SetValidationError();
            return RedirectToAction(nameof(FieldForce));
        }

        try
        {
            string? profilePhotoUrl = null;
            if (input.ProfilePhoto is { Length: > 0 })
            {
                var uploads = Path.Combine(environment.ContentRootPath, "wwwroot", "uploads", "profiles");
                Directory.CreateDirectory(uploads);
                var filename = Guid.NewGuid().ToString() + Path.GetExtension(input.ProfilePhoto.FileName);
                var filepath = Path.Combine(uploads, filename);
                using var stream = new FileStream(filepath, FileMode.Create);
                await input.ProfilePhoto.CopyToAsync(stream);
                profilePhotoUrl = $"/uploads/profiles/{filename}";
            }

            store.RegisterFieldOfficer(agentUserId.Value, input, profilePhotoUrl);
            TempData["AgentSuccess"] = $"{input.Name} has been registered as field force.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["AgentError"] = ex.Message;
        }
        return RedirectToAction(nameof(FieldForce));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(20 * 1024 * 1024)]
    public async Task<IActionResult> UpdateProfilePicture(IFormFile profilePicture)
    {
        var agentUserId = GetAgentUserId();
        if (agentUserId is null) return LoginRedirect();

        if (profilePicture is { Length: > 0 })
        {
            var uploads = Path.Combine(environment.ContentRootPath, "wwwroot", "uploads", "profiles");
            Directory.CreateDirectory(uploads);
            var filename = Guid.NewGuid().ToString() + Path.GetExtension(profilePicture.FileName);
            var filepath = Path.Combine(uploads, filename);
            using var stream = new FileStream(filepath, FileMode.Create);
            await profilePicture.CopyToAsync(stream);
            var photoPath = $"/uploads/profiles/{filename}";
            
            store.UpdateUserProfilePicture(agentUserId.Value, photoPath);
            TempData["AgentSuccess"] = "প্রোফাইল ছবি সফলভাবে আপডেট হয়েছে।";
        }
        else
        {
            TempData["AgentError"] = "অনুগ্রহ করে একটি ছবি নির্বাচন করুন।";
        }
        
        return RedirectToAction(nameof(Profile));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult SetFieldOfficerActive(int fieldOfficerUserId, bool isActive)
    {
        var agentUserId = GetAgentUserId();
        if (agentUserId is null) return LoginRedirect();
        if (store.SetFieldOfficerActive(agentUserId.Value, fieldOfficerUserId, isActive))
            TempData["AgentSuccess"] = isActive ? "Field force account activated." : "Field force account deactivated.";
        else
            TempData["AgentError"] = "The field force account was not found.";
        return RedirectToAction(nameof(FieldForce));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(20 * 1024 * 1024)]
    public async Task<IActionResult> RegisterDeliveryMan([Bind(Prefix = "DeliveryRegistration")] DeliveryManRegistrationInput input)
    {
        var agentUserId = GetAgentUserId();
        if (agentUserId is null) return LoginRedirect();
        if (!ModelState.IsValid)
        {
            SetValidationError();
            return RedirectToAction(nameof(DeliveryTeam));
        }

        var savedFiles = new List<string>();
        var registered = false;
        try
        {
            var profile = await SaveDeliveryFile(input.ProfilePhoto, "profile");
            AddSavedFile(savedFiles, profile);
            var nidFront = await SaveDeliveryFile(input.NidFrontPhoto, "nid-front");
            AddSavedFile(savedFiles, nidFront);
            var nidBack = await SaveDeliveryFile(input.NidBackPhoto, "nid-back");
            AddSavedFile(savedFiles, nidBack);
            var license = await SaveDeliveryFile(input.DrivingLicensePhoto, "license");
            AddSavedFile(savedFiles, license);
            deliveryStore.RegisterByAgent(agentUserId.Value, input, profile, nidFront, nidBack, license);
            registered = true;
            TempData["AgentSuccess"] = $"{input.Name} has been registered as a delivery man.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["AgentError"] = ex.Message;
        }
        finally
        {
            if (!registered) DeleteDeliveryFiles(savedFiles);
        }
        return RedirectToAction(nameof(DeliveryTeam));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult SetDeliveryManActive(int deliveryManId, bool isActive)
    {
        var agentUserId = GetAgentUserId();
        if (agentUserId is null) return LoginRedirect();
        if (deliveryStore.SetActiveByAgent(agentUserId.Value, deliveryManId, isActive))
            TempData["AgentSuccess"] = isActive ? "Delivery man activated." : "Delivery man deactivated.";
        else
            TempData["AgentError"] = "The delivery man was not found.";
        return RedirectToAction(nameof(DeliveryTeam));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult UpdateServiceRequestStatus(int requestId, string status)
    {
        var agentUserId = GetAgentUserId();
        if (agentUserId is null) return LoginRedirect();
        var district = store.GetAgentDistrict(agentUserId.Value);
        if (district is null)
        {
            TempData["AgentError"] = "Assign a district before managing service requests.";
        }
        else
        {
            try
            {
                serviceRequestStore.UpdateStatusForDistrict(requestId, district.DistrictName, status);
                TempData["AgentSuccess"] = "Service request status updated.";
            }
            catch (InvalidOperationException ex)
            {
                TempData["AgentError"] = ex.Message;
            }
        }
        return RedirectToAction(nameof(ServiceRequests));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult UpdateProfile(string name)
    {
        var agentUserId = GetAgentUserId();
        if (agentUserId is null) return LoginRedirect();
        if (string.IsNullOrWhiteSpace(name) || name.Trim().Length > 150)
        {
            TempData["AgentError"] = "Enter a valid name.";
        }
        else
        {
            if (store.UpdateAgentProfile(agentUserId.Value, name))
            {
                HttpContext.Session.SetString("UserName", name.Trim());
                TempData["AgentSuccess"] = "Profile updated.";
            }
            else
            {
                TempData["AgentError"] = "The agent account was not found.";
            }
        }
        return RedirectToAction(nameof(Profile));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult AssignDistrict(int districtId)
    {
        var agentUserId = GetAgentUserId();
        if (agentUserId is null) return LoginRedirect();
        if (districtId <= 0)
        {
            TempData["AgentError"] = "Select a valid district.";
            return RedirectToAction(nameof(Profile));
        }

        try
        {
            store.AssignAgentDistrict(agentUserId.Value, districtId);
            TempData["AgentSuccess"] = "District assigned successfully.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["AgentError"] = ex.Message;
        }
        return RedirectToAction(nameof(Profile));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult ChangePassword([Bind(Prefix = "Password")] ChangePasswordInputModel input)
    {
        var agentUserId = GetAgentUserId();
        if (agentUserId is null) return LoginRedirect();
        if (!ModelState.IsValid)
        {
            TempData["AgentError"] = "Check the password fields and try again.";
        }
        else if (!store.ChangePassword(agentUserId.Value, input.OldPassword.Trim(), input.NewPassword.Trim()))
        {
            TempData["AgentError"] = "Current password is incorrect.";
        }
        else
        {
            TempData["AgentSuccess"] = "Password changed successfully.";
        }
        return RedirectToAction(nameof(Profile));
    }

    private IActionResult AgentView(string viewName)
    {
        var agentUserId = GetAgentUserId();
        return agentUserId is null ? LoginRedirect() : View(viewName, BuildPortal(agentUserId.Value));
    }

    private AgentDashboardViewModel BuildPortal(int agentUserId)
    {
        var district = store.GetAgentDistrict(agentUserId);
        var user = store.GetUserById(agentUserId);
        return new AgentDashboardViewModel
        {
            AgentName = user?.Name ?? HttpContext.Session.GetString("UserName") ?? "Agent",
            AgentPhone = user?.Phone ?? HttpContext.Session.GetString("UserPhone") ?? "",
            ProfilePictureUrl = user?.ProfilePictureUrl,
            District = district,
            Locations = store.GetLocationCatalog(),
            FieldOfficers = store.GetFieldOfficersByAgent(agentUserId),
            Shops = store.GetShopkeepersByAgent(agentUserId),
            DeliveryMen = deliveryStore.GetByAgent(agentUserId),
            Assignments = deliveryStore.GetAssignmentsForAgent(agentUserId),
            ServiceRequests = district is null ? [] : serviceRequestStore.GetForDistrict(district.DistrictName)
        };
    }

    private int? GetAgentUserId() =>
        HttpContext.Session.GetString("UserRole") == Roles.Agent
            ? HttpContext.Session.GetInt32("UserId")
            : null;

    private RedirectToActionResult LoginRedirect() => RedirectToAction("Login", "Account");

    private void SetValidationError() =>
        TempData["AgentError"] = string.Join(" ", ModelState.Values.SelectMany(x => x.Errors).Select(x => x.ErrorMessage));

    private async Task<string?> SaveDeliveryFile(IFormFile? file, string category)
    {
        if (file is null || file.Length == 0) return null;
        if (file.Length > 4 * 1024 * 1024) throw new InvalidOperationException("Each image must be 4 MB or smaller.");
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (extension is not (".jpg" or ".jpeg" or ".png" or ".webp"))
            throw new InvalidOperationException("Only JPG, PNG and WebP images are allowed.");
        var folder = Path.Combine(environment.ContentRootPath, "uploads", "delivery", category);
        Directory.CreateDirectory(folder);
        var fileName = $"{Guid.NewGuid():N}{extension}";
        var filePath = Path.Combine(folder, fileName);
        try
        {
            await using var stream = System.IO.File.Create(filePath);
            await file.CopyToAsync(stream);
        }
        catch
        {
            if (System.IO.File.Exists(filePath)) System.IO.File.Delete(filePath);
            throw;
        }
        return $"/uploads/delivery/{category}/{fileName}";
    }

    private static void AddSavedFile(ICollection<string> files, string? path)
    {
        if (!string.IsNullOrWhiteSpace(path)) files.Add(path);
    }

    private void DeleteDeliveryFiles(IEnumerable<string> paths)
    {
        foreach (var path in paths)
        {
            var relativePath = path.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
            var fullPath = Path.GetFullPath(Path.Combine(environment.ContentRootPath, relativePath));
            var deliveryRoot = Path.GetFullPath(Path.Combine(environment.ContentRootPath, "uploads", "delivery"));
            if (fullPath.StartsWith(deliveryRoot + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase)
                && System.IO.File.Exists(fullPath))
                System.IO.File.Delete(fullPath);
        }
    }
}
