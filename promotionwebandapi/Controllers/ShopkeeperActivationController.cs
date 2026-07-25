using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

public sealed class ShopkeeperActivationController(
    AppStore appStore,
    ShopkeeperActivationStore activationStore,
    SslCommerzService sslCommerz,
    IConfiguration configuration) : Controller
{
    [HttpGet]
    public IActionResult Index()
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");
        if (activationStore.IsActivated(shop.Id)) return RedirectToAction("Dashboard", "Shopkeeper");

        return View(new ShopkeeperActivationViewModel
        {
            Shop = shop,
            Amount = sslCommerz.ActivationFee,
            IsConfigured = sslCommerz.IsConfigured,
            LatestPayment = activationStore.GetLatest(shop.Id)
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Pay()
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");
        if (activationStore.IsActivated(shop.Id)) return RedirectToAction("Dashboard", "Shopkeeper");
        if (!sslCommerz.IsConfigured)
        {
            TempData["ActivationError"] = "SSLCOMMERZ is not configured. Add the merchant credentials first.";
            return RedirectToAction(nameof(Index));
        }

        var transactionReference = $"SA{shop.Id}-{Guid.NewGuid():N}";
        var transactionId = transactionReference[..Math.Min(30, transactionReference.Length)];
        var payment = activationStore.CreateAttempt(shop.Id, transactionId, sslCommerz.ActivationFee);
        var result = await sslCommerz.CreateSessionAsync(
            shop,
            payment.TransactionId,
            CallbackUrl(nameof(Success)),
            CallbackUrl(nameof(Fail)),
            CallbackUrl(nameof(Cancel)),
            CallbackUrl(nameof(Ipn)));

        activationStore.SetSession(payment.TransactionId, result.SessionKey, result.RawResponse);
        if (!result.Success || string.IsNullOrWhiteSpace(result.GatewayUrl))
        {
            activationStore.MarkStatus(payment.TransactionId, "Failed", result.RawResponse);
            TempData["ActivationError"] = result.Error ?? "SSLCOMMERZ payment session could not be created.";
            return RedirectToAction(nameof(Index));
        }

        return Redirect(result.GatewayUrl);
    }

    [AcceptVerbs("GET", "POST")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> Success()
    {
        var result = await ValidateCallback();
        if (result.Success)
        {
            TempData["ActivationSuccess"] = "Payment verified. Your shopkeeper account is now active.";
            return RedirectToAction("Dashboard", "Shopkeeper");
        }

        TempData["ActivationError"] = result.Message;
        return RedirectToAction(nameof(Index));
    }

    [AcceptVerbs("GET", "POST")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> Ipn()
    {
        var result = await ValidateCallback();
        return result.Success ? Ok("VALID") : BadRequest(result.Message);
    }

    [AcceptVerbs("GET", "POST")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> Fail()
    {
        var values = await ReadCallbackValues();
        if (values.TryGetValue("tran_id", out var transactionId))
            activationStore.MarkStatus(transactionId, "Failed", Serialize(values));
        TempData["ActivationError"] = "Payment failed. No activation fee was recorded.";
        return RedirectToAction(nameof(Index));
    }

    [AcceptVerbs("GET", "POST")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> Cancel()
    {
        var values = await ReadCallbackValues();
        if (values.TryGetValue("tran_id", out var transactionId))
            activationStore.MarkStatus(transactionId, "Cancelled", Serialize(values));
        TempData["ActivationError"] = "Payment was cancelled.";
        return RedirectToAction(nameof(Index));
    }

    private async Task<(bool Success, string Message)> ValidateCallback()
    {
        var values = await ReadCallbackValues();
        if (!values.TryGetValue("tran_id", out var transactionId)
            || !values.TryGetValue("val_id", out var validationId)
            || string.IsNullOrWhiteSpace(transactionId)
            || string.IsNullOrWhiteSpace(validationId))
            return (false, "Payment callback is missing required verification data.");

        var payment = activationStore.GetByTransactionId(transactionId);
        if (payment is null) return (false, "Payment transaction was not found.");
        if (payment.Status == "Paid") return (true, "Payment was already verified.");

        var validation = await sslCommerz.ValidateAsync(validationId);
        var validCurrency = string.Equals(validation.Currency, payment.Currency, StringComparison.OrdinalIgnoreCase);
        var validAmount = validation.Amount == payment.Amount;
        var validTransaction = string.Equals(validation.TransactionId, payment.TransactionId, StringComparison.Ordinal);

        if (!validation.IsValid || !validCurrency || !validAmount || !validTransaction || validation.RiskLevel != 0)
        {
            activationStore.MarkStatus(payment.TransactionId, "Failed", validation.RawResponse);
            return (false, validation.RiskLevel == 1
                ? "Payment is marked as risky and requires manual review."
                : validation.Error ?? "Payment could not be verified.");
        }

        return activationStore.MarkPaid(payment, validation)
            ? (true, "Payment verified.")
            : (false, "Payment verification could not be saved.");
    }

    private async Task<Dictionary<string, string>> ReadCallbackValues()
    {
        var values = Request.Query.ToDictionary(x => x.Key, x => x.Value.ToString(), StringComparer.OrdinalIgnoreCase);
        if (Request.HasFormContentType)
        {
            var form = await Request.ReadFormAsync();
            foreach (var item in form) values[item.Key] = item.Value.ToString();
        }
        return values;
    }

    private string CallbackUrl(string action)
    {
        var configuredBaseUrl = configuration["SslCommerz:PublicBaseUrl"]?.TrimEnd('/');
        if (!string.IsNullOrWhiteSpace(configuredBaseUrl))
            return $"{configuredBaseUrl}{Url.Action(action, "ShopkeeperActivation")}";
        return Url.Action(action, "ShopkeeperActivation", null, Request.Scheme)
            ?? throw new InvalidOperationException("Payment callback URL could not be generated.");
    }

    private Shopkeeper? GetCurrentShop()
    {
        if (HttpContext.Session.GetString("UserRole") != Roles.Shopkeeper) return null;
        return appStore.GetShopkeeperByPhone(HttpContext.Session.GetString("UserPhone") ?? "");
    }

    private static string Serialize(IReadOnlyDictionary<string, string> values) =>
        string.Join("&", new[] { "status", "tran_id", "error", "failedreason" }
            .Where(values.ContainsKey)
            .Select(key => $"{key}={values[key]}"));
}
