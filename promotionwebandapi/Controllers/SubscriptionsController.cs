using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SubscriptionsController : ControllerBase
{
    private readonly ISubscriptionService _subscriptionService;
    private readonly IConfiguration _configuration;

    public SubscriptionsController(
        ISubscriptionService subscriptionService,
        IConfiguration configuration)
    {
        _subscriptionService = subscriptionService;
        _configuration = configuration;
    }

    private string GetPublicBaseUrl()
    {
        var configUrl = _configuration["SslCommerz:PublicBaseUrl"]?.Trim();
        if (!string.IsNullOrWhiteSpace(configUrl))
        {
            return configUrl.TrimEnd('/');
        }

        return $"{Request.Scheme}://{Request.Host}";
    }

    [HttpGet("plans")]
    public async Task<ActionResult<IReadOnlyList<SubscriptionPlanDto>>> GetPlans(
        [FromQuery] bool activeOnly = true,
        CancellationToken cancellationToken = default)
    {
        var plans = await _subscriptionService.GetPlansAsync(activeOnly, cancellationToken);
        return Ok(plans);
    }

    [HttpGet("plans/{serviceCode}")]
    public async Task<ActionResult<SubscriptionPlanDto>> GetPlanByCode(
        string serviceCode,
        CancellationToken cancellationToken = default)
    {
        var plan = await _subscriptionService.GetPlanByCodeAsync(serviceCode, cancellationToken);
        if (plan is null)
        {
            return NotFound(new { message = $"Subscription plan '{serviceCode}' not found." });
        }

        return Ok(plan);
    }

    [HttpPost("initiate")]
    public async Task<ActionResult<InitiatePaymentResponse>> InitiateSubscription(
        [FromBody] InitiateSubscriptionPaymentRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.UserId))
            {
                return BadRequest(new { message = "User ID is required." });
            }
            if (string.IsNullOrWhiteSpace(request.ServiceCode))
            {
                return BadRequest(new { message = "Service code is required." });
            }

            var response = await _subscriptionService.InitiateSubscriptionPaymentAsync(
                request.UserId,
                request.ServiceCode,
                request.UserRequirements,
                GetPublicBaseUrl(),
                cancellationToken);

            return Ok(response);
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpGet("user-subscriptions")]
    public async Task<ActionResult<IReadOnlyList<UserSubscriptionDto>>> GetUserSubscriptions(
        [FromQuery] string userId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            return BadRequest(new { message = "User ID is required." });
        }

        var subscriptions = await _subscriptionService.GetUserSubscriptionsAsync(userId, cancellationToken);
        return Ok(subscriptions);
    }

    [HttpGet("admin/all")]
    public async Task<ActionResult<IReadOnlyList<UserSubscriptionDto>>> GetAllSubscriptions(
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        CancellationToken cancellationToken = default)
    {
        var subscriptions = await _subscriptionService.GetAllSubscriptionsAsync(search, status, cancellationToken);
        return Ok(subscriptions);
    }

    [HttpPost("admin/update-plan")]
    public async Task<IActionResult> UpdatePlan(
        [FromBody] UpdateSubscriptionPlanRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.ServiceCode))
        {
            return BadRequest(new { message = "Service code is required." });
        }

        var success = await _subscriptionService.UpdatePlanAsync(request, cancellationToken);
        if (!success)
        {
            return NotFound(new { message = $"Plan with service code '{request.ServiceCode}' was not found." });
        }

        return Ok(new { message = "Subscription plan updated successfully." });
    }

    [HttpPost("admin/update-status")]
    public async Task<IActionResult> UpdateStatus(
        [FromBody] UpdateSubscriptionStatusRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.SubscriptionId <= 0)
        {
            return BadRequest(new { message = "Valid subscription ID is required." });
        }

        var success = await _subscriptionService.UpdateSubscriptionStatusAsync(
            request.SubscriptionId,
            request.SubscriptionStatus,
            request.AdminNotes,
            cancellationToken);

        if (!success)
        {
            return NotFound(new { message = $"Subscription with ID {request.SubscriptionId} not found." });
        }

        return Ok(new { message = "Subscription status updated successfully." });
    }
}
