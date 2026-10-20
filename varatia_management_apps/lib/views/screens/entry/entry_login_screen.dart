import 'package:flutter/material.dart';

import '../../../core/models/user_role.dart';
import '../../../core/utils/app_context.dart';
import '../../../data/services/registration_api_service.dart';
import '../../widgets/app_widgets.dart';
import 'entry_routes.dart';

class EntryLoginScreen extends StatefulWidget {
  const EntryLoginScreen({super.key});

  @override
  State<EntryLoginScreen> createState() => _EntryLoginScreenState();
}

class _EntryLoginScreenState extends State<EntryLoginScreen> {
  final TextEditingController _phoneController =
      TextEditingController(text: '01855667788');
  final TextEditingController _passwordController =
      TextEditingController(text: 'Password123');
  final RegistrationApiService _registrationApiService =
      RegistrationApiService();

  bool _isSubmitting = false;
  bool _isResetSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _registrationApiService.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final phoneNumber = _phoneController.text.trim();
    final password = _passwordController.text;
    final validationError = _validateLogin(phoneNumber, password);
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _registrationApiService.login(
        phoneNumber: phoneNumber,
        password: password,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));

      if (result.otpRequired) {
        Navigator.of(
          context,
        ).pushNamed(AppRoutes.otp, arguments: result.toOtpSession());
        return;
      }

      _navigateAfterAuthentication(result.resolvedRole);
    } on RegistrationApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to login right now: ${error.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    FocusScope.of(context).unfocus();

    final phoneNumber = _phoneController.text.trim();
    final normalizedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalizedPhoneNumber.length < 10 ||
        normalizedPhoneNumber.length > 15) {
      setState(() {
        _errorMessage = 'Enter your phone number first.';
      });
      return;
    }

    setState(() {
      _isResetSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _registrationApiService.forgotPassword(
        phoneNumber: phoneNumber,
      );

      if (!mounted) {
        return;
      }

      final otpLabel = result.debugOtpCode.isEmpty
          ? result.message
          : '${result.message} OTP: ${result.debugOtpCode}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(otpLabel)));
      Navigator.of(context).pushNamed(
        AppRoutes.resetPassword,
        arguments: result.toResetPasswordSession(),
      );
    } on RegistrationApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Unable to request password reset right now. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isResetSubmitting = false);
      }
    }
  }

  String? _validateLogin(String phoneNumber, String password) {
    final normalizedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalizedPhoneNumber.length < 10 ||
        normalizedPhoneNumber.length > 15) {
      return 'Phone number must contain 10 to 15 digits.';
    }

    if (password.isEmpty) {
      return 'Password is required.';
    }

    return null;
  }

  void _navigateAfterAuthentication(EntryUserRole? role) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
      arguments: role ?? EntryUserRole.tenant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSubmitting || _isResetSubmitting;

    return EntryScaffold(
      compact: true,
      onBack: () {
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.splash, arguments: false);
      },
      eyebrow: context.tr(bn: 'আবার স্বাগতম', en: 'Welcome back'),
      title: context.tr(bn: 'লগইন', en: 'Login'),
      subtitle: context.tr(
        bn: 'আমার ঠিকানা কমিউনিটি ফিডে সাইন ইন করুন।',
        en: 'Sign in to access Amar Thikanaa community feed.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EntryTextField(
            controller: _phoneController,
            enabled: !isBusy,
            dense: true,
            label: context.tr(bn: 'ফোন নম্বর', en: 'Phone Number'),
            hint: context.tr(bn: 'ফোন নম্বর লিখুন', en: 'Enter phone number'),
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          EntryTextField(
            controller: _passwordController,
            enabled: !isBusy,
            dense: true,
            label: context.tr(bn: 'পাসওয়ার্ড', en: 'Password'),
            hint: context.tr(bn: 'পাসওয়ার্ড লিখুন', en: 'Enter password'),
            icon: Icons.lock_outline_rounded,
            obscureText: true,
            textInputAction: TextInputAction.done,
          ),
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
          const SizedBox(height: 14),
          FilledButton(
            onPressed: isBusy ? null : _login,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr(bn: 'এগিয়ে যান', en: 'Continue')),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isBusy ? null : _forgotPassword,
              child: Text(
                _isResetSubmitting
                    ? context.tr(bn: 'পাঠানো হচ্ছে...', en: 'Sending...')
                    : context.tr(
                        bn: 'পাসওয়ার্ড ভুলে গেছেন?',
                        en: 'Forgot Password?',
                      ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.tr(bn: 'অ্যাকাউন্ট নেই?', en: "Don't have an account?"),
              ),
              TextButton(
                onPressed: isBusy
                    ? null
                    : () {
                        Navigator.of(context).pushNamed(AppRoutes.signUp);
                      },
                child: Text(context.tr(bn: 'সাইন আপ', en: 'Sign Up')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
