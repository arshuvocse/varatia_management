using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public sealed class ShopkeeperWithdrawalInputModel
{
    [Range(typeof(decimal), "10", "9999999999.99", ErrorMessage = "কমপক্ষে ৳১০ উত্তোলনের অনুরোধ করুন।")]
    public decimal Amount { get; set; }

    [Required, StringLength(30)]
    public string PaymentMethod { get; set; } = "bKash";

    [Required, RegularExpression(@"^01\d{9}$", ErrorMessage = "সঠিক ১১ সংখ্যার মোবাইল নম্বর দিন।")]
    public string AccountNumber { get; set; } = "";
}

public sealed class ShopkeeperWithdrawalViewModel
{
    public int Id { get; init; }
    public decimal Amount { get; init; }
    public string PaymentMethod { get; init; } = "";
    public string AccountNumber { get; init; } = "";
    public string Status { get; init; } = "Pending";
    public DateTime CreatedAt { get; init; }
    public string ShopName { get; init; } = "";
    public string ShopCode { get; init; } = "";
    public string ShopPhone { get; init; } = "";
}

public sealed class WithdrawalProcessInputModel
{
    public int RequestId { get; set; }
    [Required, RegularExpression("Approved|Rejected|Paid")]
    public string Status { get; set; } = "";
    [StringLength(250)] public string? Note { get; set; }
}

public sealed class ShopkeeperSupportInputModel
{
    [Required, StringLength(100)]
    public string Subject { get; set; } = "";

    [Required, StringLength(2000)]
    public string Message { get; set; } = "";
}

public sealed class ShopkeeperWalletSummary
{
    public decimal Balance { get; init; }
    public decimal Withdrawable { get; init; }
    public decimal PendingWithdrawal { get; init; }
}
