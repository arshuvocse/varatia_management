import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_context.dart';
import '../../../../data/services/registration_api_service.dart';
import '../../../widgets/app_widgets.dart';
import '../../entry/entry_routes.dart';

class AmarElakaAuthPage extends StatefulWidget {
  const AmarElakaAuthPage({
    super.key,
    this.initialMode = AmarElakaAuthMode.login,
  });

  final AmarElakaAuthMode initialMode;

  @override
  State<AmarElakaAuthPage> createState() => _AmarElakaAuthPageState();
}

enum AmarElakaAuthMode { login, register }

class _AmarElakaAuthPageState extends State<AmarElakaAuthPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final RegistrationApiService _registrationApiService =
      RegistrationApiService();

  late AmarElakaAuthMode _mode = widget.initialMode;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isLogin => _mode == AmarElakaAuthMode.login;

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

    if (_isLogin) {
      await _login();
    } else {
      await _register();
    }
  }

  Future<void> _login() async {
    final phoneNumber = _normalizePhoneNumber(_phoneController.text);
    final password = _passwordController.text;
    final validationError = _validateLogin(context, phoneNumber, password);
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Login successful.')));

      Navigator.of(context).pushReplacementNamed(AppRoutes.amarElaka);
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = context.tr(
            bn: 'এখন লগইন করা যাচ্ছে না। আবার চেষ্টা করুন।',
            en: 'Unable to login right now. Please try again.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _register() async {
    final fullName = _nameController.text.trim();
    final phoneNumber = _normalizePhoneNumber(_phoneController.text);
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final validationError = _validateRegister(
      context,
      fullName: fullName,
      phoneNumber: phoneNumber,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (validationError != null) {
      setState(() => _errorMessage = validationError);
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

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));

      if (result.otpRequired) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.otp,
          arguments: result.toOtpSession(
            nextRouteName: AppRoutes.amarElaka,
            clearStackAfterVerification: false,
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacementNamed(AppRoutes.amarElaka);
    } on RegistrationApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = context.tr(
            bn: 'এখন অ্যাকাউন্ট তৈরি করা যাচ্ছে না। আবার চেষ্টা করুন।',
            en: 'Unable to create account right now. Please try again.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _validateLogin(
    BuildContext context,
    String phoneNumber,
    String password,
  ) {
    if (phoneNumber.length < 10 || phoneNumber.length > 15) {
      return context.tr(
        bn: 'ফোন নম্বরে ১০ থেকে ১৫টি সংখ্যা থাকতে হবে।',
        en: 'Phone number must contain 10 to 15 digits.',
      );
    }

    if (password.isEmpty) {
      return context.tr(
        bn: 'পাসওয়ার্ড দিতে হবে।',
        en: 'Password is required.',
      );
    }

    return null;
  }

  String? _validateRegister(
    BuildContext context, {
    required String fullName,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) {
    if (fullName.length < 3) {
      return context.tr(
        bn: 'আপনার পুরো নাম লিখুন।',
        en: 'Please enter your full name.',
      );
    }

    if (phoneNumber.length < 10 || phoneNumber.length > 15) {
      return context.tr(
        bn: 'ফোন নম্বরে ১০ থেকে ১৫টি সংখ্যা থাকতে হবে।',
        en: 'Phone number must contain 10 to 15 digits.',
      );
    }

    if (password.length < 6) {
      return context.tr(
        bn: 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।',
        en: 'Password must be at least 6 characters long.',
      );
    }

    if (password != confirmPassword) {
      return context.tr(
        bn: 'পাসওয়ার্ড এবং নিশ্চিত পাসওয়ার্ড মিলছে না।',
        en: 'Password and confirm password do not match.',
      );
    }

    return null;
  }

  String _normalizePhoneNumber(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void _setMode(AmarElakaAuthMode mode) {
    if (_isSubmitting || _mode == mode) {
      return;
    }

    setState(() {
      _mode = mode;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'আমার এলাকায় লগইন' : 'আমার এলাকায় যোগ দিন';
    final subtitle = _isLogin
        ? 'লোকাল পোস্ট, আপডেট এবং সহায়তা দেখতে আপনার ফোন নম্বর ব্যবহার করুন।'
        : 'পোস্ট, কমেন্ট এবং ওয়ার্ড আপডেট পেতে একটি অ্যাকাউন্ট তৈরি করুন।';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FB),
        surfaceTintColor: const Color(0xFFF6F8FB),
        leading: IconButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                _AmarElakaAuthHeader(title: title, subtitle: subtitle),
                const SizedBox(height: 22),
                _AmarElakaModeSwitch(mode: _mode, onChanged: _setMode),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isLogin) ...[
                        EntryTextField(
                          controller: _nameController,
                          enabled: !_isSubmitting,
                          dense: true,
                          label: context.tr(bn: 'পুরো নাম', en: 'Full Name'),
                          hint: context.tr(
                            bn: 'আপনার নাম লিখুন',
                            en: 'Enter your name',
                          ),
                          icon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                      ],
                      EntryTextField(
                        controller: _phoneController,
                        enabled: !_isSubmitting,
                        dense: true,
                        label: context.tr(bn: 'ফোন নম্বর', en: 'Phone Number'),
                        hint: context.tr(
                          bn: 'ফোন নম্বর লিখুন',
                          en: 'Enter phone number',
                        ),
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      EntryTextField(
                        controller: _passwordController,
                        enabled: !_isSubmitting,
                        dense: true,
                        label: context.tr(bn: 'পাসওয়ার্ড', en: 'Password'),
                        hint: _isLogin
                            ? context.tr(
                                bn: 'পাসওয়ার্ড লিখুন',
                                en: 'Enter password',
                              )
                            : context.tr(
                                bn: 'পাসওয়ার্ড তৈরি করুন',
                                en: 'Create password',
                              ),
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: _isLogin
                            ? TextInputAction.done
                            : TextInputAction.next,
                      ),
                      if (!_isLogin) ...[
                        const SizedBox(height: 14),
                        EntryTextField(
                          controller: _confirmPasswordController,
                          enabled: !_isSubmitting,
                          dense: true,
                          label: context.tr(
                            bn: 'পাসওয়ার্ড নিশ্চিত করুন',
                            en: 'Confirm Password',
                          ),
                          hint: context.tr(
                            bn: 'আবার পাসওয়ার্ড লিখুন',
                            en: 'Re-enter password',
                          ),
                          icon: Icons.verified_user_outlined,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        _AmarElakaErrorMessage(message: _errorMessage!),
                      ],
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isLogin
                                    ? Icons.login_rounded
                                    : Icons.person_add_alt_1_rounded,
                              ),
                        label: Text(
                          _isLogin
                              ? context.tr(bn: 'লগইন', en: 'Login')
                              : context.tr(
                                  bn: 'অ্যাকাউন্ট তৈরি করুন',
                                  en: 'Create Account',
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _setMode(
                                  _isLogin
                                      ? AmarElakaAuthMode.register
                                      : AmarElakaAuthMode.login,
                                ),
                          child: Text(
                            _isLogin
                                ? context.tr(
                                    bn: 'নতুন? অ্যাকাউন্ট তৈরি করুন',
                                    en: 'New here? Create an account',
                                  )
                                : context.tr(
                                    bn: 'আগে থেকেই অ্যাকাউন্ট আছে? লগইন',
                                    en: 'Already have an account? Login',
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmarElakaAuthHeader extends StatelessWidget {
  const _AmarElakaAuthHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.location_city_rounded,
            color: Color(0xFF0EA5E9),
            size: 31,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 29,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textMuted,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _AmarElakaModeSwitch extends StatelessWidget {
  const _AmarElakaModeSwitch({required this.mode, required this.onChanged});

  final AmarElakaAuthMode mode;
  final ValueChanged<AmarElakaAuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _ModeButton(
            label: context.tr(bn: 'লগইন', en: 'Login'),
            icon: Icons.login_rounded,
            selected: mode == AmarElakaAuthMode.login,
            onTap: () => onChanged(AmarElakaAuthMode.login),
          ),
          _ModeButton(
            label: context.tr(bn: 'রেজিস্টার', en: 'Register'),
            icon: Icons.person_add_alt_1_rounded,
            selected: mode == AmarElakaAuthMode.register,
            onTap: () => onChanged(AmarElakaAuthMode.register),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            height: 46,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x100F172A),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? AppColors.primary : AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmarElakaErrorMessage extends StatelessWidget {
  const _AmarElakaErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFB42318),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
