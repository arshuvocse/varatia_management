using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ViewFeatures;
using Moq;
using PromotionWeb.Controllers;
using PromotionWeb.Models;
using PromotionWeb.Services;
using Xunit;

namespace PromotionWeb.Tests;

public class AdminVaratiaAndTeachLearnTests
{
    private class TestSession : ISession
    {
        private readonly Dictionary<string, byte[]> _storage = new();
        public bool IsAvailable => true;
        public string Id => "test-session-id";
        public IEnumerable<string> Keys => _storage.Keys;
        public void Clear() => _storage.Clear();
        public Task CommitAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task LoadAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
        public void Remove(string key) => _storage.Remove(key);
        public void Set(string key, byte[] value) => _storage[key] = value;
        public bool TryGetValue(string key, out byte[] value) => _storage.TryGetValue(key, out value!);
    }

    [Fact]
    public async Task TeachAndLearn_WhenNotCompany_RedirectsToLogin()
    {
        var controller = new AccountController(null!, null!, null!, null!, null!, null!, null!);
        var httpContext = new DefaultHttpContext { Session = new TestSession() };
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };

        var mockService = new Mock<IVaratiaAdminService>();

        var result = await controller.TeachAndLearn(mockService.Object);

        var redirect = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(AccountController.Login), redirect.ActionName);
    }

    [Fact]
    public async Task VaratiaManagement_WhenNotCompany_RedirectsToLogin()
    {
        var controller = new AccountController(null!, null!, null!, null!, null!, null!, null!);
        var httpContext = new DefaultHttpContext { Session = new TestSession() };
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };

        var mockService = new Mock<IVaratiaAdminService>();

        var result = await controller.VaratiaManagement(mockService.Object);

        var redirect = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(AccountController.Login), redirect.ActionName);
    }

    [Fact]
    public async Task ToggleTutorVerification_WhenNotCompany_RedirectsToLogin()
    {
        var controller = new AccountController(null!, null!, null!, null!, null!, null!, null!);
        var httpContext = new DefaultHttpContext { Session = new TestSession() };
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };

        var mockService = new Mock<IVaratiaAdminService>();

        var result = await controller.ToggleTutorVerification("TUT-001", mockService.Object);

        var redirect = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(AccountController.Login), redirect.ActionName);
    }

    [Fact]
    public async Task DeleteTutorPost_WhenNotCompany_RedirectsToLogin()
    {
        var controller = new AccountController(null!, null!, null!, null!, null!, null!, null!);
        var httpContext = new DefaultHttpContext { Session = new TestSession() };
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };

        var mockService = new Mock<IVaratiaAdminService>();

        var result = await controller.DeleteTutorPost("TUT-001", mockService.Object);

        var redirect = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(AccountController.Login), redirect.ActionName);
    }

    [Fact]
    public async Task ToggleTutorVerification_WhenCompany_TogglesAndRedirects()
    {
        var controller = new AccountController(null!, null!, null!, null!, null!, null!, null!);
        var session = new TestSession();
        session.SetString("UserRole", Roles.Company);
        var httpContext = new DefaultHttpContext { Session = session };
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };
        controller.TempData = new TempDataDictionary(httpContext, Mock.Of<ITempDataProvider>());

        var mockService = new Mock<IVaratiaAdminService>();
        mockService.Setup(s => s.ToggleTutorPostVerificationAsync("TUT-001", It.IsAny<CancellationToken>()))
                   .ReturnsAsync(true);

        var result = await controller.ToggleTutorVerification("TUT-001", mockService.Object);

        var redirect = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(AccountController.TeachAndLearn), redirect.ActionName);
        Assert.True(controller.TempData.ContainsKey("CompanyMessage"));
    }

    [Fact]
    public async Task DeleteTutorPost_WhenCompany_DeletesAndRedirects()
    {
        var controller = new AccountController(null!, null!, null!, null!, null!, null!, null!);
        var session = new TestSession();
        session.SetString("UserRole", Roles.Company);
        var httpContext = new DefaultHttpContext { Session = session };
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };
        controller.TempData = new TempDataDictionary(httpContext, Mock.Of<ITempDataProvider>());

        var mockService = new Mock<IVaratiaAdminService>();
        mockService.Setup(s => s.DeleteTutorPostAsync("TUT-001", It.IsAny<CancellationToken>()))
                   .ReturnsAsync(true);

        var result = await controller.DeleteTutorPost("TUT-001", mockService.Object);

        var redirect = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(AccountController.TeachAndLearn), redirect.ActionName);
        Assert.True(controller.TempData.ContainsKey("CompanyMessage"));
    }

    [Fact]
    public async Task ToggleGeneralPostStatus_WhenCompany_TogglesAndRedirects()
    {
        var controller = new AccountController(null!, null!, null!, null!, null!, null!, null!);
        var session = new TestSession();
        session.SetString("UserRole", Roles.Company);
        var httpContext = new DefaultHttpContext { Session = session };
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };
        controller.TempData = new TempDataDictionary(httpContext, Mock.Of<ITempDataProvider>());

        var mockService = new Mock<IVaratiaAdminService>();
        mockService.Setup(s => s.ToggleGeneralPostStatusAsync(101, It.IsAny<CancellationToken>()))
                   .ReturnsAsync(true);

        var result = await controller.ToggleGeneralPostStatus(mockService.Object, 101);

        var redirect = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(AccountController.VaratiaManagement), redirect.ActionName);
        Assert.Equal("generalposts", redirect.RouteValues?["tab"]);
        Assert.True(controller.TempData.ContainsKey("CompanyMessage"));
    }

    [Fact]
    public async Task ToggleGeneralPostVerification_WhenCompany_TogglesAndRedirects()
    {
        var controller = new AccountController(null!, null!, null!, null!, null!, null!, null!);
        var session = new TestSession();
        session.SetString("UserRole", Roles.Company);
        var httpContext = new DefaultHttpContext { Session = session };
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };
        controller.TempData = new TempDataDictionary(httpContext, Mock.Of<ITempDataProvider>());

        var mockService = new Mock<IVaratiaAdminService>();
        mockService.Setup(s => s.ToggleGeneralPostVerificationAsync(101, It.IsAny<CancellationToken>()))
                   .ReturnsAsync(true);

        var result = await controller.ToggleGeneralPostVerification(mockService.Object, 101);

        var redirect = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(AccountController.VaratiaManagement), redirect.ActionName);
        Assert.Equal("generalposts", redirect.RouteValues?["tab"]);
        Assert.True(controller.TempData.ContainsKey("CompanyMessage"));
    }

    [Fact]
    public async Task GrantPostingCredits_WhenCompany_GrantsAndRedirects()
    {
        var controller = new AccountController(null!, null!, null!, null!, null!, null!, null!);
        var session = new TestSession();
        session.SetString("UserRole", Roles.Company);
        var httpContext = new DefaultHttpContext { Session = session };
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };
        controller.TempData = new TempDataDictionary(httpContext, Mock.Of<ITempDataProvider>());

        var mockService = new Mock<IVaratiaAdminService>();
        mockService.Setup(s => s.GrantPostingCreditsAsync("user-01", 5, It.IsAny<CancellationToken>()))
                   .ReturnsAsync(true);

        var result = await controller.GrantPostingCredits(mockService.Object, "user-01", 5);

        var redirect = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(AccountController.VaratiaManagement), redirect.ActionName);
        Assert.Equal("generalposts", redirect.RouteValues?["tab"]);
        Assert.True(controller.TempData.ContainsKey("CompanyMessage"));
    }
}

