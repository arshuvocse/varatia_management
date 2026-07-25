import 'package:flutter/material.dart';

import '../../../core/models/user_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_context.dart';
import 'tenant_auth_bridge_screen.dart';

class TenantMarketplaceWelcomePage extends StatelessWidget {
  const TenantMarketplaceWelcomePage({super.key});

  void _openAuth(BuildContext context, int initialTabIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TenantAuthBridgeScreen(
          initialTabIndex: initialTabIndex,
          destination: TenantAuthDestination.marketplaceSearch,
          authRole: EntryUserRole.tenant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        surfaceTintColor: const Color(0xFFF7F8FC),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
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
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              children: [
                Center(
                  child: Container(
                    height: 92,
                    width: 92,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.travel_explore_rounded,
                      color: Color(0xFF2563EB),
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  context.tr(
                    bn: 'আপনার নতুন বাসা খুঁজুন',
                    en: 'Find Your Next Home',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    bn: 'এলাকা, বাজেট ও বাসার ধরন অনুযায়ী ভাড়া বা বিক্রির বিজ্ঞাপন খুঁজুন।',
                    en: 'Search rent or sale listings by area, budget, and property type.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 42),
                FilledButton.icon(
                  onPressed: () => _openAuth(context, 0),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(context.tr(bn: 'লগইন করুন', en: 'Log In')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => _openAuth(context, 1),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(
                    context.tr(
                      bn: 'নতুন অ্যাকাউন্ট তৈরি করুন',
                      en: 'Create New Account',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
