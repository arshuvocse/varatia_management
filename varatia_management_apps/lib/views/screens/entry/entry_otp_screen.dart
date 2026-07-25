import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_context.dart';
import '../../../data/services/registration_api_service.dart';
import '../../widgets/app_widgets.dart';
import 'entry_routes.dart';

class EntryOtpScreen extends StatefulWidget {
  const EntryOtpScreen({super.key});

  @override
  State<EntryOtpScreen> createState() => _EntryOtpScreenState();
}

class _EntryOtpScreenState extends State<EntryOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final RegistrationApiService _registrationApiService =
      RegistrationApiService();

  OtpSession? _session;
  String? _debugOtpCode;
  DateTime? _otpExpiresAt;
  String? _errorMessage;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_session != null) {
      return;
    }

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is OtpSession) {
      _session = arguments;
      _debugOtpCode = arguments.debugOtpCode;
      _otpExpiresAt = arguments.otpExpiresAt;
    } else if (arguments is RegistrationResult) {
      _session = arguments.toOtpSession();
      _debugOtpCode = arguments.debugOtpCode;
      _otpExpiresAt = arguments.otpExpiresAt;
    } else if (arguments is LoginResult) {
      _session = arguments.toOtpSession();
      _debugOtpCode = arguments.debugOtpCode;
      _otpExpiresAt = arguments.otpExpiresAt;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _registrationApiService.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final session = _session;
    if (session == null) {
      setState(() => _errorMessage = 'OTP session was not found.');
      return;
    }

    final otpCode = _otpController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (otpCode.length != 6) {
      setState(() => _errorMessage = 'Enter the 6-digit OTP code.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final result = await _registrationApiService.verifyOtp(
        userId: session.userId,
        otpCode: otpCode,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      _navigateAfterAuthentication(session.role);
    } on RegistrationApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to verify OTP right now. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    final session = _session;
    if (session == null) {
      setState(() => _errorMessage = 'OTP session was not found.');
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final result = await _registrationApiService.resendOtp(
        userId: session.userId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _debugOtpCode = result.debugOtpCode;
        _otpExpiresAt = result.otpExpiresAt;
      });
      final otpLabel = result.debugOtpCode.isEmpty
          ? result.message
          : '${result.message} OTP: ${result.debugOtpCode}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(otpLabel)));
    } on RegistrationApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to resend OTP right now. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isVerifying || _isResending;
    final phoneNumber = _session?.phoneNumber ?? '';
    final expiresAtLabel = _formatOtpExpiresAt(_otpExpiresAt);

    return EntryScaffold(
      onBack: () => Navigator.of(context).pop(),
      eyebrow: context.tr(bn: 'Security check', en: 'Security check'),
      title: context.tr(bn: 'OTP Verification', en: 'OTP Verification'),
      subtitle: context.tr(
        bn: phoneNumber.isEmpty
            ? 'Confirm the 6-digit code sent to your phone number.'
            : 'Confirm the 6-digit code sent to $phoneNumber.',
        en: phoneNumber.isEmpty
            ? 'Confirm the 6-digit code sent to your phone number.'
            : 'Confirm the 6-digit code sent to $phoneNumber.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EntryTextField(
            controller: _otpController,
            enabled: !isBusy,
            label: context.tr(
              bn: 'Enter the 6-digit code',
              en: 'Enter the 6-digit code',
            ),
            hint: '123456',
            icon: Icons.pin_rounded,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
          if (_debugOtpCode != null && _debugOtpCode!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Dev OTP: $_debugOtpCode',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
          if (expiresAtLabel != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD8DEE9)),
              ),
              child: Text(expiresAtLabel),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFB42318),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: isBusy ? null : _verifyOtp,
            child: _isVerifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr(bn: 'Verify', en: 'Verify')),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: isBusy ? null : _resendOtp,
              child: Text(
                _isResending
                    ? context.tr(bn: 'Sending...', en: 'Sending...')
                    : context.tr(bn: 'Resend Code', en: 'Resend Code'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateAfterAuthentication(Object? roleArgument) {
    final session = _session;
    final nextRouteName = session?.nextRouteName;
    if (nextRouteName != null && nextRouteName.isNotEmpty) {
      if (session?.clearStackAfterVerification ?? true) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          nextRouteName,
          (route) => false,
          arguments: session?.nextRouteArguments,
        );
      } else {
        Navigator.of(context).pushReplacementNamed(
          nextRouteName,
          arguments: session?.nextRouteArguments,
        );
      }
      return;
    }

    final routeName = roleArgument == null ? AppRoutes.role : AppRoutes.home;
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: roleArgument,
    );
  }

  String? _formatOtpExpiresAt(DateTime? value) {
    if (value == null) {
      return null;
    }

    final localValue = value.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localValue),
    );

    return context.tr(
      bn: 'কোডটি $timeLabel পর্যন্ত বৈধ থাকবে।',
      en: 'This code will remain valid until $timeLabel.',
    );
  }
}
