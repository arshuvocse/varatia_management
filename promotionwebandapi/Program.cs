using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Http.Features;
using PromotionWeb.Hubs;
using PromotionWeb.Models;
using PromotionWeb.Services;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Filters;
using OrderProcessAPI.Hubs;
using OrderProcessAPI.Middleware;
using OrderProcessAPI.Security;
using OrderProcessAPI.Services;

var builder = WebApplication.CreateBuilder(args);

const long maxGeneralPostUploadBytes = 100L * 1024L * 1024L;
builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = maxGeneralPostUploadBytes;
});
builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = maxGeneralPostUploadBytes;
});

builder.Services.AddControllersWithViews(options =>
{
    options.Filters.Add<ApiStatusResultFilter>();
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.DocInclusionPredicate((docName, apiDesc) =>
    {
        return apiDesc.ActionDescriptor.EndpointMetadata
            .Any(meta => meta is Microsoft.AspNetCore.Mvc.ApiControllerAttribute);
    });
});
builder.Services.AddSignalR();

var dataProtectionPath = Path.Combine(builder.Environment.ContentRootPath, "DataProtectionKeys");
try
{
    if (!Directory.Exists(dataProtectionPath))
    {
        Directory.CreateDirectory(dataProtectionPath);
    }
    builder.Services.AddDataProtection()
        .PersistKeysToFileSystem(new DirectoryInfo(dataProtectionPath))
        .SetApplicationName("SmartBazar");
}
catch (Exception)
{
    builder.Services.AddDataProtection()
        .SetApplicationName("SmartBazar");
}

builder.Services.AddAntiforgery(options =>
{
    options.Cookie.Name = "SmartBazar.Antiforgery";
    options.Cookie.HttpOnly = true;
    options.Cookie.SameSite = SameSiteMode.Lax;
    options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
});

builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.Cookie.Name = "SmartBazar.Auth";
        options.Cookie.HttpOnly = true;
        options.Cookie.IsEssential = true;
        options.Cookie.SameSite = SameSiteMode.Lax;
        options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        options.ExpireTimeSpan = TimeSpan.FromDays(30);
        options.SlidingExpiration = true;
        options.LoginPath = "/Account/Login";
    });
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromHours(4);
    options.Cookie.Name = "SmartBazar.Session";
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
    options.Cookie.SameSite = SameSiteMode.Lax;
    options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
});
builder.Services.AddScoped<AppStore>();
builder.Services.AddScoped<CustomerOrderStore>();
builder.Services.AddScoped<ShopkeeperSaleStore>();
builder.Services.AddScoped<ProductDistributionStore>();
builder.Services.AddScoped<ShopkeeperWalletCreditService>();
builder.Services.AddScoped<DistrictLeaderboardService>();
builder.Services.AddScoped<ShopkeeperExpenseStore>();
builder.Services.AddScoped<ShopkeeperRequestStore>();
builder.Services.AddScoped<ChatStore>();
builder.Services.AddScoped<DeliveryStore>();
builder.Services.AddScoped<ServiceRequestStore>();
builder.Services.AddScoped<ShopkeeperActivationStore>();
builder.Services.AddScoped<SosStore>();
builder.Services.AddScoped<LiveSupportStore>();
builder.Services.AddScoped<LoanStore>();
builder.Services.AddHttpClient<SslCommerzService>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(30);
});
builder.Services.AddSingleton<DeliveryApiTokenStore>();

// Varatia Options & Services Configuration
var allowedOrigins =
    builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
    ?? [];
builder.Services.AddCors(options =>
{
    options.AddPolicy(
        "AllowFlutterApp",
        policy =>
        {
            if (allowedOrigins.Length > 0)
            {
                policy
                    .WithOrigins(allowedOrigins)
                    .AllowAnyMethod()
                    .AllowAnyHeader()
                    .AllowCredentials()
                    .SetPreflightMaxAge(TimeSpan.FromHours(12));
                return;
            }

            policy
                .SetIsOriginAllowed(_ => true)
                .AllowAnyMethod()
                .AllowAnyHeader()
                .AllowCredentials()
                .SetPreflightMaxAge(TimeSpan.FromHours(12));
        });
});

builder.Services.Configure<BulkSmsBdOptions>(
    builder.Configuration.GetSection(BulkSmsBdOptions.SectionName));
builder.Services.Configure<FirebaseNotificationOptions>(
    builder.Configuration.GetSection(FirebaseNotificationOptions.SectionName));
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders =
        ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

builder.Services.AddSingleton<SqlConnectionFactory>();
builder.Services.AddSingleton<PasswordHasher>();
builder.Services.AddHttpClient<ISmsOtpService, BulkSmsBdOtpService>();
builder.Services.AddHttpClient<IMonthlyPaymentService, MonthlyPaymentService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IAccountService, AccountService>();
builder.Services.AddScoped<IFlatOwnerProfileService, FlatOwnerProfileService>();
builder.Services.AddScoped<IManagementDataService, ManagementDataService>();
builder.Services.AddScoped<IDhakaLocationService, DhakaLocationService>();
builder.Services.AddScoped<IDhakaPoliceZoneService, DhakaPoliceZoneService>();
builder.Services.AddScoped<ITenantAreaService, TenantAreaService>();
builder.Services.AddScoped<ITenantTutorService, TenantTutorService>();
builder.Services.AddScoped<ITenantOwnerInfoService, TenantOwnerInfoService>();
builder.Services.AddScoped<IOwnerPostService, OwnerPostService>();
builder.Services.AddScoped<IOwnerTenantService, OwnerTenantService>();
builder.Services.AddScoped<IPropertyManagementService, PropertyManagementService>();
builder.Services.AddScoped<ITenantPaymentService, TenantPaymentService>();
builder.Services.AddScoped<IExpenseService, ExpenseService>();
builder.Services.AddScoped<INotificationService, FirebaseNotificationService>();
builder.Services.AddScoped<ICommunicationService, CommunicationService>();
builder.Services.AddScoped<IReportService, ReportService>();
builder.Services.AddScoped<IAnnouncementService, AnnouncementService>();
builder.Services.AddScoped<IGeneralPostService, GeneralPostService>();
builder.Services.AddScoped<IPostChatService, PostChatService>();
builder.Services.AddScoped<IAdminChatService, AdminChatService>();
builder.Services.AddScoped<ISavedPostsService, SavedPostsService>();
builder.Services.AddScoped<ITenantChatService, TenantChatService>();
builder.Services.AddSingleton<IMessageRealtimeService, MessageRealtimeService>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseForwardedHeaders();
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();

var uploadsPath = Path.Combine(app.Environment.ContentRootPath, "uploads");
if (!Directory.Exists(uploadsPath))
{
    try
    {
        Directory.CreateDirectory(uploadsPath);
    }
    catch (Exception exception) when (exception is UnauthorizedAccessException or IOException)
    {
        app.Logger.LogWarning(
            exception,
            "The uploads directory could not be created at {UploadsPath}. Uploads will remain disabled until the directory exists and has Modify permission.",
            uploadsPath);
    }
}
app.UseStaticFiles();
if (Directory.Exists(uploadsPath))
{
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(uploadsPath),
        RequestPath = "/uploads"
    });
}

app.UseRouting();
app.UseCors("AllowFlutterApp");

app.Use(async (context, next) =>
{
    if (HttpMethods.IsOptions(context.Request.Method))
    {
        context.Response.StatusCode = StatusCodes.Status204NoContent;
        return;
    }

    await next();
});
app.UseMiddleware<ApiExceptionHandlingMiddleware>();
app.UseStatusCodePages(ApiStatusCodePages.WriteFailureResponseAsync);

app.UseSession();
app.UseAuthentication();
app.Use(async (context, next) =>
{
    if (context.User.Identity?.IsAuthenticated == true
        && context.Session.GetInt32("UserId") is null)
    {
        var idValue = context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var name = context.User.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value;
        var phone = context.User.FindFirst("phone")?.Value;
        var role = context.User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;

        if (int.TryParse(idValue, out var userId)
            && !string.IsNullOrWhiteSpace(name)
            && !string.IsNullOrWhiteSpace(phone)
            && !string.IsNullOrWhiteSpace(role))
        {
            context.Session.SetInt32("UserId", userId);
            context.Session.SetString("UserName", name);
            context.Session.SetString("UserPhone", phone);
            context.Session.SetString("UserRole", role);
        }
    }

    await next();
});
app.Use(async (context, next) =>
{
    var role = context.Session.GetString("UserRole");
    var userId = context.Session.GetInt32("UserId");
    var path = context.Request.Path;
    var activationPath = path.StartsWithSegments("/ShopkeeperActivation");
    var logoutPath = path.StartsWithSegments("/Account/Logout");

    if (role == Roles.Shopkeeper
        && userId is not null
        && !activationPath
        && !logoutPath)
    {
        var activationStore = context.RequestServices.GetRequiredService<ShopkeeperActivationStore>();
        if (!activationStore.IsActivatedByUserId(userId.Value))
        {
            if (context.Request.Headers.Accept.Any(x => x?.Contains("application/json", StringComparison.OrdinalIgnoreCase) == true))
            {
                context.Response.StatusCode = StatusCodes.Status402PaymentRequired;
                await context.Response.WriteAsJsonAsync(new
                {
                    success = false,
                    message = "A one-time BDT 50 activation payment is required."
                });
                return;
            }

            context.Response.Redirect("/ShopkeeperActivation");
            return;
        }
    }

    await next();
});
app.UseAuthorization();

var enableSwagger =
    app.Environment.IsDevelopment()
    || builder.Configuration.GetValue<bool>("Swagger:Enabled");

if (enableSwagger)
{
    app.UseWhen(
        context => context.Request.Path.StartsWithSegments("/swagger"),
        swaggerApp => swaggerApp.UseMiddleware<SwaggerBasicAuthMiddleware>());
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.MapControllers();

app.MapHub<ChatHub>("/hubs/chat");
app.MapHub<MessageHub>("/hubs/messages");
app.MapHub<PostChatHub>("/hubs/post-chat");
app.MapHub<AdminChatHub>("/hubs/admin-chat");
app.MapHub<LiveSupportHub>("/hubs/live-support");

app.Run();
