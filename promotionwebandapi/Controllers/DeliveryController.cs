using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

public sealed class DeliveryController(
    DeliveryStore deliveryStore,
    AppStore appStore,
    IWebHostEnvironment environment) : Controller
{
    [HttpGet]
    public IActionResult Dashboard() => DeliveryView("Dashboard");

    [HttpGet]
    public IActionResult Orders() => DeliveryView("Orders");

    [HttpGet]
    public IActionResult History() => DeliveryView("History");

    [HttpGet]
    public IActionResult Profile() => DeliveryView("Profile");

    [HttpGet]
    public IActionResult ChangePassword() => DeliveryView("ChangePassword");

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult SetAvailability(string availability)
    {
        var userId = GetDeliveryUserId();
        if (userId is null) return RedirectToAction("Login", "Account");
        try
        {
            deliveryStore.UpdateAvailability(userId.Value, availability);
            TempData["DeliverySuccess"] = "Availability updated.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["DeliveryError"] = ex.Message;
        }
        return RedirectToAction(nameof(Dashboard));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UpdateStatus(int assignmentId, DeliveryStatusUpdateInput input)
    {
        var userId = GetDeliveryUserId();
        if (userId is null) return RedirectToAction("Login", "Account");
        try
        {
            var proof = await SaveFile(input.ProofPhoto, "proof");
            var signature = await SaveFile(input.CustomerSignature, "signature");
            deliveryStore.UpdateStatus(userId.Value, assignmentId, input, proof, signature);
            TempData["DeliverySuccess"] = $"Order status updated to {input.Status}.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["DeliveryError"] = ex.Message;
        }
        return RedirectToAction(nameof(Orders));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult UpdateLocation(decimal latitude, decimal longitude, int? assignmentId)
    {
        var userId = GetDeliveryUserId();
        if (userId is null) return Unauthorized(new { success = false, message = "Login expired." });
        if (latitude is < -90 or > 90 || longitude is < -180 or > 180)
        {
            return BadRequest(new { success = false, message = "Valid latitude and longitude are required." });
        }

        try
        {
            deliveryStore.UpdateLiveLocation(userId.Value, latitude, longitude, assignmentId);
            return Json(new { success = true, message = "Location updated." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(20 * 1024 * 1024)]
    public async Task<IActionResult> UpdateProfile(DeliveryProfileUpdateInput input)
    {
        var userId = GetDeliveryUserId();
        if (userId is null) return RedirectToAction("Login", "Account");
        if (!ModelState.IsValid)
        {
            TempData["DeliveryError"] = string.Join(" ", ModelState.Values.SelectMany(x => x.Errors).Select(x => x.ErrorMessage));
            return RedirectToAction(nameof(Profile));
        }
        try
        {
            var profile = await SaveFile(input.ProfilePhoto, "profile");
            var nidFront = await SaveFile(input.NidFrontPhoto, "nid-front");
            var nidBack = await SaveFile(input.NidBackPhoto, "nid-back");
            var license = await SaveFile(input.DrivingLicensePhoto, "license");
            deliveryStore.UpdateProfile(userId.Value, input, profile, nidFront, nidBack, license);
            HttpContext.Session.SetString("UserName", input.Name.Trim());
            TempData["DeliverySuccess"] = "Profile updated.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["DeliveryError"] = ex.Message;
        }
        return RedirectToAction(nameof(Profile));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult ChangePassword(ChangePasswordInputModel input)
    {
        var userId = GetDeliveryUserId();
        if (userId is null) return RedirectToAction("Login", "Account");
        if (!ModelState.IsValid)
        {
            TempData["DeliveryError"] = "Check the password fields and try again.";
        }
        else if (!appStore.ChangePassword(userId.Value, input.OldPassword.Trim(), input.NewPassword.Trim()))
        {
            TempData["DeliveryError"] = "Current password is incorrect.";
        }
        else
        {
            TempData["DeliverySuccess"] = "Password changed successfully.";
        }
        return RedirectToAction(nameof(ChangePassword));
    }

    private IActionResult DeliveryView(string viewName)
    {
        var userId = GetDeliveryUserId();
        if (userId is null) return RedirectToAction("Login", "Account");
        var deliveryMan = deliveryStore.GetByUserId(userId.Value);
        if (deliveryMan is null) return RedirectToAction("Login", "Account");
        var model = new DeliveryDashboardViewModel
        {
            DeliveryMan = deliveryMan,
            Assignments = deliveryStore.GetAssignmentsForDeliveryMan(userId.Value)
        };
        return View(viewName, model);
    }

    private int? GetDeliveryUserId() =>
        HttpContext.Session.GetString("UserRole") == Roles.DeliveryMan
            ? HttpContext.Session.GetInt32("UserId")
            : null;

    private async Task<string?> SaveFile(IFormFile? file, string category)
    {
        if (file is null || file.Length == 0) return null;
        if (file.Length > 4 * 1024 * 1024) throw new InvalidOperationException("Each image must be 4 MB or smaller.");
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (extension is not (".jpg" or ".jpeg" or ".png" or ".webp"))
            throw new InvalidOperationException("Only JPG, PNG and WebP images are allowed.");
        var folder = Path.Combine(environment.ContentRootPath, "uploads", "delivery", category);
        Directory.CreateDirectory(folder);
        var fileName = $"{Guid.NewGuid():N}{extension}";
        await using var stream = System.IO.File.Create(Path.Combine(folder, fileName));
        await file.CopyToAsync(stream);
        return $"/uploads/delivery/{category}/{fileName}";
    }
}
