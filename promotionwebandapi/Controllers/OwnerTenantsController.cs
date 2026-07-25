using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/owner/tenants")]
public sealed class OwnerTenantsController : ControllerBase
{
    private readonly IOwnerTenantService _ownerTenantService;

    public OwnerTenantsController(IOwnerTenantService ownerTenantService)
    {
        _ownerTenantService = ownerTenantService;
    }

    [HttpGet]
    public async Task<ActionResult<OwnerTenantListResponse>> GetTenants(
        CancellationToken cancellationToken)
    {
        var response = await _ownerTenantService.GetTenantsAsync(cancellationToken);
        return Ok(response);
    }

    [HttpPost]
    public async Task<ActionResult<CreateOwnerTenantResponse>> CreateTenant(
        [FromBody] CreateOwnerTenantRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _ownerTenantService.CreateTenantAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (OwnerTenantValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (OwnerTenantConflictException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpPut("{tenantId}")]
    public async Task<ActionResult<UpdateOwnerTenantResponse>> UpdateTenant(
        string tenantId,
        [FromBody] UpdateOwnerTenantRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _ownerTenantService.UpdateTenantAsync(
                tenantId,
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (OwnerTenantNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (OwnerTenantValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (OwnerTenantConflictException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpDelete("{tenantId}")]
    public async Task<ActionResult<DeleteOwnerTenantResponse>> DeleteTenant(
        string tenantId,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _ownerTenantService.DeleteTenantAsync(
                tenantId,
                cancellationToken);

            return Ok(response);
        }
        catch (OwnerTenantNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (OwnerTenantValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpPost("{tenantId}/move-out")]
    public async Task<ActionResult<MoveOutOwnerTenantResponse>> MoveOutTenant(
        string tenantId,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _ownerTenantService.MoveOutTenantAsync(
                tenantId,
                cancellationToken);

            return Ok(response);
        }
        catch (OwnerTenantNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (OwnerTenantValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (OwnerTenantConflictException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }
}
