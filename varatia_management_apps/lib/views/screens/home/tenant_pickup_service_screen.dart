import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_context.dart';
import '../../../data/services/auth_session_service.dart';
import '../../../data/services/pickup_api_service.dart';

const int pickupFreeEligibilityMonths = 3;

bool isPickupServiceFreeEligible(DateTime? createdAt, {DateTime? now}) {
  if (createdAt == null) {
    return false;
  }

  final eligibleAt = pickupFreeEligibleAt(createdAt);
  final current = (now ?? DateTime.now()).toUtc();
  return !current.isBefore(eligibleAt);
}

DateTime pickupFreeEligibleAt(DateTime createdAt) {
  return _addCalendarMonths(createdAt.toUtc(), pickupFreeEligibilityMonths);
}

int pickupFreeRemainingDays(DateTime? createdAt, {DateTime? now}) {
  if (createdAt == null) {
    return 0;
  }

  final eligibleAt = pickupFreeEligibleAt(createdAt);
  final current = (now ?? DateTime.now()).toUtc();
  if (!current.isBefore(eligibleAt)) {
    return 0;
  }

  return (eligibleAt.difference(current).inHours / 24).ceil();
}

DateTime _addCalendarMonths(DateTime value, int months) {
  final monthIndex = value.month - 1 + months;
  final year = value.year + monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final maxDay = _daysInMonth(year, month);
  final day = value.day > maxDay ? maxDay : value.day;

  return DateTime.utc(
    year,
    month,
    day,
    value.hour,
    value.minute,
    value.second,
    value.millisecond,
    value.microsecond,
  );
}

int _daysInMonth(int year, int month) {
  return DateTime.utc(year, month + 1, 0).day;
}

class TenantPickupServiceScreen extends StatefulWidget {
  const TenantPickupServiceScreen({super.key});

  @override
  State<TenantPickupServiceScreen> createState() =>
      _TenantPickupServiceScreenState();
}

class _TenantPickupServiceScreenState extends State<TenantPickupServiceScreen> {
  static const int _paidPickupCharge = 500;

  final AuthSessionService _authSessionService = AuthSessionService();
  final PickupApiService _pickupApiService = PickupApiService();
  final TextEditingController _pickupAddressController =
      TextEditingController();
  final TextEditingController _dropAddressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  late Future<_PickupEligibilityData> _eligibilityFuture;
  String _selectedItemType = 'Furniture';

  static const List<String> _itemTypes = <String>[
    'Furniture',
    'Appliance',
    'Boxes',
    'Documents',
  ];

  @override
  void initState() {
    super.initState();
    _eligibilityFuture = _loadEligibility();
  }

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _dropAddressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<_PickupEligibilityData> _loadEligibility() async {
    final session = await _authSessionService.readSession();
    final createdAt = session?.createdAt;

    return _PickupEligibilityData(
      createdAt: createdAt,
      isFreeEligible: isPickupServiceFreeEligible(createdAt),
      eligibleAt: createdAt == null ? null : pickupFreeEligibleAt(createdAt),
      remainingDays: pickupFreeRemainingDays(createdAt),
    );
  }

  Future<void> _submitPickupRequest(_PickupEligibilityData eligibility) async {
    final pickupAddress = _pickupAddressController.text.trim();
    final dropAddress = _dropAddressController.text.trim();

    if (pickupAddress.isEmpty || dropAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              bn: 'পিকআপ ও ড্রপ ঠিকানা লিখুন।',
              en: 'Enter pickup and drop addresses.',
            ),
          ),
        ),
      );
      return;
    }

    if (eligibility.isFreeEligible) {
      await _executeSubmission(
        pickupAddress,
        dropAddress,
        _selectedItemType,
        _noteController.text,
        false,
      );
      return;
    }

    _showPaidCheckout(
      pickupAddress,
      dropAddress,
      _selectedItemType,
      _noteController.text,
    );
  }

  Future<void> _executeSubmission(
    String pickup,
    String drop,
    String itemType,
    String note,
    bool isPaid,
  ) async {
    setState(() => _isSubmitting = true);
    final session = await _authSessionService.readSession();
    final tenantId = session?.userId ?? 'unknown';

    final success = await _pickupApiService.createPickupRequest(
      tenantId: tenantId,
      pickupAddress: pickup,
      dropAddress: drop,
      itemType: itemType,
      note: note,
      isPaid: isPaid,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        _pickupAddressController.clear();
        _dropAddressController.clear();
        _noteController.clear();
        _showSubmittedSnackBar(isFree: !isPaid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                bn: 'দুঃখিত, রিকোয়েস্ট সাবমিট করা যায়নি।',
                en: 'Sorry, could not submit request.',
              ),
            ),
          ),
        );
      }
    }
  }

  void _showSubmittedSnackBar({required bool isFree}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFree
              ? context.tr(
                  bn: 'ফ্রি পিকআপ রিকোয়েস্ট নেয়া হয়েছে।',
                  en: 'Free pickup request submitted.',
                )
              : context.tr(
                  bn: 'পেইড পিকআপ বুকিং নেয়া হয়েছে।',
                  en: 'Paid pickup booking submitted.',
                ),
        ),
      ),
    );
  }

  void _showPaidCheckout(
    String pickup,
    String drop,
    String itemType,
    String note,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(bn: 'পেইড পিকআপ', en: 'Paid Pickup'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    bn: '৩ মাস পূর্ণ না হওয়ায় এই সার্ভিসটি পেইড হিসেবে বুক হবে।',
                    en: 'This service will be booked as paid because 3 months are not complete yet.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _PickupChargeRow(
                  label: context.tr(bn: 'সার্ভিস চার্জ', en: 'Service Charge'),
                  value: context.money(_paidPickupCharge),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _PickupPaymentChip(
                      label: 'bKash',
                      color: Color(0xFFE2136E),
                    ),
                    _PickupPaymentChip(
                      label: 'Nagad',
                      color: Color(0xFFF97316),
                    ),
                    _PickupPaymentChip(label: 'Cash', color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            Navigator.of(sheetContext).pop();
                            await _executeSubmission(
                              pickup,
                              drop,
                              itemType,
                              note,
                              true,
                            );
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                    child: Text(
                      context.tr(
                        bn: 'পেইড বুকিং কনফার্ম করুন',
                        en: 'Confirm Paid Booking',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget? _buildBottomAction(AsyncSnapshot<_PickupEligibilityData> snapshot) {
    final data = snapshot.data;
    if (snapshot.connectionState == ConnectionState.waiting || data == null) {
      return null;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: FilledButton.icon(
          onPressed: _isSubmitting ? null : () => _submitPickupRequest(data),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  data.isFreeEligible
                      ? Icons.card_giftcard_rounded
                      : Icons.payments_rounded,
                ),
          style: FilledButton.styleFrom(
            backgroundColor: data.isFreeEligible
                ? AppColors.success
                : AppColors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          label: Text(
            data.isFreeEligible
                ? context.tr(bn: 'ফ্রি পিকআপ বুক করুন', en: 'Book Free Pickup')
                : context.tr(
                    bn: 'পেইড বুকিংয়ে যান',
                    en: 'Continue to Paid Booking',
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PickupEligibilityData>(
      future: _eligibilityFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FB),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F8FB),
            title: Text(context.tr(bn: 'পিকআপ সার্ভিস', en: 'Pickup Service')),
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          bottomNavigationBar: _buildBottomAction(snapshot),
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() => _eligibilityFuture = _loadEligibility());
              await _eligibilityFuture;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
              children: [
                const _PickupHeroCard(),
                const SizedBox(height: 14),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 2)
                else if (snapshot.hasError)
                  _PickupStatusCard.error(
                    message: context.tr(
                      bn: 'জয়েনিং তারিখ পড়া যায়নি। আপাতত পেইড সার্ভিস হিসেবে চালু করুন।',
                      en: 'Unable to read joining date. Continue as paid service for now.',
                    ),
                  )
                else if (data != null)
                  _PickupStatusCard(data: data),
                const SizedBox(height: 14),
                _PickupBookingForm(
                  pickupAddressController: _pickupAddressController,
                  dropAddressController: _dropAddressController,
                  noteController: _noteController,
                  itemTypes: _itemTypes,
                  selectedItemType: _selectedItemType,
                  onItemTypeChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedItemType = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                const _PickupGuidelinesCard(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PickupEligibilityData {
  const _PickupEligibilityData({
    required this.createdAt,
    required this.isFreeEligible,
    required this.eligibleAt,
    required this.remainingDays,
  });

  final DateTime? createdAt;
  final bool isFreeEligible;
  final DateTime? eligibleAt;
  final int remainingDays;
}

class _PickupHeroCard extends StatelessWidget {
  const _PickupHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEDD5), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFED7AA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12F97316),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.airport_shuttle_rounded,
              color: AppColors.accent,
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    bn: 'ঘর বদল ও মালামাল পিকআপ',
                    en: 'Move-out and item pickup',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    bn: 'জয়েনিং তারিখ অনুযায়ী ফ্রি বা পেইড সার্ভিস দেখানো হবে।',
                    en: 'Free or paid service is decided from your joining date.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupStatusCard extends StatelessWidget {
  const _PickupStatusCard({required _PickupEligibilityData data})
    : _data = data,
      _errorMessage = null;

  const _PickupStatusCard.error({required String message})
    : _data = null,
      _errorMessage = message;

  final _PickupEligibilityData? _data;
  final String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return _PickupSurfaceCard(
        borderColor: const Color(0xFFFED7AA),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9A3412),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final data = _data!;
    final statusColor = data.isFreeEligible
        ? AppColors.success
        : AppColors.accent;
    final createdAt = data.createdAt?.toLocal();
    final eligibleAt = data.eligibleAt?.toLocal();

    return _PickupSurfaceCard(
      borderColor: statusColor.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.isFreeEligible
                      ? Icons.card_giftcard_rounded
                      : Icons.payments_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.isFreeEligible
                          ? context.tr(
                              bn: 'আপনি ফ্রি পিকআপ পাবেন',
                              en: 'You get free pickup',
                            )
                          : context.tr(
                              bn: 'পেইড পিকআপ প্রযোজ্য',
                              en: 'Paid pickup applies',
                            ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.isFreeEligible
                          ? context.tr(
                              bn: 'আপনার জয়েনিং ৩ মাস পূর্ণ হয়েছে।',
                              en: 'Your joining period has completed 3 months.',
                            )
                          : data.createdAt == null
                          ? context.tr(
                              bn: 'জয়েনিং তারিখ নেই, তাই পেইড সার্ভিস হিসেবে চলবে।',
                              en: 'Joining date is missing, so this will continue as paid service.',
                            )
                          : context.tr(
                              bn: '৩ মাস পূর্ণ হলে এই সার্ভিস ফ্রি হবে।',
                              en: 'This service becomes free after 3 months.',
                            ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PickupDivider(),
          const SizedBox(height: 12),
          _PickupInfoRow(
            label: context.tr(bn: 'জয়েনিং তারিখ', en: 'Joining Date'),
            value: createdAt == null
                ? context.tr(bn: 'পাওয়া যায়নি', en: 'Not found')
                : context.shortDateText(createdAt),
          ),
          _PickupInfoRow(
            label: context.tr(bn: 'ফ্রি হবে', en: 'Free From'),
            value: eligibleAt == null
                ? context.tr(bn: 'যাচাই হয়নি', en: 'Not verified')
                : context.shortDateText(eligibleAt),
          ),
          if (!data.isFreeEligible && data.createdAt != null)
            _PickupInfoRow(
              label: context.tr(bn: 'বাকি', en: 'Remaining'),
              value: context.tr(
                bn: '${context.digitsText(data.remainingDays)} দিন',
                en: '${context.digitsText(data.remainingDays)} days',
              ),
            ),
        ],
      ),
    );
  }
}

class _PickupBookingForm extends StatelessWidget {
  const _PickupBookingForm({
    required this.pickupAddressController,
    required this.dropAddressController,
    required this.noteController,
    required this.itemTypes,
    required this.selectedItemType,
    required this.onItemTypeChanged,
  });

  final TextEditingController pickupAddressController;
  final TextEditingController dropAddressController;
  final TextEditingController noteController;
  final List<String> itemTypes;
  final String selectedItemType;
  final ValueChanged<String?> onItemTypeChanged;

  @override
  Widget build(BuildContext context) {
    return _PickupSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(bn: 'বুকিং তথ্য', en: 'Booking Details'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: pickupAddressController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: context.tr(bn: 'পিকআপ ঠিকানা', en: 'Pickup Address'),
              prefixIcon: const Icon(Icons.location_on_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dropAddressController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: context.tr(bn: 'ড্রপ ঠিকানা', en: 'Drop Address'),
              prefixIcon: const Icon(Icons.flag_rounded),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedItemType,
            items: itemTypes
                .map(
                  (type) => DropdownMenuItem<String>(
                    value: type,
                    child: Text(_itemTypeLabel(context, type)),
                  ),
                )
                .toList(growable: false),
            onChanged: onItemTypeChanged,
            decoration: InputDecoration(
              labelText: context.tr(bn: 'মালামালের ধরন', en: 'Item Type'),
              prefixIcon: const Icon(Icons.inventory_2_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.tr(bn: 'নোট', en: 'Note'),
              hintText: context.tr(
                bn: 'সময়, ফ্লোর বা বিশেষ নির্দেশনা লিখুন',
                en: 'Write time, floor, or special instructions',
              ),
              prefixIcon: const Icon(Icons.notes_rounded),
            ),
          ),
        ],
      ),
    );
  }

  String _itemTypeLabel(BuildContext context, String value) {
    return switch (value) {
      'Furniture' => context.tr(bn: 'ফার্নিচার', en: 'Furniture'),
      'Appliance' => context.tr(bn: 'ইলেকট্রনিক্স', en: 'Appliance'),
      'Boxes' => context.tr(bn: 'বক্স', en: 'Boxes'),
      'Documents' => context.tr(bn: 'ডকুমেন্ট', en: 'Documents'),
      _ => value,
    };
  }
}

class _PickupGuidelinesCard extends StatelessWidget {
  const _PickupGuidelinesCard();

  @override
  Widget build(BuildContext context) {
    return _PickupSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(bn: 'সার্ভিস নিয়ম', en: 'Service Rules'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _PickupRuleTile(
            icon: Icons.verified_rounded,
            text: context.tr(
              bn: 'জয়েনিংয়ের ৩ মাস পূর্ণ হলে পিকআপ সার্ভিস ফ্রি।',
              en: 'Pickup service is free after 3 months from joining.',
            ),
          ),
          _PickupRuleTile(
            icon: Icons.payments_rounded,
            text: context.tr(
              bn: '৩ মাসের আগে বুক করলে পেইড সার্ভিস চার্জ প্রযোজ্য।',
              en: 'Paid service charge applies before 3 months.',
            ),
          ),
          _PickupRuleTile(
            icon: Icons.support_agent_rounded,
            text: context.tr(
              bn: 'রিকোয়েস্ট সাবমিট হলে সাপোর্ট টিম সময় কনফার্ম করবে।',
              en: 'Support will confirm the schedule after request submission.',
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupSurfaceCard extends StatelessWidget {
  const _PickupSurfaceCard({
    required this.child,
    this.borderColor = AppColors.border,
  });

  final Widget child;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

class _PickupInfoRow extends StatelessWidget {
  const _PickupInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupRuleTile extends StatelessWidget {
  const _PickupRuleTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _PickupChargeRow extends StatelessWidget {
  const _PickupChargeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _PickupPaymentChip extends StatelessWidget {
  const _PickupPaymentChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        context.demoText(label),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

class _PickupDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.border);
  }
}
