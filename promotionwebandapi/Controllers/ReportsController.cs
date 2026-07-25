using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/reports")]
public sealed class ReportsController : ControllerBase
{
    private readonly IReportService _reportService;

    public ReportsController(IReportService reportService)
    {
        _reportService = reportService;
    }

    [HttpGet("summary")]
    public async Task<ActionResult<ReportSummaryResponse>> GetSummary(
        [FromQuery] string user_id,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(user_id))
        {
            return BadRequest(new { message = "user_id is required." });
        }

        var response = await _reportService.GetSummaryAsync(user_id, cancellationToken);
        return Ok(response);
    }

    [HttpGet("payments-export")]
    public async Task<IActionResult> ExportPaymentsCsv(
        [FromQuery] string user_id,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(user_id))
        {
            return BadRequest(new { message = "user_id is required." });
        }

        var csvContent = await _reportService.ExportPaymentsCsvAsync(
            user_id,
            cancellationToken);

        return File(
            System.Text.Encoding.UTF8.GetBytes(csvContent),
            "text/csv",
            $"payment-report-{DateTime.UtcNow:yyyyMMddHHmmss}.csv");
    }
}
