using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/payments")]
public sealed class PaymentsController : ControllerBase
{
    private readonly IMonthlyPaymentService _paymentService;
    private readonly IConfiguration _configuration;

    public PaymentsController(
        IMonthlyPaymentService paymentService,
        IConfiguration configuration)
    {
        _paymentService = paymentService;
        _configuration = configuration;
    }

    [HttpPost("initiate")]
    public async Task<ActionResult<InitiatePaymentResponse>> InitiatePayment(
        [FromBody] InitiatePaymentRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.UserId))
            {
                return BadRequest(new { message = "User ID is required." });
            }

            var response = await _paymentService.InitiatePaymentAsync(
                request.UserId,
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

    [HttpGet("status")]
    [HttpGet("/api/monthly-payment/status")]
    public async Task<ActionResult<PaymentStatusResponse>> GetPaymentStatus(
        [FromQuery] string userId,
        CancellationToken cancellationToken)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(userId))
            {
                return BadRequest(new { message = "User ID is required." });
            }

            var response = await _paymentService.GetPaymentStatusAsync(userId, cancellationToken);
            return Ok(response);
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (InvalidOperationException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    [HttpGet("history")]
    [HttpGet("/api/monthly-payment/history")]
    public async Task<ActionResult<MonthlyPaymentHistoryResponse>> GetPaymentHistory(
        [FromQuery] string userId,
        [FromQuery] int? year,
        CancellationToken cancellationToken)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(userId))
            {
                return BadRequest(new { message = "User ID is required." });
            }

            var requestedYear = year ?? DateTime.UtcNow.AddHours(6).Year;
            var response = await _paymentService.GetPaymentHistoryAsync(
                userId,
                requestedYear,
                cancellationToken);

            return Ok(response);
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (InvalidOperationException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    [AcceptVerbs("GET", "POST")]
    [Route("success")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> PaymentSuccess(CancellationToken cancellationToken)
    {
        var callbackData = await ReadCallbackDataAsync("SUCCESS", cancellationToken);
        var result = await _paymentService.ProcessCallbackAsync(callbackData, cancellationToken);

        return GetHtmlResponse(
            result.Success ? "Payment verified" : "Payment verification failed",
            result.Success
                ? "Your BDT 50 service charge payment has been verified successfully. You can close this window and continue."
                : result.Message,
            isSuccess: result.Success);
    }

    [AcceptVerbs("GET", "POST")]
    [Route("ipn")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> PaymentIpn(CancellationToken cancellationToken)
    {
        var callbackData = await ReadCallbackDataAsync(null, cancellationToken);
        var result = await _paymentService.ProcessCallbackAsync(callbackData, cancellationToken);

        return result.Success ? Ok("VALID") : BadRequest(result.Message);
    }

    [AcceptVerbs("GET", "POST")]
    [Route("fail")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> PaymentFail(CancellationToken cancellationToken)
    {
        var callbackData = await ReadCallbackDataAsync("FAILED", cancellationToken);
        await _paymentService.ProcessCallbackAsync(callbackData, cancellationToken);

        return GetHtmlResponse(
            "Payment failed",
            "Sorry, your payment could not be completed. Please try again.",
            isSuccess: false);
    }

    [AcceptVerbs("GET", "POST")]
    [Route("cancel")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> PaymentCancel(CancellationToken cancellationToken)
    {
        var callbackData = await ReadCallbackDataAsync("CANCELLED", cancellationToken);
        await _paymentService.ProcessCallbackAsync(callbackData, cancellationToken);

        return GetHtmlResponse(
            "Payment cancelled",
            "You cancelled the payment process. Payment is required to continue.",
            isSuccess: false);
    }

    private async Task<MonthlyPaymentCallbackData> ReadCallbackDataAsync(
        string? fallbackStatus,
        CancellationToken cancellationToken)
    {
        var values = Request.Query.ToDictionary(
            item => item.Key,
            item => item.Value.ToString(),
            StringComparer.OrdinalIgnoreCase);

        if (Request.HasFormContentType)
        {
            var form = await Request.ReadFormAsync(cancellationToken);
            foreach (var item in form)
            {
                values[item.Key] = item.Value.ToString();
            }
        }

        string? Read(string key) => values.TryGetValue(key, out var value) ? value : null;

        return new MonthlyPaymentCallbackData
        {
            TransactionId = Read("tran_id"),
            ValidationId = Read("val_id"),
            Status = Read("status") ?? fallbackStatus,
            Amount = Read("amount"),
            Currency = Read("currency"),
            RawData = string.Join(
                "&",
                values
                    .OrderBy(item => item.Key, StringComparer.OrdinalIgnoreCase)
                    .Select(item => $"{item.Key}={item.Value}"))
        };
    }

    private string GetPublicBaseUrl()
    {
        var configuredBaseUrl = _configuration["SslCommerz:PublicBaseUrl"]?.TrimEnd('/');
        if (!string.IsNullOrWhiteSpace(configuredBaseUrl))
        {
            return configuredBaseUrl;
        }

        return $"{Request.Scheme}://{Request.Host}{Request.PathBase}";
    }

    private ContentResult GetHtmlResponse(string title, string message, bool isSuccess)
    {
        var color = isSuccess ? "#10B981" : "#EF4444";
        var icon = isSuccess ? "OK" : "!";
        var postMessage = isSuccess ? "success" : "failed";
        var html = $$"""
            <!DOCTYPE html>
            <html>
            <head>
                <title>{{title}}</title>
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                        text-align: center;
                        padding: 50px 20px;
                        background-color: #F8FAFC;
                        color: #1E293B;
                        margin: 0;
                    }
                    .card {
                        max-width: 400px;
                        margin: 0 auto;
                        background: white;
                        padding: 40px 30px;
                        border-radius: 20px;
                        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -4px rgba(0, 0, 0, 0.05);
                        border: 1px solid #F1F5F9;
                    }
                    h2 {
                        color: {{color}};
                        margin-top: 0;
                        font-size: 22px;
                        font-weight: 700;
                    }
                    p {
                        color: #64748B;
                        font-size: 15px;
                        line-height: 1.6;
                        margin-bottom: 0;
                    }
                    .icon {
                        width: 56px;
                        height: 56px;
                        margin: 0 auto 24px;
                        border-radius: 999px;
                        display: grid;
                        place-items: center;
                        color: white;
                        background: {{color}};
                        font-size: 20px;
                        font-weight: 800;
                    }
                </style>
            </head>
            <body>
                <div class="card">
                    <div class="icon">{{icon}}</div>
                    <h2>{{title}}</h2>
                    <p>{{message}}</p>
                </div>
                <script>
                    if (window.parent) {
                        window.parent.postMessage('payment_{{postMessage}}', '*');
                    }
                </script>
            </body>
            </html>
            """;

        return new ContentResult
        {
            Content = html,
            ContentType = "text/html",
            StatusCode = 200
        };
    }
}
