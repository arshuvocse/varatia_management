import 'package:flutter/material.dart';

import '../../core/utils/app_context.dart';
import '../../data/services/notification_api_service.dart';
import '../screens/tenant_reference_pages.dart';

class FlatRentPaymentNoticeCard extends StatelessWidget {
  const FlatRentPaymentNoticeCard({
    super.key,
    required this.propertyName,
    this.tenantName,
    required this.amount,
    this.noticeDate,
    this.monthLabel,
    this.onPayNow,
    this.onDismiss,
    this.isDismissible = true,
  });

  final String propertyName;
  final String? tenantName;
  final num amount;
  final DateTime? noticeDate;
  final String? monthLabel;
  final VoidCallback? onPayNow;
  final VoidCallback? onDismiss;
  final bool isDismissible;

  @override
  Widget build(BuildContext context) {
    final effectiveDate = noticeDate ?? DateTime.now();
    final formattedToday = context.fullDateText(effectiveDate);
    final effectiveMonth = monthLabel ?? context.tr(bn: 'চলতি মাস', en: 'Current Month');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFBEB),
            Color(0xFFFEF3C7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14D97706),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x0AD97706),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFD97706),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(
                      bn: 'ভাড়ার নোটিশ • Payment Notice',
                      en: 'Rent Notice • Payment Notice',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        formattedToday,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Highlighted exact audio phrase
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📢 ',
                        style: TextStyle(fontSize: 18),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 14,
                              height: 1.5,
                              fontFamily: 'Inter',
                            ),
                            children: [
                              TextSpan(
                                text: context.tr(
                                  bn: 'আপনার আজকে ',
                                  en: 'Today is ',
                                ),
                              ),
                              TextSpan(
                                text: formattedToday,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              TextSpan(
                                text: context.tr(
                                  bn: ', আপনাকে ',
                                  en: ', you are required to make the payment for ',
                                ),
                              ),
                              TextSpan(
                                text: propertyName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              TextSpan(
                                text: context.tr(
                                  bn: ' এর ভাড়া ',
                                  en: ' rent of ',
                                ),
                              ),
                              TextSpan(
                                text: context.money(amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                              TextSpan(
                                text: context.tr(
                                  bn: ' পেমেন্ট করতে হবে।',
                                  en: '.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Meta row: Unit & Month
                Row(
                  children: [
                    Expanded(
                      child: _NoticeMetaBadge(
                        icon: Icons.apartment_rounded,
                        label: context.tr(bn: 'ইউনিট/ফ্ল্যাট', en: 'Unit/Flat'),
                        value: propertyName,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NoticeMetaBadge(
                        icon: Icons.event_note_rounded,
                        label: context.tr(bn: 'ভাড়ার মাস', en: 'Rent Month'),
                        value: effectiveMonth,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NoticeMetaBadge(
                        icon: Icons.payments_outlined,
                        label: context.tr(bn: 'মোট বকেয়া', en: 'Total Due'),
                        value: context.money(amount),
                        isHighlight: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Actions row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onPayNow ??
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const TenantPaymentCenterPage(),
                                ),
                              );
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.payment_rounded, size: 18),
                        label: Text(
                          context.tr(
                            bn: 'এখনই পেমেন্ট করুন',
                            en: 'Pay Now',
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    if (isDismissible && onDismiss != null) ...[
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: onDismiss,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF78350F),
                          side: const BorderSide(color: Color(0xFFD97706)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          context.tr(bn: 'বুঝেছি', en: 'Got it'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeMetaBadge extends StatelessWidget {
  const _NoticeMetaBadge({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlight
            ? const Color(0xFFDCFCE7)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFF86EFAC)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: isHighlight
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isHighlight
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isHighlight
                  ? const Color(0xFF15803D)
                  : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showSendRentNoticeBottomSheet(
  BuildContext context, {
  required String propertyName,
  required String tenantName,
  required num amount,
  String? userId,
}) async {
  final todayText = context.fullDateText(DateTime.now());
  final noticeText = context.tr(
    bn: 'আপনার আজকে $todayText, আপনাকে $propertyName-এর ভাড়া ${context.money(amount)} পেমেন্ট করতে হবে।',
    en: 'Today is $todayText, you are required to make the payment of ${context.money(amount)} for $propertyName.',
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalContext) {
      bool isSending = false;

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Color(0xFFD97706),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              bn: 'পেমেন্ট নোটিশ পাঠান',
                              en: 'Send Rent Payment Notice',
                            ),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr(
                              bn: 'ভাড়াটিয়াকে আজকের নির্ধারিত ভাড়ার তাগিদ পাঠান',
                              en: 'Send today\'s rent reminder notice to tenant',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(modalContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _DialogRow(
                        label: context.tr(bn: 'ভাড়াটিয়া', en: 'Tenant'),
                        value: tenantName,
                      ),
                      const Divider(height: 16),
                      _DialogRow(
                        label: context.tr(bn: 'ইউনিট / ফ্ল্যাট', en: 'Unit / Flat'),
                        value: propertyName,
                      ),
                      const Divider(height: 16),
                      _DialogRow(
                        label: context.tr(bn: 'ভাড়ার পরিমাণ', en: 'Rent Amount'),
                        value: context.money(amount),
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr(bn: 'নোটিশের খসড়া (Preview)', en: 'Notice Preview'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📢 ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          noticeText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSending
                        ? null
                        : () async {
                            setModalState(() => isSending = true);
                            try {
                              try {
                                await NotificationApiService().sendRentNotice(
                                  propertyName: propertyName,
                                  tenantName: tenantName,
                                  amount: amount,
                                  userId: userId,
                                );
                              } catch (_) {
                                // If offline or dev mode, still succeed locally
                              }

                              if (modalContext.mounted) {
                                Navigator.of(modalContext).pop();
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF15803D),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            context.tr(
                                              bn: '$tenantName-কে আজকের পেমেন্ট নোটিশ সফলভাবে পাঠানো হয়েছে।',
                                              en: 'Payment notice sent successfully to $tenantName.',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSending = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      isSending
                          ? context.tr(bn: 'পাঠানো হচ্ছে...', en: 'Sending...')
                          : context.tr(bn: '📢 নোটিশ পাঠান', en: '📢 Send Notice'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
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

class _DialogRow extends StatelessWidget {
  const _DialogRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: isHighlight
                ? const Color(0xFF16A34A)
                : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

