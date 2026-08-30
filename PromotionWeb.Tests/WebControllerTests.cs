using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Xunit;
using PromotionWeb.Controllers;
using PromotionWeb.Models;

namespace PromotionWeb.Tests;

public class WebControllerTests
{
    [Fact]
    public void HomeController_Index_RedirectsToLandingPage()
    {
        var controller = new HomeController(null!, null!, null!, null!);

        var result = controller.Index();

        var redirectResult = Assert.IsType<RedirectResult>(result);
        Assert.Equal("/landing.html", redirectResult.Url);
    }

    [Fact]
    public void HomeController_TrackOrder_WithoutOrderIdOrPhone_ReturnsView()
    {
        var controller = new HomeController(null!, null!, null!, null!);

        var result = controller.TrackOrder(null, null);

        var viewResult = Assert.IsType<ViewResult>(result);
        Assert.Null(viewResult.ViewName);
    }

    [Fact]
    public void HomeController_TrackOrder_WithEmptyPhone_ReturnsView()
    {
        var controller = new HomeController(null!, null!, null!, null!);

        var result = controller.TrackOrder(101, "   ");

        var viewResult = Assert.IsType<ViewResult>(result);
        Assert.Null(viewResult.ViewName);
    }

    [Fact]
    public void AccountController_Login_WhenNotAuthenticated_ReturnsLoginView()
    {
        var controller = new AccountController(null!, null!, null!, null!, null!, null!);
        var httpContext = new DefaultHttpContext();
        httpContext.User = new ClaimsPrincipal(new ClaimsIdentity());
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };

        var result = controller.Login();

        var viewResult = Assert.IsType<ViewResult>(result);
        var model = Assert.IsType<LoginViewModel>(viewResult.Model);
        Assert.NotNull(model);
    }

    [Theory]
    [InlineData("Shopkeeper", "Dashboard", "Shopkeeper")]
    [InlineData("Customer", "PlaceOrder", "Customer")]
    [InlineData("DeliveryMan", "Dashboard", "Delivery")]
    [InlineData("Agent", "Dashboard", "Agent")]
    [InlineData("Company", "Dashboard", null)]
    public void AccountController_Login_WhenAuthenticated_RedirectsToRoleActionResult(string role, string expectedAction, string? expectedController)
    {
        var controller = new AccountController(null!, null!, null!, null!, null!, null!);
        var claims = new[]
        {
            new Claim(ClaimTypes.Name, "TestUser"),
            new Claim(ClaimTypes.Role, role)
        };
        var identity = new ClaimsIdentity(claims, "CookieAuth");
        var httpContext = new DefaultHttpContext { User = new ClaimsPrincipal(identity) };
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };

        var result = controller.Login();

        var redirectResult = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(expectedAction, redirectResult.ActionName);
        Assert.Equal(expectedController, redirectResult.ControllerName);
    }

    [Fact]
    public void AccountController_Login_WhenFieldOfficer_RedirectsToFieldForce()
    {
        var controller = new AccountController(null!, null!, null!, null!, null!, null!);
        var claims = new[]
        {
            new Claim(ClaimTypes.Name, "FieldUser"),
            new Claim(ClaimTypes.Role, "FieldOfficer")
        };
        var identity = new ClaimsIdentity(claims, "CookieAuth");
        var httpContext = new DefaultHttpContext { User = new ClaimsPrincipal(identity) };
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };

        var result = controller.Login();

        var redirectResult = Assert.IsType<RedirectResult>(result);
        Assert.Equal("/FieldForce", redirectResult.Url);
    }

    [Fact]
    public async Task AccountController_RequestPasswordResetOtp_WithInvalidPhone_ReturnsErrorJson()
    {
        var controller = new AccountController(null!, null!, null!, null!, null!, null!);
        var input = new ForgotPasswordInput { Phone = "12345" };

        var result = await controller.RequestPasswordResetOtp(input, null!);

        var jsonResult = Assert.IsType<JsonResult>(result);
        Assert.NotNull(jsonResult.Value);

        dynamic jsonVal = jsonResult.Value;
        bool success = jsonVal.GetType().GetProperty("success").GetValue(jsonVal, null);
        string message = jsonVal.GetType().GetProperty("message").GetValue(jsonVal, null);

        Assert.False(success);
        Assert.Contains("১১ সংখ্যার সঠিক মোবাইল নম্বর দিন", message);
    }
}
