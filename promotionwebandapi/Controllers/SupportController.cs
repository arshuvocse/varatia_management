using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

public sealed class SupportController(LiveSupportStore store, IWebHostEnvironment environment) : Controller
{
    [HttpGet]
    public IActionResult Dashboard()
    {
        var role = HttpContext.Session.GetString("UserRole");
        if (role != Roles.Agent && role != Roles.Company && role != Roles.SupportAgent)
        {
            return RedirectToAction("Login", "Account");
        }
        
        var userId = HttpContext.Session.GetInt32("UserId");
        if (userId.HasValue)
        {
            var agent = store.GetAgentInfo(userId.Value);
            if (role == Roles.SupportAgent && agent?.IsActive != true)
            {
                return RedirectToAction("Logout", "Account");
            }
            ViewBag.ProfilePictureUrl = agent?.ProfilePictureUrl;
            ViewBag.AgentName = agent?.Name;
            ViewBag.AgentId = userId.Value;
        }

        return View();
    }
    
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UploadProfilePicture(IFormFile? photo)
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (userId == null) return Unauthorized();
        
        var role = HttpContext.Session.GetString("UserRole");
        if (role != Roles.Agent && role != Roles.Company && role != Roles.SupportAgent) return Forbid();

        if (photo == null || photo.Length == 0)
        {
            return BadRequest("No photo uploaded.");
        }

        if (photo.Length > 5 * 1024 * 1024)
        {
            return BadRequest("Photo must not exceed 5 MB.");
        }
        
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        var ext = Path.GetExtension(photo.FileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(ext))
        {
            return BadRequest("Invalid photo format.");
        }
        
        var fileName = $"agent_{userId}_{DateTime.UtcNow.Ticks}{ext}";
        var uploadDir = Path.Combine(environment.ContentRootPath, "uploads", "profiles");
        Directory.CreateDirectory(uploadDir);
        
        var filePath = Path.Combine(uploadDir, fileName);
        await using var stream = new FileStream(filePath, FileMode.Create);
        await photo.CopyToAsync(stream);
        
        var url = $"/uploads/profiles/{fileName}";
        store.UpdateProfilePicture(userId.Value, url);
        
        return Ok(new { url });
    }
}
