using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/tenant")]
public sealed class TenantController : ControllerBase
{
    private readonly ITenantOwnerInfoService _tenantOwnerInfoService;

    public TenantController(ITenantOwnerInfoService tenantOwnerInfoService)
    {
        _tenantOwnerInfoService = tenantOwnerInfoService;
    }

    [HttpGet("owner-info")]
    public async Task<ActionResult<TenantOwnerInfoResponse>> GetOwnerInfo(
        [FromQuery] string? tenantId,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _tenantOwnerInfoService.GetOwnerInfoAsync(
                tenantId,
                cancellationToken);

            return Ok(response);
        }
        catch (TenantOwnerInfoValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (TenantOwnerInfoNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }
}
