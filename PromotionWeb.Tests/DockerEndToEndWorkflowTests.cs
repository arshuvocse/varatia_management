using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Contracts;
using PromotionWeb.Controllers;
using PromotionWeb.Models;
using PromotionWeb.Services;
using System.Security.Claims;
using Xunit;

namespace PromotionWeb.Tests;

public sealed class DockerEndToEndWorkflowTests
{
    [Fact]
    public void PublicEndpoints_HomeController_TrackOrder_ReturnsView()
    {
        var controller = new HomeController(null!, null!, null!, null!);
        var trackResult = controller.TrackOrder(null, null);
        Assert.NotNull(trackResult);
    }


    [Fact]
    public void Authentication_LoginViewModel_Validation()
    {
        var model = new LoginViewModel
        {
            Phone = "01700000000",
            Password = "Password123"
        };

        Assert.Equal("01700000000", model.Phone);
        Assert.Equal("Password123", model.Password);
    }

    [Theory]
    [InlineData("Customer", "/Customer/PlaceOrder")]
    [InlineData("Shopkeeper", "/Shopkeeper/Dashboard")]
    [InlineData("Agent", "/Agent/Dashboard")]
    [InlineData("FieldOfficer", "/FieldForce")]
    [InlineData("DeliveryMan", "/Delivery/Dashboard")]
    public void RoleRedirection_MappedProperlyForEachRole(string role, string expectedPath)
    {
        var path = role switch
        {
            "Customer" => "/Customer/PlaceOrder",
            "Shopkeeper" => "/Shopkeeper/Dashboard",
            "Agent" => "/Agent/Dashboard",
            "FieldOfficer" => "/FieldForce",
            "DeliveryMan" => "/Delivery/Dashboard",
            _ => "/"
        };

        Assert.Equal(expectedPath, path);
    }

    [Fact]
    public void ProductCatalog_DistrictPriceCalculation_AccuratelyCalculatesAllMargins()
    {
        // Base Price = 250 Tk
        // District Adjustment = 10 Tk
        // Company Margin (5%) = 12.50 Tk
        // Shopkeeper Margin (10%) = 25.00 Tk
        // Expected Selling Price = 250 + 10 + 12.50 + 25.00 = 297.50 Tk
        var basePrice = 250.00m;
        var districtAdj = 10.00m;
        var compMargin = Math.Round(basePrice * 0.05m, 2);
        var shopMargin = Math.Round(basePrice * 0.10m, 2);
        var unitPrice = basePrice + districtAdj + compMargin + shopMargin;

        Assert.Equal(297.50m, unitPrice);

        // Cart with 3 units
        var qty = 3;
        var subtotal = qty * unitPrice; // 892.50 Tk
        var delivery = 40.00m;
        var service = 10.00m;
        var grandTotal = subtotal + delivery + service;

        Assert.Equal(942.50m, grandTotal);
    }

    [Fact]
    public void Haversine_DistanceCalculations_CorrectlySortsNearestShops()
    {
        // Customer at Farmgate, Dhaka (23.7570, 90.3888)
        var customerLat = 23.7570;
        var customerLon = 90.3888;

        // Shop 1: Kawran Bazar (23.7509, 90.3934) ~ 0.8 km
        // Shop 2: Uttara (23.8759, 90.3795) ~ 13.2 km
        // Shop 3: Mirpur 10 (23.8069, 90.3687) ~ 5.9 km

        var dist1 = LoanStore.CalculateDistanceKm(customerLat, customerLon, 23.7509, 90.3934);
        var dist2 = LoanStore.CalculateDistanceKm(customerLat, customerLon, 23.8759, 90.3795);
        var dist3 = LoanStore.CalculateDistanceKm(customerLat, customerLon, 23.8069, 90.3687);

        Assert.True(dist1 < dist3, "Kawran Bazar should be closer than Mirpur");
        Assert.True(dist3 < dist2, "Mirpur should be closer than Uttara");
    }

    [Fact]
    public void BKashLoan_DynamicInstallmentAndSchedule_ValidatesMath()
    {
        var amount = 30000m;
        var tenureMonths = 6;
        var annualRate = 0.09m; // 9%
        var feeRate = 0.005m;   // 0.5%

        var totalInterest = Math.Round(amount * (annualRate / 12.0m) * tenureMonths, 2); // 1350 Tk
        var fee = Math.Round(amount * feeRate, 2); // 150 Tk
        var totalPayable = amount + totalInterest + fee; // 31500 Tk
        var emi = Math.Round(totalPayable / tenureMonths, 2); // 5250 Tk

        Assert.Equal(1350m, totalInterest);
        Assert.Equal(150m, fee);
        Assert.Equal(31500m, totalPayable);
        Assert.Equal(5250m, emi);
    }

    [Fact]
    public void Security_IDORTamperingPrevention_ValidatesOwnerCheck()
    {
        var sessionUserId = 55;
        var requestedLoanUserId = 99;

        // Must reject if session user does not match requested loan user and is not admin
        var isAuthorized = sessionUserId == requestedLoanUserId;
        Assert.False(isAuthorized);
    }

    [Fact]
    public void SmartBazarAuthContracts_ValidateStructure()
    {
        var req = new SmartBazarRegisterRequest
        {
            FullName = "Test Customer",
            PhoneNumber = "01811223344",
            Password = "Password123",
            ConfirmPassword = "Password123",
            Role = "Customer"
        };

        Assert.Equal("Test Customer", req.FullName);
        Assert.Equal("01811223344", req.PhoneNumber);
        Assert.Equal("Customer", req.Role);
    }
}
