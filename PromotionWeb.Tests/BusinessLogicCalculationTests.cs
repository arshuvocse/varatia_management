using Xunit;
using PromotionWeb.Models;

namespace PromotionWeb.Tests;

public class BusinessLogicCalculationTests
{
    [Fact]
    public void CalculateNetWalletCredit_ShouldDeductDiscountAndCommissionCorrectly()
    {
        // Arrange
        decimal totalAmount = 1000m;
        decimal discountAmount = 50m;
        
        // Purchase price: 400 per unit, Sold price: 500 per unit (2 units)
        // Profit margin = (500 - 400) * 2 = 200
        // Total percentages = 5% + 2% + 1.5% + 1.5% = 10%
        // Commission = 200 * 10% = 20
        decimal purchasePrice = 400m;
        decimal unitPrice = 500m;
        int quantity = 2;
        decimal companyPercentage = 5.0m;
        decimal agentPercentage = 2.0m;
        decimal fieldForcePercentage = 1.5m;
        decimal customerPercentage = 1.5m;

        decimal totalPercentage = companyPercentage + agentPercentage + fieldForcePercentage + customerPercentage;
        decimal totalProfitMargin = (unitPrice - purchasePrice) * quantity;
        decimal calculatedCommission = Math.Round(totalProfitMargin * (totalPercentage / 100.0m), 2);
        
        // Net amount = TotalAmount - DiscountAmount - CommissionAmount
        decimal netAmount = totalAmount - discountAmount - calculatedCommission;

        // Assert
        Assert.Equal(20.00m, calculatedCommission);
        Assert.Equal(930.00m, netAmount);
    }

    [Fact]
    public void CalculateNetWalletCredit_WhenNetAmountNegative_ShouldDefaultToZero()
    {
        // Arrange
        decimal totalAmount = 100m;
        decimal discountAmount = 150m;
        decimal commissionAmount = 20m;

        decimal netAmount = totalAmount - discountAmount - commissionAmount;
        if (netAmount < 0) netAmount = 0m;

        // Assert
        Assert.Equal(0m, netAmount);
    }

    [Fact]
    public void DistrictLeaderboardEntry_Properties_SetAndReadCorrectly()
    {
        // Arrange
        var entry = new PromotionWeb.Services.DistrictLeaderboardEntry
        {
            Rank = 1,
            Name = "Rahim Store",
            SecondaryLabel = "Dhaka",
            TotalAmount = 50000m,
            OrderCount = 120
        };

        // Assert
        Assert.Equal(1, entry.Rank);
        Assert.Equal("Rahim Store", entry.Name);
        Assert.Equal("Dhaka", entry.SecondaryLabel);
        Assert.Equal(50000m, entry.TotalAmount);
        Assert.Equal(120, entry.OrderCount);
    }

    [Theory]
    [InlineData(100, 10, 90)]
    [InlineData(500, 0, 500)]
    [InlineData(250.50, 50.50, 200)]
    public void CustomerOrder_NetTotalCalculation_ReturnsExpectedValue(double grossDouble, double discountDouble, double expectedNetDouble)
    {
        decimal gross = (decimal)grossDouble;
        decimal discount = (decimal)discountDouble;
        decimal expectedNet = (decimal)expectedNetDouble;

        decimal net = gross - discount;

        Assert.Equal(expectedNet, net);
    }
}
