import 'package:flutter/material.dart';

import '../../../data/services/auth_session_service.dart';
import '../../../data/services/subscription_api_service.dart';
import '../payment/ssl_commerz_payment_screen.dart';

class SubscriptionMatchmakingScreen extends StatefulWidget {
  const SubscriptionMatchmakingScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<SubscriptionMatchmakingScreen> createState() =>
      _SubscriptionMatchmakingScreenState();
}

class _SubscriptionMatchmakingScreenState
    extends State<SubscriptionMatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final SubscriptionApiService _apiService = SubscriptionApiService();
  final AuthSessionService _sessionService = AuthSessionService();

  bool _isLoading = true;
  String? _errorMessage;
  String? _userId;

  List<SubscriptionPlanItem> _plans = [];
  List<UserSubscriptionItem> _mySubscriptions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _sessionService.readSession();
      final userId = session?.userId ?? '';
      _userId = userId;

      final plansFuture = _apiService.getPlans();
      final userSubsFuture = userId.isNotEmpty
          ? _apiService.getUserSubscriptions(userId)
          : Future.value(<UserSubscriptionItem>[]);

      final results = await Future.wait([plansFuture, userSubsFuture]);
      if (mounted) {
        setState(() {
          _plans = results[0] as List<SubscriptionPlanItem>;
          _mySubscriptions = results[1] as List<UserSubscriptionItem>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _handleSubscribe(SubscriptionPlanItem plan) async {
    if (_userId == null || _userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে প্রথমে লগইন করুন।'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final requirementsController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        _getPlanIcon(plan.serviceCode),
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        plan.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'সার্ভিস ফি',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        Text(
                          '৳ ${plan.fee.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${plan.deliveryDays} কার্যদিবসে নিশ্চিত সন্ধান',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'আপনার সুনির্দিষ্ট চাহিদা ও বিবরণ লিখুন:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: requirementsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _getPlaceholder(plan.serviceCode),
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: Color(0xFF047857),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'পেমেন্ট নিশ্চিত হওয়ার পর অ্যাডমিন টিম অনুসন্ধান শুরু করবে। নির্ধারিত ${plan.deliveryDays} কার্যদিবসের মধ্যে ফলাফল জানানো হবে।',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.payment_rounded, color: Colors.white),
                  label: Text(
                    'SSLCommerz দিয়ে পেমেন্ট করুন (৳ ${plan.fee.toStringAsFixed(0)})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    final userRequirements = requirementsController.text.trim();

    // Start payment initiation
    if (!mounted) return;
    _showLoadingDialog();

    try {
      final initiationResult = await _apiService.initiateSubscriptionPayment(
        userId: _userId!,
        serviceCode: plan.serviceCode,
        userRequirements: userRequirements.isNotEmpty ? userRequirements : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Launch SSLCommerz Payment Screen
      final paymentSuccess = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => SslCommerzPaymentScreen(
            paymentUrl: initiationResult.gatewayPageUrl,
          ),
        ),
      );

      // Reload data regardless
      await _loadData();

      if (paymentSuccess == true && mounted) {
        _tabController.animateTo(1); // Switch to My Subscriptions tab
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 ${plan.title} সফলভাবে সাবস্ক্রাইব করা হয়েছে! অ্যাডমিন টিম কাজ শুরু করেছে।',
            ),
            backgroundColor: const Color(0xFF047857),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('পেমেন্ট শুরু করা যায়নি: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'SSLCommerz পেমেন্ট গেটওয়ে প্রস্তুত হচ্ছে...',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPlanIcon(String code) {
    switch (code) {
      case 'find_flat':
        return '🏢';
      case 'find_tenant':
        return '🏡';
      case 'find_tutor':
        return '👨‍🏫';
      case 'find_student':
        return '🎓';
      default:
        return '🎯';
    }
  }

  String _getPlaceholder(String code) {
    switch (code) {
      case 'find_flat':
        return 'উদাঃ মিরপুর ১০ বা শেওড়াপাড়ায় ২ বেড, ২ বাথ, বাজেট ১৫-২০ হাজার টাকা...';
      case 'find_tenant':
        return 'উদাঃ উত্তরা সেক্টর ৪-এ ৪ তলায় ৩ বেডের ফ্ল্যাট, ছোট ফ্যামিলির জন্য...';
      case 'find_tutor':
        return 'উদাঃ ক্লাস ১০ (SSC 2026) বিজ্ঞান বিভাগ, পদার্থ ও গণিত পড়ানোর দক্ষ টিউটর চাই...';
      case 'find_student':
        return 'উদাঃ ধানমন্ডি বা লালমাটিয়া এলাকায় ক্লাস ৮-১২ এর গণিত ও আইসিটি পড়াতে আগ্রহী...';
      default:
        return 'আপনার সুনির্দিষ্ট পছন্দ বা শর্তসমূহ লিখুন...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'সাবস্ক্রিপশন ও ম্যাচমেকিং',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              icon: const Icon(Icons.stars_rounded, size: 20),
              text: 'প্যাকেজ সমূহ (${_plans.length})',
            ),
            Tab(
              icon: const Icon(Icons.assignment_turned_in_rounded, size: 20),
              text: 'আমার সাবস্ক্রিপশন (${_mySubscriptions.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('পুনরায় চেষ্টা করুন'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPlansTab(),
                    _buildMySubscriptionsTab(),
                  ],
                ),
    );
  }

  Widget _buildPlansTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Hero Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Colors.amberAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'অ্যাডমিন গ্যারান্টি ম্যাচমেকিং',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'আপনার সুবিধাজনক সময়ের মধ্যে সঠিক ফ্ল্যাট, নির্ভরযোগ্য ভাড়াটিয়া, দক্ষ টিউটর কিংবা কাঙ্ক্ষিত টিউশন খুঁজতে অ্যাডমিনের প্রিমিয়াম ম্যাচমেকিং সার্ভিস গ্রহণ করুন।',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'উপলব্ধ সার্ভিসসমূহ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          ..._plans.map((plan) => _buildPlanCard(plan)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlanItem plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getPlanIcon(plan.serviceCode),
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getRoleLabel(plan.targetRole),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    '৳ ${plan.fee.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        size: 13,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${plan.deliveryDays} কার্যদিবসে নিশ্চিত সেবা (SLA)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _handleSubscribe(plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'সাবস্ক্রাইব করুন',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMySubscriptionsTab() {
    if (_mySubscriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('🎯', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 16),
              const Text(
                'কোনো সাবস্ক্রিপশন পাওয়া যায়নি',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'পছন্দের প্যাকেজ বেছে নিয়ে সাবস্ক্রাইব করুন। অ্যাডমিন টিম দ্রুত আপনার চাহিদামতো সার্ভিস প্রদান করবে।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('প্যাকেজ দেখুন'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mySubscriptions.length,
        itemBuilder: (context, index) {
          final sub = _mySubscriptions[index];
          return _buildSubscriptionItemCard(sub);
        },
      ),
    );
  }

  Widget _buildSubscriptionItemCard(UserSubscriptionItem sub) {
    Color statusColor;
    String statusText;
    if (sub.isMatched) {
      statusColor = const Color(0xFF047857);
      statusText = '✓ ম্যাচিং সম্পন্ন (Matched)';
    } else if (sub.isCancelled) {
      statusColor = const Color(0xFFDC2626);
      statusText = '✕ বাতিল';
    } else {
      statusColor = const Color(0xFF2563EB);
      statusText = '🔍 খোঁজা হচ্ছে (In Progress)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sub.isMatched
              ? const Color(0xFFA7F3D0)
              : sub.isExpired
                  ? const Color(0xFFFECACA)
                  : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              children: [
                Text(
                  _getPlanIcon(sub.serviceCode),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'ID: ${sub.transactionId}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // SLA Timeline & Countdown Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    sub.isMatched
                        ? Icons.check_circle_rounded
                        : sub.isExpired
                            ? Icons.warning_amber_rounded
                            : Icons.hourglass_top_rounded,
                    size: 20,
                    color: sub.isMatched
                        ? const Color(0xFF047857)
                        : sub.isExpired
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.isMatched
                              ? 'ম্যাচমেকিং সফলভাবে সম্পন্ন হয়েছে!'
                              : sub.isExpired
                                  ? 'নির্ধারিত সময় পার হয়েছে (${sub.remainingDays.abs()} দিন অতিবাহিত)'
                                  : 'নির্ধারিত ডেলিভারি: বাকি আর ${sub.remainingDays} দিন (${sub.deliveryDays} দিন SLA)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sub.isMatched
                                ? const Color(0xFF047857)
                                : sub.isExpired
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFB45309),
                          ),
                        ),
                        Text(
                          'ডেডলাইন: ${_formatDate(sub.deadlineAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Admin Notes if present
            if (sub.adminNotes != null && sub.adminNotes!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.campaign_rounded,
                          size: 16,
                          color: Color(0xFF047857),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'অ্যাডমিন ম্যাচিং আপডেট:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub.adminNotes!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF065F46),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // User requirements if present
            if (sub.userRequirements != null &&
                sub.userRequirements!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '📝 আপনার চাহিদা: "${sub.userRequirements!}"',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF64748B),
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Footer row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'সাবস্ক্রিপশনের তারিখ: ${_formatDate(sub.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                Text(
                  '৳ ${sub.amount.toStringAsFixed(0)} (পেইড)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(String targetRole) {
    switch (targetRole.toLowerCase()) {
      case 'tenant':
        return '👥 ভাড়াটিয়াদের জন্য';
      case 'owner':
        return '🏡 বাড়িওয়ালাদের জন্য';
      case 'student':
        return '📚 শিক্ষার্থী ও অভিভাবকদের জন্য';
      case 'teacher':
        return '👨‍🏫 শিক্ষকদের জন্য';
      default:
        return '👤 সকলের জন্য';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'জানু',
      'ফেব্রু',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টে',
      'অক্টো',
      'নভে',
      'ডিসে'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
