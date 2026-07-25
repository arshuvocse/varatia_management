namespace OrderProcessAPI.Contracts;

public sealed class ExpenseRecordDto
{
    public int Id { get; init; }
    public string Title { get; init; } = string.Empty;
    public string Category { get; init; } = string.Empty;
    public int Amount { get; init; }
    public string MonthLabel { get; init; } = string.Empty;
}

public sealed class CreateExpenseRequest
{
    public string Title { get; init; } = string.Empty;
    public string Category { get; init; } = string.Empty;
    public int Amount { get; init; }
    public string MonthLabel { get; init; } = string.Empty;
    public string UserId { get; init; } = string.Empty;
}

public sealed class CreateExpenseResponse
{
    public ExpenseRecordDto Expense { get; init; } = new();
    public string Message { get; init; } = string.Empty;
}

public sealed class UpdateExpenseRequest
{
    public string Title { get; init; } = string.Empty;
    public string Category { get; init; } = string.Empty;
    public int Amount { get; init; }
    public string MonthLabel { get; init; } = string.Empty;
    public string UserId { get; init; } = string.Empty;
}

public sealed class UpdateExpenseResponse
{
    public ExpenseRecordDto Expense { get; init; } = new();
    public string Message { get; init; } = string.Empty;
}

public sealed class DeleteExpenseResponse
{
    public int ExpenseId { get; init; }
    public string Message { get; init; } = string.Empty;
}
