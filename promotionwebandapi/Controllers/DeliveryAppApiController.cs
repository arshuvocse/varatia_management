using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Models;
using PromotionWeb.Services;
using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Controllers;

[ApiController]
[Route("api/delivery-app")]
public sealed class DeliveryAppApiController(
    AppStore appStore,
    DeliveryStore deliveryStore,
    DeliveryApiTokenStore tokenStore,
    IWebHostEnvironment environment) : ControllerBase
{
    [HttpPost("login")]
    public IActionResult Login([FromBody] DeliveryAppLoginRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new { success = false, message = "Phone and password are required." });
        }

        var user = appStore.ValidateUser(request.Phone.Trim(), request.Password);
        if (user is null || user.Role != Roles.DeliveryMan)
        {
            return Unauthorized(new { success = false, message = "Invalid delivery login." });
        }

        var deliveryMan = deliveryStore.GetByUserId(user.Id);
        if (deliveryMan is null)
        {
            return Unauthorized(new { success = false, message = "Delivery profile was not found." });
        }

        var token = tokenStore.Create(user.Id, user.Name, user.Phone, user.Role);
        return Ok(new
        {
            success = true,
            token,
            user = ToDeliveryManDto(deliveryMan)
        });
    }

    [HttpPost("logout")]
    public IActionResult Logout()
    {
        tokenStore.Revoke(Request.Headers.Authorization);
        return Ok(new { success = true });
    }

    [HttpGet("me")]
    public IActionResult Me()
    {
        var session = GetSession();
        if (session is null) return UnauthorizedResponse();

        var deliveryMan = deliveryStore.GetByUserId(session.UserId);
        return deliveryMan is null
            ? UnauthorizedResponse()
            : Ok(new { success = true, user = ToDeliveryManDto(deliveryMan) });
    }

    [HttpGet("orders")]
    public IActionResult Orders()
    {
        var session = GetSession();
        if (session is null) return UnauthorizedResponse();

        var deliveryMan = deliveryStore.GetByUserId(session.UserId);
        var assignments = deliveryStore.GetAssignmentsForDeliveryMan(session.UserId);
        return Ok(new
        {
            success = true,
            deliveryMan = deliveryMan is null ? null : ToDeliveryManDto(deliveryMan),
            assignments = assignments.Select(ToAssignmentDto)
        });
    }

    [HttpPost("availability")]
    public IActionResult Availability([FromBody] DeliveryAvailabilityRequest request)
    {
        var session = GetSession();
        if (session is null) return UnauthorizedResponse();

        try
        {
            deliveryStore.UpdateAvailability(session.UserId, request.Availability);
            return Ok(new { success = true, message = "Availability updated." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    [HttpPost("orders/{assignmentId:int}/status")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UpdateStatus(int assignmentId, [FromForm] DeliveryAppStatusRequest request)
    {
        var session = GetSession();
        if (session is null) return UnauthorizedResponse();

        try
        {
            var proof = await SaveFile(request.ProofPhoto, "proof");
            var signature = await SaveFile(request.CustomerSignature, "signature");
            deliveryStore.UpdateStatus(session.UserId, assignmentId, new DeliveryStatusUpdateInput
            {
                Status = request.Status,
                Otp = request.Otp,
                CashCollectedAmount = request.CashCollectedAmount,
                DeliveryNote = request.DeliveryNote,
                Latitude = request.Latitude,
                Longitude = request.Longitude
            }, proof, signature);

            return Ok(new { success = true, message = $"Order status updated to {request.Status}." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    [HttpPost("location")]
    public IActionResult UpdateLocation([FromBody] DeliveryAppLocationRequest request)
    {
        var session = GetSession();
        if (session is null) return UnauthorizedResponse();
        if (!ModelState.IsValid)
        {
            return BadRequest(new { success = false, message = "Valid latitude and longitude are required." });
        }

        try
        {
            deliveryStore.UpdateLiveLocation(session.UserId, request.Latitude!.Value, request.Longitude!.Value, request.AssignmentId);
            return Ok(new { success = true, intervalSeconds = 60, message = "Location updated." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    [HttpGet("nearby")]
    public IActionResult Nearby([FromQuery] decimal latitude, [FromQuery] decimal longitude,
        [FromQuery] decimal radiusKm = 5, [FromQuery] int limit = 20)
    {
        var session = GetSession();
        if (session is null) return UnauthorizedResponse();
        if (latitude is < -90 or > 90 || longitude is < -180 or > 180)
        {
            return BadRequest(new { success = false, message = "Valid latitude and longitude are required." });
        }

        try
        {
            var nearby = deliveryStore.GetNearbyDeliveryMenForDeliveryMan(session.UserId, latitude, longitude, radiusKm, limit);
            return Ok(new
            {
                success = true,
                radiusKm,
                deliveryMen = nearby.Select(ToNearbyDeliveryManDto)
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    private DeliveryApiSession? GetSession() => tokenStore.Get(Request.Headers.Authorization);

    private UnauthorizedObjectResult UnauthorizedResponse() =>
        Unauthorized(new { success = false, message = "Login expired. Please login again." });

    private static object ToDeliveryManDto(DeliveryMan deliveryMan) => new
    {
        deliveryMan.Id,
        deliveryMan.UserId,
        deliveryMan.Name,
        deliveryMan.Phone,
        deliveryMan.Address,
        deliveryMan.DivisionName,
        deliveryMan.DistrictName,
        deliveryMan.ThanaName,
        deliveryMan.Latitude,
        deliveryMan.Longitude,
        deliveryMan.LastLatitude,
        deliveryMan.LastLongitude,
        deliveryMan.LastLocationAt,
        deliveryMan.VehicleType,
        deliveryMan.VehicleNumber,
        deliveryMan.Availability,
        deliveryMan.IsActive,
        deliveryMan.ProfilePhotoUrl
    };

    private static object ToNearbyDeliveryManDto(NearbyDeliveryMan item)
    {
        var deliveryMan = item.DeliveryMan;
        return new
        {
            deliveryMan.Id,
            deliveryMan.UserId,
            deliveryMan.Name,
            deliveryMan.Phone,
            deliveryMan.DistrictName,
            deliveryMan.ThanaName,
            deliveryMan.LastLatitude,
            deliveryMan.LastLongitude,
            deliveryMan.LastLocationAt,
            deliveryMan.Availability,
            deliveryMan.IsActive,
            DistanceKm = item.DistanceKm
        };
    }

    private static object ToAssignmentDto(DeliveryAssignment assignment) => new
    {
        assignment.AssignmentId,
        assignment.OrderId,
        assignment.CustomerName,
        assignment.CustomerPhone,
        assignment.CustomerLatitude,
        assignment.CustomerLongitude,
        assignment.ShopName,
        assignment.ShopPhone,
        assignment.CollectionAmount,
        assignment.Status,
        assignment.DeliveryOtp,
        assignment.DeliveryNote,
        assignment.CashCollectedAmount,
        assignment.CurrentLatitude,
        assignment.CurrentLongitude,
        assignment.AssignedAt,
        assignment.DeliveredAt,
        Details = assignment.Details.Select(item => new
        {
            item.ProductName,
            item.Sku,
            item.Quantity,
            item.UnitPrice,
            item.TotalPrice
        })
    };

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

public sealed class DeliveryAvailabilityRequest
{
    [Required]
    public string Availability { get; set; } = "";
}
