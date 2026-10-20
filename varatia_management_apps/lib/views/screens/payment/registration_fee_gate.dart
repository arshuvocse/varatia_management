import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/registration_payment_api_service.dart';
import 'ssl_commerz_payment_screen.dart';

/// Checks if user has paid the registration fee.
/// If not, displays an SSLCommerz payment gate.
Future<bool> ensureRegistrationFeePaid(
  BuildContext context, {
  required String userId,
}) async {
  if (userId.trim().isEmpty) return true;

  final apiService = RegistrationPaymentApiService();

  try {
    final status = await apiService.getRegistrationStatus(userId);
    if (!context.mounted) return false;

    // If fee is not active or already paid, allow through
    if (!status.isRequired || status.isPaid) {
      return true;
    }

    final feeAmount = status.fee.toStringAsFixed(0);

    final shouldPay = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => PopScope(
        canPop: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadii.card),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.primary,
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'রেজিস্ট্রেশন ফি পরিশোধ করুন',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'আপনার অ্যাকাউন্ট সম্পূর্ণ সক্রিয় করতে এবং সকল সুবিধা উপভোগ করতে ৳ $feeAmount টাকা ওয়ান-টাইম রেজিস্ট্রেশন ফি প্রদান করুন।',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    const Text(
                      'SSLCommerz নিরাপদ পেমেন্ট গেটওয়ে',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(true),
                  icon: const Icon(Icons.payment_rounded),
                  label: Text('SSLCommerz দিয়ে ৳ $feeAmount পে করুন'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(false),
                  child: const Text('পরে করব', style: TextStyle(color: AppColors.textMuted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldPay != true || !context.mounted) return false;

    _showLoadingDialog(context);
    try {
      final gatewayUrl = await apiService.initiateRegistrationPayment(userId);
      if (!context.mounted) return false;
      _dismissLoadingDialog(context);

      final paymentResult = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => SslCommerzPaymentScreen(paymentUrl: gatewayUrl),
        ),
      );

      if (!context.mounted) return false;
      if (paymentResult != true) {
        _showMessage(context, 'পেমেন্ট সম্পন্ন হয়নি। আবার চেষ্টা করতে পারেন।');
        return false;
      }

      final verified = await apiService.getRegistrationStatus(userId);
      if (verified.isPaid) {
        if (context.mounted) {
          _showMessage(context, 'অভিনন্দন! আপনার রেজিস্ট্রেশন ফি সফলভাবে পরিশোধিত হয়েছে।');
        }
        return true;
      }

      return false;
    } catch (error) {
      if (context.mounted) {
        _dismissLoadingDialog(context);
        _showMessage(context, error.toString());
      }
      return false;
    }
  } catch (error) {
    if (context.mounted) {
      _showMessage(context, error.toString());
    }
    return false;
  } finally {
    apiService.dispose();
  }
}

void _showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 20),
            Expanded(child: Text('পেমেন্ট গেটওয়ে লোড হচ্ছে...')),
          ],
        ),
      ),
    ),
  );
}

void _dismissLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
