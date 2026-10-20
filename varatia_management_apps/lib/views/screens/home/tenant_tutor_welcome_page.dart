import 'package:flutter/material.dart';

import '../../../core/models/user_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_context.dart';
import 'tenant_auth_bridge_screen.dart';

class TenantTutorWelcomePage extends StatelessWidget {
  const TenantTutorWelcomePage({super.key});

  void _openAuth(BuildContext context, int initialTabIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TenantAuthBridgeScreen(
          initialTabIndex: initialTabIndex,
          destination: TenantAuthDestination.tutorTeachLearn,
          authRole: EntryUserRole.tenant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 1,
              shadowColor: Colors.black12,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF1E293B),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    context.tr(
                      bn: 'শিক্ষক বা শিক্ষার্থী খুঁজুন',
                      en: 'Find Your Perfect Tutor',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(
                      bn: 'এলাকার যাচাইকৃত শিক্ষক ও শিক্ষার্থী পোস্ট দিয়ে সহজে আপনার প্রয়োজন মেটান।',
                      en: 'Easily meet your needs with verified tutor and student posts in your area.',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 14.5,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openAuth(context, 0),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                context.tr(bn: 'লগইন করুন', en: 'Log In'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openAuth(context, 1),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                context.tr(
                                  bn: 'নতুন অ্যাকাউন্ট তৈরি করুন',
                                  en: 'Create New Account',
                                ),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
