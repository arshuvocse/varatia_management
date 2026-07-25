using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public sealed class ShopkeeperSaleInputModel
{
    [Required(ErrorMessage = "Customer name লিখুন।")]
    [StringLength(150, ErrorMessage = "Customer name সর্বোচ্চ 150 অক্ষরের হতে পারে।")]
    public string CustomerName { get; set; } = "";

    [Required(ErrorMessage = "Customer mobile লিখুন।")]
    [RegularExpression(@"^\d{11}$", ErrorMessage = "Mobile number 11 digit হতে হবে।")]
    public string CustomerPhone { get; set; } = "";

    [Required(ErrorMessage = "Payment method নির্বাচন করুন।")]
    public string PaymentMethod { get; set; } = "";

    [MinLength(1, ErrorMessage = "কমপক্ষে একটি product যোগ করুন।")]
    public List<ShopkeeperSaleItemInputModel> Items { get; set; } = [];
}

public sealed class ShopkeeperSaleItemInputModel
{
    [Range(1, int.MaxValue, ErrorMessage = "Valid product নির্বাচন করুন।")]
    public int ProductId { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Quantity কমপক্ষে 1 হতে হবে।")]
    public int Quantity { get; set; }
}

public sealed class ShopkeeperSaleResult
{
    public int Id { get; init; }
    public string InvoiceNo { get; init; } = "";
    public decimal GrossAmount { get; init; }
    public decimal CashbackAmount { get; init; }
    public decimal SystemCommission { get; init; }
}

public sealed class PendingPosPayment
{
    public string TransactionId { get; init; } = "";
    public int ShopkeeperId { get; init; }
    public decimal Amount { get; init; }
    public ShopkeeperSaleInputModel Sale { get; init; } = new();
}
