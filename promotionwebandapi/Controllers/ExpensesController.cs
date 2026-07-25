using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/expenses")]
public sealed class ExpensesController : ControllerBase
{
    private readonly IExpenseService _expenseService;

    public ExpensesController(IExpenseService expenseService)
    {
        _expenseService = expenseService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ExpenseRecordDto>>> GetAll(
        [FromQuery] string user_id,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(user_id))
        {
            return BadRequest(new { message = "user_id is required." });
        }

        var response = await _expenseService.GetAllAsync(user_id, cancellationToken);
        return Ok(response);
    }

    [HttpPost]
    public async Task<ActionResult<CreateExpenseResponse>> Create(
        [FromBody] CreateExpenseRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _expenseService.CreateAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (ExpenseValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpPut("{expenseId:int}")]
    public async Task<ActionResult<UpdateExpenseResponse>> Update(
        int expenseId,
        [FromBody] UpdateExpenseRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _expenseService.UpdateAsync(
                expenseId,
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (ExpenseValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (ExpenseNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    [HttpDelete("{expenseId:int}")]
    public async Task<ActionResult<DeleteExpenseResponse>> Delete(
        int expenseId,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _expenseService.DeleteAsync(
                expenseId,
                cancellationToken);

            return Ok(response);
        }
        catch (ExpenseValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (ExpenseNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }
}
