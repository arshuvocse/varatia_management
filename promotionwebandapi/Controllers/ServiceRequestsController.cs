using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

[ApiController]
[Route("api/service-requests")]
public sealed class ServiceRequestsController(ServiceRequestStore store) : ControllerBase
{
    [HttpPost]
    public IActionResult Create([FromBody] ServiceRequestInputModel input)
    {
        var request = store.Create(input);
        return Ok(new
        {
            success = true,
            message = "Your request has been submitted successfully.",
            requestId = request.Id
        });
    }
}
