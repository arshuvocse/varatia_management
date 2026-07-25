import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_context.dart';
import '../../../data/services/auth_session_service.dart';
import '../../widgets/app_widgets.dart';
import 'entry_routes.dart';

class EntrySplashScreen extends StatefulWidget {
  const EntrySplashScreen({super.key, this.autoNavigate = true});

  final bool autoNavigate;

  @override
  State<EntrySplashScreen> createState() => _EntrySplashScreenState();
}

class _EntrySplashScreenState extends State<EntrySplashScreen> {
  Timer? _splashTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoNavigate) {
      _splashTimer = Timer(
        const Duration(milliseconds: 1500),
        () => unawaited(_continueFromSplash()),
      );
    }
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  Future<void> _continueFromSplash() async {
    if (!mounted || _hasNavigated) {
      return;
    }

    _hasNavigated = true;
    final session = await AuthSessionService().readSession();
    if (!mounted) {
      return;
    }

    final role = session?.role;
    final hasVerifiedSession =
        session != null &&
        session.userId.trim().isNotEmpty &&
        session.isPhoneVerified &&
        role != null;

    if (!hasVerifiedSession) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.home,
      arguments: HomeRouteArguments(
        role: role,
        initialTabIndex: session.lastHomeTabIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.accent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Center(child: AppBrandLogo(width: 280)),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    context.tr(
                      bn: 'স্মার্ট প্রপার্টি ম্যানেজমেন্ট',
                      en: 'Smart Property Management',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => unawaited(_continueFromSplash()),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  child: Text(context.tr(bn: 'শুরু করুন', en: 'Get Started')),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    value: 0.82,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
