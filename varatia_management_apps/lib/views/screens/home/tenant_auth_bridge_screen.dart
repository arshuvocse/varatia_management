import 'package:flutter/material.dart';
import '../../../core/models/user_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_context.dart';
import '../../../data/services/auth_session_service.dart';
import '../../../data/services/registration_api_service.dart';
import '../../widgets/app_widgets.dart';
import '../entry/entry_routes.dart';
import 'monthly_service_charge_gate.dart';

class TenantAuthBridgeScreen extends StatefulWidget {
  const TenantAuthBridgeScreen({
    super.key,
    this.initialTabIndex = 0,
    this.destination = TenantAuthDestination.postComposer,
    this.authRole = EntryUserRole.owner,
  });

  final int initialTabIndex;
  final TenantAuthDestination destination;
  final EntryUserRole authRole;

  @override
  State<TenantAuthBridgeScreen> createState() => _TenantAuthBridgeScreenState();
}

enum TenantAuthDestination {
  postComposer,
  marketplaceSearch,
  tutorTeachLearn,
  pickupService,
  secureDeal,
  smartBazar,
  profile,
}

class _TenantAuthBridgeScreenState extends State<TenantAuthBridgeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RegistrationApiService _registrationApiService =
      RegistrationApiService();

  // Login Controllers
  final TextEditingController _loginPhoneController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  // Register Controllers
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regConfirmPasswordController =
      TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
      vsync: this,
    );
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _registrationApiService.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final phone = _loginPhoneController.text.trim().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final password = _loginPasswordController.text;

    if (phone.length < 10 || phone.length > 15) {
      _showError('সঠিক ফোন নম্বর লিখুন।');
      return;
    }
    if (password.isEmpty) {
      _showError('পাসওয়ার্ড লিখুন।');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _registrationApiService.login(
        phoneNumber: phone,
        password: password,
      );

      if (!mounted) return;

      // Keep the role associated with the card that opened this auth flow.
      final session = AuthSession(
        userId: result.userId,
        fullName: result.fullName,
        phoneNumber: result.phoneNumber,
        role: widget.authRole,
        isPhoneVerified: !result.otpRequired || result.isPhoneVerified,
        createdAt: result.createdAt ?? DateTime.now(),
      );
      await AuthSessionService().saveSession(session);

      if (!mounted) return;

      if (result.otpRequired) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.otp,
          arguments: result.toOtpSession(
            nextRouteName: _nextRouteName,
            nextRouteArguments: _nextRouteArguments,
          ),
        );
        return;
      }

      await _goToDestination();
    } on RegistrationApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('লগইন করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    final name = _regNameController.text.trim();
    final phone = _regPhoneController.text.trim().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final password = _regPasswordController.text;
    final confirmPassword = _regConfirmPasswordController.text;

    if (name.length < 3) {
      _showError('আপনার নাম লিখুন।');
      return;
    }
    if (phone.length < 10 || phone.length > 15) {
      _showError('সঠিক ফোন নম্বর লিখুন।');
      return;
    }
    if (password.length < 6) {
      _showError('পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।');
      return;
    }
    if (password != confirmPassword) {
      _showError('পাসওয়ার্ড দুটি মেলেনি।');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _registrationApiService.register(
        fullName: name,
        phoneNumber: phone,
        password: password,
        confirmPassword: confirmPassword,
        role: widget.authRole.apiValue,
      );

      if (!mounted) return;

      // Keep the role associated with the card that opened this auth flow.
      final session = AuthSession(
        userId: result.userId,
        fullName: result.fullName,
        phoneNumber: result.phoneNumber,
        role: widget.authRole,
        isPhoneVerified: !result.otpRequired,
        createdAt: result.createdAt ?? DateTime.now(),
      );
      await AuthSessionService().saveSession(session);

      if (!mounted) return;

      if (result.otpRequired) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.otp,
          arguments: result.toOtpSession(
            nextRouteName: _nextRouteName,
            nextRouteArguments: _nextRouteArguments,
          ),
        );
        return;
      }

      await _goToDestination();
    } on RegistrationApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('অ্যাকাউন্ট তৈরি করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String get _nextRouteName =>
      (widget.destination == TenantAuthDestination.marketplaceSearch ||
          widget.destination == TenantAuthDestination.tutorTeachLearn ||
          widget.destination == TenantAuthDestination.pickupService ||
          widget.destination == TenantAuthDestination.secureDeal ||
          widget.destination == TenantAuthDestination.smartBazar ||
          widget.destination == TenantAuthDestination.profile)
      ? AppRoutes.home
      : AppRoutes.postComposer;

  Object? get _nextRouteArguments {
    if (widget.destination == TenantAuthDestination.marketplaceSearch) {
      return const HomeRouteArguments(
        role: EntryUserRole.tenant,
        initialTabIndex: 1,
      );
    }
    if (widget.destination == TenantAuthDestination.tutorTeachLearn) {
      return const HomeRouteArguments(
        role: EntryUserRole.tenant,
        initialTabIndex: 0,
      );
    }
    if (widget.destination == TenantAuthDestination.profile) {
      return const HomeRouteArguments(
        role: EntryUserRole.tenant,
        initialTabIndex: 4,
      );
    }
    return null;
  }

  Future<void> _goToDestination() async {
    if (_requiresMonthlyServiceCharge) {
      final userId = await AuthSessionService().readUserId();
      if (!mounted) return;

      if (userId == null || userId.isEmpty) {
        _showError('User session was not found. Please log in again.');
        return;
      }

      final canContinue = await ensureMonthlyServiceChargePaid(
        context,
        userId: userId,
        serviceName: _monthlyServiceName,
      );
      if (!mounted || !canContinue) return;
    }

    if (widget.destination == TenantAuthDestination.marketplaceSearch ||
        widget.destination == TenantAuthDestination.tutorTeachLearn ||
        widget.destination == TenantAuthDestination.pickupService ||
        widget.destination == TenantAuthDestination.secureDeal ||
        widget.destination == TenantAuthDestination.smartBazar ||
        widget.destination == TenantAuthDestination.profile) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        _nextRouteName,
        (route) => false,
        arguments: _nextRouteArguments,
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed(_nextRouteName);
  }

  bool get _requiresMonthlyServiceCharge =>
      widget.destination == TenantAuthDestination.tutorTeachLearn ||
      widget.destination == TenantAuthDestination.pickupService ||
      widget.destination == TenantAuthDestination.secureDeal ||
      widget.destination == TenantAuthDestination.smartBazar;

  String get _monthlyServiceName {
    switch (widget.destination) {
      case TenantAuthDestination.tutorTeachLearn:
        return 'Tutor Service';
      case TenantAuthDestination.pickupService:
        return 'Pickup Service';
      case TenantAuthDestination.secureDeal:
        return 'Secure Deal';
      case TenantAuthDestination.smartBazar:
        return 'Smart Bazar';
      case TenantAuthDestination.postComposer:
      case TenantAuthDestination.marketplaceSearch:
      case TenantAuthDestination.profile:
        return 'this service';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.authRole == EntryUserRole.owner
              ? context.tr(
                  bn: 'ফ্ল্যাট মালিক অ্যাকাউন্ট',
                  en: 'Flat Owner Account',
                )
              : context.tr(bn: 'ভাড়াটিয়া অ্যাকাউন্ট', en: 'Tenant Account'),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            ScreenHeader(
              title: context.tr(
                bn: 'সাইন-ইন / নিবন্ধন',
                en: 'Sign In / Register',
              ),
              subtitle: context.tr(
                bn:
                    widget.destination ==
                        TenantAuthDestination.marketplaceSearch
                    ? 'বাসা বা ফ্ল্যাট খুঁজতে লগইন অথবা নতুন অ্যাকাউন্ট তৈরি করুন।'
                    : 'বাসা বা ফ্ল্যাটের বিজ্ঞাপন দিতে ফ্ল্যাট মালিক হিসেবে লগইন অথবা নতুন অ্যাকাউন্ট তৈরি করুন।',
                en:
                    widget.destination ==
                        TenantAuthDestination.marketplaceSearch
                    ? 'Log in or create an account to search for a flat or home.'
                    : 'Log in or create a Flat Owner account to post a home or flat advertisement.',
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                tabs: [
                  Tab(
                    text: context.tr(bn: 'লগইন', en: 'Login'),
                  ),
                  Tab(
                    text: context.tr(bn: 'সাইন আপ', en: 'Sign Up'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFB42318),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            _tabController.index == 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EntryTextField(
                        controller: _loginPhoneController,
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
                        controller: _loginPasswordController,
                        enabled: !_isSubmitting,
                        dense: true,
                        label: context.tr(bn: 'পাসওয়ার্ড', en: 'Password'),
                        hint: context.tr(
                          bn: 'পাসওয়ার্ড লিখুন',
                          en: 'Enter password',
                        ),
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _login,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(context.tr(bn: 'লগইন করুন', en: 'Log In')),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EntryTextField(
                        controller: _regNameController,
                        enabled: !_isSubmitting,
                        dense: true,
                        label: context.tr(bn: 'নাম', en: 'Name'),
                        hint: context.tr(
                          bn: 'আপনার নাম লিখুন',
                          en: 'Enter your name',
                        ),
                        icon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      EntryTextField(
                        controller: _regPhoneController,
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
                      const SizedBox(height: 12),
                      EntryTextField(
                        controller: _regPasswordController,
                        enabled: !_isSubmitting,
                        dense: true,
                        label: context.tr(bn: 'পাসওয়ার্ড', en: 'Password'),
                        hint: context.tr(
                          bn: 'পাসওয়ার্ড লিখুন',
                          en: 'Enter password',
                        ),
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      EntryTextField(
                        controller: _regConfirmPasswordController,
                        enabled: !_isSubmitting,
                        dense: true,
                        label: context.tr(
                          bn: 'পাসওয়ার্ড নিশ্চিত করুন',
                          en: 'Confirm Password',
                        ),
                        hint: context.tr(
                          bn: 'পাসওয়ার্ড পুনরায় লিখুন',
                          en: 'Re-enter password',
                        ),
                        icon: Icons.verified_user_outlined,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _register,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  context.tr(
                                    bn: 'অ্যাকাউন্ট তৈরি করুন',
                                    en: 'Create Account',
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
