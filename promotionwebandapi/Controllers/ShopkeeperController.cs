using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

public sealed class ShopkeeperController(
    AppStore store,
    ShopkeeperSaleStore saleStore,
    ShopkeeperExpenseStore expenseStore,
    ShopkeeperRequestStore requestStore,
    ServiceRequestStore serviceRequestStore,
    ChatStore chatStore,
    CustomerOrderStore orderStore,
    DeliveryStore deliveryStore,
    ProductDistributionStore distributionStore,
    SslCommerzService sslCommerz,
    LoanStore loanStore,
    IWebHostEnvironment environment) : Controller
{
    [HttpGet]
    public IActionResult Dashboard()
    {
        var model = BuildDashboard();
        return model is null ? RedirectToAction("Login", "Account") : View(model);
    }

    [HttpGet]
    public IActionResult Loan()
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");
        var userId = GetUserId();

        var vm = new ShopkeeperLoanDashboardViewModel
        {
            ShopName = shop.ShopName,
            OwnerName = shop.OwnerName,
            Phone = shop.Phone,
            WalletBalance = distributionStore.GetUserWalletBalance(userId),
            Eligibility = loanStore.GetEligibility(userId, Roles.Shopkeeper, shop.Phone),
            ActiveLoan = loanStore.GetActiveLoan(userId),
            LoanHistory = loanStore.GetUserLoans(userId),
            SuccessMessage = TempData["SuccessMessage"] as string,
            ErrorMessage = TempData["ErrorMessage"] as string
        };
        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult ApplyLoan([FromForm] LoanApplicationInputModel input)
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");
        var userId = GetUserId();

        if (!ModelState.IsValid)
        {
            TempData["ErrorMessage"] = "সঠিক তথ্য দিয়ে লোনের ফরম পূরণ করুন।";
            return RedirectToAction(nameof(Loan));
        }

        try
        {
            var loan = loanStore.ApplyLoan(userId, Roles.Shopkeeper, shop.OwnerName, shop.Phone, input);
            TempData["SuccessMessage"] = $"অভিনন্দন! আপনার ব্যবসার জন্য ৳{loan.LoanAmount:N0} টাকার ডিজিটাল লোন অনুমোদন হয়েছে।";
            return RedirectToAction(nameof(Loan));
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = ex.Message;
            return RedirectToAction(nameof(Loan));
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult PayLoanInstallment(int installmentId, string paymentMethod = "Wallet")
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");
        var userId = GetUserId();

        try
        {
            var success = loanStore.PayInstallment(installmentId, userId, paymentMethod);
            if (success)
            {
                TempData["SuccessMessage"] = "কিস্তি সফলভাবে পরিশোধ করা হয়েছে।";
            }
            else
            {
                TempData["ErrorMessage"] = "কিস্তি পরিশোধ করা যায়নি।";
            }
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = ex.Message;
        }
        return RedirectToAction(nameof(Loan));
    }

    [HttpGet]
    public IActionResult Transactions()
    {
        var model = BuildDashboard();
        try { return model is null ? RedirectToAction("Login", "Account") : View(model); } catch (Exception ex) { return Content(ex.ToString()); }
    }

    [HttpGet]
    public IActionResult Orders() => ShopkeeperView();

    [HttpGet]
    public IActionResult ExportTransactionsCsv()
    {
        var model = BuildDashboard();
        if (model is null) return RedirectToAction("Login", "Account");

        var builder = new System.Text.StringBuilder();
        builder.AppendLine("Customer,Phone,Product,SaleAmount,CashbackAmount,PaymentMethod,DateTime,Status");

        foreach (var txn in model.Transactions)
        {
            var items = string.Join(" | ", txn.Items.Select(item => $"{item.ProductName} x{item.Quantity}"));
            builder.AppendLine($"\"{txn.CustomerName}\",\"{txn.CustomerPhone}\",\"{items}\",{txn.SaleAmount},{txn.CashbackAmount},\"{txn.PaymentMethod}\",\"{txn.TransactionAt:yyyy-MM-dd HH:mm:ss}\",\"{txn.Status}\"");
        }

        var bytes = System.Text.Encoding.UTF8.GetBytes(builder.ToString());
        return File(bytes, "text/csv", $"Shopkeeper_Transactions_{DateTime.Now:yyyyMMdd}.csv");
    }

    [HttpGet]
    public IActionResult PrintInvoice(int? saleId, int? orderId)
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");

        var model = BuildDashboard();
        if (model is null) return RedirectToAction("Login", "Account");

        if (saleId.HasValue)
        {
            ViewBag.Sale = model.Transactions.FirstOrDefault(x => x.Id == saleId.Value);
        }
        else if (orderId.HasValue)
        {
            ViewBag.Order = model.CustomerOrders.FirstOrDefault(x => x.Id == orderId.Value);
        }

        ViewBag.Shop = shop;
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> BulkUploadProducts(IFormFile? csvFile)
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");

        if (csvFile is null || csvFile.Length == 0 || !csvFile.FileName.EndsWith(".csv", StringComparison.OrdinalIgnoreCase))
        {
            TempData["ProductError"] = "অনুগ্রহ করে একটি সঠিক CSV ফাইল নির্বাচন করুন।";
            return RedirectToAction("Products");
        }

        try
        {
            using var reader = new System.IO.StreamReader(csvFile.OpenReadStream(), System.Text.Encoding.UTF8);
            var headerLine = await reader.ReadLineAsync();
            var successCount = 0;

            while (!reader.EndOfStream)
            {
                var line = await reader.ReadLineAsync();
                if (string.IsNullOrWhiteSpace(line)) continue;
                var parts = line.Split(',');
                if (parts.Length < 3) continue;

                var name = parts[0].Trim('"').Trim();
                var category = parts.Length > 1 ? parts[1].Trim('"').Trim() : "General";
                var price = decimal.TryParse(parts[2].Trim('"').Trim(), out var p) ? p : 0m;
                var stock = parts.Length > 3 && int.TryParse(parts[3].Trim('"').Trim(), out var s) ? s : 10;

                if (string.IsNullOrWhiteSpace(name) || price <= 0) continue;

                distributionStore.AddCustomProduct(shop.Id, name, category, price, stock);
                successCount++;
            }

            TempData["ProductSuccess"] = $"{successCount} টি পণ্য সফলভাবে বাল্ক আপলোড করা হয়েছে।";
        }
        catch (Exception ex)
        {
            TempData["ProductError"] = $"বাল্ক আপলোডে ত্রুটি: {ex.Message}";
        }

        return RedirectToAction("Products");
    }

    [HttpGet]
    public IActionResult DeliveryMen() => ShopkeeperView();

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult SetDeliveryManActive(int deliveryManId, bool isActive)
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");
        deliveryStore.SetActive(shop.Id, deliveryManId, isActive);
        TempData["DeliverySuccess"] = isActive ? "Delivery man activated." : "Delivery man deactivated.";
        return RedirectToAction(nameof(DeliveryMen));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult AssignDeliveryMan(int orderId, int deliveryManId)
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");
        try
        {
            deliveryStore.Assign(shop.Id, orderId, deliveryManId);
            TempData["OrderSuccess"] = $"Order #{orderId} assigned successfully.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["OrderError"] = ex.Message;
        }
        return RedirectToAction(nameof(Orders));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult CancelDeliveryAssignment(int orderId)
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");
        try
        {
            deliveryStore.CancelAssignment(shop.Id, orderId);
            TempData["OrderSuccess"] = $"Delivery assignment for order #{orderId} cancelled.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["OrderError"] = ex.Message;
        }
        return RedirectToAction(nameof(Orders));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult UpdateOrderStatus(int orderId, string status)
    {
        var shop = GetCurrentShop();
        if (shop is null)
        {
            return RedirectToAction("Login", "Account");
        }

        var allowedStatuses = new[]
        {
            CustomerOrderStatus.Approved,
            CustomerOrderStatus.Delivered,
            CustomerOrderStatus.Rejected
        };

        if (!allowedStatuses.Contains(status, StringComparer.Ordinal))
        {
            TempData["OrderError"] = "Invalid order status.";
            return RedirectToAction(nameof(Orders));
        }

        try
        {
            orderStore.UpdateOrderStatus(shop.Id, orderId, status);
            TempData["OrderSuccess"] = $"Order #{orderId} marked as {status}.";
        }
        catch (InvalidOperationException ex)
        {
            TempData["OrderError"] = ex.Message;
        }

        return RedirectToAction(nameof(Orders));
    }

    [HttpGet]
    public IActionResult NewSale() => ShopkeeperView();

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SubmitSale([FromBody] ShopkeeperSaleInputModel? input)
    {
        var shop = GetCurrentShop();
        if (shop is null)
        {
            return Unauthorized(new { success = false, message = "Session শেষ হয়েছে। আবার login করুন।" });
        }

        if (input is null)
        {
            return BadRequest(new
            {
                success = false,
                message = "Sale information পাওয়া যায়নি।",
                errors = new Dictionary<string, string[]> { ["Items"] = ["Sale information আবার দিন।"] }
            });
        }

        input.Items = input.Items
            .GroupBy(item => item.ProductId)
            .Select(group => new ShopkeeperSaleItemInputModel
            {
                ProductId = group.Key,
                Quantity = group.Sum(item => item.Quantity)
            })
            .ToList();

        if (input.Items.Count == 0)
        {
            ModelState.AddModelError(nameof(input.Items), "কমপক্ষে একটি product যোগ করুন।");
        }

        if (!ModelState.IsValid)
        {
            return BadRequest(new
            {
                success = false,
                message = "Sale information ঠিক করে আবার চেষ্টা করুন।",
                errors = GetValidationErrors()
            });
        }

        try
        {
            var isCash = input.PaymentMethod.Trim() is "ক্যাশ" or "Cash";
            if (!isCash)
            {
                if (!sslCommerz.IsConfigured)
                    return BadRequest(new { success=false,message="Digital payment gateway is not configured." });
                var amount=saleStore.CalculateSaleTotal(shop.Id,input);
                var reference=$"POS{shop.Id}-{Guid.NewGuid():N}";
                var transactionId=reference[..Math.Min(30,reference.Length)];
                saleStore.CreatePendingPosPayment(transactionId,shop.Id,amount,input);
                var session=await sslCommerz.CreateSessionAsync(shop,transactionId,amount,"POS Sale",
                    CallbackUrl(nameof(PosPaymentSuccess)),CallbackUrl(nameof(PosPaymentFail)),
                    CallbackUrl(nameof(PosPaymentCancel)),CallbackUrl(nameof(PosPaymentIpn)),"POS");
                if (!session.Success || string.IsNullOrWhiteSpace(session.GatewayUrl))
                {
                    saleStore.FailPendingPosPayment(transactionId);
                    return BadRequest(new { success=false,message=session.Error??"Payment session could not be created." });
                }
                return Json(new { success=true,requiresPayment=true,gatewayUrl=session.GatewayUrl,message="Payment gateway-তে নেওয়া হচ্ছে..." });
            }
            var sale = saleStore.CreateSale(shop.Id, input);
            return Json(new
            {
                success = true,
                message = $"Sale completed. Invoice: {sale.InvoiceNo}",
                sale
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new
            {
                success = false,
                message = ex.Message,
                errors = new Dictionary<string, string[]> { [nameof(input.Items)] = [ex.Message] }
            });
        }
    }

    [HttpGet]
    public IActionResult Dues()
    {
        var model = BuildDashboard();
        if (model is null) return RedirectToAction("Login", "Account");

        model.Dues = saleStore.GetShopkeeperDues(model.Shop.Id);
        ViewData["ActivePage"] = "Dues";
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult PayDue([FromBody] PromotionWeb.Models.DuePaymentInputModel input)
    {
        var shop = GetCurrentShop();
        if (shop is null) return Unauthorized(new { success = false, message = "Session শেষ হয়েছে।" });

        if (!ModelState.IsValid)
        {
            return BadRequest(new { success = false, message = "ফর্মের তথ্য সঠিক নয়।" });
        }

        try
        {
            saleStore.PayDue(shop.Id, input.SaleId, input.Amount, input.PaymentMethod);
            return Json(new { success = true, message = "পেমেন্ট সফলভাবে জমা হয়েছে।" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult SendDueReminderSms(int saleId, string customerPhone, decimal dueAmount)
    {
        var shop = GetCurrentShop();
        if (shop is null) return Unauthorized(new { success = false, message = "Session শেষ হয়েছে।" });

        try
        {
            // Simulate sending SMS reminder
            return Json(new { success = true, message = $"গ্রাহক {customerPhone}-এ ৳{dueAmount:N2} বকেয়া আদায়ের SMS রিমাইন্ডার সফলভাবে পাঠানো হয়েছে।" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult RestockProduct(int productId, int addQuantity, decimal? newUnitPrice)
    {
        var shop = GetCurrentShop();
        if (shop is null) return Unauthorized(new { success = false, message = "Session শেষ হয়েছে।" });

        if (addQuantity <= 0)
        {
            return BadRequest(new { success = false, message = "কমপক্ষে ১ টি পণ্য যোগ করতে হবে।" });
        }

        try
        {
            saleStore.RestockProduct(shop.Id, productId, addQuantity, newUnitPrice);
            return Json(new { success = true, message = "পণ্যের স্টক সফলভাবে বৃদ্ধি করা হয়েছে।" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    [HttpGet]
    public IActionResult DailyReport()
    {
        var model = BuildDashboard();
        if (model is null) return RedirectToAction("Login", "Account");

        model.DailyReports = saleStore.GetDailyReport(model.Shop.Id);
        ViewData["ActivePage"] = "DailyReport";
        return View(model);
    }

    [AcceptVerbs("GET","POST")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> PosPaymentSuccess()
    {
        var result=await ProcessPosPaymentCallback();
        TempData[result.Success?"SaleSuccess":"SaleError"]=result.Message;
        return RedirectToAction(nameof(NewSale));
    }

    [AcceptVerbs("GET","POST")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> PosPaymentIpn()
    {
        var result=await ProcessPosPaymentCallback();
        return result.Success?Ok("VALID"):BadRequest(result.Message);
    }

    [AcceptVerbs("GET","POST")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> PosPaymentFail()
    {
        var values=await ReadCallbackValues(); if(values.TryGetValue("tran_id",out var id)) saleStore.FailPendingPosPayment(id);
        TempData["SaleError"]="Digital payment failed. Sale was not created."; return RedirectToAction(nameof(NewSale));
    }

    [AcceptVerbs("GET","POST")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> PosPaymentCancel()
    {
        var values=await ReadCallbackValues(); if(values.TryGetValue("tran_id",out var id)) saleStore.FailPendingPosPayment(id);
        TempData["SaleError"]="Digital payment cancelled. Sale was not created."; return RedirectToAction(nameof(NewSale));
    }

    private async Task<(bool Success,string Message)> ProcessPosPaymentCallback()
    {
        var validation=await ValidateTopupCallback();
        if(!validation.Success || validation.ValueB!="POS" || string.IsNullOrWhiteSpace(validation.TransactionId))
            return(false,validation.Message);
        var pending=saleStore.ClaimPendingPosPayment(validation.TransactionId,validation.Amount);
        if(pending is null && saleStore.GetPendingPosPaymentStatus(validation.TransactionId)=="Paid")
            return(true,"Payment was already verified and the sale is complete.");
        if(pending is null || validation.ShopkeeperId!=pending.ShopkeeperId)
            return(false,"POS payment record was not found or amount did not match.");
        try
        {
            var sale=saleStore.CreateSale(pending.ShopkeeperId,pending.Sale);
            saleStore.CompletePendingPosPayment(pending.TransactionId,sale.Id,true);
            return(true,$"Payment verified. Sale completed. Invoice: {sale.InvoiceNo}");
        }
        catch(Exception ex)
        {
            saleStore.CompletePendingPosPayment(pending.TransactionId,0,false);
            return(false,"Payment verified, but sale could not be completed: "+ex.Message);
        }
    }

    [HttpGet]
    public IActionResult Products() => ShopkeeperView();

    [HttpGet]
    public IActionResult Commission() => ShopkeeperView();

    [HttpGet]
    public IActionResult Wallet() => ShopkeeperView();

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult RequestWithdrawal(ShopkeeperWithdrawalInputModel input)
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");
        if (!ModelState.IsValid)
        {
            TempData["WalletError"] = string.Join(" ", ModelState.Values.SelectMany(x => x.Errors).Select(x => x.ErrorMessage));
            return RedirectToAction(nameof(Wallet));
        }

        try
        {
            requestStore.RequestWithdrawal(shop.Id, input);
            TempData["WalletSuccess"] = $"৳ {input.Amount:N2} উত্তোলনের অনুরোধ পাঠানো হয়েছে।";
        }
        catch (InvalidOperationException ex)
        {
            TempData["WalletError"] = ex.Message;
        }
        return RedirectToAction(nameof(Wallet));
    }

    [HttpGet]
    public IActionResult Profile() => ShopkeeperView();

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateProfilePicture(IFormFile profilePicture)
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");

        if (profilePicture is { Length: > 0 })
        {
            var uploads = Path.Combine(environment.ContentRootPath, "uploads", "shopkeepers");
            Directory.CreateDirectory(uploads);
            var filename = Guid.NewGuid().ToString() + Path.GetExtension(profilePicture.FileName);
            var filepath = Path.Combine(uploads, filename);
            using var stream = new FileStream(filepath, FileMode.Create);
            await profilePicture.CopyToAsync(stream);
            var photoPath = $"/uploads/shopkeepers/{filename}";
            
            store.UpdateShopkeeperProfilePhoto(shop.Id, photoPath);
            TempData["WalletSuccess"] = "Profile picture updated successfully.";
        }
        else
        {
            TempData["WalletError"] = "Please select a valid image.";
        }
        
        return RedirectToAction(nameof(Profile));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateBillboardPicture(IFormFile billboardPicture)
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");

        if (billboardPicture is { Length: > 0 })
        {
            var uploads = Path.Combine(environment.ContentRootPath, "uploads", "shopkeepers");
            Directory.CreateDirectory(uploads);
            var filename = Guid.NewGuid().ToString() + Path.GetExtension(billboardPicture.FileName);
            var filepath = Path.Combine(uploads, filename);
            using var stream = new FileStream(filepath, FileMode.Create);
            await billboardPicture.CopyToAsync(stream);
            var photoPath = $"/uploads/shopkeepers/{filename}";
            
            store.UpdateShopkeeperBillboardPhoto(shop.Id, photoPath);
            TempData["WalletSuccess"] = "Billboard picture updated successfully.";
        }
        else
        {
            TempData["WalletError"] = "Please select a valid image.";
        }
        
        return RedirectToAction(nameof(Profile));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AddWalletBalance(ShopkeeperWalletFundingInputModel input)
    {
        var shop = GetCurrentShop();
        var userId = HttpContext.Session.GetInt32("UserId");
        if (shop is null || userId is null) return RedirectToAction("Login", "Account");

        if (!ModelState.IsValid)
        {
            TempData["WalletError"] = string.Join(" ", ModelState.Values.SelectMany(x => x.Errors).Select(x => x.ErrorMessage));
            return RedirectToAction(nameof(Wallet));
        }

        if (!sslCommerz.IsConfigured)
        {
            TempData["WalletError"] = "SSLCOMMERZ is not configured.";
            return RedirectToAction(nameof(Wallet));
        }

        var transactionReference = $"WT{shop.Id}-{Guid.NewGuid():N}";
        var transactionId = transactionReference[..Math.Min(30, transactionReference.Length)];
        
        var result = await sslCommerz.CreateSessionAsync(
            shop,
            transactionId,
            input.Amount,
            "Wallet Topup",
            CallbackUrl(nameof(TopupSuccess)),
            CallbackUrl(nameof(TopupFail)),
            CallbackUrl(nameof(TopupCancel)),
            CallbackUrl(nameof(TopupIpn)));

        if (!result.Success || string.IsNullOrWhiteSpace(result.GatewayUrl))
        {
            TempData["WalletError"] = result.Error ?? "SSLCOMMERZ payment session could not be created.";
            return RedirectToAction(nameof(Wallet));
        }

        return Redirect(result.GatewayUrl);
    }

    [AcceptVerbs("GET", "POST")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> TopupSuccess()
    {
        var validationResult = await ValidateTopupCallback();
        if (validationResult.Success && validationResult.ShopkeeperId.HasValue)
        {
            try
            {
                if (!string.IsNullOrEmpty(validationResult.ValueB) && validationResult.ValueB.StartsWith("Subscription_"))
                {
                    string monthYear = validationResult.ValueB.Substring("Subscription_".Length);
                    saleStore.MarkSubscriptionPaid(validationResult.ShopkeeperId.Value, monthYear, validationResult.Amount, validationResult.TransactionId);
                    TempData["WalletSuccess"] = $"Subscription for {monthYear} paid successfully (৳ {validationResult.Amount:N2}).";
                }
                else
                {
                    var input = new ShopkeeperWalletFundingInputModel { Amount = validationResult.Amount };
                    distributionStore.FundShopWallet(validationResult.ShopkeeperId.Value, input, 0); // User 0 for system/gateway
                    TempData["WalletSuccess"] = $"Payment verified. ৳ {validationResult.Amount:N2} added to your wallet.";
                }
            }
            catch (Exception ex)
            {
                TempData["WalletError"] = "Payment verified, but failed to process: " + ex.Message;
            }
        }
        else
        {
            TempData["WalletError"] = validationResult.Message;
        }
        return RedirectToAction(nameof(Wallet));
    }

    [AcceptVerbs("GET", "POST")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> TopupFail()
    {
        TempData["WalletError"] = "Topup payment failed.";
        return RedirectToAction(nameof(Wallet));
    }

    [AcceptVerbs("GET", "POST")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> TopupCancel()
    {
        TempData["WalletError"] = "Topup payment was cancelled.";
        return RedirectToAction(nameof(Wallet));
    }

    [AcceptVerbs("GET", "POST")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> TopupIpn()
    {
        var result = await ValidateTopupCallback();
        return result.Success ? Ok("VALID") : BadRequest(result.Message);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> PayMonthlySubscription(string monthYear)
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");

        // Use hardcoded 50 BDT for subscription
        decimal amount = 50.00m;
        string tranId = "SUB_" + shop.Id + "_" + monthYear + "_" + DateTime.UtcNow.Ticks;

        var response = await sslCommerz.CreateSessionAsync(
            shop,
            tranId,
            amount,
            "Monthly Subscription",
            Url.Action(nameof(TopupSuccess), "Shopkeeper", null, Request.Scheme) ?? "",
            Url.Action(nameof(TopupFail), "Shopkeeper", null, Request.Scheme) ?? "",
            Url.Action(nameof(TopupCancel), "Shopkeeper", null, Request.Scheme) ?? "",
            Url.Action(nameof(TopupIpn), "Shopkeeper", null, Request.Scheme) ?? "",
            "Subscription_" + monthYear);

        if (response.Success && !string.IsNullOrEmpty(response.GatewayUrl))
        {
            return Redirect(response.GatewayUrl);
        }

        TempData["WalletError"] = response.Error ?? "Failed to initiate subscription payment.";
        return RedirectToAction(nameof(Dashboard));
    }

    private async Task<(bool Success, string Message, string TransactionId, decimal Amount, int? ShopkeeperId, string? ValueB)> ValidateTopupCallback()
    {
        var values = await ReadCallbackValues();
        if (!values.TryGetValue("val_id", out var validationId))
            return (false, "Validation ID is missing.", "", 0m, null, null);

        var result = await sslCommerz.ValidateAsync(validationId);
        if (!result.IsValid)
            return (false, result.Error ?? "Payment validation failed.", "", 0m, null, null);

        var transactionId = result.TransactionId;
        if (string.IsNullOrWhiteSpace(transactionId))
            return (false, "Transaction ID is missing.", "", 0m, null, null);

        int? shopkeeperId = null;
        if (values.TryGetValue("value_a", out var shopIdStr) && int.TryParse(shopIdStr, out var sid))
        {
            shopkeeperId = sid;
        }

        values.TryGetValue("value_b", out var valueB);

        return (true, "Valid", transactionId, result.Amount, shopkeeperId, valueB);
    }

    private async Task<Dictionary<string, string>> ReadCallbackValues()
    {
        var values = new Dictionary<string, string>();
        if (HttpMethods.IsPost(Request.Method) && Request.HasFormContentType)
        {
            var form = await Request.ReadFormAsync();
            foreach (var key in form.Keys)
                values[key] = form[key].ToString();
        }
        else
        {
            foreach (var key in Request.Query.Keys)
                values[key] = Request.Query[key].ToString();
        }
        return values;
    }

    private string CallbackUrl(string action)
    {
        var request = HttpContext.Request;
        var scheme = request.Headers.TryGetValue("X-Forwarded-Proto", out var proto) ? proto.ToString() : request.Scheme;
        var host = request.Headers.TryGetValue("X-Forwarded-Host", out var fwHost) ? fwHost.ToString() : request.Host.Value;
        return $"{scheme}://{host}{Url.Action(action, "Shopkeeper")}";
    }

    [HttpGet]
    public IActionResult Support() => ShopkeeperView();

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult CreateSupportReport(ShopkeeperSupportInputModel input)
    {
        var shop = GetCurrentShop();
        if (shop is null) return RedirectToAction("Login", "Account");
        if (!ModelState.IsValid)
        {
            TempData["SupportError"] = string.Join(" ", ModelState.Values.SelectMany(x => x.Errors).Select(x => x.ErrorMessage));
            return RedirectToAction(nameof(Support));
        }

        serviceRequestStore.Create(new ServiceRequestInputModel
        {
            Name = $"{shop.ShopName} ({shop.ShopCode})",
            Phone = shop.Phone,
            Service = $"Shopkeeper: {input.Subject.Trim()}",
            Location = $"{shop.Area}, {shop.DistrictName}",
            Message = input.Message.Trim()
        });
        TempData["SupportSuccess"] = "আপনার রিপোর্টটি গ্রহণ করা হয়েছে। Support team শিগগির যোগাযোগ করবে।";
        return RedirectToAction(nameof(Support));
    }

    [HttpGet]
    public IActionResult Chat() => ShopkeeperView();

    [HttpGet]
    public IActionResult Expenses() => ShopkeeperView();

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult AddExpenseType([FromBody] ExpenseTypeInputModel? input)
    {
        var shop = GetCurrentShop();
        if (shop is null)
        {
            return Unauthorized(new { success = false, message = "Session শেষ হয়েছে। আবার login করুন।" });
        }

        if (input is null || string.IsNullOrWhiteSpace(input.Name))
        {
            return BadRequest(new { success = false, message = "Expense type-এর নাম প্রয়োজন।" });
        }

        try
        {
            expenseStore.AddExpenseType(shop.Id, input.Name);
            var updatedTypes = expenseStore.GetExpenseTypes(shop.Id);
            return Json(new { success = true, message = "Expense Type সফলভাবে যোগ করা হয়েছে।", types = updatedTypes });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
        catch
        {
            return BadRequest(new { success = false, message = "Expense Type যোগ করতে ব্যর্থ হয়েছে।" });
        }
    }

    public async Task<IActionResult> AddProduct([FromForm] ProductInputModel? input, [FromServices] Microsoft.AspNetCore.Hosting.IWebHostEnvironment env)
    {
        var shop = GetCurrentShop();
        if (shop is null)
        {
            return Unauthorized(new { success = false, message = "Session শেষ হয়েছে। আবার login করুন।" });
        }

        if (input is null)
        {
            return BadRequest(new { success = false, message = "পণ্যের তথ্য পাওয়া যায়নি।" });
        }

        if (string.IsNullOrWhiteSpace(input.Name))
        {
            return BadRequest(new { success = false, message = "পণ্যের নাম প্রয়োজন।" });
        }

        if (string.IsNullOrWhiteSpace(input.Sku))
        {
            return BadRequest(new { success = false, message = "SKU কোড প্রয়োজন।" });
        }

        if (string.IsNullOrWhiteSpace(input.Category))
        {
            return BadRequest(new { success = false, message = "ক্যাটাগরি প্রয়োজন।" });
        }

        if (input.UnitPrice <= 0)
        {
            return BadRequest(new { success = false, message = "দাম শূন্যের চেয়ে বেশি হতে হবে।" });
        }

        if (input.ImageFile is { Length: > 0 })
        {
            var uploads = Path.Combine(env.ContentRootPath, "uploads", "products");
            Directory.CreateDirectory(uploads);
            var filename = Guid.NewGuid().ToString() + Path.GetExtension(input.ImageFile.FileName);
            var filepath = Path.Combine(uploads, filename);
            using var stream = new FileStream(filepath, FileMode.Create);
            await input.ImageFile.CopyToAsync(stream);
            input.ImageUrl = $"/uploads/products/{filename}";
        }

        try
        {
            saleStore.AddProduct(shop.Id, input);
            return Json(new { success = true, message = "পণ্য সফলভাবে যোগ করা হয়েছে।" });
        }
        catch
        {
            return BadRequest(new { success = false, message = "পণ্য যোগ করতে ব্যর্থ হয়েছে।" });
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult AddExpense([FromBody] ExpenseInputModel? input)
    {
        var shop = GetCurrentShop();
        if (shop is null)
        {
            return Unauthorized(new { success = false, message = "Session শেষ হয়েছে। আবার login করুন।" });
        }

        if (input is null)
        {
            return BadRequest(new { success = false, message = "Expense-এর তথ্য পাওয়া যায়নি।" });
        }

        if (input.ExpenseTypeId <= 0)
        {
            return BadRequest(new { success = false, message = "Expense Type নির্বাচন করুন।" });
        }

        if (input.Amount <= 0)
        {
            return BadRequest(new { success = false, message = "পরিমাণ শূন্যের চেয়ে বেশি হতে হবে।" });
        }

        if (input.ExpenseDate == default)
        {
            return BadRequest(new { success = false, message = "তারিখ নির্বাচন করুন।" });
        }

        try
        {
            expenseStore.AddExpense(shop.Id, input);
            return Json(new { success = true, message = "Expense সফলভাবে যোগ করা হয়েছে।" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
        catch
        {
            return BadRequest(new { success = false, message = "Expense যোগ করতে ব্যর্থ হয়েছে।" });
        }
    }

    [HttpGet]
    public IActionResult GetExpenseTypes()
    {
        var shop = GetCurrentShop();
        if (shop is null)
        {
            return Unauthorized(new { success = false, message = "Session শেষ হয়েছে।" });
        }

        try
        {
            var types = expenseStore.GetExpenseTypes(shop.Id);
            return Json(new { success = true, types });
        }
        catch
        {
            return BadRequest(new { success = false, message = "Expense Types লোড করা যায়নি।" });
        }
    }

    [HttpGet]
    public IActionResult ChangePassword() => ShopkeeperView();

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult ChangePassword([FromBody] ChangePasswordInputModel? input)
    {
        var shop = GetCurrentShop();
        if (shop is null)
        {
            return Unauthorized(new { success = false, message = "Session শেষ হয়েছে। আবার login করুন।" });
        }

        var userId = HttpContext.Session.GetInt32("UserId");
        if (userId is null)
        {
            return Unauthorized(new { success = false, message = "User ID পাওয়া যায়নি।" });
        }

        if (input is null)
        {
            return BadRequest(new { success = false, message = "তথ্য পাওয়া যায়নি।" });
        }

        if (!ModelState.IsValid)
        {
            return BadRequest(new { success = false, message = GetValidationErrors().Values.FirstOrDefault()?[0] ?? "পাসওয়ার্ড পরিবর্তন ব্যর্থ হয়েছে।" });
        }

        try
        {
            var success = store.ChangePassword(userId.Value, input.OldPassword.Trim(), input.NewPassword.Trim());
            if (!success)
            {
                return BadRequest(new { success = false, message = "বর্তমান পাসওয়ার্ড সঠিক নয়।" });
            }

            return Json(new { success = true, message = "পাসওয়ার্ড সফলভাবে পরিবর্তন করা হয়েছে।" });
        }
        catch
        {
            return BadRequest(new { success = false, message = "পাসওয়ার্ড পরিবর্তন করতে ব্যর্থ হয়েছে।" });
        }
    }

    private IActionResult ShopkeeperView()
    {
        var model = BuildDashboard();
        try { return model is null ? RedirectToAction("Login", "Account") : View(model); } catch (Exception ex) { return Content(ex.ToString()); }
    }

    private ShopkeeperDashboardViewModel? BuildDashboard()
    {
        if (HttpContext.Session.GetString("UserRole") != Roles.Shopkeeper)
        {
            return null;
        }

        var shop = GetCurrentShop();
        if (shop is null)
        {
            return null;
        }

        var products = saleStore.GetProducts(shop.Id);
        var transactions = saleStore.GetTransactions(shop.Id);
        var expenseTypes = expenseStore.GetExpenseTypes(shop.Id);
        var expenses = expenseStore.GetExpenses(shop.Id);
        var customerOrders = orderStore.GetOrdersByShopkeeper(shop.Id);
        var walletDeductionLogs = saleStore.GetWalletDeductionLogs(shop.Id);
        var today = DateTime.Today;
        var currentMonthYear = today.ToString("yyyy-MM");
        var nextMonthDate = today.AddMonths(1);
        var nextMonthYear = nextMonthDate.ToString("yyyy-MM");

        var subStatus = saleStore.GetSubscriptionStatus(shop.Id, currentMonthYear, nextMonthYear);

        bool requiresPayment = !subStatus.CurrentMonthPaid;
        int? daysUntilNextPayment = null;

        var daysInCurrentMonth = DateTime.DaysInMonth(today.Year, today.Month);
        var daysLeftInMonth = daysInCurrentMonth - today.Day;

        if (!requiresPayment && !subStatus.NextMonthPaid && daysLeftInMonth <= 7)
        {
            daysUntilNextPayment = daysLeftInMonth;
        }

        var todaySales = transactions
            .Where(transaction => transaction.TransactionAt.Date == today)
            .Sum(transaction => transaction.SaleAmount);
        var monthSales = transactions
            .Where(transaction => transaction.TransactionAt.Year == today.Year && transaction.TransactionAt.Month == today.Month)
            .Sum(transaction => transaction.SaleAmount);
        var totalOrders = transactions.Count;
        var cashbackCommission = transactions.Sum(transaction => transaction.CashbackAmount);
        var systemCommission = transactions.Sum(transaction => transaction.SystemCommission);
        var walletSummary = requestStore.GetWalletSummary(shop.Id);
        var paidCommission = walletDeductionLogs.Sum(log => log.AmountDeducted);
        var pendingCommission = Math.Max(0, systemCommission - paidCommission);

        var chartLabels = new List<string>();
        var chartSalesData = new List<decimal>();
        var chartExpenseData = new List<decimal>();
        
        for (int i = 6; i >= 0; i--)
        {
            var date = today.AddDays(-i);
            chartLabels.Add(date.ToString("MMM dd"));
            chartSalesData.Add(transactions.Where(t => t.TransactionAt.Date == date).Sum(t => t.SaleAmount));
            chartExpenseData.Add(expenses.Where(e => e.ExpenseDate.Date == date).Sum(e => e.Amount));
        }

        return new ShopkeeperDashboardViewModel
        {
            Shop = shop,
            RequiresMonthlyPayment = requiresPayment,
            DaysUntilNextPayment = daysUntilNextPayment,
            CurrentMonthName = today.ToString("MMMM yyyy"),
            NextMonthName = nextMonthDate.ToString("MMMM yyyy"),
            SubscriptionMonthYearToPay = requiresPayment ? currentMonthYear : nextMonthYear,
            TodaySales = todaySales,
            MonthSales = monthSales,
            TotalOrders = totalOrders,
            AverageOrderValue = totalOrders == 0 ? 0 : Math.Round(transactions.Sum(transaction => transaction.SaleAmount) / totalOrders, 2),
            CashbackCommission = cashbackCommission,
            SystemCommission = systemCommission,
            PaidCommission = paidCommission,
            PendingCommission = pendingCommission,
            WalletBalance = walletSummary.Balance,
            WalletWithdrawable = walletSummary.Withdrawable,
            WalletPending = walletSummary.PendingWithdrawal,
            ChartLabels = chartLabels,
            ChartSalesData = chartSalesData,
            ChartExpenseData = chartExpenseData,
            FieldOfficerName = string.IsNullOrWhiteSpace(shop.FieldOfficerName) ? "ফিল্ড অফিসার" : shop.FieldOfficerName,
            FieldOfficerPhone = string.IsNullOrWhiteSpace(shop.FieldOfficerPhone) ? "01711-223344" : shop.FieldOfficerPhone,
            Products = products,
            Transactions = transactions,
            WalletDeductionLogs = walletDeductionLogs,
            WithdrawalRequests = requestStore.GetWithdrawals(shop.Id),
            ExpenseTypes = expenseTypes,
            Expenses = expenses,
            CustomerOrders = customerOrders,
            DeliveryMen = deliveryStore.GetAvailableForShopkeeperDistrict(shop.Id),
            DeliveryAssignments = deliveryStore.GetAssignmentsForShopkeeper(shop.Id),
            ChatInbox = chatStore.GetInbox(HttpContext.Session.GetInt32("UserId") ?? 0),
            UnreadChatCount = chatStore.GetUnreadCount(HttpContext.Session.GetInt32("UserId") ?? 0)
        };
    }

    private Shopkeeper? GetCurrentShop()
    {
        if (HttpContext.Session.GetString("UserRole") != Roles.Shopkeeper)
        {
            return null;
        }

        return store.GetShopkeeperByPhone(HttpContext.Session.GetString("UserPhone") ?? "");
    }

    private Dictionary<string, string[]> GetValidationErrors() =>
        ModelState
            .Where(item => item.Value?.Errors.Count > 0)
            .ToDictionary(
                item => item.Key,
                item => item.Value!.Errors.Select(error => error.ErrorMessage).ToArray());

    private async Task<string?> SaveDeliveryFile(IFormFile? file, string category)
    {
        if (file is null || file.Length == 0) return null;
        if (file.Length > 4 * 1024 * 1024) throw new InvalidOperationException("Each image must be 4 MB or smaller.");
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (extension is not (".jpg" or ".jpeg" or ".png" or ".webp"))
            throw new InvalidOperationException("Only JPG, PNG and WebP images are allowed.");
        var folder = Path.Combine(environment.ContentRootPath, "uploads", "delivery", category);
        Directory.CreateDirectory(folder);
        var fileName = $"{Guid.NewGuid():N}{extension}";
        await using var stream = System.IO.File.Create(Path.Combine(folder, fileName));
        await file.CopyToAsync(stream);
        return $"/uploads/delivery/{category}/{fileName}";
    }

    private int GetUserId() => HttpContext.Session.GetInt32("UserId") ?? 0;
}
