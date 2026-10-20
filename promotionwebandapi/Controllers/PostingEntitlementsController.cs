using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/posting-entitlements")]
public sealed class PostingEntitlementsController : ControllerBase
{
    private readonly IPostingEntitlementService _entitlementService;
    private readonly IMonthlyPaymentService _monthlyPaymentService;

    public PostingEntitlementsController(
        IPostingEntitlementService entitlementService,
        IMonthlyPaymentService monthlyPaymentService)
    {
        _entitlementService = entitlementService;
        _monthlyPaymentService = monthlyPaymentService;
    }

    [HttpGet("{userId}")]
    public async Task<ActionResult<PostingEntitlementDto>> GetEntitlement(
        string userId,
        CancellationToken cancellationToken)
    {
        try
        {
            var entitlement = await _entitlementService.GetEntitlementAsync(userId, cancellationToken);
            return Ok(entitlement);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("initiate-payment")]
    public async Task<ActionResult<InitiatePaymentResponse>> InitiatePayment(
        [FromBody] InitiatePostingCreditPaymentRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            if (request.Amount < 100.00m)
            {
                return BadRequest(new { message = "Posting payment must be at least BDT 100.00." });
            }

            var response = await _monthlyPaymentService.InitiatePostingPaymentAsync(
                request.UserId,
                request.Amount,
                GetPublicBaseUrl(),
                cancellationToken);

            return Ok(response);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private string GetPublicBaseUrl()
    {
        var forwardedProto = Request.Headers["X-Forwarded-Proto"].FirstOrDefault();
        var forwardedHost = Request.Headers["X-Forwarded-Host"].FirstOrDefault();
        var scheme = string.IsNullOrWhiteSpace(forwardedProto) ? Request.Scheme : forwardedProto;
        var host = string.IsNullOrWhiteSpace(forwardedHost) ? Request.Host.Value : forwardedHost;

        return $"{scheme}://{host}";
    }
}
