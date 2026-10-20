import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_context.dart';
import '../../core/utils/app_language.dart';
import '../../viewmodels/app_view_models.dart';
import '../widgets/app_widgets.dart';
import 'account_screens.dart';
import 'payment/user_payment_history_screen.dart';
import 'subscription/subscription_matchmaking_screen.dart';
import 'support_screens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();

    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(
          title: context.tr(bn: 'à¦¸à§‡à¦Ÿà¦¿à¦‚à¦¸', en: 'Settings'),
          subtitle: context.tr(
            bn: 'à¦ªà§à¦°à§‹à¦«à¦¾à¦‡à¦², à¦­à¦¾à¦·à¦¾, à¦¨à§‹à¦Ÿà¦¿à¦«à¦¿à¦•à§‡à¦¶à¦¨ à¦“ à¦…à§à¦¯à¦¾à¦ª à¦¸à§‡à¦Ÿà¦†à¦ª à¦¨à¦¿à§Ÿà¦¨à§à¦¤à§à¦°à¦£ à¦•à¦°à§à¦¨à¥¤',
            en: 'Manage profile, language, notifications, and app preferences.',
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 34,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        bn: 'à¦®à¦¾à¦²à¦¿à¦• à¦ªà§à¦°à§‹à¦«à¦¾à¦‡à¦²',
                        en: 'Owner Profile',
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      viewModel.isBanglaFirst
                          ? 'à¦¬à¦¾à¦‚à¦²à¦¾-à¦«à¦¾à¦°à§à¦¸à§à¦Ÿ à¦‡à¦¨à§à¦Ÿà¦¾à¦°à¦«à§‡à¦¸ à¦šà¦¾à¦²à§ à¦†à¦›à§‡'
                          : 'English interface preview is active',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.tr(bn: 'à¦­à¦¾à¦·à¦¾', en: 'Language'),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ChoiceChip(
                label: const Text('à¦¬à¦¾à¦‚à¦²à¦¾'),
                selected: viewModel.language == AppLanguage.bangla,
                onSelected: (_) => viewModel.selectLanguage(AppLanguage.bangla),
              ),
              ChoiceChip(
                label: const Text('English'),
                selected: viewModel.language == AppLanguage.english,
                onSelected: (_) =>
                    viewModel.selectLanguage(AppLanguage.english),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.tr(
            bn: 'à¦…à§à¦¯à¦¾à¦•à¦¾à¦‰à¦¨à§à¦Ÿ',
            en: 'Account',
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.badge_outlined,
                title: context.tr(
                  bn: 'à¦ªà§à¦°à§‹à¦«à¦¾à¦‡à¦²',
                  en: 'Profile',
                ),
                subtitle: context.tr(
                  bn: 'à¦¨à¦¾à¦®, à¦®à§‹à¦¬à¦¾à¦‡à¦² à¦“ à¦®à¦¾à¦²à¦¿à¦• à¦¤à¦¥à§à¦¯',
                  en: 'Name, phone, and owner information',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileEditScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: context.tr(
                  bn: 'à¦ªà¦¾à¦¸à¦“à§Ÿà¦¾à¦°à§à¦¡ à¦ªà¦°à¦¿à¦¬à¦°à§à¦¤à¦¨',
                  en: 'Change Password',
                ),
                subtitle: context.tr(
                  bn: 'à¦…à§à¦¯à¦¾à¦•à¦¾à¦‰à¦¨à§à¦Ÿ à¦¨à¦¿à¦°à¦¾à¦ªà¦¤à§à¦¤à¦¾ à¦†à¦ªà¦¡à§‡à¦Ÿ à¦•à¦°à§à¦¨',
                  en: 'Update account security',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.history_rounded,
                title: context.tr(
                  bn: 'পেমেন্ট ও লেনদেন হিস্ট্রি',
                  en: 'Payment & Transaction History',
                ),
                subtitle: context.tr(
                  bn: 'রেজিস্ট্রেশন ফি, মাসিক চার্জ ও ভাড়ার বিবরণ',
                  en: 'Registration fee, monthly charge, and rent receipts',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const UserPaymentHistoryScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.verified_outlined,
                title: context.tr(
                  bn: 'ম্যাচমেকিং সাবস্ক্রিপশন সার্ভিস',
                  en: 'Matchmaking Subscription Service',
                ),
                subtitle: context.tr(
                  bn: 'ফ্ল্যাট, ভাড়াটিয়া, গৃহশিক্ষক বা টিউশন নিশ্চিত সন্ধান',
                  en: 'Guaranteed matchmaking for flats, tenants, tutors, or tuition',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SubscriptionMatchmakingScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.tr(bn: 'à¦†à¦°à¦“', en: 'More'),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: context.tr(
                  bn: 'à¦¨à§‹à¦Ÿà¦¿à¦«à¦¿à¦•à§‡à¦¶à¦¨',
                  en: 'Notifications',
                ),
                subtitle: context.tr(
                  bn: 'à¦°à§‡à¦¨à§à¦Ÿ à¦°à¦¿à¦®à¦¾à¦‡à¦¨à§à¦¡à¦¾à¦° à¦“ à¦ªà§‡à¦®à§‡à¦¨à§à¦Ÿ à¦…à§à¦¯à¦¾à¦²à¦¾à¦°à§à¦Ÿ',
                  en: 'Rent reminders and payment alerts',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.receipt_long_rounded,
                title: context.tr(
                  bn: 'à¦¬à¦¿à¦² à¦“ à¦–à¦°à¦š',
                  en: 'Bills & Expenses',
                ),
                subtitle: context.tr(
                  bn: 'à¦‡à¦‰à¦Ÿà¦¿à¦²à¦¿à¦Ÿà¦¿, à¦¸à¦¾à¦°à§à¦­à¦¿à¦¸ à¦“ à¦…à¦¨à§à¦¯à¦¾à¦¨à§à¦¯ à¦¬à§à¦¯à§Ÿ',
                  en: 'Utilities, services, and other costs',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ExpensesScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: context.tr(
                  bn: 'à¦•à¦®à¦¿à¦‰à¦¨à¦¿à¦•à§‡à¦¶à¦¨',
                  en: 'Communication',
                ),
                subtitle: context.tr(
                  bn: 'à¦­à¦¾à§œà¦¾à¦Ÿà¦¿à§Ÿà¦¾à¦¦à§‡à¦° à¦®à§‡à¦¸à§‡à¦œ à¦“ à¦¨à§‹à¦Ÿ',
                  en: 'Tenant messages and notes',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CommunicationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primaryDark),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
    );
  }
}
