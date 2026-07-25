import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_context.dart';
import '../../viewmodels/app_view_models.dart';
import '../widgets/app_widgets.dart';
import 'property_screen.dart';
import 'support_screens.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final summary = viewModel.summary;

    return ListView(
      padding: screenPadding,
      children: [
        _DashboardTopBar(
          onNotificationTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
          onProfileTap: () {
            context.read<ShellViewModel>().selectTab(4);
          },
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(bn: 'আজকের সারাংশ', en: "Today's Overview"),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr(
                  bn: 'প্রপার্টি, টেন্যান্ট, পেমেন্ট আর বকেয়ার অবস্থা একসাথে দেখুন।',
                  en: 'See properties, tenants, payments, and due status together.',
                ),
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr(
                          bn: 'এই মাসের মোট বকেয়া ${context.money(summary.dueRent)}',
                          en: 'This month has ${context.money(summary.dueRent)} still due.',
                        ),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.18,
          children: [
            SummaryCard(
              label: context.tr(bn: 'মোট প্রপার্টি', en: 'Total Property'),
              value: context.digitsText(summary.totalProperties),
              icon: Icons.apartment_rounded,
              color: AppColors.primary,
            ),
            SummaryCard(
              label: context.tr(bn: 'মোট টেন্যান্ট', en: 'Total Tenant'),
              value: context.digitsText(summary.totalTenants),
              icon: Icons.people_alt_rounded,
              color: AppColors.accent,
            ),
            SummaryCard(
              label: context.tr(bn: 'মাসিক আয়', en: 'Monthly Income'),
              value: context.money(summary.monthlyIncome),
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.success,
            ),
            SummaryCard(
              label: context.tr(bn: 'বকেয়া ভাড়া', en: 'Due Rent'),
              value: context.money(summary.dueRent),
              icon: Icons.pending_actions_rounded,
              color: AppColors.danger,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.tr(bn: 'দ্রুত কাজ', en: 'Quick Actions'),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              QuickActionTile(
                label: context.tr(bn: 'প্রপার্টি যোগ করুন', en: 'Add Property'),
                icon: Icons.add_business_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddBuildingScreen(),
                    ),
                  );
                },
              ),
              QuickActionTile(
                label: context.tr(bn: 'টেন্যান্ট', en: 'Tenant'),
                icon: Icons.person_add_alt_1_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TenantScreen(),
                    ),
                  );
                },
              ),
              QuickActionTile(
                label: context.tr(bn: 'বিল ও খরচ', en: 'Bills & Expenses'),
                icon: Icons.receipt_long_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ExpensesScreen(),
                    ),
                  );
                },
              ),
              QuickActionTile(
                label: context.tr(bn: 'বার্তা', en: 'Messages'),
                icon: Icons.chat_bubble_rounded,
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
        const SizedBox(height: 18),
        SectionCard(
          title: context.tr(bn: 'বকেয়া ভাড়ার তালিকা', en: 'Due Rent List'),
          child: Column(
            children: viewModel.dueProperties
                .map(
                  (property) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  '${property.buildingName ?? ''} • ${property.floorLabel ?? ''}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            context.money(property.dueAmount),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.tr(
            bn: 'সাম্প্রতিক কার্যক্রম',
            en: 'Recent Activities',
          ),
          child: Column(
            children: viewModel.recentActivities
                .map(
                  (activity) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    title: Text(activity.title),
                    subtitle: Text(activity.subtitle),
                    trailing: Text(
                      activity.timeLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const AppLogoMark(size: 50),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amar Thikanaa',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        context.tr(
                          bn: 'ম্যানেজমেন্ট সিস্টেম',
                          en: 'Management System',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _HeaderButton(
          icon: Icons.notifications_none_rounded,
          onTap: onNotificationTap,
        ),
        const SizedBox(width: 10),
        _HeaderButton(icon: Icons.person_outline_rounded, onTap: onProfileTap),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primaryDark),
        ),
      ),
    );
  }
}
