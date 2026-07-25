using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class ManagementController : ControllerBase
{
    private readonly IManagementDataService _managementDataService;

    public ManagementController(IManagementDataService managementDataService)
    {
        _managementDataService = managementDataService;
    }

    [HttpGet("bootstrap")]
    public async Task<ActionResult<ManagementBootstrapResponse>> GetBootstrap(
        CancellationToken cancellationToken)
    {
        var response = await _managementDataService.GetBootstrapAsync(
            cancellationToken);

        return Ok(response);
    }
}
