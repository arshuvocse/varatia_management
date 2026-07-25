import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_context.dart';
import 'smart_bazar_welcome_page.dart';
import 'smart_bazar_view_model.dart';

enum SmartBazarRole { customer, shopkeeper, fieldOfficer }

class SmartBazarDashboardScreen extends StatefulWidget {
  const SmartBazarDashboardScreen({
    super.key,
    required this.initialRole,
    required this.userId,
    this.fullName = '',
    this.phoneNumber = '',
  });

  final SmartBazarRole initialRole;
  final String userId;
  final String fullName;
  final String phoneNumber;

  @override
  State<SmartBazarDashboardScreen> createState() =>
      _SmartBazarDashboardScreenState();
}

class _SmartBazarDashboardScreenState extends State<SmartBazarDashboardScreen> {
  late SmartBazarRole _currentRole;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataForCurrentRole();
    });
  }

  void _fetchDataForCurrentRole() {
    final viewModel = context.read<SmartBazarViewModel>();
    final userId = widget.userId.trim();
    if (userId.isEmpty) {
      viewModel.setError(
        'Smart Bazar session was not found. Please log in again.',
      );
      return;
    }
    switch (_currentRole) {
      case SmartBazarRole.customer:
        viewModel.loadCustomerDashboard(userId);
        break;
      case SmartBazarRole.shopkeeper:
        viewModel.loadShopkeeperDashboard(userId);
        break;
      case SmartBazarRole.fieldOfficer:
        viewModel.loadFieldOfficerDashboard(userId);
        break;
    }
  }

  void _switchRole(SmartBazarRole role) {
    if (_currentRole == role) return;
    setState(() {
      _currentRole = role;
      _currentTab = 0;
    });
    _fetchDataForCurrentRole();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the Smart Bazar ViewModel
    final viewModel = context.watch<SmartBazarViewModel>();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          drawer: _buildDrawer(),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(child: _buildBody(viewModel)),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(viewModel),
        ),
        if (_currentRole == SmartBazarRole.shopkeeper &&
            viewModel.isShopPaymentDue)
          _buildPaymentOverlay(viewModel),
      ],
    );
  }

  Widget _buildPaymentOverlay(SmartBazarViewModel viewModel) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 48,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr(bn: 'মাসিক ফি বকেয়া', en: 'Monthly Fee Due'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    bn: 'দোকানদার ড্যাশবোর্ড ব্যবহার চালিয়ে যেতে দয়া করে SSL Commerz-এর মাধ্যমে মাসিক ৫০ টাকা ফি পরিশোধ করুন।',
                    en: 'Please pay the monthly fee of 50 TK using SSL Commerz to continue using the Shopkeeper Dashboard.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      viewModel.processMonthlyPayment(widget.userId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr(
                              bn: 'পেমেন্ট সফল হয়েছে!',
                              en: 'Payment Successful!',
                            ),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      context.tr(
                        bn: 'SSL Commerz দিয়ে ৫০ ৳ পে করুন',
                        en: 'Pay 50 TK via SSL Commerz',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- DRAWER ---
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          children: [
            Text(
              context.tr(bn: 'রোল পরিবর্তন করুন', en: 'Switch Role'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildRoleDrawerItem(
              role: SmartBazarRole.customer,
              title: context.tr(bn: 'গ্রাহক (Customer)', en: 'Customer App'),
              icon: Icons.person_outline_rounded,
              color: const Color(0xFF10B981),
            ),
            _buildRoleDrawerItem(
              role: SmartBazarRole.shopkeeper,
              title: context.tr(
                bn: 'দোকানদার (Shopkeeper)',
                en: 'Shopkeeper App',
              ),
              icon: Icons.storefront_rounded,
              color: const Color(0xFF3B82F6),
            ),
            _buildRoleDrawerItem(
              role: SmartBazarRole.fieldOfficer,
              title: context.tr(
                bn: 'ফিল্ড অফিসার (Field Officer)',
                en: 'Field Officer App',
              ),
              icon: Icons.badge_outlined,
              color: const Color(0xFF8B5CF6),
            ),
            const Divider(height: 40),
            if (widget.fullName.trim().isNotEmpty ||
                widget.phoneNumber.trim().isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(
                  widget.fullName.trim().isEmpty
                      ? context.tr(
                          bn: 'Smart Bazar User',
                          en: 'Smart Bazar User',
                        )
                      : widget.fullName.trim(),
                ),
                subtitle: widget.phoneNumber.trim().isEmpty
                    ? null
                    : Text(widget.phoneNumber.trim()),
              ),
              const Divider(height: 24),
            ],
            ListTile(
              leading: const Icon(
                Icons.exit_to_app_rounded,
                color: Colors.redAccent,
              ),
              title: Text(context.tr(bn: 'লগ আউট', en: 'Log Out')),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const SmartBazarWelcomePage(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDrawerItem({
    required SmartBazarRole role,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _currentRole == role;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? color : const Color(0xFF64748B),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : AppColors.textPrimary,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: color)
            : null,
        onTap: () {
          _switchRole(role);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // --- BODY ROUTER ---
  Widget _buildBody(SmartBazarViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load data: ${viewModel.errorMessage}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchDataForCurrentRole,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return switch (_currentRole) {
      SmartBazarRole.customer => _buildCustomerDashboard(viewModel),
      SmartBazarRole.shopkeeper => _buildShopkeeperDashboard(viewModel),
      SmartBazarRole.fieldOfficer => _buildFieldOfficerDashboard(viewModel),
    };
  }

  // --- CUSTOMER DASHBOARD ---
  Widget _buildCustomerDashboard(SmartBazarViewModel viewModel) {
    final themeColor = const Color(0xFF10B981); // Green

    // Get transactions relevant to customer (purchases, cashbacks, withdrawals)
    final listTxns = viewModel.transactions.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Builder(
                builder: (context) => InkWell(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(bn: 'স্বাগতম, রাকিব', en: 'Welcome, Rakib'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    context.tr(bn: '০১৭১২-৩৪৫৬৭৮', en: '01712-345678'),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => _showNoticesDialog(viewModel),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Wallet Balance Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F9F68), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr(bn: 'ওয়ালেট ব্যালেন্স', en: 'Wallet Balance'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '৳ ${viewModel.customerWalletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showWithdrawDialog(viewModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: themeColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        context.tr(bn: 'ব্যালেন্স তুলুন', en: 'Withdraw'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${context.tr(bn: 'মোট ক্যাশব্যাক', en: 'Total Cashback')}: ৳ ${viewModel.customerTotalCashback.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Action Grid (4 items)
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              _buildQuickActionItem(
                icon: Icons.qr_code_scanner_rounded,
                label: context.tr(bn: 'কিউআর স্ক্যান', en: 'QR Scan'),
                color: themeColor,
                onTap: () => _showQRScanDialog(viewModel),
              ),
              _buildQuickActionItem(
                icon: Icons.receipt_long_rounded,
                label: context.tr(bn: 'লেনদেন হিসাব', en: 'History'),
                color: themeColor,
                onTap: () => _showTransactionsDialog(viewModel),
              ),
              _buildQuickActionItem(
                icon: Icons.card_giftcard_rounded,
                label: context.tr(bn: 'আমার অফার', en: 'My Offer'),
                color: themeColor,
                onTap: () => _showOffersDialog(viewModel),
              ),
              _buildQuickActionItem(
                icon: Icons.share_rounded,
                label: context.tr(bn: 'রেফার করুন', en: 'Refer'),
                color: themeColor,
                onTap: () => _showReferDialog(viewModel),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Promotional Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '%',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(
                          bn: 'প্রতিটি কেনাকাটায় ২% ক্যাশব্যাক পান',
                          en: 'Get 2% Cashback on every purchase',
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr(
                          bn: 'ইনস্ট্যান্ট ওয়ালেটে যোগ হবে',
                          en: 'Instantly added to your wallet',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Custom Basket Illustration using stack/containers
                const _BasketIllustration(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent Transactions Section
          _buildRecentTransactionsHeader(
            () => _showTransactionsDialog(viewModel),
          ),
          const SizedBox(height: 12),
          if (listTxns.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  context.tr(
                    bn: 'কোনো লেনদেন পাওয়া যায়নি।',
                    en: 'No transactions found.',
                  ),
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ...listTxns.map((txn) {
              return _buildTransactionItem(
                storeName: txn.title,
                time: txn.subtitle,
                amount:
                    '${txn.isCredit ? "" : "-"}৳ ${txn.amount.toStringAsFixed(2)}',
                cashback: txn.cashback > 0
                    ? '+৳ ${txn.cashback.toStringAsFixed(2)}'
                    : '',
                isCredit: txn.isCredit,
                iconColor: themeColor,
              );
            }),
        ],
      ),
    );
  }

  // --- SHOPKEEPER DASHBOARD ---
  Widget _buildShopkeeperDashboard(SmartBazarViewModel viewModel) {
    final themeColor = const Color(0xFF3B82F6); // Blue

    // Get list of sales transactions
    final shopSales = viewModel.transactions
        .where((t) => t.type == 'sale')
        .take(4)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Builder(
                builder: (context) => InkWell(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(bn: 'মা স্টোর', en: 'Ma Store'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    context.tr(
                      bn: 'দোকান কোড: MS1001',
                      en: 'Store Code: MS1001',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => _showNoticesDialog(viewModel),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Shopkeeper Wallet Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F9F68), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr(bn: 'ওয়ালেট ব্যালেন্স', en: 'Wallet Balance'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '৳ ${viewModel.shopWalletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddBalanceDialog(viewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F9F68),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 20,
                    ),
                    label: Text(
                      context.tr(
                        bn: 'SSL Commerz দিয়ে ব্যালেন্স অ্যাড করুন',
                        en: 'Add Balance via SSL Commerz',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sales Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr(bn: 'আজকের বিক্রি', en: "Today's Sale"),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '৳ ${viewModel.shopTodaySales.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${context.tr(bn: 'এই মাসের বিক্রি', en: "This Month's Sale")}: ৳ ${viewModel.shopMonthlySales.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Action Grid (4 items)
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              _buildQuickActionItem(
                icon: Icons.add_circle_outline_rounded,
                label: context.tr(bn: 'সেল করুন', en: 'Sell'),
                color: themeColor,
                onTap: () => _showSellDialog(viewModel),
              ),
              _buildQuickActionItem(
                icon: Icons.list_alt_rounded,
                label: context.tr(bn: 'লেনদেন তালিকা', en: 'Trans. List'),
                color: themeColor,
                onTap: () => _showTransactionsDialog(viewModel),
              ),
              _buildQuickActionItem(
                icon: Icons.people_outline_rounded,
                label: context.tr(bn: 'কাস্টমার তালিকা', en: 'Customers'),
                color: themeColor,
                onTap: () => _showCustomerListDialog(viewModel),
              ),
              _buildQuickActionItem(
                icon: Icons.analytics_outlined,
                label: context.tr(bn: 'রিপোর্ট', en: 'Reports'),
                color: themeColor,
                onTap: () => _showReportsDialog(viewModel),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cashback Commission Card (৩%)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr(
                        bn: 'ক্যাশব্যাক কমিশন (৩%)',
                        en: 'Cashback Commission (3%)',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showReportsDialog(viewModel),
                      child: Text(
                        context.tr(bn: 'সব দেখুন >', en: 'See All >'),
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildCommissionStat(
                        label: context.tr(
                          bn: 'গ্রাহক ক্যাশব্যাক (২%)',
                          en: 'User Cashback (2%)',
                        ),
                        value:
                            '৳ ${viewModel.shopCustomerCashback.toStringAsFixed(2)}',
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    Container(
                      height: 32,
                      width: 1,
                      color: const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: _buildCommissionStat(
                        label: context.tr(
                          bn: 'আমাদের কমিশন (১%)',
                          en: 'Our Comm. (1%)',
                        ),
                        value:
                            '৳ ${viewModel.shopCompanyCommission.toStringAsFixed(2)}',
                        color: themeColor,
                      ),
                    ),
                    Container(
                      height: 32,
                      width: 1,
                      color: const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: _buildCommissionStat(
                        label: context.tr(bn: 'মোট কমিশন', en: 'Total Comm.'),
                        value:
                            '৳ ${viewModel.shopTotalCommission.toStringAsFixed(2)}',
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent Transactions Section
          _buildRecentTransactionsHeader(
            () => _showTransactionsDialog(viewModel),
          ),
          const SizedBox(height: 12),
          if (shopSales.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  context.tr(
                    bn: 'কোনো বিক্রয় রেকর্ড পাওয়া যায়নি।',
                    en: 'No sales recorded yet.',
                  ),
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ...shopSales.map((txn) {
              return _buildTransactionItem(
                storeName: context.tr(
                  bn: 'কাস্টমার (${txn.id})',
                  en: 'Customer (${txn.id})',
                ),
                time: txn.subtitle,
                amount: '৳ ${txn.amount.toStringAsFixed(2)}',
                cashback: '৳ ${txn.cashback.toStringAsFixed(2)} ক্যাশব্যাক',
                isCredit: true,
                iconColor: themeColor,
              );
            }),
        ],
      ),
    );
  }

  // Helper for commission breakdown
  Widget _buildCommissionStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  // --- FIELD OFFICER DASHBOARD ---
  Widget _buildFieldOfficerDashboard(SmartBazarViewModel viewModel) {
    final themeColor = const Color(0xFF8B5CF6); // Purple

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Builder(
                builder: (context) => InkWell(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(bn: 'ফিল্ড অফিসার', en: 'Field Officer'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    context.tr(bn: 'মোঃ হাসান', en: 'Md. Hasan'),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Notification bell with badge "3"
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => _showNoticesDialog(viewModel),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Performance Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr(bn: 'আমার পারফরম্যান্স', en: 'My Performance'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            context.tr(bn: 'এই মাস', en: 'This Month'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 14,
                  childAspectRatio: 2.2,
                  children: [
                    _buildPerformanceMetric(
                      label: context.tr(bn: 'মোট দোকান', en: 'Total Stores'),
                      value: '${viewModel.foTotalStores}',
                    ),
                    _buildPerformanceMetric(
                      label: context.tr(
                        bn: 'সক্রিয় দোকান',
                        en: 'Active Stores',
                      ),
                      value: '${viewModel.foActiveStores}',
                    ),
                    _buildPerformanceMetric(
                      label: context.tr(bn: 'মোট বিক্রি', en: 'Total Sales'),
                      value: '৳ ${viewModel.foTotalSales.toStringAsFixed(0)}',
                    ),
                    _buildPerformanceMetric(
                      label: context.tr(
                        bn: 'আমাদের কমিশন (১%)',
                        en: 'Our Comm. (1%)',
                      ),
                      value:
                          '৳ ${viewModel.foOurCommission.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Action Grid (4 items)
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              _buildQuickActionItem(
                icon: Icons.store_rounded,
                label: context.tr(bn: 'দোকানসমূহ', en: 'Stores'),
                color: themeColor,
                onTap: () => _showStoresDialog(viewModel),
              ),
              _buildQuickActionItem(
                icon: Icons.fingerprint_rounded,
                label: context.tr(bn: 'কালেকশন', en: 'Collection'),
                color: themeColor,
                onTap: () => _showCollectionDialog(viewModel),
              ),
              _buildQuickActionItem(
                icon: Icons.campaign_rounded,
                label: context.tr(bn: 'নোটিস', en: 'Notices'),
                color: themeColor,
                onTap: () => _showNoticesDialog(viewModel),
              ),
              _buildQuickActionItem(
                icon: Icons.support_agent_rounded,
                label: context.tr(bn: 'সাপোর্ট', en: 'Support'),
                color: themeColor,
                onTap: () => _showSupportDialog(viewModel),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Store Performance list
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr(bn: 'দোকান পারফরম্যান্স', en: 'Store Performance'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: () => _showStoresDialog(viewModel),
                child: Text(
                  context.tr(bn: 'সব দেখুন >', en: 'See All >'),
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...viewModel.stores.take(4).map((store) {
            final double sales = store.totalSales;
            final double comm = store.commission;
            // Let's dynamically color the progress bar
            Color progColor = themeColor;
            if (store.progress >= 0.8) {
              progColor = const Color(0xFF10B981);
            } else if (store.progress >= 0.5) {
              progColor = Colors.orangeAccent;
            } else {
              progColor = Colors.amber;
            }

            return _buildStorePerformanceRow(
              storeName: '${store.name} (${store.code})',
              sales: '৳ ${sales.toStringAsFixed(0)}',
              commission: '৳ ${comm.toStringAsFixed(0)}',
              progress: store.progress,
              progressColor: progColor,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStorePerformanceRow({
    required String storeName,
    required String sales,
    required String commission,
    required double progress,
    required Color progressColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.store_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${context.tr(bn: 'বিক্রি', en: 'Sales')}: $sales',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${context.tr(bn: 'কমিশন', en: 'Comm')}: $commission',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  // --- GLOBAL HELPERS FOR DASHBOARDS ---
  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsHeader(VoidCallback onViewAllTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.tr(bn: 'সাম্প্রতিক লেনদেন', en: 'Recent Transactions'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        InkWell(
          onTap: onViewAllTap,
          child: Text(
            context.tr(bn: 'সব দেখুন >', en: 'See All >'),
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String storeName,
    required String time,
    required String amount,
    required String cashback,
    required bool isCredit,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isCredit
                ? iconColor.withValues(alpha: 0.1)
                : Colors.redAccent.withValues(alpha: 0.1),
            child: Icon(
              isCredit ? Icons.storefront_rounded : Icons.outbox_rounded,
              size: 18,
              color: isCredit ? iconColor : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isCredit ? AppColors.textPrimary : Colors.redAccent,
                ),
              ),
              if (cashback.isNotEmpty)
                Text(
                  cashback,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- BOTTOM NAV BAR BUILDER ---
  Widget _buildBottomNavigationBar(SmartBazarViewModel viewModel) {
    final themeColor = switch (_currentRole) {
      SmartBazarRole.customer => const Color(0xFF10B981),
      SmartBazarRole.shopkeeper => const Color(0xFF3B82F6),
      SmartBazarRole.fieldOfficer => const Color(0xFF8B5CF6),
    };

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildBottomNavItems(themeColor, viewModel),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBottomNavItems(
    Color themeColor,
    SmartBazarViewModel viewModel,
  ) {
    if (_currentRole == SmartBazarRole.customer) {
      return [
        _buildBottomNavItem(
          index: 0,
          icon: Icons.home_rounded,
          label: context.tr(bn: 'হোম', en: 'Home'),
          activeColor: themeColor,
        ),
        _buildBottomNavItem(
          index: 1,
          icon: Icons.receipt_long_rounded,
          label: context.tr(bn: 'লেনদেন', en: 'History'),
          activeColor: themeColor,
          customOnTap: () => _showTransactionsDialog(viewModel),
        ),
        _buildCenterNavButton(
          icon: Icons.qr_code_scanner_rounded,
          activeColor: themeColor,
          onTap: () => _showQRScanDialog(viewModel),
        ),
        _buildBottomNavItem(
          index: 2,
          icon: Icons.local_offer_outlined,
          label: context.tr(bn: 'অফার', en: 'Offers'),
          activeColor: themeColor,
          customOnTap: () => _showOffersDialog(viewModel),
        ),
        _buildBottomNavItem(
          index: 3,
          icon: Icons.person_outline_rounded,
          label: context.tr(bn: 'প্রোফাইল', en: 'Profile'),
          activeColor: themeColor,
          customOnTap: () => _showProfileDialog(),
        ),
      ];
    } else if (_currentRole == SmartBazarRole.shopkeeper) {
      return [
        _buildBottomNavItem(
          index: 0,
          icon: Icons.home_rounded,
          label: context.tr(bn: 'হোম', en: 'Home'),
          activeColor: themeColor,
        ),
        _buildBottomNavItem(
          index: 1,
          icon: Icons.shopping_basket_outlined,
          label: context.tr(bn: 'সেল', en: 'Sell'),
          activeColor: themeColor,
          customOnTap: () => _showSellDialog(viewModel),
        ),
        _buildCenterNavButton(
          icon: Icons.qr_code_scanner_rounded,
          activeColor: themeColor,
          onTap: () => _showSellDialog(viewModel),
        ),
        _buildBottomNavItem(
          index: 2,
          icon: Icons.analytics_outlined,
          label: context.tr(bn: 'রিপোর্ট', en: 'Reports'),
          activeColor: themeColor,
          customOnTap: () => _showReportsDialog(viewModel),
        ),
        _buildBottomNavItem(
          index: 3,
          icon: Icons.person_outline_rounded,
          label: context.tr(bn: 'প্রোফাইল', en: 'Profile'),
          activeColor: themeColor,
          customOnTap: () => _showProfileDialog(),
        ),
      ];
    } else {
      // Field Officer
      return [
        _buildBottomNavItem(
          index: 0,
          icon: Icons.home_rounded,
          label: context.tr(bn: 'হোম', en: 'Home'),
          activeColor: themeColor,
        ),
        _buildBottomNavItem(
          index: 1,
          icon: Icons.store_rounded,
          label: context.tr(bn: 'দোকান', en: 'Stores'),
          activeColor: themeColor,
          customOnTap: () => _showStoresDialog(viewModel),
        ),
        _buildCenterNavButton(
          icon: Icons.add_rounded,
          activeColor: themeColor,
          onTap: () => _showAddStoreDialog(viewModel),
        ),
        _buildBottomNavItem(
          index: 2,
          icon: Icons.analytics_outlined,
          label: context.tr(bn: 'রিপোর্ট', en: 'Reports'),
          activeColor: themeColor,
          customOnTap: () => _showReportsDialog(viewModel),
        ),
        _buildBottomNavItem(
          index: 3,
          icon: Icons.person_outline_rounded,
          label: context.tr(bn: 'প্রোফাইল', en: 'Profile'),
          activeColor: themeColor,
          customOnTap: () => _showProfileDialog(),
        ),
      ];
    }
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
    VoidCallback? customOnTap,
  }) {
    final isSelected = _currentTab == index;
    return InkWell(
      onTap: customOnTap ?? () => setState(() => _currentTab = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? activeColor : const Color(0xFF94A3B8),
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterNavButton({
    required IconData icon,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: activeColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  // ==========================================
  // SIMULATION DIALOGS & SHEET IMPLEMENTATION
  // ==========================================

  // --- QR SCAN SIMULATOR ---
  void _showQRScanDialog(SmartBazarViewModel viewModel) {
    String? selectedStoreName = viewModel.stores.isNotEmpty
        ? viewModel.stores.first.name
        : null;
    final amountController = TextEditingController();
    bool isPaying = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isPaying) {
              return Container(
                height: 380,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF10B981),
                        ),
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.tr(
                        bn: 'পেমেন্ট প্রসেসিং হচ্ছে...',
                        en: 'Processing payment...',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        bn: 'অনুগ্রহ করে অপেক্ষা করুন।',
                        en: 'Please wait a moment.',
                      ),
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr(
                          bn: 'কিউআর পেমেন্ট সিমুলেশন',
                          en: 'QR Payment Simulation',
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Mock scanner graphic
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 36,
                          color: Color(0xFF10B981),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '[ SCANNER ACTIVE ]',
                          style: TextStyle(
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Store Selection
                  Text(
                    context.tr(bn: 'দোকান নির্বাচন করুন', en: 'Select Store'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedStoreName,
                    items: viewModel.stores.map((store) {
                      return DropdownMenuItem<String>(
                        value: store.name,
                        child: Text(store.name),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedStoreName = val),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF10B981)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  Text(
                    context.tr(
                      bn: 'পেমেন্ট পরিমাণ (টাকা)',
                      en: 'Payment Amount (BDT)',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: '৳ ০.০০',
                      prefixIcon: const Icon(
                        Icons.monetization_on_outlined,
                        color: Color(0xFF10B981),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      final amountText = amountController.text.trim();
                      if (amountText.isEmpty || selectedStoreName == null) {
                        return;
                      }
                      final double? amount = double.tryParse(amountText);
                      if (amount == null || amount <= 0) return;

                      setModalState(() => isPaying = true);

                      Future.delayed(const Duration(milliseconds: 1200), () async {
                        if (!context.mounted) return;
                        // Triggers the sale
                        final category = viewModel.productCategories.firstWhere(
                          (c) => c.name.toLowerCase() == 'others',
                          orElse: () => viewModel.productCategories.isNotEmpty
                              ? viewModel.productCategories.first
                              : SmartBazarProductCategory(
                                  id: '0',
                                  name: 'Default',
                                  commissionPercent: 1.0,
                                ),
                        );
                        await viewModel.addSale(
                          shopkeeperId: widget.userId,
                          customerPhone: '01712-345678',
                          amount: amount,
                          storeName: selectedStoreName!,
                          category: category,
                        );

                        if (!mounted || !context.mounted) return;

                        Navigator.pop(context); // Close bottom sheet

                        // Show success popup
                        _showSuccessDialog(
                          title: context.tr(
                            bn: 'পেমেন্ট সফল!',
                            en: 'Payment Successful!',
                          ),
                          message: context.tr(
                            bn: '৳ ${amount.toStringAsFixed(2)} পেমেন্ট সম্পন্ন হয়েছে $selectedStoreName এ। আপনি ২% (৳ ${(amount * 0.02).toStringAsFixed(2)}) ক্যাশব্যাক পেয়েছেন!',
                            en: 'Paid ৳ ${amount.toStringAsFixed(2)} to $selectedStoreName. You received 2% (৳ ${(amount * 0.02).toStringAsFixed(2)}) cashback!',
                          ),
                          themeColor: const Color(0xFF10B981),
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.tr(
                        bn: 'পেমেন্ট সম্পন্ন করুন',
                        en: 'Complete Payment',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- WITHDRAW BALANCE DIALOG ---
  void _showWithdrawDialog(SmartBazarViewModel viewModel) {
    String selectedMethod = 'bKash';
    final numberController = TextEditingController();
    final amountController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                context.tr(
                  bn: 'ব্যালেন্স উত্তোলন করুন',
                  en: 'Withdraw Balance',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${context.tr(bn: 'সর্বোচ্চ উত্তোলনযোগ্য ব্যালেন্স', en: 'Available Balance')}: ৳ ${viewModel.customerWalletBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Method
                    Text(
                      context.tr(bn: 'পেমেন্ট গেটওয়ে', en: 'Payment Method'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      value: selectedMethod,
                      isExpanded: true,
                      items: ['bKash', 'Nagad', 'Rocket', 'Bank Account'].map((
                        m,
                      ) {
                        return DropdownMenuItem<String>(
                          value: m,
                          child: Text(m),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedMethod = val ?? 'bKash'),
                    ),
                    const SizedBox(height: 14),

                    // Account Number
                    Text(
                      context.tr(bn: 'অ্যাকাউন্ট নম্বর', en: 'Account Number'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: numberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '০১৭xx-xxxxxx',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Amount
                    Text(
                      context.tr(bn: 'পরিমাণ (৳)', en: 'Amount (৳)'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '৳ ৫০০',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr(bn: 'বাতিল', en: 'Cancel')),
                ),
                FilledButton(
                  onPressed: () async {
                    final numStr = numberController.text.trim();
                    final amtStr = amountController.text.trim();
                    if (numStr.isEmpty || amtStr.isEmpty) return;

                    final double? amount = double.tryParse(amtStr);
                    if (amount == null || amount <= 0) return;

                    if (amount > viewModel.customerWalletBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr(
                              bn: 'ওয়ালেটে পর্যাপ্ত ব্যালেন্স নেই।',
                              en: 'Insufficient wallet balance.',
                            ),
                          ),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }

                    final success = await viewModel.withdrawBalance(
                      customerId: widget.userId,
                      amount: amount,
                      method: selectedMethod,
                      number: numStr,
                    );

                    if (!mounted || !context.mounted) return;

                    if (success) {
                      Navigator.pop(context);
                      _showSuccessDialog(
                        title: context.tr(
                          bn: 'অনুরোধ সফল!',
                          en: 'Request Successful!',
                        ),
                        message: context.tr(
                          bn: '৳ ${amount.toStringAsFixed(2)} ক্যাশআউট অনুরোধ প্রসেসিং করা হচ্ছে।',
                          en: '৳ ${amount.toStringAsFixed(2)} cash-out request is being processed.',
                        ),
                        themeColor: const Color(0xFF10B981),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                  child: Text(context.tr(bn: 'সাবমিট', en: 'Submit')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- SELL DIALOG (SHOPKEEPER) ---
  void _showAddBalanceDialog(SmartBazarViewModel viewModel) {
    final amountController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            context.tr(bn: 'ব্যালেন্স অ্যাড করুন', en: 'Add Balance'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr(bn: 'অ্যামাউন্ট (টাকা)', en: 'Amount (BDT)'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '৳ ৫০০',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr(
                          bn: 'SSL Commerz এর মাধ্যমে পেমেন্ট সুরক্ষিত।',
                          en: 'Payment secured by SSL Commerz.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr(bn: 'বাতিল', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                final amtStr = amountController.text.trim();
                final double? amount = double.tryParse(amtStr);
                if (amount != null && amount > 0) {
                  viewModel.addShopWalletBalance(widget.userId, amount);
                  Navigator.pop(context);
                  _showSuccessDialog(
                    title: context.tr(
                      bn: 'ব্যালেন্স যুক্ত হয়েছে!',
                      en: 'Balance Added!',
                    ),
                    message: context.tr(
                      bn: 'আপনার ওয়ালেটে ৳ ${amount.toStringAsFixed(2)} সফলভাবে যোগ করা হয়েছে।',
                      en: '৳ ${amount.toStringAsFixed(2)} has been successfully added to your wallet.',
                    ),
                    themeColor: const Color(0xFF10B981),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: Text(context.tr(bn: 'অ্যাড করুন', en: 'Add')),
            ),
          ],
        );
      },
    );
  }

  // --- SELL DIALOG (SHOPKEEPER) ---
  void _showSellDialog(SmartBazarViewModel viewModel) {
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    SmartBazarProductCategory? selectedCategory;
    if (viewModel.productCategories.isNotEmpty) {
      selectedCategory = viewModel.productCategories.first;
    }
    double currentAmount = 0.0;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double commission = 0.0;
            if (selectedCategory != null) {
              commission =
                  currentAmount * (selectedCategory!.commissionPercent / 100);
            }
            bool isInsufficient = commission > viewModel.shopWalletBalance;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                context.tr(
                  bn: 'নতুন বিক্রয় রেকর্ড করুন',
                  en: 'Record New Sale',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Phone Number field
                    Text(
                      context.tr(
                        bn: 'কাস্টমার ফোন নম্বর',
                        en: 'Customer Phone',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '০১৭xx-xxxxxx',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Helper Quick Button
                    OutlinedButton(
                      onPressed: () {
                        phoneController.text = '01712-345678';
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size(60, 24),
                        side: const BorderSide(color: Color(0xFF3B82F6)),
                      ),
                      child: Text(
                        context.tr(
                          bn: 'রাকিব (০১৭১২-৩৪৫৬৭৮) সিলেক্ট করুন',
                          en: 'Select Rakib (01712-345678)',
                        ),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product Category
                    Text(
                      context.tr(
                        bn: 'প্রোডাক্ট ক্যাটাগরি',
                        en: 'Product Category',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<SmartBazarProductCategory>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: viewModel.productCategories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text('${c.name} (${c.commissionPercent}%)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedCategory = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    Text(
                      context.tr(
                        bn: 'মোট বিক্রির পরিমাণ (টাকা)',
                        en: 'Sale Amount (BDT)',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setDialogState(() {
                          currentAmount = double.tryParse(val) ?? 0.0;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: '৳ ১০০০',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),

                    // Commission deduction message
                    if (currentAmount > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isInsufficient
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isInsufficient
                                ? Colors.red.withValues(alpha: 0.3)
                                : Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                bn: 'কমিশন কাটা হবে: ৳ ${commission.toStringAsFixed(2)}',
                                en: 'Commission Deduction: ৳ ${commission.toStringAsFixed(2)}',
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isInsufficient
                                    ? Colors.red
                                    : const Color(0xFF047857),
                              ),
                            ),
                            if (isInsufficient) ...[
                              const SizedBox(height: 4),
                              Text(
                                context.tr(
                                  bn: 'আপনার ওয়ালেটে পর্যাপ্ত ব্যালেন্স নেই।',
                                  en: 'Insufficient wallet balance.',
                                ),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr(bn: 'বাতিল', en: 'Cancel')),
                ),
                FilledButton(
                  onPressed: isInsufficient
                      ? null
                      : () async {
                          final phone = phoneController.text.trim();
                          if (phone.isEmpty ||
                              currentAmount <= 0 ||
                              selectedCategory == null) {
                            return;
                          }

                          final success = await viewModel.addSale(
                            shopkeeperId: widget.userId,
                            customerPhone: phone,
                            amount: currentAmount,
                            storeName: 'Ma Store',
                            category: selectedCategory!,
                          );

                          if (!mounted || !context.mounted) return;

                          Navigator.pop(context); // close dialog

                          if (success) {
                            _showSuccessDialog(
                              title: context.tr(
                                bn: 'বিক্রি সফল!',
                                en: 'Sale Recorded!',
                              ),
                              message: context.tr(
                                bn: '৳ ${currentAmount.toStringAsFixed(2)} বিক্রয় রেকর্ড করা হয়েছে। কমিশন ৳ ${commission.toStringAsFixed(2)} কাটা হয়েছে।',
                                en: 'Sale of ৳ ${currentAmount.toStringAsFixed(2)} recorded. Commission ৳ ${commission.toStringAsFixed(2)} deducted.',
                              ),
                              themeColor: const Color(0xFF3B82F6),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  viewModel.errorMessage ?? 'Failed',
                                ),
                              ),
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: isInsufficient
                        ? Colors.grey
                        : const Color(0xFF3B82F6),
                  ),
                  child: Text(context.tr(bn: 'রেকর্ড করুন', en: 'Record')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- ADD STORE DIALOG (FIELD OFFICER) ---
  void _showAddStoreDialog(SmartBazarViewModel viewModel) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final ownerController = TextEditingController();
    final upazilaController = TextEditingController();
    final districtController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            context.tr(bn: 'নতুন দোকান নিবন্ধন করুন', en: 'Register New Store'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Store Name
                Text(
                  context.tr(bn: 'দোকানের নাম', en: 'Store Name'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),

                // Store Code
                Text(
                  context.tr(bn: 'দোকান কোড', en: 'Store Code'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: 'যেমন: MS1005',
                  ),
                ),
                const SizedBox(height: 10),

                // Owner Name
                Text(
                  context.tr(bn: 'মালিকের নাম', en: 'Owner Name'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: ownerController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),

                // Location info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(bn: 'উপজেলা', en: 'Upazila'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: upazilaController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(bn: 'জেলা', en: 'District'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: districtController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr(bn: 'বাতিল', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final code = codeController.text.trim();
                final owner = ownerController.text.trim();
                final upazila = upazilaController.text.trim();
                final district = districtController.text.trim();

                if (name.isEmpty ||
                    code.isEmpty ||
                    owner.isEmpty ||
                    upazila.isEmpty ||
                    district.isEmpty) {
                  return;
                }

                await viewModel.addStore(
                  fieldOfficerId: widget.userId,
                  name: name,
                  code: code,
                  ownerName: owner,
                  upazila: upazila,
                  district: district,
                );

                if (!mounted || !context.mounted) return;

                Navigator.pop(context);

                _showSuccessDialog(
                  title: context.tr(
                    bn: 'নিবন্ধন সম্পন্ন!',
                    en: 'Registration Complete!',
                  ),
                  message: context.tr(
                    bn: 'দোকান "$name" সফলভাবে নিবন্ধন করা হয়েছে।',
                    en: 'Store "$name" has been successfully registered.',
                  ),
                  themeColor: const Color(0xFF8B5CF6),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              child: Text(context.tr(bn: 'নিবন্ধন করুন', en: 'Register')),
            ),
          ],
        );
      },
    );
  }

  // --- STORES DIALOG (FIELD OFFICER STORE LIST) ---
  void _showStoresDialog(SmartBazarViewModel viewModel) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr(bn: 'নিবন্ধিত দোকানসমূহ', en: 'Registered Stores'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Color(0xFF8B5CF6),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showAddStoreDialog(viewModel);
                },
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: viewModel.stores.length,
              itemBuilder: (context, index) {
                final store = viewModel.stores[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            store.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDD6FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              store.code,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF5B21B6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${context.tr(bn: 'মালিক', en: 'Owner')}: ${store.ownerName}',
                      ),
                      Text(
                        '${context.tr(bn: 'লোকেশন', en: 'Location')}: ${store.upazila}, ${store.district}',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${context.tr(bn: 'বিক্রি', en: 'Sales')}: ৳ ${store.totalSales.toStringAsFixed(0)}',
                          ),
                          Text(
                            '${context.tr(bn: 'কমিশন', en: 'Comm')}: ৳ ${store.commission.toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr(bn: 'বন্ধ করুন', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  // --- REPORT DIALOG WITH MOCK VECTOR CHARTS ---
  void _showReportsDialog(SmartBazarViewModel viewModel) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            context.tr(
              bn: 'বিক্রয় ও কমিশন রিপোর্ট',
              en: 'Sales & Commissions Report',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(
                  bn: 'গত ৭ দিনের দৈনিক বিক্রির বিবরণ বিবরণ',
                  en: 'Daily sales status for the last 7 days',
                ),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 24),
              // Vector Growth Chart built via containers
              Container(
                height: 150,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar(40, 'Mon', context),
                    _buildBar(65, 'Tue', context),
                    _buildBar(90, 'Wed', context),
                    _buildBar(55, 'Thu', context),
                    _buildBar(110, 'Fri', context),
                    _buildBar(130, 'Sat', context),
                    _buildBar(145, 'Sun', context),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr(
                      bn: 'মোট বিক্রির লক্ষ্যমাত্রা',
                      en: 'Target Sales',
                    ),
                  ),
                  const Text(
                    '৳ ১০,০০,০০০',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr(
                      bn: 'কমিশন অর্জিত হয়েছে',
                      en: 'Commission Earned',
                    ),
                  ),
                  Text(
                    '৳ ${(viewModel.shopTotalCommission + viewModel.foOurCommission).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr(bn: 'বন্ধ করুন', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBar(double height, String label, BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 22,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // --- TRANSACTIONS HISTORY VIEW ALL ---
  void _showTransactionsDialog(SmartBazarViewModel viewModel) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            context.tr(
              bn: 'সম্পূর্ণ লেনদেন ইতিহাস',
              en: 'Full Transaction History',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: viewModel.transactions.isEmpty
                ? Center(
                    child: Text(
                      context.tr(
                        bn: 'কোনো লেনদেন নেই।',
                        en: 'No transactions.',
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: viewModel.transactions.length,
                    itemBuilder: (context, index) {
                      final txn = viewModel.transactions[index];
                      return _buildTransactionItem(
                        storeName: txn.title,
                        time: txn.subtitle,
                        amount:
                            '${txn.isCredit ? "" : "-"}৳ ${txn.amount.toStringAsFixed(2)}',
                        cashback: txn.cashback > 0
                            ? '+৳ ${txn.cashback.toStringAsFixed(2)}'
                            : '',
                        isCredit: txn.isCredit,
                        iconColor: const Color(0xFF10B981),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr(bn: 'বন্ধ করুন', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  // --- OFFERS MODAL ---
  void _showOffersDialog(SmartBazarViewModel viewModel) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            context.tr(bn: 'স্মার্টবাজার অফারসমূহ', en: 'Smart Bazar Offers'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOfferTile(
                title: context.tr(
                  bn: '১০০% ক্যাশব্যাক বোনাস',
                  en: '100% Cashback Bonus',
                ),
                desc: context.tr(
                  bn: 'প্রথম কিউআর স্ক্যান পেমেন্টে সর্বোচ্চ ৫০ টাকা বোনাস পান!',
                  en: 'Get up to ৳ 50 bonus on first scan payment!',
                ),
                code: 'FIRSTSCAN50',
              ),
              const SizedBox(height: 12),
              _buildOfferTile(
                title: context.tr(
                  bn: 'শপ সেল ধামাকা অফার',
                  en: 'Shop Sale Dhamaka',
                ),
                desc: context.tr(
                  bn: 'দোকানের মাসিক সেল ১ লাখ টাকা স্পর্শ করলে ২% অতিরিক্ত ক্যাশব্যাক কমিশন!',
                  en: 'Earn extra 2% commission upon reaching 100k sales!',
                ),
                code: 'BOOST100K',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr(bn: 'বন্ধ করুন', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOfferTile({
    required String title,
    required String desc,
    required String code,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBCFE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                color: Color(0xFFEC4899),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF9D174D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFF472B6),
                style: BorderStyle.solid,
              ),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDB2777),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REFER APP MODAL ---
  void _showReferDialog(SmartBazarViewModel viewModel) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            context.tr(bn: 'বন্ধু রেফার করুন, আয় করুন', en: 'Refer & Earn'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.share_rounded,
                color: Color(0xFF10B981),
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                context.tr(
                  bn: 'আপনার রেফারেল লিংক দিয়ে বন্ধুকে ডাউনলোড করান। তারা প্রথম পেমেন্ট করলেই আপনি পাবেন ৳৫০ বোনাস!',
                  en: 'Invite your friends using your refer link. Get ৳ 50 cash bonus on their first transaction!',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SB-9921-RAKIB',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr(
                                bn: 'রেফার কোড কপি হয়েছে!',
                                en: 'Referral code copied!',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr(bn: 'বন্ধ করুন', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  // --- COLLECTION DIALOG (OFFICER) ---
  void _showCollectionDialog(SmartBazarViewModel viewModel) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            context.tr(
              bn: 'কমিশন কালেকশন স্ট্যাটাস',
              en: 'Commission Collections',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCollectionItem('মা স্টোর', '৳ ১,২৫০', true, context),
              _buildCollectionItem('সোহেল স্টোর', '৳ ৯৮৫', true, context),
              _buildCollectionItem('রহমান স্টোর', '৳ ৭৫৪', false, context),
              _buildCollectionItem('নিউ জনতা স্টোর', '৳ ৬৫২', false, context),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr(bn: 'বন্ধ করুন', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCollectionItem(
    String shop,
    String amount,
    bool isCollected,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shop,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                amount,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCollected
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isCollected
                  ? context.tr(bn: 'গৃহীত', en: 'Received')
                  : context.tr(bn: 'বাকি', en: 'Pending'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isCollected
                    ? const Color(0xFF065F46)
                    : const Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NOTICES DIALOG ---
  void _showNoticesDialog(SmartBazarViewModel viewModel) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            context.tr(
              bn: 'স্মার্টবাজার গুরুত্বপূর্ণ নোটিশ',
              en: 'Smart Bazar Notices',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNoticeTile(
                title: context.tr(
                  bn: 'ঈদ বোনাস ক্যাম্পেইন',
                  en: 'Eid Bonus Campaign',
                ),
                date: '১৮ জুন, ২০২৬',
                content: context.tr(
                  bn: 'ঈদুল আজহা উপলক্ষে প্রতিটি রিটেইল ট্রানজেকশনে ৩% ক্যাশব্যাক দেওয়া হবে!',
                  en: 'On the occasion of Eid-ul-Adha, 3% cashback will be given on all retail transactions!',
                ),
              ),
              const SizedBox(height: 12),
              _buildNoticeTile(
                title: context.tr(
                  bn: 'সার্ভার রক্ষণাবেক্ষণ',
                  en: 'Server Maintenance Notice',
                ),
                date: '১৫ জুন, ২০২৬',
                content: context.tr(
                  bn: 'আগামী শুক্রবার রাত ১২টা থেকে ভোর ৩টা পর্যন্ত সিস্টেম আপগ্রেডেশনের কাজ চলবে।',
                  en: 'Next Friday from 12 AM to 3 AM, system maintenance will take place.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr(bn: 'বন্ধ করুন', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoticeTile({
    required String title,
    required String date,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                date,
                style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  // --- SUPPORT INFO DIALOG ---
  void _showSupportDialog(SmartBazarViewModel viewModel) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            context.tr(bn: 'গ্রাহক সেবা ও সহায়তা', en: 'Customer Support'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSupportTile(
                Icons.call_rounded,
                context.tr(bn: 'হেল্পলাইন কল করুন', en: 'Call Helpline'),
                '১৬২৪৭ (০৯:০০ AM - ০৯:০০ PM)',
              ),
              const SizedBox(height: 10),
              _buildSupportTile(
                Icons.email_outlined,
                context.tr(bn: 'ইমেইল সাপোর্ট', en: 'Email Support'),
                'support@smartbazar.com',
              ),
              const SizedBox(height: 10),
              _buildSupportTile(
                Icons.forum_outlined,
                context.tr(bn: 'লাইভ চ্যাট', en: 'Live Chat Support'),
                'm.me/smartbazar.official',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr(bn: 'বন্ধ করুন', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSupportTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- PROFILE SIMULATION ---
  void _showProfileDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            context.tr(bn: 'ব্যবহারকারী প্রোফাইল', en: 'User Profile'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFFE2E8F0),
                child: Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 14),
              Text(
                'মোঃ রাকিব হাসান (Rakib)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                '০১৭১২-৩৪৫৬৭৮',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              SizedBox(height: 12),
              Chip(
                label: Text(
                  'Premium Member',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Color(0xFFEC4899),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr(bn: 'বন্ধ করুন', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  // --- CUSTOMER LIST DIALOG (SHOPKEEPER) ---
  void _showCustomerListDialog(SmartBazarViewModel viewModel) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            context.tr(bn: 'নিয়মিত কাস্টমার তালিকা', en: 'Regular Customers'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              children: [
                _buildCustomerRow('রাকিব হাসান', '০১৭১২-৩৪৫৬৭৮', '৳ ২,৪৫০.০০'),
                _buildCustomerRow('সজীব চৌধুরী', '০১৭১৫-xxxxx', '৳ ১,৮২০.০০'),
                _buildCustomerRow('জাকির হোসাইন', '০১৮১২-xxxxx', '৳ ১,৫৬০.০০'),
                _buildCustomerRow('মিম রহমান', '০১৭৩৩-xxxxx', '৳ ১,২৪০.০০'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr(bn: 'বন্ধ করুন', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerRow(String name, String phone, String purchase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                phone,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          Text(
            purchase,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF3B82F6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --- GENERAL SUCCESS POPUP ---
  void _showSuccessDialog({
    required String title,
    required String message,
    required Color themeColor,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: themeColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            Center(
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: themeColor,
                  minimumSize: const Size(120, 40),
                ),
                child: Text(context.tr(bn: 'ঠিক আছে', en: 'Ok')),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Basket illustration for the promotional banner
class _BasketIllustration extends StatelessWidget {
  const _BasketIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 60,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background accent circle
          Positioned(
            bottom: 0,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Veggies inside the basket
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444), // Tomato red
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 28,
            child: Container(
              width: 14,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981), // Green cucumber
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            right: 14,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B), // Orange carrot
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Basket body
          Positioned(
            bottom: 4,
            child: Container(
              width: 48,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFB45309), // Wood brown basket
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: CustomPaint(painter: _BasketTexturePainter()),
            ),
          ),
          // Basket handle
          Positioned(
            bottom: 14,
            child: Container(
              width: 48,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: const Color(0xFFB45309), width: 3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BasketTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw vertical stripes to simulate woven texture
    for (double i = 8; i < size.width; i += 8) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    // Draw horizontal stripe
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
