using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public sealed class ShopkeeperDueViewModel
{
    public int SaleId { get; init; }
    public string InvoiceNo { get; init; } = "";
    public int CustomerId { get; init; }
    public string CustomerName { get; init; } = "";
    public string CustomerPhone { get; init; } = "";
    public decimal GrossAmount { get; init; }
    public decimal PaidAmount { get; init; }
    public decimal DueAmount { get; init; }
    public DateTime SoldAt { get; init; }
}

public sealed class DuePaymentInputModel
{
    [Required(ErrorMessage = "Sale ID প্রয়োজন।")]
    public int SaleId { get; set; }

    [Range(1, double.MaxValue, ErrorMessage = "Payment amount সঠিক নয়।")]
    public decimal Amount { get; set; }

    [Required(ErrorMessage = "Payment method নির্বাচন করুন।")]
    public string PaymentMethod { get; set; } = "";
}

public sealed class DailyReportViewModel
{
    public DateTime Date { get; init; }
    public int TotalSalesCount { get; init; }
    public decimal TotalSalesAmount { get; init; }
    public decimal TotalCashCollected { get; init; }
    public decimal TotalDueCollected { get; init; }
}
