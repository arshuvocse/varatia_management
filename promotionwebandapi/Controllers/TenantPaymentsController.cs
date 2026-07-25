using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/tenant/payments")]
public sealed class TenantPaymentsController : ControllerBase
{
    private readonly ITenantPaymentService _tenantPaymentService;

    public TenantPaymentsController(ITenantPaymentService tenantPaymentService)
    {
        _tenantPaymentService = tenantPaymentService;
    }

    [HttpGet]
    public async Task<ActionResult<GetRentPaymentsResponse>> GetRentPayments(
        [FromQuery] string user_id,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(user_id))
        {
            return BadRequest(new { message = "user_id is required." });
        }

        var response = await _tenantPaymentService.GetRentPaymentsAsync(
            user_id,
            cancellationToken);

        return Ok(response);
    }

    [HttpPost("confirm")]
    public async Task<ActionResult<ConfirmTenantPaymentResponse>> ConfirmPayment(
        [FromBody] ConfirmTenantPaymentRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _tenantPaymentService.ConfirmPaymentAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (TenantPaymentValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (TenantPaymentNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }
}
