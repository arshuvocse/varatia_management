import 'package:flutter/material.dart';

import '../../../core/utils/app_context.dart';
import '../../../data/services/registration_api_service.dart';
import '../../widgets/app_widgets.dart';
import 'entry_routes.dart';

class EntrySignUpScreen extends StatefulWidget {
  const EntrySignUpScreen({super.key});

  @override
  State<EntrySignUpScreen> createState() => _EntrySignUpScreenState();
}

class _EntrySignUpScreenState extends State<EntrySignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final RegistrationApiService _registrationApiService =
      RegistrationApiService();

  bool _isSubmitting = false;
  bool _agreedToTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _registrationApiService.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final fullName = _nameController.text.trim();
    final phoneNumber = _normalizePhoneNumber(_phoneController.text);
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final validationError = _validate(
      fullName: fullName,
      phoneNumber: phoneNumber,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _registrationApiService.register(
        fullName: fullName,
        phoneNumber: phoneNumber,
        password: password,
        confirmPassword: confirmPassword,
      );

      if (!mounted) {
        return;
      }

      if (result.otpRequired) {
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.otp, arguments: result.toOtpSession());
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.tr(bn: result.message, en: result.message)),
          ),
        );
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    } on RegistrationApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError(
        context.tr(
          bn: 'Unable to create account right now. Please try again.',
          en: 'Unable to create account right now. Please try again.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validate({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) {
    final normalizedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (fullName.length < 3) {
      return context.tr(
        bn: 'Please enter your full name.',
        en: 'Please enter your full name.',
      );
    }

    if (normalizedPhoneNumber.length < 10 ||
        normalizedPhoneNumber.length > 15) {
      return context.tr(
        bn: 'Phone number must contain 10 to 15 digits.',
        en: 'Phone number must contain 10 to 15 digits.',
      );
    }

    if (password.length < 6) {
      return context.tr(
        bn: 'Password must be at least 6 characters long.',
        en: 'Password must be at least 6 characters long.',
      );
    }

    if (password != confirmPassword) {
      return context.tr(
        bn: 'Password and confirm password do not match.',
        en: 'Password and confirm password do not match.',
      );
    }

    if (!_agreedToTerms) {
      return context.tr(
        bn: 'শর্তাবলী এবং গোপনীয়তা নীতি মেনে নেওয়া আবশ্যক।',
        en: 'You must accept the Terms of Service and Privacy Policy.',
      );
    }

    return null;
  }

  String _normalizePhoneNumber(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return EntryScaffold(
      onBack: () => Navigator.of(context).pop(),
      eyebrow: context.tr(bn: 'New account', en: 'New account'),
      title: context.tr(bn: 'Sign Up', en: 'Sign Up'),
      subtitle: context.tr(
        bn: 'আমার ঠিকানা কমিউনিটিতে যোগ দিন এবং বাসা ভাড়া ও শিক্ষক পোস্ট করুন।',
        en: 'Join Amar Thikanaa community to discover & publish rentals and tutoring posts.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EntryTextField(
            controller: _nameController,
            enabled: !_isSubmitting,
            textInputAction: TextInputAction.next,
            label: context.tr(bn: 'Name', en: 'Name'),
            hint: context.tr(bn: 'Enter your name', en: 'Enter your name'),
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _phoneController,
            enabled: !_isSubmitting,
            textInputAction: TextInputAction.next,
            label: context.tr(bn: 'Phone Number', en: 'Phone Number'),
            hint: context.tr(
              bn: 'Enter phone number (e.g. 017xxxxxxxx)',
              en: 'Enter phone number (e.g. 017xxxxxxxx)',
            ),
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _passwordController,
            enabled: !_isSubmitting,
            textInputAction: TextInputAction.next,
            label: context.tr(bn: 'Password', en: 'Password'),
            hint: context.tr(bn: 'Create password', en: 'Create password'),
            icon: Icons.lock_outline_rounded,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _confirmPasswordController,
            enabled: !_isSubmitting,
            textInputAction: TextInputAction.done,
            label: context.tr(bn: 'Confirm Password', en: 'Confirm Password'),
            hint: context.tr(bn: 'Re-enter password', en: 'Re-enter password'),
            icon: Icons.verified_user_outlined,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _agreedToTerms,
                onChanged: _isSubmitting
                    ? null
                    : (val) => setState(() => _agreedToTerms = val ?? false),
              ),
              Expanded(
                child: Text(
                  context.tr(
                    bn: 'আমি ব্যবহারের শর্তাবলী ও গোপনীয়তা নীতি মেনে নিচ্ছি',
                    en: 'I agree to the Terms of Service and Privacy Policy',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 12.5),
                ),
              ),
            ],
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
                : Text(context.tr(bn: 'Create Account', en: 'Create Account')),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.tr(
                  bn: 'Already have an account?',
                  en: 'Already have an account?',
                ),
              ),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: Text(context.tr(bn: 'Login', en: 'Login')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
