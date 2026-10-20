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
        var controller = new AccountController(null!, null!, null!, null!, null!, null!, null!);
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
        var controller = new AccountController(null!, null!, null!, null!, null!, null!, null!);
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
        var controller = new AccountController(null!, null!, null!, null!, null!, null!, null!);
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
        var controller = new AccountController(null!, null!, null!, null!, null!, null!, null!);
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

    [Fact]
    public void Test_SeedTeamMembers()
    {
        var connStr = "Server=104.234.134.230\\MSSQLSERVER2022;Database=SmartBazarDbmssql;User Id=amarthi1_db;Password=Shuvo**10;TrustServerCertificate=True;";
        using var conn = new Microsoft.Data.SqlClient.SqlConnection(connStr);
        conn.Open();

        using var cmd = new Microsoft.Data.SqlClient.SqlCommand("""
            DECLARE @DhakaId INT, @CtgId INT, @SylhetId INT, @RajshahiId INT;
            SELECT TOP 1 @DhakaId = Id FROM dbo.tbl_Districts WHERE Name LIKE N'%Dhaka%' OR Name LIKE N'%ঢাকা%' ORDER BY Id;
            SELECT TOP 1 @CtgId = Id FROM dbo.tbl_Districts WHERE Name LIKE N'%Chatto%' OR Name LIKE N'%Chittagong%' OR Name LIKE N'%চট্টগ্রাম%' ORDER BY Id;
            SELECT TOP 1 @SylhetId = Id FROM dbo.tbl_Districts WHERE Name LIKE N'%Sylhet%' OR Name LIKE N'%সিলেট%' ORDER BY Id;
            SELECT TOP 1 @RajshahiId = Id FROM dbo.tbl_Districts WHERE Name LIKE N'%Rajshahi%' OR Name LIKE N'%রাজশাহী%' ORDER BY Id;

            IF @DhakaId IS NULL SELECT TOP 1 @DhakaId = Id FROM dbo.tbl_Districts;
            IF @CtgId IS NULL SELECT TOP 1 @CtgId = Id FROM dbo.tbl_Districts WHERE Id <> @DhakaId;
            IF @CtgId IS NULL SET @CtgId = @DhakaId;
            IF @SylhetId IS NULL SELECT TOP 1 @SylhetId = Id FROM dbo.tbl_Districts WHERE Id NOT IN (@DhakaId, @CtgId);
            IF @SylhetId IS NULL SET @SylhetId = @DhakaId;
            IF @RajshahiId IS NULL SELECT TOP 1 @RajshahiId = Id FROM dbo.tbl_Districts WHERE Id NOT IN (@DhakaId, @CtgId, @SylhetId);
            IF @RajshahiId IS NULL SET @RajshahiId = @DhakaId;

            -- 1. Agent: মোঃ রফিকুল ইসলাম (Dhaka)
            DECLARE @Agent1Id INT;
            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01711000101')
            BEGIN
                INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, IsActive, CreatedAt, ProfilePictureUrl)
                VALUES (N'মোঃ রফিকুল ইসলাম', '01711000101', '1234', N'Agent', 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80');
                SET @Agent1Id = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                SELECT @Agent1Id = Id FROM dbo.tbl_Users WHERE Phone = '01711000101';
            END

            IF @Agent1Id IS NOT NULL AND @DhakaId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.tbl_AgentDistricts WHERE AgentUserId = @Agent1Id)
            BEGIN
                INSERT INTO dbo.tbl_AgentDistricts (AgentUserId, DistrictId) VALUES (@Agent1Id, @DhakaId);
            END

            -- 2. FieldOfficer: তানভীর আহমেদ (under Agent 1)
            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01812000202')
            BEGIN
                INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, ParentUserId, IsActive, CreatedAt, ProfilePictureUrl)
                VALUES (N'তানভীর আহমেদ', '01812000202', '1234', N'FieldOfficer', @Agent1Id, 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80');
            END

            -- 3. Agent: আব্দুল কাদের (Chittagong)
            DECLARE @Agent2Id INT;
            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01913000303')
            BEGIN
                INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, IsActive, CreatedAt, ProfilePictureUrl)
                VALUES (N'আব্দুল কাদের', '01913000303', '1234', N'Agent', 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&auto=format&fit=crop&q=80');
                SET @Agent2Id = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                SELECT @Agent2Id = Id FROM dbo.tbl_Users WHERE Phone = '01913000303';
            END

            IF @Agent2Id IS NOT NULL AND @CtgId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.tbl_AgentDistricts WHERE AgentUserId = @Agent2Id)
            BEGIN
                INSERT INTO dbo.tbl_AgentDistricts (AgentUserId, DistrictId) VALUES (@Agent2Id, @CtgId);
            END

            -- 4. FieldOfficer: মাহমুদুল হাসান (under Agent 2)
            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01714000404')
            BEGIN
                INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, ParentUserId, IsActive, CreatedAt, ProfilePictureUrl)
                VALUES (N'মাহমুদুল হাসান', '01714000404', '1234', N'FieldOfficer', @Agent2Id, 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200&auto=format&fit=crop&q=80');
            END

            -- 5. Agent: সাইফুল ইসলাম (Sylhet)
            DECLARE @Agent3Id INT;
            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01515000505')
            BEGIN
                INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, IsActive, CreatedAt, ProfilePictureUrl)
                VALUES (N'সাইফুল ইসলাম', '01515000505', '1234', N'Agent', 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&auto=format&fit=crop&q=80');
                SET @Agent3Id = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                SELECT @Agent3Id = Id FROM dbo.tbl_Users WHERE Phone = '01515000505';
            END

            IF @Agent3Id IS NOT NULL AND @SylhetId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.tbl_AgentDistricts WHERE AgentUserId = @Agent3Id OR DistrictId = @SylhetId)
            BEGIN
                INSERT INTO dbo.tbl_AgentDistricts (AgentUserId, DistrictId) VALUES (@Agent3Id, @SylhetId);
            END

            -- 6. FieldOfficer: মেহেদী হাসান রনি (under Agent 3)
            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01616000606')
            BEGIN
                INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, ParentUserId, IsActive, CreatedAt, ProfilePictureUrl)
                VALUES (N'মেহেদী হাসান রনি', '01616000606', '1234', N'FieldOfficer', @Agent3Id, 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=200&auto=format&fit=crop&q=80');
            END

            -- 7. Agent: আরিফুল হক (Rajshahi)
            DECLARE @Agent4Id INT;
            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Phone = '01817000707')
            BEGIN
                INSERT INTO dbo.tbl_Users (Name, Phone, PasswordHash, Role, IsActive, CreatedAt, ProfilePictureUrl)
                VALUES (N'আরিফুল হক', '01817000707', '1234', N'Agent', 1, SYSUTCDATETIME(), 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80');
                SET @Agent4Id = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                SELECT @Agent4Id = Id FROM dbo.tbl_Users WHERE Phone = '01817000707';
            END

            IF @Agent4Id IS NOT NULL AND @RajshahiId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.tbl_AgentDistricts WHERE AgentUserId = @Agent4Id OR DistrictId = @RajshahiId)
            BEGIN
                INSERT INTO dbo.tbl_AgentDistricts (AgentUserId, DistrictId) VALUES (@Agent4Id, @RajshahiId);
            END
        """, conn);

        cmd.ExecuteNonQuery();

        using var readCmd = new Microsoft.Data.SqlClient.SqlCommand("SELECT COUNT(1) FROM dbo.tbl_Users WHERE Role IN (N'Agent', N'FieldOfficer');", conn);
        var configMock = new Moq.Mock<Microsoft.Extensions.Configuration.IConfiguration>();
        var connSection = new Moq.Mock<Microsoft.Extensions.Configuration.IConfigurationSection>();
        connSection.Setup(x => x["DefaultConnection"]).Returns(connStr);
        connSection.Setup(x => x.Value).Returns(connStr);
        configMock.Setup(x => x.GetSection("ConnectionStrings")).Returns(connSection.Object);

        var store = new PromotionWeb.Services.AppStore(configMock.Object);
        var list = store.GetTeamDirectory();
        Assert.NotEmpty(list);
    }

    [Fact]
    public void AdminVaratiaManagementViewModel_RegistrationFee_DefaultsAreCorrect()
    {
        var model = new AdminVaratiaManagementViewModel();

        Assert.Equal(50.00m, model.RegistrationFee);
        Assert.True(model.IsRegistrationFeeActive);
        Assert.Empty(model.SslCommerzPayments);
        Assert.Equal(0m, model.TotalRegistrationFeesCollected);
        Assert.Equal(0m, model.TotalMonthlyFeesCollected);
    }

    [Fact]
    public void CompanySettingsViewModel_RegistrationFee_DefaultsAreCorrect()
    {
        var model = new CompanySettingsViewModel();

        Assert.Equal(50.00m, model.RegistrationFee);
        Assert.True(model.IsRegistrationFeeActive);
    }

    [Fact]
    public void CompanySettingsInputModel_CanSetRegistrationFee()
    {
        var input = new CompanySettingsInputModel
        {
            RegistrationFee = 100.00m,
            IsRegistrationFeeActive = false
        };

        Assert.Equal(100.00m, input.RegistrationFee);
        Assert.False(input.IsRegistrationFeeActive);
    }

    [Fact]
    public void OrderProcessContracts_RegistrationFeeStatusResponse_PropertiesCheck()
    {
        var response = new OrderProcessAPI.Contracts.RegistrationFeeStatusResponse
        {
            UserId = "user-123",
            IsPaid = true,
            IsRequired = false,
            Fee = 75.00m,
            Currency = "BDT",
            TransactionId = "REG-12345",
            PaidAt = DateTime.UtcNow
        };

        Assert.Equal("user-123", response.UserId);
        Assert.True(response.IsPaid);
        Assert.False(response.IsRequired);
        Assert.Equal(75.00m, response.Fee);
        Assert.Equal("BDT", response.Currency);
        Assert.Equal("REG-12345", response.TransactionId);
        Assert.NotNull(response.PaidAt);
    }
}
