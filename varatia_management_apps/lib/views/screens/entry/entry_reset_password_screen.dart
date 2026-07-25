import 'package:flutter/material.dart';

import '../../../core/utils/app_context.dart';
import '../../../data/services/registration_api_service.dart';
import '../../widgets/app_widgets.dart';
import 'entry_routes.dart';

class EntryResetPasswordScreen extends StatefulWidget {
  const EntryResetPasswordScreen({super.key});

  @override
  State<EntryResetPasswordScreen> createState() =>
      _EntryResetPasswordScreenState();
}

class _EntryResetPasswordScreenState extends State<EntryResetPasswordScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final RegistrationApiService _registrationApiService =
      RegistrationApiService();

  PasswordResetSession? _session;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_session != null) {
      return;
    }

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is PasswordResetSession) {
      _session = arguments;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _registrationApiService.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final session = _session;
    if (session == null) {
      setState(() => _errorMessage = 'Password reset session was not found.');
      return;
    }

    final otpCode = _otpController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (otpCode.length != 6) {
      setState(() => _errorMessage = 'Enter the 6-digit OTP code.');
      return;
    }

    if (password.length < 6) {
      setState(
        () => _errorMessage = 'Password must be at least 6 characters long.',
      );
      return;
    }

    if (password != confirmPassword) {
      setState(
        () => _errorMessage = 'Password and confirm password do not match.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _registrationApiService.resetPassword(
        userId: session.userId,
        otpCode: otpCode,
        newPassword: password,
        confirmPassword: confirmPassword,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } on RegistrationApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Unable to reset password right now. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneNumber = _session?.phoneNumber ?? '';
    final expiresAtLabel = _formatOtpExpiresAt(_session?.otpExpiresAt);

    return EntryScaffold(
      onBack: () => Navigator.of(context).pop(),
      eyebrow: context.tr(bn: 'Recovery', en: 'Recovery'),
      title: context.tr(bn: 'Reset Password', en: 'Reset Password'),
      subtitle: context.tr(
        bn: phoneNumber.isEmpty
            ? 'Enter the OTP and your new password.'
            : 'Enter the OTP sent to $phoneNumber and set a new password.',
        en: phoneNumber.isEmpty
            ? 'Enter the OTP and your new password.'
            : 'Enter the OTP sent to $phoneNumber and set a new password.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EntryTextField(
            controller: _otpController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'OTP Code', en: 'OTP Code'),
            hint: '123456',
            icon: Icons.pin_rounded,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          if (_session?.debugOtpCode case final debugOtpCode?
              when debugOtpCode.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD8DEE9)),
              ),
              child: Text('Dev OTP: $debugOtpCode'),
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
          const SizedBox(height: 16),
          EntryTextField(
            controller: _passwordController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'New Password', en: 'New Password'),
            hint: context.tr(
              bn: 'Enter new password',
              en: 'Enter new password',
            ),
            icon: Icons.lock_outline_rounded,
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _confirmPasswordController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Confirm Password', en: 'Confirm Password'),
            hint: context.tr(bn: 'Re-enter password', en: 'Re-enter password'),
            icon: Icons.verified_user_outlined,
            obscureText: true,
            textInputAction: TextInputAction.done,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
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
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr(bn: 'Reset Password', en: 'Reset Password')),
          ),
        ],
      ),
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
      bn: 'ওটিপিটি $timeLabel পর্যন্ত বৈধ থাকবে।',
      en: 'The OTP will remain valid until $timeLabel.',
    );
  }
}
