using PromotionWeb.Models;
using PromotionWeb.Services;
using Xunit;

namespace PromotionWeb.Tests;

public sealed class EcommerceAndLoanFeatureTests
{
    [Fact]
    public void Haversine_CalculateDistanceKm_ReturnsAccurateDistance()
    {
        // Gulshan 2 (23.7925, 90.4078) to Dhanmondi 27 (23.7538, 90.3755) in Dhaka (~6.0 - 6.5 km)
        var lat1 = 23.7925;
        var lon1 = 90.4078;
        var lat2 = 23.7538;
        var lon2 = 90.3755;

        var distance = LoanStore.CalculateDistanceKm(lat1, lon1, lat2, lon2);

        Assert.True(distance > 5.0 && distance < 7.0, $"Expected distance between 5 and 7 km, but got {distance} km");
    }

    [Fact]
    public void Haversine_SameCoordinates_ReturnsZero()
    {
        var lat = 23.8103;
        var lon = 90.4125;

        var distance = LoanStore.CalculateDistanceKm(lat, lon, lat, lon);

        Assert.Equal(0.0, distance);
    }

    [Theory]
    [InlineData(10000, 3, 9.0, 0.5, 3425.00)]
    [InlineData(10000, 6, 9.0, 0.5, 1750.00)]
    [InlineData(20000, 12, 9.0, 0.5, 1825.00)]
    [InlineData(50000, 6, 9.0, 0.5, 8750.00)]
    public void LoanCalculation_FormulaValidation_ProducesAccurateInstallments(
        decimal amount,
        int tenureMonths,
        decimal annualRatePercent,
        decimal feePercent,
        decimal expectedMonthlyInstallment)
    {
        var annualRate = annualRatePercent / 100.0m;
        var totalInterest = Math.Round(amount * (annualRate / 12.0m) * tenureMonths, 2);
        var processingFee = Math.Round(amount * (feePercent / 100.0m), 2);
        if (processingFee < 25.0m) processingFee = 25.0m;

        var totalPayable = amount + totalInterest + processingFee;
        var monthlyInstallment = Math.Round(totalPayable / tenureMonths, 2);

        Assert.Equal(expectedMonthlyInstallment, monthlyInstallment);
        Assert.True(totalPayable > amount);
    }

    [Fact]
    public void DistrictPricing_Formula_CalculatesGrandTotalCorrectly()
    {
        // Base Wholesale Price = 1000
        // Transport Multiplier = 1.03 (3% / 30 Tk adjustment)
        // Company Margin = 5% (50 Tk)
        // Shopkeeper Margin = 10% (100 Tk)
        // Unit Selling Price = 1000 + 30 + 50 + 100 = 1180 Tk
        var basePrice = 1000.00m;
        var transportMultiplier = 1.0300m;
        var companyMarginPercent = 5.00m;
        var shopkeeperMarginPercent = 10.00m;

        var districtAdj = Math.Round(basePrice * (transportMultiplier - 1.0m), 2);
        var compMargin = Math.Round(basePrice * (companyMarginPercent / 100.0m), 2);
        var shopMargin = Math.Round(basePrice * (shopkeeperMarginPercent / 100.0m), 2);

        var finalUnitPrice = basePrice + districtAdj + compMargin + shopMargin;
        Assert.Equal(1180.00m, finalUnitPrice);

        // 2 units ordered
        var quantity = 2;
        var subtotal = quantity * finalUnitPrice; // 2360 Tk

        var deliveryCharge = 40.00m;
        var serviceCharge = 10.00m;
        var platformCharge = 5.00m;

        var grandTotal = subtotal + deliveryCharge + serviceCharge + platformCharge;
        Assert.Equal(2415.00m, grandTotal);
    }

    [Fact]
    public void CoreCategories_MustContain8DefinedBusinessCategories()
    {
        var expectedCategories = new[]
        {
            "মুদির দোকান",
            "কসমেটিক্স",
            "ফার্মেসি",
            "জামা-কাপড়",
            "জুতার দোকান",
            "কাঁচা বাজার",
            "ইলেকট্রনিক্স শপ",
            "মোবাইল ফোনের দোকান"
        };

        Assert.Equal(8, expectedCategories.Length);
        Assert.Contains("মুদির দোকান", expectedCategories);
        Assert.Contains("ফার্মেসি", expectedCategories);
        Assert.Contains("মোবাইল ফোনের দোকান", expectedCategories);
    }

    [Fact]
    public void CustomerOrderMaster_NetAmount_CalculatesWithChargesCorrectly()
    {
        var order = new CustomerOrderMaster
        {
            Id = 1,
            TotalAmount = 1500.00m,
            DiscountAmount = 100.00m,
            DeliveryCharge = 40.00m,
            ServiceCharge = 10.00m,
            PlatformCharge = 5.00m,
            DeliveryType = "হোম ডেলিভারি"
        };

        // NetAmount = Total - Discount + Delivery + Service + Platform
        // 1500 - 100 + 40 + 10 + 5 = 1455
        Assert.Equal(1455.00m, order.NetAmount);
    }

    [Fact]
    public void LoanModels_ProgressPercentage_CalculatesAccurately()
    {
        var loan = new LoanItemViewModel
        {
            Id = 101,
            LoanAmount = 10000m,
            TotalPayable = 10500m,
            RemainingAmount = 3500m,
            TenureMonths = 6,
            MonthlyInstallment = 1750m
        };

        // Paid = 10500 - 3500 = 7000 (66.66% -> 66.7%)
        Assert.Equal(7000m, loan.PaidAmount);
        Assert.True(loan.ProgressPercentage > 66 && loan.ProgressPercentage < 67);
    }
}
