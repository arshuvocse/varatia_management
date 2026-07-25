using System.Globalization;
using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class ExpenseService : IExpenseService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public ExpenseService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<ExpenseRecordDto>> GetAllAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var items = await connection.QueryAsync<ExpenseRecordDto>(
            new CommandDefinition(
                """
                SELECT Id, Title, Category, Amount, MonthLabel
                FROM dbo.Expenses
                WHERE UserId = @UserId
                ORDER BY Id DESC;
                """,
                new { UserId = userId },
                cancellationToken: cancellationToken));

        return items.ToList();
    }

    public async Task<CreateExpenseResponse> CreateAsync(
        CreateExpenseRequest request,
        CancellationToken cancellationToken = default)
    {
        var title = request.Title.Trim();
        var category = request.Category.Trim();
        var monthLabel = NormalizeMonthLabel(request.MonthLabel);

        ValidateExpense(title, category, request.Amount, monthLabel);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        try
        {
            var expenseId = await connection.ExecuteScalarAsync<int>(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.Expenses (Title, Category, Amount, MonthLabel, UserId)
                    OUTPUT INSERTED.Id
                    VALUES (@Title, @Category, @Amount, @MonthLabel, @UserId);
                    """,
                    new
                    {
                        Title = title,
                        Category = category,
                        Amount = request.Amount,
                        MonthLabel = monthLabel,
                        UserId = request.UserId,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            await InsertActivityAsync(
                connection,
                transaction,
                "Expense added",
                $"{title} was recorded for {monthLabel}.",
                cancellationToken);
            await SyncExpenseMetricAsync(
                connection,
                transaction,
                monthLabel,
                cancellationToken);

            await transaction.CommitAsync(cancellationToken);

            return new CreateExpenseResponse
            {
                Expense = new ExpenseRecordDto
                {
                    Id = expenseId,
                    Title = title,
                    Category = category,
                    Amount = request.Amount,
                    MonthLabel = monthLabel,
                },
                Message = "Expense created successfully.",
            };
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    public async Task<UpdateExpenseResponse> UpdateAsync(
        int expenseId,
        UpdateExpenseRequest request,
        CancellationToken cancellationToken = default)
    {
        if (expenseId <= 0)
        {
            throw new ExpenseValidationException("Valid expense id is required.");
        }

        var title = request.Title.Trim();
        var category = request.Category.Trim();
        var monthLabel = NormalizeMonthLabel(request.MonthLabel);

        ValidateExpense(title, category, request.Amount, monthLabel);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        try
        {
            var existingExpense = await connection.QuerySingleOrDefaultAsync<ExpenseLookup>(
                new CommandDefinition(
                    """
                    SELECT Id, Title, Category, Amount, MonthLabel
                    FROM dbo.Expenses
                    WHERE Id = @ExpenseId;
                    """,
                    new { ExpenseId = expenseId },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            if (existingExpense is null)
            {
                throw new ExpenseNotFoundException("Expense was not found.");
            }

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    UPDATE dbo.Expenses
                    SET
                        Title = @Title,
                        Category = @Category,
                        Amount = @Amount,
                        MonthLabel = @MonthLabel
                    WHERE Id = @ExpenseId;
                    """,
                    new
                    {
                        ExpenseId = expenseId,
                        Title = title,
                        Category = category,
                        Amount = request.Amount,
                        MonthLabel = monthLabel,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            await InsertActivityAsync(
                connection,
                transaction,
                "Expense updated",
                $"{title} was updated for {monthLabel}.",
                cancellationToken);
            await SyncExpenseMetricAsync(
                connection,
                transaction,
                existingExpense.MonthLabel,
                cancellationToken);

            if (!string.Equals(
                    existingExpense.MonthLabel,
                    monthLabel,
                    StringComparison.OrdinalIgnoreCase))
            {
                await SyncExpenseMetricAsync(
                    connection,
                    transaction,
                    monthLabel,
                    cancellationToken);
            }

            await transaction.CommitAsync(cancellationToken);

            return new UpdateExpenseResponse
            {
                Expense = new ExpenseRecordDto
                {
                    Id = expenseId,
                    Title = title,
                    Category = category,
                    Amount = request.Amount,
                    MonthLabel = monthLabel,
                },
                Message = "Expense updated successfully.",
            };
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    public async Task<DeleteExpenseResponse> DeleteAsync(
        int expenseId,
        CancellationToken cancellationToken = default)
    {
        if (expenseId <= 0)
        {
            throw new ExpenseValidationException("Valid expense id is required.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        try
        {
            var existingExpense = await connection.QuerySingleOrDefaultAsync<ExpenseLookup>(
                new CommandDefinition(
                    """
                    SELECT Id, Title, Category, Amount, MonthLabel
                    FROM dbo.Expenses
                    WHERE Id = @ExpenseId;
                    """,
                    new { ExpenseId = expenseId },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            if (existingExpense is null)
            {
                throw new ExpenseNotFoundException("Expense was not found.");
            }

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    DELETE FROM dbo.Expenses
                    WHERE Id = @ExpenseId;
                    """,
                    new { ExpenseId = expenseId },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            await InsertActivityAsync(
                connection,
                transaction,
                "Expense deleted",
                $"{existingExpense.Title} was removed from {existingExpense.MonthLabel}.",
                cancellationToken);
            await SyncExpenseMetricAsync(
                connection,
                transaction,
                existingExpense.MonthLabel,
                cancellationToken);

            await transaction.CommitAsync(cancellationToken);

            return new DeleteExpenseResponse
            {
                ExpenseId = expenseId,
                Message = "Expense deleted successfully.",
            };
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    private static void ValidateExpense(
        string title,
        string category,
        int amount,
        string monthLabel)
    {
        if (string.IsNullOrWhiteSpace(title) || title.Length < 2)
        {
            throw new ExpenseValidationException(
                "Expense title must contain at least 2 characters.");
        }

        if (string.IsNullOrWhiteSpace(category) || category.Length < 2)
        {
            throw new ExpenseValidationException(
                "Expense category must contain at least 2 characters.");
        }

        if (amount <= 0)
        {
            throw new ExpenseValidationException(
                "Expense amount must be greater than zero.");
        }

        if (string.IsNullOrWhiteSpace(monthLabel))
        {
            throw new ExpenseValidationException("Month label is required.");
        }
    }

    private static string NormalizeMonthLabel(string monthLabel)
    {
        var parts = monthLabel
            .Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

        return string.Join(' ', parts);
    }

    private static async Task InsertActivityAsync(
        Microsoft.Data.SqlClient.SqlConnection connection,
        System.Data.Common.DbTransaction transaction,
        string title,
        string subtitle,
        CancellationToken cancellationToken)
    {
        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                INSERT INTO dbo.Activities (Title, Subtitle, TimeLabel)
                VALUES (@Title, @Subtitle, 'Today');
                """,
                new
                {
                    Title = title,
                    Subtitle = subtitle,
                },
                transaction: transaction,
                cancellationToken: cancellationToken));
    }

    private static async Task SyncExpenseMetricAsync(
        Microsoft.Data.SqlClient.SqlConnection connection,
        System.Data.Common.DbTransaction transaction,
        string monthLabel,
        CancellationToken cancellationToken)
    {
        var metricLabel = NormalizeMetricLabel(monthLabel);
        var totalValue = await connection.ExecuteScalarAsync<decimal>(
            new CommandDefinition(
                """
                SELECT CAST(ISNULL(SUM(CAST(Amount AS DECIMAL(18,2))), 0) AS DECIMAL(18,2))
                FROM dbo.Expenses
                WHERE MonthLabel = @MonthLabel;
                """,
                new { MonthLabel = monthLabel },
                transaction: transaction,
                cancellationToken: cancellationToken));

        var existingMetricId = await connection.ExecuteScalarAsync<int?>(
            new CommandDefinition(
                """
                SELECT TOP (1) Id
                FROM dbo.Metrics
                WHERE MetricType = 'expense'
                  AND Label = @Label
                ORDER BY Id;
                """,
                new { Label = metricLabel },
                transaction: transaction,
                cancellationToken: cancellationToken));

        if (existingMetricId.HasValue)
        {
            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    UPDATE dbo.Metrics
                    SET Value = @Value
                    WHERE Id = @MetricId;
                    """,
                    new
                    {
                        MetricId = existingMetricId.Value,
                        Value = totalValue,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            return;
        }

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                INSERT INTO dbo.Metrics (MetricType, Label, Value)
                VALUES ('expense', @Label, @Value);
                """,
                new
                {
                    Label = metricLabel,
                    Value = totalValue,
                },
                transaction: transaction,
                cancellationToken: cancellationToken));
    }

    private static string NormalizeMetricLabel(string monthLabel)
    {
        if (DateTime.TryParseExact(
                monthLabel,
                ["MMMM yyyy", "MMM yyyy", "MMMM", "MMM"],
                CultureInfo.InvariantCulture,
                DateTimeStyles.None,
                out var parsedDate))
        {
            return parsedDate.ToString("MMM", CultureInfo.InvariantCulture);
        }

        var firstToken = monthLabel
            .Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .FirstOrDefault();
        if (string.IsNullOrWhiteSpace(firstToken))
        {
            return "N/A";
        }

        var compactToken = firstToken.Length <= 3
            ? firstToken
            : firstToken[..3];

        return CultureInfo.InvariantCulture.TextInfo.ToTitleCase(
            compactToken.ToLowerInvariant());
    }

    private sealed class ExpenseLookup
    {
        public int Id { get; init; }
        public string Title { get; init; } = string.Empty;
        public string Category { get; init; } = string.Empty;
        public int Amount { get; init; }
        public string MonthLabel { get; init; } = string.Empty;
    }
}

public sealed class ExpenseValidationException : Exception
{
    public ExpenseValidationException(string message)
        : base(message)
    {
    }
}

public sealed class ExpenseNotFoundException : Exception
{
    public ExpenseNotFoundException(string message)
        : base(message)
    {
    }
}
