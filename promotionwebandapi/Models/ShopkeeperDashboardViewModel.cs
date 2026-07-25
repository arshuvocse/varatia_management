namespace PromotionWeb.Models;

public sealed class ShopkeeperDashboardViewModel
{
    public Shopkeeper Shop { get; init; } = default!;
    public decimal TodaySales { get; init; }
    public decimal MonthSales { get; init; }
    public int TotalOrders { get; init; }
    public decimal AverageOrderValue { get; init; }
    public decimal CashbackCommission { get; init; }
    public decimal SystemCommission { get; init; }
    public decimal PaidCommission { get; init; }
    public decimal PendingCommission { get; init; }

    // Chart Data
    public List<string> ChartLabels { get; set; } = new();
    public List<decimal> ChartSalesData { get; set; } = new();
    public List<decimal> ChartExpenseData { get; set; } = new();
    
    // Subscription properties
    public bool RequiresMonthlyPayment { get; init; }
    public int? DaysUntilNextPayment { get; init; }
    public string CurrentMonthName { get; init; } = "";
    public string NextMonthName { get; init; } = "";
    public string SubscriptionMonthYearToPay { get; init; } = "";
    
    public decimal WalletBalance { get; init; }
    public decimal WalletWithdrawable { get; init; }
    public decimal WalletPending { get; init; }
    public string SupportNumber { get; init; } = "09678-123456";
    public string FieldOfficerName { get; init; } = "";
    public string FieldOfficerPhone { get; init; } = "";
    public IReadOnlyList<ShopkeeperProductViewModel> Products { get; init; } = [];
    public IReadOnlyList<ShopkeeperTransactionViewModel> Transactions { get; init; } = [];
    public IReadOnlyList<ShopkeeperWalletDeductionLogViewModel> WalletDeductionLogs { get; init; } = [];
    public IReadOnlyList<ShopkeeperWithdrawalViewModel> WithdrawalRequests { get; init; } = [];
    public IReadOnlyList<ShopkeeperExpenseTypeViewModel> ExpenseTypes { get; init; } = [];
    public IReadOnlyList<ShopkeeperExpenseViewModel> Expenses { get; init; } = [];
    public IReadOnlyList<CustomerOrderMaster> CustomerOrders { get; init; } = [];
    public IReadOnlyList<DeliveryMan> DeliveryMen { get; init; } = [];
    public IReadOnlyList<DeliveryAssignment> DeliveryAssignments { get; init; } = [];
    public IReadOnlyList<ChatConversationViewModel> ChatInbox { get; init; } = [];
    public int UnreadChatCount { get; init; }
    public IReadOnlyList<ShopkeeperDueViewModel> Dues { get; set; } = [];
    public IReadOnlyList<DailyReportViewModel> DailyReports { get; set; } = [];
    public int PendingCustomerOrderCount =>
        CustomerOrders.Count(order => order.Status == CustomerOrderStatus.Pending);
    public int UnassignedApprovedOrderCount =>
        CustomerOrders.Count(order => order.Status == CustomerOrderStatus.Approved);
}

public sealed class ShopkeeperExpenseTypeViewModel
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
}

public sealed class ShopkeeperExpenseViewModel
{
    public int Id { get; init; }
    public int ExpenseTypeId { get; init; }
    public string ExpenseTypeName { get; init; } = "";
    public decimal Amount { get; init; }
    public DateTime ExpenseDate { get; init; }
}

public sealed class ShopkeeperProductViewModel
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
    public string Sku { get; init; } = "";
    public string Category { get; init; } = "";
    public decimal UnitPrice { get; init; }
    public decimal PurchasePrice { get; init; }
    public int StockQuantity { get; init; }
    public decimal ShopkeeperPercentage { get; init; }
    public decimal CompanyPercentage { get; init; }
    public decimal AgentPercentage { get; init; }
    public decimal FieldForcePercentage { get; init; }
    public decimal CustomerPercentage { get; init; }
    public decimal TotalCommissionPercentage =>
        CompanyPercentage + AgentPercentage + FieldForcePercentage + CustomerPercentage;
    public string? ImageUrl { get; init; }
}

public sealed class ShopkeeperWalletDeductionLogViewModel
{
    public int Id { get; init; }
    public int SaleId { get; init; }
    public string InvoiceNo { get; init; } = "";
    public int ProductId { get; init; }
    public string ProductName { get; init; } = "";
    public decimal AmountDeducted { get; init; }
    public DateTime CreatedAt { get; init; }
}

public sealed class ShopkeeperTransactionViewModel
{
    public int Id { get; init; }
    public string InvoiceNo { get; init; } = "";
    public string CustomerName { get; init; } = "";
    public string CustomerPhone { get; init; } = "";
    public decimal SaleAmount { get; init; }
    public decimal CashbackAmount { get; init; }
    public decimal SystemCommission { get; init; }
    public string PaymentMethod { get; init; } = "";
    public DateTime TransactionAt { get; init; }
    public string Status { get; init; } = "";
    public IReadOnlyList<ShopkeeperTransactionItemViewModel> Items { get; init; } = [];
}

public sealed class ShopkeeperTransactionItemViewModel
{
    public string ProductName { get; init; } = "";
    public int Quantity { get; init; }
    public decimal UnitPrice { get; init; }
    public decimal LineTotal => Quantity * UnitPrice;
}
