using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IExpenseService
{
    Task<IReadOnlyList<ExpenseRecordDto>> GetAllAsync(
        string userId,
        CancellationToken cancellationToken = default);

    Task<CreateExpenseResponse> CreateAsync(
        CreateExpenseRequest request,
        CancellationToken cancellationToken = default);

    Task<UpdateExpenseResponse> UpdateAsync(
        int expenseId,
        UpdateExpenseRequest request,
        CancellationToken cancellationToken = default);

    Task<DeleteExpenseResponse> DeleteAsync(
        int expenseId,
        CancellationToken cancellationToken = default);
}
