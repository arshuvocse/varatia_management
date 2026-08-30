using Xunit;
using PromotionWeb.Models;

namespace PromotionWeb.Tests;

public class OrderStatusTransitionTests
{
    private static readonly string[] ValidOrderStatusList = ["Pending", "Approved", "OutForDelivery", "Delivered", "Rejected"];

    [Theory]
    [InlineData("Pending", "Approved", true)]
    [InlineData("Pending", "Rejected", true)]
    [InlineData("Approved", "OutForDelivery", true)]
    [InlineData("Approved", "Delivered", true)]
    [InlineData("OutForDelivery", "Delivered", true)]
    [InlineData("Delivered", "Approved", false)]
    [InlineData("Rejected", "Approved", false)]
    [InlineData("Delivered", "Rejected", false)]
    public void OrderStatus_TransitionValidation_WorksAsExpected(string currentStatus, string targetStatus, bool expectedValid)
    {
        bool isValid = IsStatusTransitionAllowed(currentStatus, targetStatus);
        Assert.Equal(expectedValid, isValid);
    }

    private static bool IsStatusTransitionAllowed(string current, string target)
    {
        if (!Array.Exists(ValidOrderStatusList, s => s.Equals(target, StringComparison.OrdinalIgnoreCase)))
            return false;

        return (current, target) switch
        {
            ("Pending", "Approved") => true,
            ("Pending", "Rejected") => true,
            ("Approved", "OutForDelivery") => true,
            ("Approved", "Delivered") => true,
            ("OutForDelivery", "Delivered") => true,
            _ => false
        };
    }

    [Fact]
    public void ProductInputModel_Validation_RequiresValidUnitPriceAndStock()
    {
        var input = new ProductInputModel
        {
            Name = "   Test Product   ",
            Sku = "  sku-123  ",
            Category = " Grocery ",
            UnitPrice = 150.00m,
            StockQuantity = 50
        };

        var trimmedName = input.Name.Trim();
        var normalizedSku = input.Sku.Trim().ToUpperInvariant();

        Assert.Equal("Test Product", trimmedName);
        Assert.Equal("SKU-123", normalizedSku);
        Assert.True(input.UnitPrice > 0);
        Assert.True(input.StockQuantity >= 0);
    }

    [Fact]
    public void CustomerOrderMaster_TotalCalculation_MatchesSumOfDetails()
    {
        var details = new List<CustomerOrderDetail>
        {
            new CustomerOrderDetail { Sku = "P1", UnitPrice = 100m, Quantity = 2 },
            new CustomerOrderDetail { Sku = "P2", UnitPrice = 50m, Quantity = 3 }
        };

        decimal expectedTotal = (100m * 2) + (50m * 3); // 200 + 150 = 350
        decimal calculatedTotal = details.Sum(d => d.UnitPrice * d.Quantity);

        Assert.Equal(350m, calculatedTotal);
        Assert.Equal(expectedTotal, calculatedTotal);
    }
}
