import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_session_service.dart';
import '../../../data/services/registration_payment_api_service.dart';
import 'registration_fee_gate.dart';

class UserPaymentHistoryScreen extends StatefulWidget {
  const UserPaymentHistoryScreen({super.key});

  @override
  State<UserPaymentHistoryScreen> createState() => _UserPaymentHistoryScreenState();
}

class _UserPaymentHistoryScreenState extends State<UserPaymentHistoryScreen> {
  final RegistrationPaymentApiService _apiService = RegistrationPaymentApiService();
  final AuthSessionService _sessionService = AuthSessionService();

  bool _isLoading = true;
  String? _errorMessage;
  UserPaymentHistory? _history;
  RegistrationStatus? _regStatus;
  String _selectedFilter = 'all'; // all, reg, monthly, rent
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
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

      if (userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ইউজার সেশন পাওয়া যায়নি। অনুগ্রহ করে লগইন করুন।';
        });
        return;
      }

      final results = await Future.wait([
        _apiService.getUserPaymentHistory(userId),
        _apiService.getRegistrationStatus(userId),
      ]);

      if (!mounted) return;

      setState(() {
        _history = results[0] as UserPaymentHistory;
        _regStatus = results[1] as RegistrationStatus;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<PaymentHistoryItem> get _filteredPayments {
    final list = _history?.payments ?? [];
    if (_selectedFilter == 'reg') {
      return list.where((p) => p.paymentType.toLowerCase().contains('registration')).toList();
    }
    if (_selectedFilter == 'monthly') {
      return list.where((p) => p.paymentType.toLowerCase().contains('monthly')).toList();
    }
    if (_selectedFilter == 'rent') {
      return list.where((p) => p.paymentType.toLowerCase().contains('rent')).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('পেমেন্ট ও লেনদেন হিস্ট্রি'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 56),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('পুনরায় চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      );
    }

    final payments = _filteredPayments;
    final totalPaid = _history?.totalPaid ?? 0.0;
    final isUnpaidReg = _regStatus != null && _regStatus!.isRequired && !_regStatus!.isPaid;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Registration fee pending alert banner if unpaid
          if (isUnpaidReg) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'রেজিস্ট্রেশন ফি বকেয়া আছে',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'অ্যাকাউন্ট ভেরিফাই করতে ৳ ${_regStatus!.fee.toStringAsFixed(0)} পে করুন।',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      if (_userId != null) {
                        final paid = await ensureRegistrationFeePaid(context, userId: _userId!);
                        if (paid) {
                          _loadData();
                        }
                      }
                    },
                    child: const Text('পে করুন'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Total Collection / Paid Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.elevated,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'মোট সফল পেমেন্ট',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _regStatus?.isPaid == true ? 'ভেরিফাইড ইউজার' : 'ইউজার অ্যাকাউন্ট',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '৳ ${totalPaid.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SummaryChip(
                      label: 'মোট লেনদেন: ${_history?.payments.length ?? 0}',
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(width: 8),
                    _SummaryChip(
                      label: 'SSLCommerz সুরক্ষিত',
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Filter Segmented Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'সব (${_history?.payments.length ?? 0})',
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'রেজিস্ট্রেশন ফি',
                  isSelected: _selectedFilter == 'reg',
                  onTap: () => setState(() => _selectedFilter = 'reg'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'মাসিক সার্ভিস চার্জ',
                  isSelected: _selectedFilter == 'monthly',
                  onTap: () => setState(() => _selectedFilter = 'monthly'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'ভাড়ার রশিদ',
                  isSelected: _selectedFilter == 'rent',
                  onTap: () => setState(() => _selectedFilter = 'rent'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Transactions List
          if (payments.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text(
                    'কোনো লেনদেন রেকর্ড পাওয়া যায়নি',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'আপনার পেমেন্ট সম্পন্ন হলে বিস্তারিত এখানে প্রদর্শিত হবে।',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...payments.map((payment) => _PaymentCard(payment: payment)),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final PaymentHistoryItem payment;

  @override
  Widget build(BuildContext context) {
    final isSuccess = payment.isSuccess;
    final isPending = payment.isPending;
    final isReg = payment.paymentType.toLowerCase().contains('registration');
    final isRent = payment.paymentType.toLowerCase().contains('rent');

    Color iconBgColor = const Color(0xFFE0E7FF);
    Color iconColor = const Color(0xFF4338CA);
    IconData iconData = Icons.payments_rounded;

    if (isReg) {
      iconBgColor = const Color(0xFFEDE9FE);
      iconColor = const Color(0xFF7C3AED);
      iconData = Icons.verified_user_rounded;
    } else if (isRent) {
      iconBgColor = const Color(0xFFD1FAE5);
      iconColor = const Color(0xFF059669);
      iconData = Icons.home_work_rounded;
    }

    final date = payment.paymentDate ?? payment.createdOn;
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.title.isNotEmpty ? payment.title : payment.paymentType,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳ ${payment.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isSuccess ? const Color(0xFF059669) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? const Color(0xFFDCFCE7)
                          : isPending
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isSuccess
                          ? '✓ সফল'
                          : isPending
                              ? '⏳ পেন্ডিং'
                              : '✕ ব্যর্থ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSuccess
                            ? const Color(0xFF166534)
                            : isPending
                                ? const Color(0xFF92400E)
                                : const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: payment.transactionId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ট্রানজেকশন আইডি কপি করা হয়েছে')),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      payment.transactionId,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  payment.gateway,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
