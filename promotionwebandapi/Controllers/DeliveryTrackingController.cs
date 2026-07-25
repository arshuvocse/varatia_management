using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

[Route("delivery-tracking")]
public sealed class DeliveryTrackingController(AppStore appStore, DeliveryStore deliveryStore) : Controller
{
    [HttpGet("shopkeeper/delivery-men")]
    public IActionResult ShopkeeperDeliveryMen()
    {
        var shop = GetCurrentShop();
        if (shop is null) return Unauthorized(new { success = false, message = "Login expired." });

        return Json(new
        {
            success = true,
            deliveryMen = deliveryStore.GetAvailableForShopkeeperDistrict(shop.Id).Select(ToDeliveryManDto)
        });
    }

    [HttpGet("agent/delivery-men")]
    public IActionResult AgentDeliveryMen()
    {
        var agentUserId = HttpContext.Session.GetInt32("UserId");
        if (HttpContext.Session.GetString("UserRole") != Roles.Agent || agentUserId is null)
        {
            return Unauthorized(new { success = false, message = "Login expired." });
        }

        return Json(new
        {
            success = true,
            deliveryMen = deliveryStore.GetByAgent(agentUserId.Value).Select(ToDeliveryManDto)
        });
    }

    [HttpGet("orders/{orderId:int}")]
    public IActionResult Order(int orderId)
    {
        var role = HttpContext.Session.GetString("UserRole");
        var userId = HttpContext.Session.GetInt32("UserId");
        DeliveryAssignment? assignment = null;

        if (role == Roles.Shopkeeper)
        {
            var shop = GetCurrentShop();
            if (shop is null) return Unauthorized(new { success = false, message = "Login expired." });
            assignment = deliveryStore.GetAssignmentsForShopkeeper(shop.Id).FirstOrDefault(x => x.OrderId == orderId);
        }
        else if (role == Roles.Customer && userId is not null)
        {
            assignment = deliveryStore.GetAssignmentsForCustomer(userId.Value).FirstOrDefault(x => x.OrderId == orderId);
        }
        else if (role == Roles.DeliveryMan && userId is not null)
        {
            assignment = deliveryStore.GetAssignmentsForDeliveryMan(userId.Value).FirstOrDefault(x => x.OrderId == orderId);
        }
        else
        {
            return Unauthorized(new { success = false, message = "Login expired." });
        }

        return assignment is null
            ? NotFound(new { success = false, message = "Active delivery assignment was not found." })
            : Json(new { success = true, assignment = ToAssignmentDto(assignment) });
    }

    private Shopkeeper? GetCurrentShop()
    {
        if (HttpContext.Session.GetString("UserRole") != Roles.Shopkeeper) return null;
        return appStore.GetShopkeeperByPhone(HttpContext.Session.GetString("UserPhone") ?? "");
    }

    private static object ToDeliveryManDto(DeliveryMan person) => new
    {
        person.Id,
        person.Name,
        person.Phone,
        person.Availability,
        person.IsActive,
        Latitude = person.LastLatitude ?? person.Latitude,
        Longitude = person.LastLongitude ?? person.Longitude,
        person.LastLatitude,
        person.LastLongitude,
        person.LastLocationAt,
        person.VehicleType,
        person.VehicleNumber,
        person.ShopName,
        person.DistrictName,
        person.ThanaName
    };

    private static object ToAssignmentDto(DeliveryAssignment assignment) => new
    {
        assignment.AssignmentId,
        assignment.OrderId,
        assignment.Status,
        assignment.DeliveryManName,
        assignment.DeliveryManPhone,
        assignment.CustomerName,
        assignment.CustomerPhone,
        assignment.CustomerLatitude,
        assignment.CustomerLongitude,
        assignment.ShopName,
        DeliveryLatitude = assignment.CurrentLatitude,
        DeliveryLongitude = assignment.CurrentLongitude,
        assignment.AssignedAt,
        assignment.DeliveredAt
    };
}
