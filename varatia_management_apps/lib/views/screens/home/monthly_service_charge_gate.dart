import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/service_charge_payment_api_service.dart';
import '../payment/ssl_commerz_payment_screen.dart';

Future<bool> ensureMonthlyServiceChargePaid(
  BuildContext context, {
  required String userId,
  required String serviceName,
}) async {
  final paymentApiService = ServiceChargePaymentApiService();

  try {
    final isPaid = await paymentApiService.checkPaymentStatus(userId);
    if (!context.mounted) return false;
    if (isPaid) return true;

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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.payment_rounded,
                color: AppColors.primary,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'Monthly service charge required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'To use $serviceName this month, please pay the 50 taka monthly service charge.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(true),
                  child: const Text('Pay 50 taka'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldPay != true || !context.mounted) return false;

    _showMonthlyServiceChargeLoadingDialog(context);
    try {
      final gatewayUrl = await paymentApiService.initiatePayment(userId);
      if (!context.mounted) return false;
      _dismissMonthlyServiceChargeLoadingDialog(context);

      final paymentResult = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => SslCommerzPaymentScreen(paymentUrl: gatewayUrl),
        ),
      );

      if (paymentResult != true || !context.mounted) return false;

      return paymentApiService.checkPaymentStatus(userId);
    } catch (error) {
      if (context.mounted) {
        _dismissMonthlyServiceChargeLoadingDialog(context);
        _showMonthlyServiceChargeMessage(context, error.toString());
      }
      return false;
    }
  } on ServiceChargePaymentApiException catch (error) {
    if (context.mounted) {
      _showMonthlyServiceChargeMessage(context, error.message);
    }
    return false;
  } finally {
    paymentApiService.dispose();
  }
}

void _showMonthlyServiceChargeLoadingDialog(BuildContext context) {
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
            Expanded(child: Text('Loading payment gateway...')),
          ],
        ),
      ),
    ),
  );
}

void _dismissMonthlyServiceChargeLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}

void _showMonthlyServiceChargeMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
