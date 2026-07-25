using System;

namespace PromotionWeb.Models;

public sealed class ExpenseInputModel
{
    public int ExpenseTypeId { get; set; }
    public decimal Amount { get; set; }
    public DateTime ExpenseDate { get; set; }
}
