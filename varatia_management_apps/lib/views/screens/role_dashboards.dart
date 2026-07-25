import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_context.dart';
import '../../core/utils/local_lang.dart';
import '../../data/models/app_models.dart';
import '../../data/services/auth_session_service.dart';
import '../../data/services/dhaka_location_api_service.dart';
import '../../data/services/owner_tenant_api_service.dart';
import '../../data/services/tenant_area_api_service.dart';
import '../../viewmodels/app_view_models.dart';
import '../../viewmodels/role_dashboard_view_models.dart';
import '../widgets/app_widgets.dart';
import 'entry/entry_routes.dart';
import 'home/tenant_general_post_details_screen.dart';
import 'home/tenant_home_screen.dart';
import 'property_screen.dart';
import 'tenant_reference_pages.dart';

const _roleHomeSurfaceShadow = <BoxShadow>[
  BoxShadow(color: Color(0x120F172A), blurRadius: 18, offset: Offset(0, 8)),
  BoxShadow(color: Color(0x0A0F172A), blurRadius: 6, offset: Offset(0, 2)),
];

Future<void> _confirmTenantLogout(BuildContext context) async {
  final navigator = Navigator.of(context);
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(context.tr(bn: 'লগআউট', en: 'Log Out')),
        content: Text(
          context.tr(
            bn: 'আপনি কি নিশ্চিতভাবে লগআউট করতে চান?',
            en: 'Are you sure you want to log out?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr(bn: 'না', en: 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(context.tr(bn: 'লগআউট', en: 'Log Out')),
          ),
        ],
      );
    },
  );

  if (shouldLogout != true || !context.mounted) {
    return;
  }

  await AuthSessionService().clear();
  navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
}

class AdminDashboardOverviewPage extends StatelessWidget {
  const AdminDashboardOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminDashboardViewModel>();

    return ListView(
      padding: screenPadding,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc(AppLocalLang.adminControl),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.loc(AppLocalLang.adminControlSubtitle),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const _HeaderProfileButton(),
          ],
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: viewModel.summaryItems
              .map((item) => _MetricCard(item: item))
              .toList(growable: false),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.loc(AppLocalLang.recentActivity),
          child: Column(
            children: viewModel.recentActivities
                .map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ActivityTile(activity: activity),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class AdminVerificationRequestPage extends StatelessWidget {
  const AdminVerificationRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminDashboardViewModel>();
    final request = viewModel.verificationRequest;

    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(
          title: context.loc(AppLocalLang.verificationRequest),
          subtitle: context.loc(AppLocalLang.verificationRequestSubtitle),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.loc(AppLocalLang.userInfo),
          child: Row(
            children: [
              Container(
                height: 68,
                width: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  request.photoInitials,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        context.demoText(request.roleLabel),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.loc(AppLocalLang.documents),
          child: Column(
            children: [
              _DocumentPlaceholder(
                title: context.loc(AppLocalLang.nidFront),
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              _DocumentPlaceholder(
                title: context.loc(AppLocalLang.nidBack),
                icon: Icons.copy_all_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => showComingSoonSnackBar(
                  context,
                  context.demoText('Reject request'),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                child: Text(context.loc(AppLocalLang.reject)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => showComingSoonSnackBar(
                  context,
                  context.demoText('Approve request'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: Text(context.loc(AppLocalLang.approve)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(
          title: context.loc(AppLocalLang.settings),
          subtitle: context.loc(AppLocalLang.adminSettingsSubtitle),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.loc(AppLocalLang.controlCenter),
          child: Column(
            children: [
              _SettingTile(
                title: context.loc(AppLocalLang.userModeration),
                subtitle: context.loc(AppLocalLang.userModerationSubtitle),
              ),
              const SizedBox(height: 12),
              _SettingTile(
                title: context.loc(AppLocalLang.revenueReports),
                subtitle: context.loc(AppLocalLang.revenueReportsSubtitle),
              ),
              const SizedBox(height: 12),
              _SettingTile(
                title: context.loc(AppLocalLang.systemAlerts),
                subtitle: context.loc(AppLocalLang.systemAlertsSubtitle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key});

  void _selectOwnerTab(BuildContext context, int index) {
    context.read<RoleShellViewModel>().selectTab(index);
  }

  void _showOwnerComingSoon(BuildContext context, String label) {
    showComingSoonSnackBar(context, context.demoText(label));
  }

  void _handleQuickAction(
    BuildContext context,
    _OwnerHomeQuickActionType type,
  ) {
    switch (type) {
      case _OwnerHomeQuickActionType.billing:
      case _OwnerHomeQuickActionType.payments:
        _selectOwnerTab(context, 1);
        return;
      case _OwnerHomeQuickActionType.tenants:
        _selectOwnerTab(context, 2);
        return;
      case _OwnerHomeQuickActionType.profile:
        _selectOwnerTab(context, 3);
        return;
      case _OwnerHomeQuickActionType.addProperty:
        _showOwnerComingSoon(context, 'Add New');
        return;
      case _OwnerHomeQuickActionType.reports:
        _showOwnerComingSoon(context, 'Reports');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OwnerDashboardViewModel>();
    final confirmedPayments = viewModel.confirmedPaymentsForLatestMonth;
    final properties = viewModel.properties;
    final dueSummary = viewModel.dueBills == 0
        ? context.demoText('No dues pending')
        : context.demoText('${context.money(viewModel.dueBills)} due pending');

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFFEFF), Color(0xFFF7F8FC), Color(0xFFFDFCF9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
        children: [
          Row(
            children: [
              const Expanded(child: _OwnerBrandLockup()),
              _OwnerHeaderCircleButton(
                icon: Icons.notifications_none_rounded,
                onTap: () =>
                    _showOwnerComingSoon(context, 'Owner Notifications'),
              ),
              const SizedBox(width: 8),
              _OwnerHeaderCircleButton(
                icon: Icons.person_rounded,
                backgroundColor: const Color(0xFFF0F2F5),
                iconColor: const Color(0xFF7A818C),
                onTap: () => _selectOwnerTab(context, 3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _OwnerBulletinTicker(
            message: context.demoText(
              'Bulletin: Send monthly bills, collect rent, add tenants, and track dues from one place.',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _OwnerHomeActionPill(
                icon: Icons.home_work_rounded,
                label: context.demoText('${properties.length} Properties'),
                backgroundColor: const Color(0xFFEAF3FF),
                foregroundColor: AppColors.primary,
                onTap: () => _showOwnerComingSoon(context, 'Property List'),
              ),
              const Spacer(),
              _OwnerHomeActionPill(
                icon: Icons.receipt_long_rounded,
                label: dueSummary,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.accent,
                borderColor: const Color(0xFFE3E8F2),
                onTap: () => _selectOwnerTab(context, 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectOwnerTab(context, 2),
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE3E8F2)),
                        boxShadow: _roleHomeSurfaceShadow,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.search_rounded,
                            size: 30,
                            color: Color(0xFF737986),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.demoText(
                                'Search tenant, property, or payment...',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 14,
                                    color: const Color(0xFF6D7481),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 118,
                child: FilledButton(
                  onPressed: () => _selectOwnerTab(context, 2),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 58),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(context.demoText('Search')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _OwnerBillPromotionBanner(onTap: () => _selectOwnerTab(context, 1)),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final crossAxisCount = maxWidth >= 420
                  ? 4
                  : maxWidth >= 320
                  ? 3
                  : 2;

              return GridView.builder(
                itemCount: _ownerHomeQuickActions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 126,
                ),
                itemBuilder: (context, index) {
                  final item = _ownerHomeQuickActions[index];

                  return _OwnerHomeQuickActionCard(
                    item: item,
                    onTap: () => _handleQuickAction(context, item.type),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          _OwnerHomeSectionTitle(
            title: context.loc(AppLocalLang.myProperties),
            actionLabel: context.loc(AppLocalLang.addNew),
            onAction: () => _showOwnerComingSoon(context, 'Add New'),
          ),
          const SizedBox(height: 12),
          if (properties.isEmpty)
            const _OwnerEmptyPropertyCard()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 330 ? 1 : 2;

                return GridView.builder(
                  itemCount: properties.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 288,
                  ),
                  itemBuilder: (context, index) {
                    return _OwnerPropertyCard(property: properties[index]);
                  },
                );
              },
            ),
          const SizedBox(height: 24),
          _OwnerHomePaymentsPanel(
            viewModel: viewModel,
            confirmedPayments: confirmedPayments,
          ),
        ],
      ),
    );
  }
}

class _OwnerBrandLockup extends StatelessWidget {
  const _OwnerBrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogoMark(size: 48),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Amar',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(
                      text: 'Thikanaa',
                      style: TextStyle(color: AppColors.success),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 1),
              Text(
                context.demoText('Manage rent, tenants, and properties'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10.5,
                  color: const Color(0xFF6D7481),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnerHeaderCircleButton extends StatelessWidget {
  const _OwnerHeaderCircleButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor = Colors.transparent,
    this.iconColor = AppColors.textPrimary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
      ),
    );
  }
}

class _OwnerBulletinTicker extends StatefulWidget {
  const _OwnerBulletinTicker({required this.message});

  final String message;

  @override
  State<_OwnerBulletinTicker> createState() => _OwnerBulletinTickerState();
}

class _OwnerBulletinTickerState extends State<_OwnerBulletinTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.danger,
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
    final painter = TextPainter(
      text: TextSpan(text: widget.message, style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    final textWidth = painter.width + 18;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD6D6)),
        boxShadow: _roleHomeSurfaceShadow,
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.campaign_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final offset =
                          constraints.maxWidth -
                          (constraints.maxWidth + textWidth) *
                              _controller.value;

                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                  );
                },
                child: Text(
                  widget.message,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: textStyle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _OwnerHomeActionPill extends StatelessWidget {
  const _OwnerHomeActionPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
            boxShadow: backgroundColor == Colors.white
                ? _roleHomeSurfaceShadow
                : null,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 176),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: foregroundColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      color: foregroundColor,
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

class _OwnerBillPromotionBanner extends StatelessWidget {
  const _OwnerBillPromotionBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFDB53E), Color(0xFFFF6E20)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: _roleHomeSurfaceShadow,
          ),
          child: Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFF57C00),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc(AppLocalLang.monthlyBillGenerator),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.demoText('Prepare rent and utility bills'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

enum _OwnerHomeQuickActionType {
  billing,
  tenants,
  addProperty,
  payments,
  reports,
  profile,
}

class _OwnerHomeQuickActionData {
  const _OwnerHomeQuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.type,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final _OwnerHomeQuickActionType type;
}

const _ownerHomeQuickActions = <_OwnerHomeQuickActionData>[
  _OwnerHomeQuickActionData(
    title: 'Send Bill',
    subtitle: 'Rent cycle',
    icon: Icons.request_quote_rounded,
    color: AppColors.primary,
    type: _OwnerHomeQuickActionType.billing,
  ),
  _OwnerHomeQuickActionData(
    title: 'Tenants',
    subtitle: 'Manage list',
    icon: Icons.groups_rounded,
    color: AppColors.success,
    type: _OwnerHomeQuickActionType.tenants,
  ),
  _OwnerHomeQuickActionData(
    title: 'Add New',
    subtitle: 'Property',
    icon: Icons.add_home_rounded,
    color: AppColors.accent,
    type: _OwnerHomeQuickActionType.addProperty,
  ),
  _OwnerHomeQuickActionData(
    title: 'Payments',
    subtitle: 'Confirmed',
    icon: Icons.payments_rounded,
    color: Color(0xFF7C3AED),
    type: _OwnerHomeQuickActionType.payments,
  ),
  _OwnerHomeQuickActionData(
    title: 'Reports',
    subtitle: 'Overview',
    icon: Icons.bar_chart_rounded,
    color: Color(0xFF0EA5E9),
    type: _OwnerHomeQuickActionType.reports,
  ),
  _OwnerHomeQuickActionData(
    title: 'Profile',
    subtitle: 'Account',
    icon: Icons.person_rounded,
    color: Color(0xFFEC4899),
    type: _OwnerHomeQuickActionType.profile,
  ),
];

class _OwnerHomeQuickActionCard extends StatelessWidget {
  const _OwnerHomeQuickActionCard({required this.item, required this.onTap});

  final _OwnerHomeQuickActionData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF3)),
            boxShadow: _roleHomeSurfaceShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 25),
              ),
              const SizedBox(height: 10),
              Text(
                context.demoText(item.title),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: 12.8, height: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                context.demoText(item.subtitle),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10.4,
                  height: 1.15,
                  color: const Color(0xFF6F7786),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerHomeSectionTitle extends StatelessWidget {
  const _OwnerHomeSectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.demoText(title),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.demoText(actionLabel)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnerEmptyPropertyCard extends StatelessWidget {
  const _OwnerEmptyPropertyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF3)),
        boxShadow: _roleHomeSurfaceShadow,
      ),
      child: Text(
        context.demoText('No properties added yet.'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _OwnerHomePaymentsPanel extends StatelessWidget {
  const _OwnerHomePaymentsPanel({
    required this.viewModel,
    required this.confirmedPayments,
  });

  final OwnerDashboardViewModel viewModel;
  final List<RentPayment> confirmedPayments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF3)),
        boxShadow: _roleHomeSurfaceShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.demoText('Confirmed Payments'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusBadge(
                label: context.demoText(
                  '${viewModel.confirmedPaymentsThisMonthCount} paid',
                ),
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.demoText(
                          viewModel.confirmedPaymentsMonthLabel ??
                              'No confirmed payments yet',
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.demoText(
                          'Latest rent cycle with confirmed tenant payments.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OwnerPaymentQuickStat(
                  label: 'Collected',
                  value: context.money(
                    viewModel.confirmedPaymentsThisMonthTotal,
                  ),
                  icon: Icons.payments_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OwnerPaymentQuickStat(
                  label: 'Tenants Paid',
                  value: context.digitsText(
                    viewModel.confirmedPaymentsThisMonthCount,
                  ),
                  icon: Icons.person_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (confirmedPayments.isEmpty)
            const _OwnerConfirmedPaymentEmptyState()
          else
            Column(
              children: confirmedPayments
                  .take(4)
                  .map(
                    (payment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OwnerConfirmedPaymentTile(payment: payment),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class OwnerBillingGeneratorPage extends StatelessWidget {
  const OwnerBillingGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OwnerDashboardViewModel>();

    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(
          title: context.loc(AppLocalLang.monthlyBillGenerator),
          subtitle: context.loc(AppLocalLang.monthlyBillGeneratorSubtitle),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.loc(AppLocalLang.billingForm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc(AppLocalLang.selectTenant),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: viewModel.selectedTenantId,
                items: viewModel.tenants
                    .map(
                      (tenant) => DropdownMenuItem<String>(
                        value: tenant.id,
                        child: Text('${tenant.name} - ${tenant.propertyName}'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: viewModel.selectTenant,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              _BillAmountField(
                fieldKey: ValueKey('house-rent-${viewModel.selectedTenantId}'),
                initialValue: viewModel.houseRent > 0
                    ? viewModel.houseRent.toStringAsFixed(0)
                    : null,
                label: context.tr(bn: 'House Rent', en: 'House Rent'),
                icon: Icons.home_work_rounded,
                onChanged: viewModel.updateHouseRent,
              ),
              const SizedBox(height: 16),
              _BillAmountField(
                label: context.loc(AppLocalLang.electricityBill),
                icon: Icons.bolt_rounded,
                onChanged: viewModel.updateElectricityBill,
              ),
              const SizedBox(height: 16),
              _BillAmountField(
                label: context.loc(AppLocalLang.waterBill),
                icon: Icons.water_drop_rounded,
                onChanged: viewModel.updateWaterBill,
              ),
              const SizedBox(height: 16),
              _BillAmountField(
                label: context.loc(AppLocalLang.gasBill),
                icon: Icons.local_fire_department_rounded,
                onChanged: viewModel.updateGasBill,
              ),
              const SizedBox(height: 16),
              _BillAmountField(
                label: context.loc(AppLocalLang.serviceCharge),
                icon: Icons.miscellaneous_services_rounded,
                onChanged: viewModel.updateServiceCharge,
              ),
              const SizedBox(height: 16),
              _DatePickerTile(
                date: viewModel.dueDate,
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: viewModel.dueDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2032),
                  );
                  if (selectedDate != null && context.mounted) {
                    viewModel.setDueDate(selectedDate);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                context.loc(AppLocalLang.totalAmount),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: ValueKey(viewModel.totalAmount.toStringAsFixed(2)),
                initialValue: context.money(viewModel.totalAmount),
                readOnly: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calculate_rounded),
                ),
              ),
              const SizedBox(height: 18),
              if (viewModel.billSubmitError != null) ...[
                Text(
                  viewModel.billSubmitError!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: viewModel.isSendingBill
                    ? null
                    : () async {
                        final result = await context
                            .read<OwnerDashboardViewModel>()
                            .submitMonthlyBill();
                        if (!context.mounted) {
                          return;
                        }

                        final fallbackMessage = context.tr(
                          bn: 'Bill send failed.',
                          en: 'Bill send failed.',
                        );
                        final errorMessage =
                            context
                                .read<OwnerDashboardViewModel>()
                                .billSubmitError ??
                            fallbackMessage;
                        final message = result == null
                            ? errorMessage
                            : context.tr(
                                bn: 'Bill sent to ${result.tenant.name}. Total ${context.money(result.totalAmount)}',
                                en: 'Bill sent to ${result.tenant.name}. Total ${context.money(result.totalAmount)}',
                              );

                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text(message)));
                      },
                child: viewModel.isSendingBill
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(context.tr(bn: 'Sending...', en: 'Sending...')),
                        ],
                      )
                    : Text(context.loc(AppLocalLang.sendBillToTenant)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OwnerTenantsPage extends StatefulWidget {
  const OwnerTenantsPage({super.key});

  @override
  State<OwnerTenantsPage> createState() => _OwnerTenantsPageState();
}

class _OwnerTenantsPageState extends State<OwnerTenantsPage> {
  final TextEditingController _tenantSearchController = TextEditingController();
  String _tenantSearchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<OwnerDashboardViewModel>().loadTenantsFromApi();
      context.read<OwnerDashboardViewModel>().loadPropertiesFromApi();
    });
  }

  @override
  void dispose() {
    _tenantSearchController.dispose();
    super.dispose();
  }

  List<TenantProfile> _filterTenants(
    List<TenantProfile> tenants,
    OwnerDashboardViewModel viewModel,
  ) {
    final query = _tenantSearchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return tenants;
    }

    return tenants
        .where(
          (tenant) => _tenantMatchesSearch(
            tenant,
            viewModel.propertyForTenant(tenant),
            query,
          ),
        )
        .toList(growable: false);
  }

  bool _tenantMatchesSearch(
    TenantProfile tenant,
    PropertyUnit? property,
    String query,
  ) {
    final searchableText = [
      tenant.id,
      tenant.name,
      tenant.phone,
      tenant.nid,
      tenant.propertyId,
      tenant.propertyName,
      tenant.location,
      tenant.buildingId,
      tenant.buildingName,
      tenant.floorId,
      tenant.floorLabel,
      property?.id,
      property?.name,
      property?.location,
      property?.buildingId,
      property?.buildingName,
      property?.floorId,
      property?.floorLabel,
    ].join(' ').toLowerCase();

    return searchableText.contains(query);
  }

  Future<void> _openCreateTenantSheet(BuildContext context) async {
    final viewModel = context.read<OwnerDashboardViewModel>();
    final createdTenant = await showModalBottomSheet<OwnerTenantCreateResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTenantBottomSheet(viewModel: viewModel),
    );

    if (createdTenant == null || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            bn: '${createdTenant.tenant.name} was added successfully.',
            en: '${createdTenant.tenant.name} was added successfully.',
          ),
        ),
      ),
    );

    await _showTenantCredentialDialog(context, createdTenant);
  }

  Future<void> _showTenantCredentialDialog(
    BuildContext context,
    OwnerTenantCreateResult result,
  ) async {
    final smsStatus = result.credentialSmsSent
        ? context.tr(bn: 'Sent', en: 'Sent')
        : context.tr(bn: 'Not sent', en: 'Not sent');
    final hasSmsError = result.credentialSmsError.trim().isNotEmpty;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            context.tr(
              bn: 'Tenant Login Credentials',
              en: 'Tenant Login Credentials',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoLine(
                label: context.tr(bn: 'Tenant', en: 'Tenant'),
                value: result.tenant.name,
              ),
              InfoLine(
                label: context.tr(bn: 'Assigned Unit', en: 'Assigned Unit'),
                value: _tenantResidenceLabel(result.tenant, null),
              ),
              if (_firstNonEmpty([result.tenant.location]).isNotEmpty)
                InfoLine(
                  label: context.tr(bn: 'Location', en: 'Location'),
                  value: _firstNonEmpty([result.tenant.location]),
                ),
              InfoLine(
                label: context.tr(bn: 'Login Phone', en: 'Login Phone'),
                value: result.loginPhoneNumber,
              ),
              InfoLine(
                label: context.tr(
                  bn: 'Temporary Password',
                  en: 'Temporary Password',
                ),
                value: result.temporaryPassword,
              ),
              InfoLine(
                label: context.tr(bn: 'SMS Status', en: 'SMS Status'),
                value: smsStatus,
              ),
              if (hasSmsError) ...[
                const SizedBox(height: 12),
                Text(
                  context.tr(bn: 'SMS Error', en: 'SMS Error'),
                  style: Theme.of(dialogContext).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  result.credentialSmsError,
                  style: Theme.of(
                    dialogContext,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.tr(bn: 'Close', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEditTenantSheet(
    BuildContext context,
    TenantProfile tenant,
  ) async {
    final viewModel = context.read<OwnerDashboardViewModel>();
    final updatedTenant = await showModalBottomSheet<TenantProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _EditTenantBottomSheet(viewModel: viewModel, tenant: tenant),
    );

    if (updatedTenant == null || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            bn: '${updatedTenant.name} à¦¸à¦«à¦²à¦­à¦¾à¦¬à§‡ à¦†à¦ªà¦¡à§‡à¦Ÿ à¦¹à§Ÿà§‡à¦›à§‡à¥¤',
            en: '${updatedTenant.name} was updated successfully.',
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTenant(
    BuildContext context,
    TenantProfile tenant,
  ) async {
    final viewModel = context.read<OwnerDashboardViewModel>();
    viewModel.clearTenantDeleteError();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr(bn: 'Delete Tenant', en: 'Delete Tenant')),
          content: Text(
            context.tr(
              bn: '${tenant.name} কে delete করলে property আবার vacant হয়ে যাবে।',
              en: 'Deleting ${tenant.name} will mark the property as vacant again.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr(bn: 'Cancel', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: Text(context.tr(bn: 'Delete', en: 'Delete')),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    final deletedTenant = await viewModel.deleteTenant(tenantId: tenant.id);

    if (!context.mounted) {
      return;
    }

    if (deletedTenant == null) {
      final errorMessage = viewModel.tenantDeleteError;
      if (errorMessage != null && errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            bn: '${deletedTenant.name} à¦¸à¦«à¦²à¦­à¦¾à¦¬à§‡ delete à¦¹à§Ÿà§‡à¦›à§‡à¥¤',
            en: '${deletedTenant.name} was deleted successfully.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OwnerDashboardViewModel>();
    final isActionBusy =
        viewModel.isCreatingTenant ||
        viewModel.isUpdatingTenant ||
        viewModel.isDeletingTenant;
    final tenants = viewModel.tenants;
    final filteredTenants = _filterTenants(tenants, viewModel);
    final shouldShowSearch =
        tenants.isNotEmpty || _tenantSearchQuery.isNotEmpty;

    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(
          title: context.loc(AppLocalLang.tenants),
          subtitle: context.loc(AppLocalLang.tenantsSubtitleOwner),
          trailing: FilledButton.icon(
            onPressed: isActionBusy || viewModel.availableProperties.isEmpty
                ? null
                : () => _openCreateTenantSheet(context),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(context.tr(bn: 'Add Tenant', en: 'Add Tenant')),
          ),
        ),
        const SizedBox(height: 18),
        if (shouldShowSearch) ...[
          TextField(
            controller: _tenantSearchController,
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              setState(() {
                _tenantSearchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: context.tr(
                bn: 'Search tenants by name, phone, NID, property, building, floor, or location',
                en: 'Search tenants by name, phone, NID, property, building, floor, or location',
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _tenantSearchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.tr(bn: 'Clear', en: 'Clear'),
                      onPressed: () {
                        _tenantSearchController.clear();
                        setState(() {
                          _tenantSearchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (viewModel.tenantListError != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(AppRadii.card),
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
                    viewModel.tenantListError!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: viewModel.isLoadingTenants
                      ? null
                      : () => viewModel.loadTenantsFromApi(forceRefresh: true),
                  child: Text(context.tr(bn: 'Retry', en: 'Retry')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (viewModel.availableProperties.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr(
                      bn: 'নতুন tenant যোগ করতে আগে একটি vacant property দরকার।',
                      en: 'A vacant property is required before adding a new tenant.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (viewModel.isLoadingTenants && tenants.isEmpty) ...[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 18),
        ],
        if (!viewModel.isLoadingTenants && tenants.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              context.tr(bn: 'No tenants found.', en: 'No tenants found.'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (!viewModel.isLoadingTenants &&
            tenants.isNotEmpty &&
            filteredTenants.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_off_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr(
                      bn: 'No matching tenants found.',
                      en: 'No matching tenants found.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        ...filteredTenants.map(
          (tenant) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TenantInfoCard(
              tenant: tenant,
              property: viewModel.propertyForTenant(tenant),
              isActionBusy: isActionBusy,
              onEdit: () => _openEditTenantSheet(context, tenant),
              onDelete: () => _confirmDeleteTenant(context, tenant),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateTenantBottomSheet extends StatefulWidget {
  const _CreateTenantBottomSheet({required this.viewModel});

  final OwnerDashboardViewModel viewModel;

  @override
  State<_CreateTenantBottomSheet> createState() =>
      _CreateTenantBottomSheetState();
}

class _CreateTenantBottomSheetState extends State<_CreateTenantBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nidController = TextEditingController();

  String? _selectedPropertyId;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    widget.viewModel.clearTenantCreationError();
    final availableProperties = widget.viewModel.availableProperties;
    if (availableProperties.isNotEmpty) {
      _selectedPropertyId = availableProperties.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nidController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final fullName = _nameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final nid = _nidController.text.trim();

    final validationError = _validate(
      fullName: fullName,
      phoneNumber: phoneNumber,
      nid: nid,
      propertyId: _selectedPropertyId,
    );

    if (validationError != null) {
      setState(() {
        _validationError = validationError;
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    final createdTenant = await widget.viewModel.createTenant(
      fullName: fullName,
      phoneNumber: phoneNumber,
      nid: nid,
      propertyId: _selectedPropertyId!,
    );

    if (!mounted || createdTenant == null) {
      return;
    }

    Navigator.of(context).pop(createdTenant);
  }

  String? _validate({
    required String fullName,
    required String phoneNumber,
    required String nid,
    required String? propertyId,
  }) {
    final normalizedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (fullName.length < 3) {
      return context.tr(
        bn: 'Tenant name must contain at least 3 characters.',
        en: 'Tenant name must contain at least 3 characters.',
      );
    }

    if (normalizedPhoneNumber.length < 10 ||
        normalizedPhoneNumber.length > 15) {
      return context.tr(
        bn: 'Phone number must contain 10 to 15 digits.',
        en: 'Phone number must contain 10 to 15 digits.',
      );
    }

    if (nid.length < 10) {
      return context.tr(
        bn: 'NID must contain at least 10 characters.',
        en: 'NID must contain at least 10 characters.',
      );
    }

    if (propertyId == null || propertyId.isEmpty) {
      return context.tr(
        bn: 'Please select a property.',
        en: 'Please select a property.',
      );
    }

    return null;
  }

  PropertyUnit? _selectedProperty(List<PropertyUnit> properties) {
    final propertyId = _selectedPropertyId;
    if (propertyId == null || propertyId.isEmpty) {
      return null;
    }

    for (final property in properties) {
      if (property.id == propertyId) {
        return property;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final availableProperties = widget.viewModel.availableProperties;
        final selectedProperty = _selectedProperty(availableProperties);
        final isSubmitting = widget.viewModel.isCreatingTenant;
        final errorMessage =
            _validationError ?? widget.viewModel.tenantCreationError;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppShadows.card,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr(
                              bn: 'Create Tenant',
                              en: 'Create Tenant',
                            ),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        bn: 'Owner panel থেকে নতুন tenant profile যোগ করুন.',
                        en: 'Add a new tenant profile from the owner panel.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    EntryTextField(
                      controller: _nameController,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      label: context.tr(bn: 'Tenant Name', en: 'Tenant Name'),
                      hint: context.tr(
                        bn: 'Enter tenant full name',
                        en: 'Enter tenant full name',
                      ),
                      icon: Icons.person_outline_rounded,
                      dense: true,
                    ),
                    const SizedBox(height: 14),
                    EntryTextField(
                      controller: _phoneController,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      label: context.tr(bn: 'Phone Number', en: 'Phone Number'),
                      hint: context.tr(
                        bn: 'Enter tenant phone number',
                        en: 'Enter tenant phone number',
                      ),
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      dense: true,
                    ),
                    const SizedBox(height: 14),
                    EntryTextField(
                      controller: _nidController,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      label: context.tr(bn: 'NID Number', en: 'NID Number'),
                      hint: context.tr(
                        bn: 'Enter tenant NID',
                        en: 'Enter tenant NID',
                      ),
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      dense: true,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.tr(bn: 'Assign Property', en: 'Assign Property'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPropertyId,
                      items: availableProperties
                          .map(
                            (property) => DropdownMenuItem<String>(
                              value: property.id,
                              child: Text(
                                _propertyDropdownLabel(property),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                _selectedPropertyId = value;
                              });
                            },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.home_work_outlined),
                      ),
                    ),
                    if (selectedProperty != null) ...[
                      const SizedBox(height: 12),
                      _PropertyAssignmentPreview(property: selectedProperty),
                    ],
                    if (errorMessage != null) ...[
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
                          errorMessage,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFFB42318),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(context.tr(bn: 'Cancel', en: 'Cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSubmitting ? null : _submit,
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    context.tr(
                                      bn: 'Create Tenant',
                                      en: 'Create Tenant',
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PropertyAssignmentPreview extends StatelessWidget {
  const _PropertyAssignmentPreview({required this.property});

  final PropertyUnit property;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InfoLine(label: 'Location', value: property.location),
          InfoLine(
            label: 'Building',
            value: _firstNonEmpty([property.buildingName, property.buildingId]),
          ),
          InfoLine(
            label: 'Floor',
            value: _firstNonEmpty([property.floorLabel, property.floorId]),
          ),
          InfoLine(label: 'Flat/Unit', value: property.name),
          InfoLine(
            label: 'Monthly Rent',
            value: context.money(property.monthlyRent),
          ),
        ],
      ),
    );
  }
}

String _propertyDropdownLabel(PropertyUnit property) {
  final residenceLabel = _propertyResidenceLabel(property);
  final location = property.location.trim();
  if (location.isEmpty) {
    return residenceLabel;
  }

  return '$residenceLabel • $location';
}

String _propertyResidenceLabel(PropertyUnit property) {
  final parts = [
    property.buildingName,
    property.floorLabel,
    property.name,
  ].where((value) => value != null && value.trim().isNotEmpty).cast<String>();

  return parts.join(' • ');
}

class _EditTenantBottomSheet extends StatefulWidget {
  const _EditTenantBottomSheet({required this.viewModel, required this.tenant});

  final OwnerDashboardViewModel viewModel;
  final TenantProfile tenant;

  @override
  State<_EditTenantBottomSheet> createState() => _EditTenantBottomSheetState();
}

class _EditTenantBottomSheetState extends State<_EditTenantBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _nidController;

  String? _validationError;

  @override
  void initState() {
    super.initState();
    widget.viewModel.clearTenantUpdateError();
    _nameController = TextEditingController(text: widget.tenant.name);
    _phoneController = TextEditingController(text: widget.tenant.phone);
    _nidController = TextEditingController(text: widget.tenant.nid);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nidController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final fullName = _nameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final nid = _nidController.text.trim();

    final validationError = _validate(
      fullName: fullName,
      phoneNumber: phoneNumber,
      nid: nid,
    );

    if (validationError != null) {
      setState(() {
        _validationError = validationError;
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    final updatedTenant = await widget.viewModel.updateTenant(
      tenantId: widget.tenant.id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      nid: nid,
    );

    if (!mounted || updatedTenant == null) {
      return;
    }

    Navigator.of(context).pop(updatedTenant);
  }

  String? _validate({
    required String fullName,
    required String phoneNumber,
    required String nid,
  }) {
    final normalizedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (fullName.length < 3) {
      return context.tr(
        bn: 'Tenant name must contain at least 3 characters.',
        en: 'Tenant name must contain at least 3 characters.',
      );
    }

    if (normalizedPhoneNumber.length < 10 ||
        normalizedPhoneNumber.length > 15) {
      return context.tr(
        bn: 'Phone number must contain 10 to 15 digits.',
        en: 'Phone number must contain 10 to 15 digits.',
      );
    }

    if (nid.length < 10) {
      return context.tr(
        bn: 'NID must contain at least 10 characters.',
        en: 'NID must contain at least 10 characters.',
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final isSubmitting = widget.viewModel.isUpdatingTenant;
        final errorMessage =
            _validationError ?? widget.viewModel.tenantUpdateError;
        final assignedProperty = widget.viewModel.propertyForTenant(
          widget.tenant,
        );
        final residenceLabel = assignedProperty == null
            ? widget.tenant.propertyName
            : _propertyResidenceLabel(assignedProperty);

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppShadows.card,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr(bn: 'Edit Tenant', en: 'Edit Tenant'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        bn: '$residenceLabel এর tenant profile update করুন.',
                        en: 'Update the tenant profile assigned to $residenceLabel.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    EntryTextField(
                      controller: _nameController,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      label: context.tr(bn: 'Tenant Name', en: 'Tenant Name'),
                      hint: context.tr(
                        bn: 'Enter tenant full name',
                        en: 'Enter tenant full name',
                      ),
                      icon: Icons.person_outline_rounded,
                      dense: true,
                    ),
                    const SizedBox(height: 14),
                    EntryTextField(
                      controller: _phoneController,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      label: context.tr(bn: 'Phone Number', en: 'Phone Number'),
                      hint: context.tr(
                        bn: 'Enter tenant phone number',
                        en: 'Enter tenant phone number',
                      ),
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      dense: true,
                    ),
                    const SizedBox(height: 14),
                    EntryTextField(
                      controller: _nidController,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.done,
                      label: context.tr(bn: 'NID Number', en: 'NID Number'),
                      hint: context.tr(
                        bn: 'Enter tenant NID',
                        en: 'Enter tenant NID',
                      ),
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      dense: true,
                    ),
                    const SizedBox(height: 14),
                    if (assignedProperty == null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.home_work_outlined,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                residenceLabel,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _PropertyAssignmentPreview(property: assignedProperty),
                    if (errorMessage != null) ...[
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
                          errorMessage,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFFB42318),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(context.tr(bn: 'Cancel', en: 'Cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSubmitting ? null : _submit,
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    context.tr(
                                      bn: 'Save Changes',
                                      en: 'Save Changes',
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OwnerProfilePage extends StatelessWidget {
  const OwnerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OwnerDashboardViewModel>();
    final propertyViewModel = context.watch<PropertyViewModel>();
    final propertyUnits = propertyViewModel.properties;

    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(
          title: context.loc(AppLocalLang.profile),
          subtitle: context.loc(AppLocalLang.ownerWorkspaceProfileSubtitle),
        ),
        const SizedBox(height: 18),
        _ProfileSummaryCard(
          title: viewModel.ownerProfile.name,
          subtitle: context.loc(AppLocalLang.propertyOwnerRole),
          icon: Icons.person_rounded,
          badge: '${propertyUnits.length} properties',
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.tr(bn: 'Property Setup', en: 'Property Setup'),
          child: Column(
            children: [
              _OwnerProfileSetupAction(
                title: context.tr(
                  bn: 'Location & Building',
                  en: 'Location & Building',
                ),
                subtitle: context.tr(
                  bn: 'Add building name, location, and total floors.',
                  en: 'Add building name, location, and total floors.',
                ),
                icon: Icons.add_business_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddBuildingScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 22),
              _OwnerProfileSetupAction(
                title: context.tr(bn: 'Floor', en: 'Floor'),
                subtitle: context.tr(
                  bn: 'Add a floor under an existing building.',
                  en: 'Add a floor under an existing building.',
                ),
                icon: Icons.layers_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddFloorScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 22),
              _OwnerProfileSetupAction(
                title: context.tr(bn: 'Flat', en: 'Flat'),
                subtitle: context.tr(
                  bn: 'Add a flat/unit with rent and availability.',
                  en: 'Add a flat/unit with rent and availability.',
                ),
                icon: Icons.door_front_door_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddUnitScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.tr(bn: 'Property Details', en: 'Property Details'),
          child: propertyUnits.isEmpty
              ? Text(
                  context.tr(
                    bn: 'No flats added yet.',
                    en: 'No flats added yet.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : Column(
                  children: propertyUnits
                      .map(
                        (property) => Padding(
                          padding: EdgeInsets.only(
                            bottom: property == propertyUnits.last ? 0 : 12,
                          ),
                          child: _OwnerProfilePropertyTile(property: property),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.loc(AppLocalLang.workspaceSnapshot),
          child: Column(
            children: [
              InfoLine(
                label: context.loc(AppLocalLang.collectedRent),
                value: context.money(viewModel.collectedRent),
              ),
              InfoLine(
                label: context.loc(AppLocalLang.dueBills),
                value: context.money(viewModel.dueBills),
              ),
              InfoLine(
                label: context.loc(AppLocalLang.activeTenants),
                value: context.digitsText(viewModel.tenants.length),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnerProfileSetupAction extends StatelessWidget {
  const _OwnerProfileSetupAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.demoText(title),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.demoText(subtitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerProfilePropertyTile extends StatelessWidget {
  const _OwnerProfilePropertyTile({required this.property});

  final PropertyUnit property;

  String _fallback(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Not set';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.demoText(property.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge.forProperty(context, property.status),
            ],
          ),
          const SizedBox(height: 12),
          _OwnerProfilePropertyInfo(
            icon: Icons.location_on_outlined,
            label: context.tr(bn: 'Location', en: 'Location'),
            value: property.location,
          ),
          const SizedBox(height: 8),
          _OwnerProfilePropertyInfo(
            icon: Icons.apartment_rounded,
            label: context.tr(bn: 'Building', en: 'Building'),
            value: _fallback(property.buildingName),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _OwnerProfilePropertyInfo(
                  icon: Icons.layers_outlined,
                  label: context.tr(bn: 'Floor', en: 'Floor'),
                  value: _fallback(property.floorLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OwnerProfilePropertyInfo(
                  icon: Icons.door_front_door_outlined,
                  label: context.tr(bn: 'Flat', en: 'Flat'),
                  value: property.name,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerProfilePropertyInfo extends StatelessWidget {
  const _OwnerProfilePropertyInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.textMuted),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.demoText(label),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.demoText(value),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TenantHomePage extends StatelessWidget {
  const TenantHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();
    final recommendedListings = viewModel.filteredFeaturedListings
        .take(2)
        .toList(growable: false);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7FAFF), Color(0xFFF5F7FA), Color(0xFFFFF8F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -40,
            left: -26,
            child: _MarketplaceBackdropBubble(
              size: 172,
              colors: [Color(0x143B82F6), Color(0x0AFFFFFF)],
            ),
          ),
          const Positioned(
            top: 336,
            right: -48,
            child: _MarketplaceBackdropBubble(
              size: 188,
              colors: [Color(0x12F97316), Color(0x08FFFFFF)],
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 144),
            children: [
              Row(
                children: [
                  const _MarketplaceBrand(),
                  const Spacer(),
                  const _MarketplaceHeaderButton(
                    icon: Icons.notifications_none_rounded,
                  ),
                  const SizedBox(width: 4),
                  const _MarketplaceHeaderButton(
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                  const SizedBox(width: 4),
                  const _MarketplaceHeaderButton(
                    icon: Icons.account_circle_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _MarketplaceSearchBar(
                hintText: context.tr(
                  bn: 'এলাকা, বাজেট বা কীওয়ার্ড লিখুন...',
                  en: 'Search area, budget or keyword...',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 112,
                child: Row(
                  children: viewModel.quickActions
                      .map(
                        (item) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: item == viewModel.quickActions.first
                                  ? 8
                                  : 0,
                              left: item == viewModel.quickActions.first
                                  ? 0
                                  : 8,
                            ),
                            child: _HomeShortcutCard(
                              item: item,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => switch (item.type) {
                                      HomeShortcutType.createPost =>
                                        const TenantPostComposerPage(),
                                      HomeShortcutType.myPosts =>
                                        const TenantMyPostsPage(),
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 24),
              _MarketplaceSectionHeader(
                title: context.tr(bn: 'ফ্ল্যাট ভাড়া / সেল', en: 'Rent / Sale'),
                actionLabel: context.tr(bn: 'সব দেখুন', en: 'See all'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 110,
                child: Row(
                  children: viewModel.marketplaceActions
                      .map(
                        (item) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: item == viewModel.marketplaceActions.first
                                  ? 8
                                  : 0,
                              left: item == viewModel.marketplaceActions.first
                                  ? 0
                                  : 8,
                            ),
                            child: _MarketplaceActionCard(
                              item: item,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        TenantMarketplaceCategoryPage(
                                          category: item.category,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr(
                        bn: 'প্রস্তাবিত লিস্টিং',
                        en: 'Recommended Listings',
                      ),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    context.tr(bn: 'নতুন', en: 'Newest'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (recommendedListings.isEmpty)
                _MarketplaceEmptyStateCard(
                  icon: Icons.search_off_rounded,
                  title: context.tr(
                    bn: 'No matching listings',
                    en: 'No matching listings',
                  ),
                  subtitle: context.tr(
                    bn: 'Try another keyword or clear the search.',
                    en: 'Try another keyword or clear the search.',
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth < 300 ? 1 : 2;
                    final childAspectRatio = crossAxisCount == 1
                        ? 1.14
                        : constraints.maxWidth < 360
                        ? 0.58
                        : 0.64;
                    return GridView.builder(
                      itemCount: recommendedListings.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        return _FeaturedListingCard(
                          listing: recommendedListings[index],
                          isCompact: true,
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 24),
              _MarketplaceSectionHeader(
                title: context.tr(bn: 'জনপ্রিয় এলাকা', en: 'Popular Areas'),
                actionLabel: context.tr(bn: 'সব', en: 'All'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: viewModel.popularAreas.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _PopularAreaCard(
                      area: viewModel.popularAreas[index],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showLocationFilterBottomSheet(
  BuildContext context,
  TenantExperienceViewModel viewModel,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.loc(AppLocalLang.locationFilters),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (viewModel.hasActiveSearchFilters)
                      TextButton(
                        onPressed: () {
                          viewModel.clearSearchAndLocationFilters();
                          Navigator.pop(context);
                        },
                        child: Text(context.loc(AppLocalLang.reset)),
                      )
                    else
                      const SizedBox(height: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: const _MarketplaceLocationFilterFields(
                  accentColor: AppColors.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.search),
                    label: Text(context.tr(bn: 'সার্চ করুন', en: 'Search')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    },
  );
}

class TenantMarketplaceSearchPage extends StatelessWidget {
  const TenantMarketplaceSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();
    final query = viewModel.marketplaceSearchQuery.toLowerCase();

    final allListings = viewModel.generalPosts.isNotEmpty
        ? viewModel.generalPosts.map(mapGeneralPostToShowcase).toList()
        : publicTenantShowcaseListings;

    final filteredListings = query.isEmpty
        ? allListings
        : allListings
              .where(
                (l) =>
                    context.loc(l.title).toLowerCase().contains(query) ||
                    context.loc(l.location).toLowerCase().contains(query) ||
                    context.loc(l.badge).toLowerCase().contains(query),
              )
              .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        ScreenHeader(
          title: context.tr(bn: 'সার্চ', en: 'Search'),
          subtitle: context.tr(
            bn: 'এলাকা, বাজেট এবং টাইপ অনুযায়ী লিস্টিং খুঁজুন।',
            en: 'Search listings by area, budget, and property type.',
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showLocationFilterBottomSheet(context, viewModel),
                icon: const Icon(Icons.map_outlined),
                label: Text(context.tr(bn: 'এলাকা অনুযায়ী', en: 'Area wise')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => viewModel.toggleNearMe(),
                icon: Icon(
                  viewModel.isNearMeActive
                      ? Icons.my_location
                      : Icons.location_searching,
                ),
                label: Text(context.tr(bn: 'আমার আশেপাশে', en: 'Near me')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: viewModel.isNearMeActive
                      ? Colors.white
                      : AppColors.primary,
                  backgroundColor: viewModel.isNearMeActive
                      ? AppColors.primary
                      : Colors.transparent,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                context.loc(AppLocalLang.matchingListings),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              context.tr(
                bn: '${context.digitsText(filteredListings.length)} found',
                en: '${filteredListings.length} found',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredListings.isEmpty)
          _MarketplaceEmptyStateCard(
            icon: Icons.search_off_rounded,
            title: context.loc(AppLocalLang.noListingsForLocation),
            subtitle: context.loc(
              AppLocalLang.tryAnotherDivisionDistrictUpazila,
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return ListView.separated(
                  itemCount: filteredListings.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final listing = filteredListings[index];
                    return buildTenantShowcaseListingCard(
                      listing: listing,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TenantGeneralPostDetailsScreen(
                              listing: listing,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }

              return GridView.builder(
                itemCount: filteredListings.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 480,
                ),
                itemBuilder: (context, index) {
                  final listing = filteredListings[index];

                  return buildTenantShowcaseListingCard(
                    listing: listing,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              TenantGeneralPostDetailsScreen(listing: listing),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class TenantCreatePostPage extends StatelessWidget {
  const TenantCreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        ScreenHeader(
          title: context.tr(bn: 'পোস্ট করুন', en: 'Create Post'),
          subtitle: context.tr(
            bn: 'ফ্ল্যাট, সাবলেট বা বিক্রির জন্য দ্রুত পোস্ট তৈরি করুন।',
            en: 'Create a post quickly for rent, sublet, or sale.',
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.demoText('Quick Post Options'),
          child: Column(
            children: [
              _SettingTile(
                title: 'Rent Listing',
                subtitle: 'Post a flat, family unit, or bachelor listing.',
              ),
              SizedBox(height: 12),
              _SettingTile(
                title: 'Sale Listing',
                subtitle:
                    'Post apartments, land, or ready properties for sale.',
              ),
              SizedBox(height: 12),
              _SettingTile(
                title: 'My Posts',
                subtitle: 'Review, edit, and boost your existing posts.',
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
          childAspectRatio: 1.2,
          children: const [
            _QuickCategoryCard(title: 'Flat', icon: Icons.apartment_rounded),
            _QuickCategoryCard(title: 'Sublet', icon: Icons.weekend_rounded),
            _QuickCategoryCard(title: 'Hostel', icon: Icons.hotel_rounded),
            _QuickCategoryCard(
              title: 'Office',
              icon: Icons.business_center_rounded,
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () =>
              showComingSoonSnackBar(context, context.demoText('New Post')),
          child: Text(context.tr(bn: 'নতুন পোস্ট', en: 'New Post')),
        ),
      ],
    );
  }
}

class TenantPostComposerPage extends StatefulWidget {
  const TenantPostComposerPage({super.key});

  @override
  State<TenantPostComposerPage> createState() => _TenantPostComposerPageState();
}

class _TenantPostComposerPageState extends State<TenantPostComposerPage> {
  final DhakaLocationApiService _locationApiService = DhakaLocationApiService();
  final TenantAreaApiService _areaApiService = TenantAreaApiService();
  final TextEditingController _notesController = TextEditingController();

  List<DhakaDivisionOption> _divisions = const [];
  List<DhakaAreaOption> _areas = const [];
  String? _selectedDivisionId;
  String? _selectedAreaId;
  bool _isLoadingDivisions = true;
  bool _isLoadingAreas = false;
  bool _isSubmitting = false;
  String? _locationError;

  int _rooms = 1;
  int _kitchens = 1;
  int _bathrooms = 1;
  int _balconies = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDivisions());
  }

  @override
  void dispose() {
    _locationApiService.dispose();
    _areaApiService.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDivisions() async {
    setState(() {
      _isLoadingDivisions = true;
      _locationError = null;
    });

    try {
      final divisions = await _locationApiService.getDivisions();
      if (mounted) {
        setState(() => _divisions = divisions);
      }
    } on DhakaLocationApiException catch (error) {
      if (mounted) {
        setState(() => _locationError = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationError = 'Unable to load location options.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDivisions = false);
      }
    }
  }

  Future<void> _loadAreas(String divisionId) async {
    setState(() {
      _selectedDivisionId = divisionId;
      _selectedAreaId = null;
      _areas = const [];
      _isLoadingAreas = true;
      _locationError = null;
    });

    try {
      final areas = await _locationApiService.getAreas(divisionId: divisionId);
      if (mounted && _selectedDivisionId == divisionId) {
        setState(() => _areas = areas);
      }
    } on DhakaLocationApiException catch (error) {
      if (mounted) {
        setState(() => _locationError = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationError = 'Unable to load area options.');
      }
    } finally {
      if (mounted && _selectedDivisionId == divisionId) {
        setState(() => _isLoadingAreas = false);
      }
    }
  }

  DhakaDivisionOption? get _selectedDivision {
    final id = _selectedDivisionId;
    if (id == null) {
      return null;
    }
    for (final division in _divisions) {
      if (division.id == id) {
        return division;
      }
    }
    return null;
  }

  DhakaAreaOption? get _selectedArea {
    final id = _selectedAreaId;
    if (id == null) {
      return null;
    }
    for (final area in _areas) {
      if (area.id == id) {
        return area;
      }
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _composeDetails({
    required DhakaDivisionOption division,
    required DhakaAreaOption area,
  }) {
    final notes = _notesController.text.trim();
    return [
      'Looking for a home.',
      'Division: ${division.nameBn}',
      'District/Area: ${area.nameBn}',
      'Rooms: $_rooms',
      'Kitchen: $_kitchens',
      'Bathrooms: $_bathrooms',
      'Balcony: $_balconies',
      if (notes.isNotEmpty) 'Notes: $notes',
    ].join('\n');
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final division = _selectedDivision;
    final area = _selectedArea;
    if (division == null) {
      _showMessage('Select division first.');
      return;
    }
    if (area == null) {
      _showMessage('Select district or area first.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      final locationLabel = '${area.nameBn}, ${division.nameBn}';
      final result = await _areaApiService.createPost(
        postType: 'home',
        details: _composeDetails(division: division, area: area),
        locationLabel: locationLabel,
        privacy: 'ward_and_nearby',
      );

      if (!mounted) {
        return;
      }

      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(result.message),
          content: Text(
            [
              'Location: $locationLabel',
              'Rooms: $_rooms',
              'Kitchen: $_kitchens',
              'Bathrooms: $_bathrooms',
              'Balcony: $_balconies',
            ].join('\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (shouldClose == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } on TenantAreaApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to create post right now.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Home Search Post'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const ScreenHeader(
            title: 'Post Home Requirement',
            subtitle:
                'Select where you want to rent a home and add room details.',
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Location',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_locationError != null) ...[
                  Text(
                    _locationError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                DropdownButtonFormField<String>(
                  value: _selectedDivisionId,
                  isExpanded: true,
                  items: _divisions
                      .map(
                        (division) => DropdownMenuItem<String>(
                          value: division.id,
                          child: Text(division.nameBn),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _isLoadingDivisions
                      ? null
                      : (value) {
                          if (value != null) {
                            unawaited(_loadAreas(value));
                          }
                        },
                  decoration: InputDecoration(
                    labelText: 'Division',
                    hintText: _isLoadingDivisions
                        ? 'Loading divisions...'
                        : 'Select division',
                    prefixIcon: const Icon(Icons.map_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedAreaId,
                  isExpanded: true,
                  items: _areas
                      .map(
                        (area) => DropdownMenuItem<String>(
                          value: area.id,
                          child: Text(area.nameBn),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _isLoadingAreas || _areas.isEmpty
                      ? null
                      : (value) => setState(() => _selectedAreaId = value),
                  decoration: InputDecoration(
                    labelText: 'District / Area',
                    hintText: _selectedDivisionId == null
                        ? 'Select division first'
                        : _isLoadingAreas
                        ? 'Loading areas...'
                        : 'Select district or area',
                    prefixIcon: const Icon(Icons.location_city_outlined),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Home Details',
            child: Column(
              children: [
                _TenantRequirementCounter(
                  icon: Icons.meeting_room_outlined,
                  label: 'Rooms',
                  value: _rooms,
                  minValue: 1,
                  onChanged: (value) => setState(() => _rooms = value),
                ),
                const SizedBox(height: 12),
                _TenantRequirementCounter(
                  icon: Icons.soup_kitchen_outlined,
                  label: 'Kitchen',
                  value: _kitchens,
                  minValue: 0,
                  onChanged: (value) => setState(() => _kitchens = value),
                ),
                const SizedBox(height: 12),
                _TenantRequirementCounter(
                  icon: Icons.bathtub_outlined,
                  label: 'Bathroom',
                  value: _bathrooms,
                  minValue: 1,
                  onChanged: (value) => setState(() => _bathrooms = value),
                ),
                const SizedBox(height: 12),
                _TenantRequirementCounter(
                  icon: Icons.balcony_outlined,
                  label: 'Balcony',
                  value: _balconies,
                  minValue: 0,
                  onChanged: (value) => setState(() => _balconies = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Extra Notes',
            child: TextField(
              controller: _notesController,
              minLines: 4,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Budget, family/bachelor, preferred road, etc.',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.post_add_rounded),
            label: Text(_isSubmitting ? 'Posting...' : 'Post Requirement'),
          ),
        ],
      ),
    );
  }
}

class _TenantRequirementCounter extends StatelessWidget {
  const _TenantRequirementCounter({
    required this.icon,
    required this.label,
    required this.value,
    required this.minValue,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int value;
  final int minValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final canDecrease = value > minValue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton.filledTonal(
            onPressed: canDecrease ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
            tooltip: 'Decrease $label',
          ),
          SizedBox(
            width: 44,
            child: Text(
              context.digitsText(value),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton.filled(
            onPressed: value >= 10 ? null : () => onChanged(value + 1),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Increase $label',
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _TenantPostComposerOverviewPage extends StatelessWidget {
  // ignore: unused_element_parameter
  const _TenantPostComposerOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        ScreenHeader(
          title: context.tr(bn: 'পোস্ট করুন', en: 'Create Post'),
          subtitle: context.tr(
            bn: 'ফ্ল্যাট, সাবলেট বা অফিস স্পেসের জন্য দ্রুত পোস্ট তৈরি করুন।',
            en: 'Create a polished post for rent, sublet, or office space.',
          ),
        ),
        const SizedBox(height: 18),
        _ShortcutPageHeroCard(
          title: context.tr(
            bn: 'নতুন লিস্টিং শুরু করুন',
            en: 'Start a fresh listing',
          ),
          subtitle: context.tr(
            bn: 'ছবি, লোকেশন, ভাড়া/দাম আর রুলস যোগ করে কয়েক মিনিটে পোস্ট লাইভ করুন।',
            en: 'Add photos, location, price, and rules to go live in minutes.',
          ),
          gradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
          icon: Icons.add_home_work_rounded,
          actionLabel: context.tr(bn: 'আমার পোস্ট দেখুন', en: 'View My Posts'),
          onAction: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TenantMyPostsPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: context.demoText('Published'),
                value: context.digitsText(viewModel.publishedPostCount),
                icon: Icons.public_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                label: context.demoText('Drafts'),
                value: context.digitsText(viewModel.draftPostCount),
                icon: Icons.edit_document,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                label: context.demoText('Inquiries'),
                value: context.digitsText(viewModel.totalPostInquiries),
                icon: Icons.mark_email_unread_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.tr(
            bn: 'লিস্টিং টাইপ বাছাই করুন',
            en: 'Choose Listing Type',
          ),
          child: GridView.builder(
            itemCount: viewModel.postTemplates.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (context, index) {
              return _PostTemplateCard(
                template: viewModel.postTemplates[index],
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.tr(bn: 'পাবলিশের আগে', en: 'Before You Publish'),
          child: Column(
            children: viewModel.postChecklist
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PostChecklistTile(item: item),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.tr(bn: 'দ্রুত অ্যাকশন', en: 'Quick Actions'),
          child: Column(
            children: [
              _PostActionTile(
                title: context.tr(
                  bn: 'ভাড়ার পোস্ট তৈরি করুন',
                  en: 'Create Rent Post',
                ),
                subtitle: context.tr(
                  bn: 'ফ্যামিলি বা ব্যাচেলর লিস্টিং-এর জন্য ফরম খুলুন।',
                  en: 'Open the composer for family or bachelor listings.',
                ),
                icon: Icons.apartment_rounded,
                color: AppColors.primary,
                onTap: () => showComingSoonSnackBar(
                  context,
                  context.demoText('Rent listing'),
                ),
              ),
              const SizedBox(height: 12),
              _PostActionTile(
                title: context.tr(
                  bn: 'সেল পোস্ট তৈরি করুন',
                  en: 'Create Sale Post',
                ),
                subtitle: context.tr(
                  bn: 'অ্যাপার্টমেন্ট বা রেডি প্রপার্টি সেলের জন্য শুরু করুন।',
                  en: 'Start a sale post for apartments or ready properties.',
                ),
                icon: Icons.sell_rounded,
                color: AppColors.accent,
                onTap: () => showComingSoonSnackBar(
                  context,
                  context.demoText('Sale listing'),
                ),
              ),
              const SizedBox(height: 12),
              _PostActionTile(
                title: context.tr(
                  bn: 'আমার পোস্ট ম্যানেজ করুন',
                  en: 'Manage My Posts',
                ),
                subtitle: context.tr(
                  bn: 'এডিট, রিনিউ বা স্ট্যাটাস দেখুন।',
                  en: 'Edit, renew, and track the status of your posts.',
                ),
                icon: Icons.dashboard_customize_rounded,
                color: const Color(0xFF7C3AED),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TenantMyPostsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => showComingSoonSnackBar(
            context,
            context.demoText('Create listing'),
          ),
          child: Text(
            context.tr(bn: 'নতুন পোস্ট শুরু করুন', en: 'Create Listing'),
          ),
        ),
      ],
    );
  }
}

class TenantMyPostsPage extends StatefulWidget {
  const TenantMyPostsPage({super.key});

  @override
  State<TenantMyPostsPage> createState() => _TenantMyPostsPageState();
}

class _TenantMyPostsPageState extends State<TenantMyPostsPage> {
  bool _didRequestOwnerPosts = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRequestOwnerPosts) {
      return;
    }

    _didRequestOwnerPosts = true;
    final viewModel = context.read<TenantExperienceViewModel>();
    unawaited(
      viewModel.loadOwnerPosts(
        status: viewModel.ownerPostStatusFilter,
        forceRefresh: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.demoText('My Posts')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          IconButton(
            tooltip: context.demoText('Refresh posts'),
            onPressed: viewModel.isLoadingOwnerPosts
                ? null
                : () => viewModel.loadOwnerPosts(
                    status: viewModel.ownerPostStatusFilter,
                    forceRefresh: true,
                  ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _ShortcutPageHeroCard(
            title: context.tr(
              bn: 'আপনার সক্রিয় পোস্ট',
              en: 'Your active posts',
            ),
            subtitle: context.tr(
              bn: 'পোস্টের স্ট্যাটাস, রেসপন্স আর আপডেট একসাথে ম্যানেজ করুন।',
              en: 'Manage post status, responses, and recent updates from one place.',
            ),
            gradient: const [Color(0xFFFFF3E8), Color(0xFFFFE1C2)],
            icon: Icons.edit_note_rounded,
            isDarkForeground: false,
            actionLabel: context.tr(bn: 'নতুন পোস্ট', en: 'New Post'),
            onAction: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TenantPostComposerPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  label: context.demoText('Published'),
                  value: context.digitsText(viewModel.publishedPostCount),
                  icon: Icons.public_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  label: context.demoText('Drafts'),
                  value: context.digitsText(viewModel.draftPostCount),
                  icon: Icons.drafts_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  label: context.demoText('Inquiries'),
                  value: context.digitsText(viewModel.totalPostInquiries),
                  icon: Icons.forum_outlined,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChoiceChip(
                label: Text(context.demoText('All')),
                selected: viewModel.ownerPostStatusFilter == null,
                onSelected: viewModel.isLoadingOwnerPosts
                    ? null
                    : (_) => viewModel.loadOwnerPosts(forceRefresh: true),
              ),
              ChoiceChip(
                label: Text(context.demoText('Published')),
                selected: viewModel.ownerPostStatusFilter == 'published',
                onSelected: viewModel.isLoadingOwnerPosts
                    ? null
                    : (_) => viewModel.loadOwnerPosts(
                        status: 'published',
                        forceRefresh: true,
                      ),
              ),
              ChoiceChip(
                label: Text(context.demoText('Draft')),
                selected: viewModel.ownerPostStatusFilter == 'draft',
                onSelected: viewModel.isLoadingOwnerPosts
                    ? null
                    : (_) => viewModel.loadOwnerPosts(
                        status: 'draft',
                        forceRefresh: true,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (viewModel.isLoadingOwnerPosts && viewModel.managedPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (viewModel.ownerPostListError != null &&
              viewModel.managedPosts.isEmpty)
            _MarketplaceEmptyStateCard(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load posts',
              subtitle: viewModel.ownerPostListError!,
            )
          else if (viewModel.managedPosts.isEmpty)
            const _MarketplaceEmptyStateCard(
              icon: Icons.post_add_rounded,
              title: 'No posts found',
              subtitle: 'Create a new post or choose another status filter.',
            )
          else ...[
            if (viewModel.ownerPostListError != null) ...[
              _MarketplaceEmptyStateCard(
                icon: Icons.info_outline_rounded,
                title: 'Showing saved posts',
                subtitle: viewModel.ownerPostListError!,
              ),
              const SizedBox(height: 14),
            ],
            ...viewModel.managedPosts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ManagedPostCard(post: post),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TenantSavedListingsPage extends StatelessWidget {
  const TenantSavedListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();
    final savedPosts = viewModel.savedGeneralPosts;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        ScreenHeader(
          title: context.tr(bn: 'সেভড', en: 'Saved'),
          subtitle: context.tr(
            bn: 'পছন্দের লিস্টিংগুলো পরে দেখার জন্য এখানে রাখা আছে।',
            en: 'Your bookmarked listings are stored here for later review.',
          ),
        ),
        const SizedBox(height: 18),
        if (viewModel.isLoadingSavedPosts)
          const Center(child: CircularProgressIndicator())
        else if (savedPosts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                context.tr(
                  bn: 'আপনার কোনো সেভ করা তালিকা নেই।',
                  en: 'You have no saved listings.',
                ),
                style: const TextStyle(color: Color(0xFF6E7683)),
              ),
            ),
          )
        else
          ...savedPosts.map((post) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: buildTenantShowcaseListingCard(
                listing: mapGeneralPostToShowcase(post),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        final listing = mapGeneralPostToShowcase(post);
                        return TenantGeneralPostDetailsScreen(listing: listing);
                      },
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }
}

class TenantMarketplaceCategoryPage extends StatelessWidget {
  const TenantMarketplaceCategoryPage({super.key, required this.category});

  final MarketplaceCategory category;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();
    final action = viewModel.actionFor(category);
    final listings = viewModel.listingsFor(category);
    final isRent = category == MarketplaceCategory.rent;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(action.title),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _MarketplaceCategoryHero(
            action: action,
            listingCount: listings.length,
            title: context.tr(
              bn: isRent
                  ? 'আপনার পছন্দের ভাড়ার বাসা খুঁজুন'
                  : 'পছন্দের সেল প্রপার্টি দেখুন',
              en: isRent
                  ? 'Find curated rental homes'
                  : 'Browse sale-ready properties',
            ),
            subtitle: context.tr(
              bn: isRent
                  ? 'এলাকা, বাজেট আর বেডরুম অনুযায়ী বাছাই করা লিস্টিং।'
                  : 'অ্যাপার্টমেন্ট, রেডি ফ্ল্যাট আর ইনভেস্টমেন্ট প্রপার্টি এক জায়গায়।',
              en: isRent
                  ? 'Curated listings by area, budget, and bedroom type.'
                  : 'Apartments, ready flats, and investment properties in one place.',
            ),
          ),
          const SizedBox(height: 18),
          _MarketplaceSearchBar(
            hintText: context.tr(
              bn: isRent
                  ? 'মিরপুর, ২ বেড, ফ্যামিলি, বাজেট...'
                  : 'ধানমন্ডি, ৩ বেড, সেল, ইনভেস্টমেন্ট...',
              en: isRent
                  ? 'Mirpur, 2 bed, family, budget...'
                  : 'Dhanmondi, 3 bed, sale, investment...',
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: context.loc(AppLocalLang.quickFilters),
            actionLabel: viewModel.hasActiveFiltersFor(category)
                ? context.loc(AppLocalLang.reset)
                : null,
            onAction: viewModel.hasActiveFiltersFor(category)
                ? () => viewModel.clearFiltersForCategory(category)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: action.quickFilters
                      .map(
                        (filter) => _MarketplaceFilterChip(
                          label: filter,
                          color: action.gradient.first,
                          isSelected:
                              viewModel.selectedQuickFilterFor(category) ==
                              filter,
                          onTap: () =>
                              viewModel.toggleQuickFilter(category, filter),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: viewModel.popularAreas
                      .take(4)
                      .map(
                        (area) => ActionChip(
                          avatar: Icon(
                            area.icon,
                            size: 16,
                            color: action.gradient.first,
                          ),
                          label: Text(area.name),
                          onPressed: () =>
                              viewModel.updateMarketplaceSearchQuery(area.name),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 18),
                Text(
                  context.loc(AppLocalLang.location),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _MarketplaceLocationFilterFields(
                  accentColor: action.gradient.first,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(
                    bn: isRent ? 'ভাড়ার লিস্টিং' : 'সেল লিস্টিং',
                    en: isRent ? 'Rental Listings' : 'Sale Listings',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                context.tr(
                  bn: '${context.digitsText(listings.length)} টি পাওয়া গেছে',
                  en: '${listings.length} found',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: action.gradient.first,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (listings.isEmpty)
            _MarketplaceEmptyStateCard(
              icon: Icons.location_off_rounded,
              title: context.loc(AppLocalLang.noListingsFound),
              subtitle: context.loc(
                AppLocalLang.adjustDivisionDistrictUpazilaFilters,
              ),
            )
          else
            ...listings.map(
              (listing) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _FeaturedListingCard(listing: listing),
              ),
            ),
          const SizedBox(height: 6),
          FilledButton(
            onPressed: () => showComingSoonSnackBar(
              context,
              isRent ? 'Rent inquiry' : 'Sale inquiry',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: isRent ? AppColors.primary : AppColors.accent,
            ),
            child: Text(
              context.tr(
                bn: isRent
                    ? 'ভাড়ার জন্য রিকোয়েস্ট পাঠান'
                    : 'সেল প্রপার্টি দেখতে চান',
                en: isRent
                    ? 'Send Rent Inquiry'
                    : 'Request a Sale Consultation',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TenantMenuPage extends StatelessWidget {
  const TenantMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        ScreenHeader(
          title: 'Menu',
          subtitle: 'Access profile, payment, and support tools.',
        ),
        const SizedBox(height: 18),
        _ProfileSummaryCard(
          title: viewModel.tenantProfile.name,
          subtitle: 'Tenant Account',
          icon: Icons.person_outline_rounded,
          badge: viewModel.activeTenant.propertyName,
        ),
        const SizedBox(height: 18),
        _TenantMenuActionTile(
          title: 'Payment & Agreement',
          subtitle: 'Open payment details and generate agreement.',
          icon: Icons.receipt_long_rounded,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TenantPaymentCenterPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _TenantMenuActionTile(
          title: 'Monthly Bills',
          subtitle: 'Review current monthly utility and service bills.',
          icon: Icons.calendar_month_rounded,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TenantMonthlyBillsPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _TenantMenuActionTile(
          title: 'Manager Details',
          subtitle: 'Check manager profile and total outstanding charges.',
          icon: Icons.badge_outlined,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PropertyManagerDetailsPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _TenantMenuActionTile(
          title: 'Owner Profile',
          subtitle: 'View owner contact options and selected listing.',
          icon: Icons.person_pin_rounded,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const OwnerProfileDetailsPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _TenantMenuActionTile(
          title: 'Confirm Move-In',
          subtitle: 'Open move-in confirmation and support shortcuts.',
          icon: Icons.login_rounded,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TenantConfirmMoveInPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _TenantMenuActionTile(
          title: 'Maintenance Request',
          subtitle: 'Report plumbing, electrical, and other issues.',
          icon: Icons.build_circle_rounded,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TenantMaintenanceRequestPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class TenantPaymentHistoryPage extends StatelessWidget {
  const TenantPaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(
          title: 'Payment History',
          subtitle: 'Track rent receipts and prepare your next payment.',
        ),
        const SizedBox(height: 18),
        _MiniStatCard(
          label: 'Total paid this year',
          value: context.money(viewModel.totalPaidThisYear),
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'History',
          child: Column(
            children: viewModel.paymentHistory
                .map(
                  (payment) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TenantPaymentHistoryCard(payment: payment),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.demoText('Payment Methods'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: viewModel.paymentMethods
              .map((method) => _PaymentMethodCard(method: method))
              .toList(growable: false),
        ),
      ],
    );
  }
}

class TenantMaintenanceRequestPage extends StatelessWidget {
  const TenantMaintenanceRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.demoText('Maintenance Request')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          ScreenHeader(
            title: 'Maintenance Request',
            subtitle:
                'Choose a category, describe the issue, and send it to the owner.',
          ),
          const SizedBox(height: 18),
          Text(
            context.demoText('Category'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: viewModel.maintenanceCategories
                .map(
                  (category) => _MaintenanceCategoryCard(
                    category: category,
                    isSelected:
                        viewModel.selectedMaintenanceCategory == category.id,
                    onTap: () =>
                        viewModel.selectMaintenanceCategory(category.id),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          Text(
            context.demoText('Describe your issue'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            minLines: 5,
            maxLines: 5,
            onChanged: viewModel.updateIssueDescription,
            decoration: InputDecoration(
              hintText: context.demoText('Describe your issue'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () =>
                showComingSoonSnackBar(context, context.demoText('Take Photo')),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(context.demoText('Take Photo')),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => showComingSoonSnackBar(
              context,
              context.demoText('Send to Owner'),
            ),
            child: Text(context.demoText('Send to Owner')),
          ),
        ],
      ),
    );
  }
}

class TenantProfilePage extends StatelessWidget {
  const TenantProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(
          title: 'Profile',
          subtitle: 'Personal summary and access to tenant tools.',
        ),
        const SizedBox(height: 18),
        _ProfileSummaryCard(
          title: viewModel.tenantProfile.name,
          subtitle: 'Tenant',
          icon: Icons.person_outline_rounded,
          badge: viewModel.activeTenant.propertyName,
        ),
        const SizedBox(height: 18),
        _TenantMenuActionTile(
          title: 'Rent Payment',
          subtitle: 'Submit rent payment and view payment entries.',
          icon: Icons.account_balance_wallet_rounded,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TenantRentPaymentPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _TenantMenuActionTile(
          title: context.tr(bn: 'আমার পোস্ট', en: 'My Posts'),
          subtitle: context.tr(
            bn: 'আপনার দেয়া সব পোস্ট এখানে দেখুন।',
            en: 'View all the posts you have created.',
          ),
          icon: Icons.post_add_rounded,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TenantMyPostsPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _TenantMenuActionTile(
          title: context.tr(bn: 'লগআউট', en: 'Log Out'),
          subtitle: context.tr(
            bn: 'এই ডিভাইস থেকে আপনার টেন্যান্ট একাউন্ট থেকে বের হয়ে যান।',
            en: 'Sign out from your tenant account on this device.',
          ),
          icon: Icons.logout_rounded,
          iconColor: AppColors.danger,
          iconBackgroundColor: const Color(0xFFFFECE8),
          titleColor: AppColors.danger,
          onTap: () => _confirmTenantLogout(context),
        ),
      ],
    );
  }
}

class TenantRentPaymentPage extends StatefulWidget {
  const TenantRentPaymentPage({super.key});

  @override
  State<TenantRentPaymentPage> createState() => _TenantRentPaymentPageState();
}

class _TenantRentPaymentPageState extends State<TenantRentPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController(text: 'Omer Hasan');
  final _amountController = TextEditingController(text: '15000');
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  int _selectedYear = DateTime.now().year;
  final Set<String> _selectedPaymentTypes = {'Vara'};
  String _selectedMethod = 'Cash';
  bool _didInitializeDefaults = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitializeDefaults) {
      return;
    }

    final viewModel = context.read<TenantExperienceViewModel>();
    _ownerNameController.text = viewModel.ownerProfile.name;
    final property = viewModel.activeTenantProperty;
    if (property != null) {
      _amountController.text = property.monthlyRent.toString();
    }

    _didInitializeDefaults = true;
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  int _parseAmount(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(normalized) ?? 0;
  }

  Future<void> _submitPayment() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_selectedPaymentTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.demoText('Select a payment type'))),
      );
      return;
    }

    final ownerName = _ownerNameController.text.trim();
    final amount = _parseAmount(_amountController.text);
    final tenantViewModel = context.read<TenantExperienceViewModel>();
    final result = await tenantViewModel.confirmRentPayment(
      ownerName: ownerName,
      monthName: _selectedMonth,
      year: _selectedYear,
      paymentTypes: _selectedPaymentTypes.toList(growable: false),
      amount: amount,
      method: _selectedMethod,
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      final errorMessage =
          tenantViewModel.rentPaymentSubmitError ??
          'Unable to confirm payment right now.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.demoText(errorMessage))));
      return;
    }

    context.read<OwnerDashboardViewModel>().syncConfirmedPayment(
      payment: result.payment,
      dueAmount: result.dueAmount,
    );
    context.read<PaymentViewModel>().refresh();
    context.read<PropertyViewModel>().refresh();

    FocusScope.of(context).unfocus();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.demoText('Payment Confirmed')),
          content: Text(
            context.demoText('${result.tenant.name}: ${result.message}'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.demoText('OK')),
            ),
          ],
        );
      },
    );
  }

  void _togglePaymentType(String type, bool selected) {
    setState(() {
      if (selected) {
        _selectedPaymentTypes.add(type);
        return;
      }
      if (_selectedPaymentTypes.length > 1) {
        _selectedPaymentTypes.remove(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();
    final entries = viewModel.rentPaymentEntries;
    final monthGroups = <String, List<TenantRentPaymentEntry>>{};
    for (final entry in entries) {
      monthGroups.putIfAbsent(entry.monthLabel, () => []).add(entry);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.demoText('Rent Payment')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          ScreenHeader(
            title: 'Rent Payment',
            subtitle: 'Enter owner, month, year, payment type, and method.',
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Payment Entry',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _ownerNameController,
                    textInputAction: TextInputAction.next,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: context.demoText('Owner Name'),
                      prefixIcon: const Icon(Icons.person_pin_rounded),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return context.demoText('Enter owner name');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedMonth,
                          items: viewModel.rentPaymentMonthNames
                              .map(
                                (month) => DropdownMenuItem<String>(
                                  value: month,
                                  child: Text(
                                    context.demoText(month),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _selectedMonth = value);
                          },
                          decoration: InputDecoration(
                            labelText: context.demoText('Month'),
                            prefixIcon: const Icon(
                              Icons.calendar_month_rounded,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 132,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _selectedYear,
                          items: viewModel.rentPaymentYears
                              .map(
                                (year) => DropdownMenuItem<int>(
                                  value: year,
                                  child: Text(
                                    context.digitsText(year),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _selectedYear = value);
                          },
                          decoration: InputDecoration(
                            labelText: context.demoText('Year'),
                            prefixIcon: const Icon(Icons.event_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.category_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.demoText('Payment Type'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: viewModel.rentPaymentTypeLabels
                            .map(
                              (type) => FilterChip(
                                label: Text(context.demoText(type)),
                                selected: _selectedPaymentTypes.contains(type),
                                onSelected: (selected) =>
                                    _togglePaymentType(type, selected),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: context.demoText('Rent Amount'),
                      prefixIcon: const Icon(Icons.payments_rounded),
                    ),
                    validator: (value) {
                      if (_parseAmount(value ?? '') <= 0) {
                        return context.demoText('Enter a valid rent amount');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedMethod,
                    items: viewModel.rentPaymentMethodLabels
                        .map(
                          (method) => DropdownMenuItem<String>(
                            value: method,
                            child: Text(
                              context.demoText(method),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _selectedMethod = value);
                    },
                    decoration: InputDecoration(
                      labelText: context.demoText('Payment Method'),
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: viewModel.isSubmittingRentPayment
                        ? null
                        : _submitPayment,
                    icon: viewModel.isSubmittingRentPayment
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(
                      context.demoText(
                        viewModel.isSubmittingRentPayment
                            ? 'Confirming...'
                            : 'Payment',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Payment List',
            child: entries.isEmpty
                ? const _EmptyRentPaymentList()
                : Column(
                    children: monthGroups.entries
                        .map(
                          (group) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _TenantRentPaymentMonthGroup(
                              monthLabel: group.key,
                              entries: group.value,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRentPaymentList extends StatelessWidget {
  const _EmptyRentPaymentList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.primary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            context.demoText('No payment entries yet.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _TenantRentPaymentMonthGroup extends StatelessWidget {
  const _TenantRentPaymentMonthGroup({
    required this.monthLabel,
    required this.entries,
  });

  final String monthLabel;
  final List<TenantRentPaymentEntry> entries;

  @override
  Widget build(BuildContext context) {
    final totalAmount = entries.fold<int>(0, (sum, item) => sum + item.amount);
    final firstEntry = entries.first;
    final localizedMonthLabel =
        '${context.demoText(firstEntry.monthName)} ${context.digitsText(firstEntry.year)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  localizedMonthLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                context.money(totalAmount),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: entry == entries.last ? 0 : 10),
              child: _TenantRentPaymentEntryTile(entry: entry),
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantRentPaymentEntryTile extends StatelessWidget {
  const _TenantRentPaymentEntryTile({required this.entry});

  final TenantRentPaymentEntry entry;

  @override
  Widget build(BuildContext context) {
    final paidAt = DateFormat('dd MMM yyyy, hh:mm a').format(entry.paidAt);
    final localizedTypes = entry.paymentTypes.map(context.demoText).join(', ');
    final localizedMonthLabel =
        '${context.demoText(entry.monthName)} ${context.digitsText(entry.year)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.ownerName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '$localizedTypes - ${context.demoText(entry.method)} - $localizedMonthLabel - $paidAt',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            context.money(entry.amount),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceBrand extends StatelessWidget {
  const _MarketplaceBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogoMark(size: 44),
        const SizedBox(width: 10),
        const BrandTitle(fontSize: 24),
      ],
    );
  }
}

class _MarketplaceHeaderButton extends StatelessWidget {
  const _MarketplaceHeaderButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () => showComingSoonSnackBar(context, context.demoText('Action')),
      radius: 22,
      child: SizedBox(
        height: 40,
        width: 40,
        child: Icon(icon, color: AppColors.textPrimary, size: 28),
      ),
    );
  }
}

class _MarketplaceSearchBar extends StatefulWidget {
  const _MarketplaceSearchBar({required this.hintText});

  final String hintText;

  @override
  State<_MarketplaceSearchBar> createState() => _MarketplaceSearchBarState();
}

class _MarketplaceSearchBarState extends State<_MarketplaceSearchBar> {
  late final TextEditingController _controller;

  Future<void> _showLocationFilters() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final viewModel = sheetContext.watch<TenantExperienceViewModel>();

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppShadows.card,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.demoText('Filter by location'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (viewModel.hasActiveSearchFilters)
                          TextButton(
                            onPressed: viewModel.clearSearchAndLocationFilters,
                            child: Text(context.demoText('Reset')),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _MarketplaceLocationFilterFields(
                      accentColor: AppColors.primary,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(context.demoText('Show results')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<TenantExperienceViewModel>();
    _controller = TextEditingController(text: viewModel.marketplaceSearchQuery);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.watch<TenantExperienceViewModel>();
    if (_controller.text != viewModel.marketplaceSearchQuery) {
      _controller.value = TextEditingValue(
        text: viewModel.marketplaceSearchQuery,
        selection: TextSelection.collapsed(
          offset: viewModel.marketplaceSearchQuery.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 28,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: viewModel.updateMarketplaceSearchQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.demoText(widget.hintText),
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: _showLocationFilters,
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          if (viewModel.hasSearchQuery)
            IconButton(
              onPressed: () => viewModel.updateMarketplaceSearchQuery(''),
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

class _MarketplaceLocationFilterFields extends StatefulWidget {
  const _MarketplaceLocationFilterFields({required this.accentColor});

  final Color accentColor;

  @override
  State<_MarketplaceLocationFilterFields> createState() =>
      _MarketplaceLocationFilterFieldsState();
}

class _MarketplaceLocationFilterFieldsState
    extends State<_MarketplaceLocationFilterFields> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(context.read<TenantExperienceViewModel>().loadDhakaDivisions());
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();
    final locationError = viewModel.dhakaLocationError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (viewModel.hasActiveLocationFilter) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (viewModel.selectedDivision != null)
                _MarketplaceFilterChip(
                  label: context.tr(
                    bn: 'বিভাগ: ${context.demoText(viewModel.selectedDivision!)}',
                    en: 'Division: ${viewModel.locationLabelForFilter(viewModel.selectedDivision)}',
                  ),
                  color: widget.accentColor,
                ),
              if (viewModel.selectedDistrict != null)
                _MarketplaceFilterChip(
                  label: context.tr(
                    bn: 'জেলা: ${context.demoText(viewModel.selectedDistrict!)}',
                    en: 'Area: ${viewModel.locationLabelForFilter(viewModel.selectedDistrict)}',
                  ),
                  color: widget.accentColor,
                ),
              if (viewModel.selectedUpazila != null)
                _MarketplaceFilterChip(
                  label: context.tr(
                    bn: 'উপজেলা: ${context.demoText(viewModel.selectedUpazila!)}',
                    en: 'Upazila: ${viewModel.selectedUpazila!}',
                  ),
                  color: widget.accentColor,
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        if (locationError != null) ...[
          Text(
            context.tr(bn: locationError, en: locationError),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
        ],
        _MarketplaceLocationDropdown(
          label: context.tr(bn: 'বিভাগ', en: 'Division'),
          hintText: viewModel.isLoadingDhakaDivisions
              ? context.tr(bn: 'লোড হচ্ছে...', en: 'Loading...')
              : context.tr(bn: 'বিভাগ নির্বাচন করুন', en: 'Select division'),
          icon: Icons.map_outlined,
          value: viewModel.selectedDivision,
          items: viewModel.availableDivisionOptions,
          accentColor: widget.accentColor,
          onChanged: viewModel.selectDivision,
        ),
        const SizedBox(height: 12),
        _MarketplaceLocationDropdown(
          label: context.tr(bn: 'এলাকা', en: 'Area'),
          hintText: viewModel.selectedDivision == null
              ? context.tr(
                  bn: 'আগে বিভাগ নির্বাচন করুন',
                  en: 'Select division first',
                )
              : viewModel.isLoadingDhakaAreas
              ? context.tr(bn: 'লোড হচ্ছে...', en: 'Loading...')
              : context.tr(bn: 'এলাকা নির্বাচন করুন', en: 'Select area'),
          icon: Icons.location_city_outlined,
          value: viewModel.selectedDistrict,
          items: viewModel.availableAreaOptions,
          accentColor: widget.accentColor,
          onChanged: viewModel.selectDistrict,
        ),
      ],
    );
  }
}

class _MarketplaceLocationDropdown extends StatelessWidget {
  const _MarketplaceLocationDropdown({
    required this.label,
    required this.hintText,
    required this.icon,
    required this.items,
    required this.accentColor,
    required this.onChanged,
    this.value,
  });

  final String label;
  final String hintText;
  final IconData icon;
  final List<MarketplaceLocationOption> items;
  final Color accentColor;
  final ValueChanged<String?> onChanged;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.id,
              child: Text(item.labelBn),
            ),
          )
          .toList(growable: false),
      onChanged: items.isEmpty ? null : onChanged,
      hint: Text(hintText),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: accentColor),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: accentColor),
      ),
    );
  }
}

class _MarketplaceEmptyStateCard extends StatelessWidget {
  const _MarketplaceEmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Text(
            context.demoText(title),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            context.demoText(subtitle),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MarketplaceSectionHeader extends StatelessWidget {
  const _MarketplaceSectionHeader({
    required this.title,
    required this.actionLabel,
  });

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.demoText(title),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          context.demoText(actionLabel),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 2),
        const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      ],
    );
  }
}

class _MarketplaceCategoryHero extends StatelessWidget {
  const _MarketplaceCategoryHero({
    required this.action,
    required this.listingCount,
    required this.title,
    required this.subtitle,
  });

  final MarketplaceActionData action;
  final int listingCount;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: action.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(action.icon, color: Colors.white, size: 30),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  context.tr(
                    bn: '${context.digitsText(listingCount)} টি লিস্টিং',
                    en: '$listingCount listings',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            context.demoText(title),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.demoText(subtitle),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceFilterChip extends StatelessWidget {
  const _MarketplaceFilterChip({
    required this.label,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected ? color : color.withValues(alpha: 0.1);
    final foregroundColor = isSelected ? Colors.white : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            context.demoText(label),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutPageHeroCard extends StatelessWidget {
  const _ShortcutPageHeroCard({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
    this.isDarkForeground = true,
  });

  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isDarkForeground;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isDarkForeground
        ? Colors.white
        : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: isDarkForeground ? 0.18 : 0.88,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: isDarkForeground ? Colors.white : AppColors.accent,
                  size: 30,
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: onAction,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(
                    alpha: isDarkForeground ? 0.16 : 0.9,
                  ),
                ),
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  color: isDarkForeground ? Colors.white : AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            context.demoText(title),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: foregroundColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.demoText(subtitle),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: foregroundColor.withValues(
                alpha: isDarkForeground ? 0.88 : 0.78,
              ),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.demoText(actionLabel),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDarkForeground ? Colors.white : AppColors.accent,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostTemplateCard extends StatelessWidget {
  const _PostTemplateCard({required this.template});

  final PostCategoryTemplate template;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxHeight.isFinite && constraints.maxHeight < 156;
        final padding = isCompact ? 12.0 : 16.0;
        final iconSize = isCompact ? 40.0 : 44.0;
        final gap = isCompact ? 2.0 : 4.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => showComingSoonSnackBar(
              context,
              context.demoText(template.title),
            ),
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: iconSize,
                    width: iconSize,
                    decoration: BoxDecoration(
                      color: template.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(template.icon, color: template.color),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            context.demoText(template.title),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: isCompact ? 14 : null,
                                ),
                          ),
                        ),
                        SizedBox(height: gap),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            context.demoText(template.subtitle),
                            maxLines: isCompact ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontSize: isCompact ? 11 : null),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PostChecklistTile extends StatelessWidget {
  const _PostChecklistTile({required this.item});

  final PostChecklistItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isCompleted
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: item.isCompleted ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.demoText(item.title),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  context.demoText(item.subtitle),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostActionTile extends StatelessWidget {
  const _PostActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.demoText(title),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.demoText(subtitle),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagedPostCard extends StatelessWidget {
  const _ManagedPostCard({required this.post});

  final ManagedPostData post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: post.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(post.icon, color: post.statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.demoText(post.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.location,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _PostStatusChip(
                    label: post.statusLabel,
                    color: post.statusColor,
                  ),
                  const SizedBox(height: 6),
                  _PostStatusChip(
                    label: post.fulfillmentLabel,
                    color: post.fulfillmentColor,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ListingFeatureChip(
                icon: Icons.category_outlined,
                label: post.categoryLabel,
              ),
              _ListingFeatureChip(
                icon: Icons.sell_outlined,
                label: post.priceLabel,
              ),
              _ListingFeatureChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: context.tr(
                  bn: '${context.digitsText(post.inquiryCount)}টি জিজ্ঞাসা',
                  en: '${post.inquiryCount} inquiries',
                ),
              ),
            ],
          ),
          if (post.remarks.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _ListingFeatureChip(
              icon: Icons.comment_outlined,
              label: post.remarks,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.demoText(post.updatedLabel),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              OutlinedButton(
                onPressed: () => showComingSoonSnackBar(
                  context,
                  context.demoText('Edit post'),
                ),
                child: Text(context.demoText('Edit')),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () => showComingSoonSnackBar(
                  context,
                  context.demoText('Boost post'),
                ),
                child: Text(context.demoText('Boost')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostStatusChip extends StatelessWidget {
  const _PostStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        context.demoText(label),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontSize: 12, color: color),
      ),
    );
  }
}

class _HomeShortcutCard extends StatelessWidget {
  const _HomeShortcutCard({required this.item, required this.onTap});

  final HomeShortcutData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPrimary = item.isPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: item.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  item.icon,
                  color: isPrimary ? AppColors.primary : AppColors.accent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.demoText(item.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isPrimary ? Colors.white : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.demoText(item.subtitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.88)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: isPrimary ? Colors.white : AppColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketplaceActionCard extends StatelessWidget {
  const _MarketplaceActionCard({required this.item, required this.onTap});

  final MarketplaceActionData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: item.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Icon(item.icon, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.demoText(item.title),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.demoText(item.subtitle),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularAreaCard extends StatelessWidget {
  const _PopularAreaCard({required this.area});

  final PopularAreaData area;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 102,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(area.icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            context.demoText(area.name),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantMenuActionTile extends StatelessWidget {
  const _TenantMenuActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.primary,
    this.iconBackgroundColor = AppColors.surfaceSoft,
    this.titleColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadii.card);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: borderRadius,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.demoText(title),
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: titleColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.demoText(subtitle),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderProfileButton extends StatelessWidget {
  const _HeaderProfileButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final DashboardStatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const Spacer(),
          Text(item.value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            context.demoText(item.label),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final AdminActivityLog activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              activity.userName.characters.first,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.userName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  context.demoText(activity.action),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            activity.timestampLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DocumentPlaceholder extends StatelessWidget {
  const _DocumentPlaceholder({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 34),
          const SizedBox(height: 12),
          Text(
            context.demoText(title),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            context.demoText('Image placeholder'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.settings_suggest_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.demoText(title),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  context.demoText(subtitle),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            context.demoText(label),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _OwnerPaymentQuickStat extends StatelessWidget {
  const _OwnerPaymentQuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  context.demoText(label),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerConfirmedPaymentEmptyState extends StatelessWidget {
  const _OwnerConfirmedPaymentEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.demoText('No tenant payments have been confirmed yet.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _OwnerConfirmedPaymentTile extends StatelessWidget {
  const _OwnerConfirmedPaymentTile({required this.payment});

  final RentPayment payment;

  @override
  Widget build(BuildContext context) {
    final paidDate = payment.paidOn == null
        ? '-'
        : DateFormat('dd MMM yyyy').format(payment.paidOn!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.verified_rounded, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.tenantName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${payment.propertyName} • ${payment.monthLabel}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  context.demoText('Paid on $paidDate'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge.forPayment(context, payment.status),
              const SizedBox(height: 10),
              Text(
                context.money(payment.amount),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerPropertyCard extends StatelessWidget {
  const _OwnerPropertyCard({required this.property});

  final OwnerPropertyCardData property;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            showComingSoonSnackBar(context, context.demoText(property.title)),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF3)),
            boxShadow: _roleHomeSurfaceShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 132,
                child: Stack(
                  children: [
                    const Positioned.fill(child: _OwnerPropertyArtwork()),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: StatusBadge.forProperty(context, property.status),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.58),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.apartment_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.demoText('Owner'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.demoText(property.title),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFF7B8492),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            context.demoText(property.location),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 12,
                                  color: const Color(0xFF6E7683),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      context.money(property.rent),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _OwnerPropertyMeta(
                            icon: Icons.receipt_long_rounded,
                            label: context.demoText('Rent'),
                          ),
                        ),
                        Expanded(
                          child: _OwnerPropertyMeta(
                            icon: Icons.verified_user_rounded,
                            label: context.demoText('Managed'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerPropertyMeta extends StatelessWidget {
  const _OwnerPropertyMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF7B8492)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11.5,
              color: const Color(0xFF657080),
            ),
          ),
        ),
      ],
    );
  }
}

class _OwnerPropertyArtwork extends StatelessWidget {
  const _OwnerPropertyArtwork();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF3FF), Color(0xFFFFE8D1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 22,
              bottom: 18,
              child: Container(
                height: 78,
                width: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD9E5F6), width: 3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    3,
                    (_) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        2,
                        (_) => Container(
                          height: 10,
                          width: 10,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 22,
              bottom: 16,
              child: Container(
                height: 54,
                width: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            Positioned(
              right: 34,
              bottom: 16,
              child: Container(
                height: 34,
                width: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
            ),
            Positioned(
              left: 96,
              top: 22,
              child: Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillAmountField extends StatelessWidget {
  const _BillAmountField({
    this.fieldKey,
    this.initialValue,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final Key? fieldKey;
  final String? initialValue;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        TextFormField(
          key: fieldKey,
          initialValue: initialValue,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(prefixIcon: Icon(icon)),
        ),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.demoText('Due Date'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

enum _TenantCardAction { edit, delete }

class _TenantInfoCard extends StatelessWidget {
  const _TenantInfoCard({
    required this.tenant,
    this.property,
    this.onEdit,
    this.onDelete,
    this.isActionBusy = false,
  });

  final TenantProfile tenant;
  final PropertyUnit? property;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isActionBusy;

  @override
  Widget build(BuildContext context) {
    final residenceLabel = _tenantResidenceLabel(tenant, property);
    final locationLabel = _firstNonEmpty([tenant.location, property?.location]);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              tenant.name.characters.first,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenant.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _TenantCardMetaLine(
                  icon: Icons.home_work_outlined,
                  value: residenceLabel,
                ),
                if (locationLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _TenantCardMetaLine(
                    icon: Icons.location_on_outlined,
                    value: locationLabel,
                  ),
                ],
                const SizedBox(height: 4),
                _TenantCardMetaLine(
                  icon: Icons.phone_android_rounded,
                  value: tenant.phone,
                ),
                const SizedBox(height: 4),
                _TenantCardMetaLine(
                  icon: Icons.badge_outlined,
                  value: tenant.nid,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.tr(bn: 'Edit', en: 'Edit'),
            onPressed: isActionBusy ? null : onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<_TenantCardAction>(
            enabled: !isActionBusy,
            onSelected: (action) {
              switch (action) {
                case _TenantCardAction.edit:
                  onEdit?.call();
                  break;
                case _TenantCardAction.delete:
                  onDelete?.call();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<_TenantCardAction>(
                value: _TenantCardAction.edit,
                child: Text(context.tr(bn: 'Edit', en: 'Edit')),
              ),
              PopupMenuItem<_TenantCardAction>(
                value: _TenantCardAction.delete,
                child: Text(context.tr(bn: 'Delete', en: 'Delete')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TenantCardMetaLine extends StatelessWidget {
  const _TenantCardMetaLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String _tenantResidenceLabel(TenantProfile tenant, PropertyUnit? property) {
  final parts = [
    _firstNonEmpty([tenant.buildingName, property?.buildingName]),
    _firstNonEmpty([tenant.floorLabel, property?.floorLabel]),
    _firstNonEmpty([tenant.propertyName, property?.name]),
  ].where((value) => value.isNotEmpty).toList(growable: false);

  if (parts.isEmpty) {
    return '-';
  }

  return parts.join(' • ');
}

String _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }

  return '';
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.demoText(title),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  context.demoText(subtitle),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    context.demoText(badge),
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedListingCard extends StatelessWidget {
  const _FeaturedListingCard({required this.listing, this.isCompact = false});

  final FeaturedListingData listing;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTightCompactLayout =
            isCompact &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight < 300;
        final heroHeight = isCompact
            ? (constraints.maxHeight.isFinite
                  ? (constraints.maxHeight * 0.4).clamp(104.0, 132.0)
                  : 132.0)
            : 194.0;
        final titleMaxLines = useTightCompactLayout ? 1 : 2;
        final titleFontSize = useTightCompactLayout
            ? 14.0
            : (isCompact ? 15.0 : 16.0);
        final priceFontSize = useTightCompactLayout ? 15.0 : 17.0;
        final bodyTopPadding = useTightCompactLayout
            ? 10.0
            : (isCompact ? 12.0 : 14.0);
        final bodyBottomPadding = useTightCompactLayout ? 10.0 : 12.0;
        final smallGap = useTightCompactLayout ? 4.0 : 6.0;
        final mediumGap = useTightCompactLayout ? 8.0 : 10.0;
        final featureSpacing = useTightCompactLayout ? 4.0 : 6.0;
        final featureChips = [
          _ListingFeatureChip(
            icon: Icons.bed_rounded,
            label: context.tr(
              bn: '${context.digitsText(listing.bedrooms)} বেড',
              en: '${listing.bedrooms} Bed',
            ),
            isCompact: useTightCompactLayout,
          ),
          _ListingFeatureChip(
            icon: Icons.bathtub_outlined,
            label: context.tr(
              bn: '${context.digitsText(listing.bathrooms)} বাথ',
              en: '${listing.bathrooms} Bath',
            ),
            isCompact: useTightCompactLayout,
          ),
          if (!useTightCompactLayout)
            _ListingFeatureChip(
              icon: Icons.square_foot_rounded,
              label: context.tr(
                bn: '${context.digitsText(listing.areaSqft)} বর্গফুট',
                en: '${listing.areaSqft} sqft',
              ),
            ),
        ];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: heroHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: listing.imageGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _ListingHeroArtwork(listing: listing),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: listing.tagColor,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          context.demoText(listing.badgeLabel),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 6,
                            width: index == 0 ? 16 : 6,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.66),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  bodyTopPadding,
                  16,
                  bodyBottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.demoText(listing.title),
                      maxLines: titleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: titleFontSize,
                      ),
                    ),
                    SizedBox(height: smallGap),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: useTightCompactLayout ? 12 : null,
                                ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: mediumGap),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          listing.priceLabel,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: priceFontSize,
                              ),
                        ),
                        if (listing.priceSuffix.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            context.demoText(listing.priceSuffix),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: useTightCompactLayout ? 11 : null,
                                ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: mediumGap),
                    Wrap(
                      spacing: featureSpacing,
                      runSpacing: featureSpacing,
                      children: featureChips,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MarketplaceBackdropBubble extends StatelessWidget {
  const _MarketplaceBackdropBubble({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: colors),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ListingHeroArtwork extends StatelessWidget {
  const _ListingHeroArtwork({required this.listing});

  final FeaturedListingData listing;

  bool get _isInterior {
    return listing.imageIcon == Icons.chair_alt_rounded ||
        listing.imageIcon == Icons.weekend_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: listing.imageGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (_isInterior)
            const _InteriorListingScene()
          else
            _BuildingListingScene(listing: listing),
        ],
      ),
    );
  }
}

class _InteriorListingScene extends StatelessWidget {
  const _InteriorListingScene();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 16,
          top: 12,
          right: 16,
          bottom: 32,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5E8D8), Color(0xFFE7D2BC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        Positioned(
          left: 28,
          top: 20,
          child: Container(
            height: 76,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD7E4F6), width: 3),
            ),
            child: const Center(
              child: Icon(Icons.view_column_rounded, color: Color(0xFF94A3B8)),
            ),
          ),
        ),
        Positioned(
          left: 96,
          top: 44,
          child: Container(
            height: 52,
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFD6B38A),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          left: 106,
          top: 32,
          child: Container(
            height: 12,
            width: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFB45309),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Positioned(
          left: 22,
          bottom: 34,
          child: Container(
            height: 56,
            width: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F1E7),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          left: 28,
          bottom: 72,
          child: Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5E3C),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Positioned(
          right: 24,
          bottom: 36,
          child: Container(
            height: 56,
            width: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFC99765),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          right: 34,
          bottom: 90,
          child: Container(
            height: 40,
            width: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF4E7C52),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Positioned(
          right: 22,
          bottom: 116,
          child: Container(
            height: 22,
            width: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF76B57D),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 24,
          child: Container(
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFB08968),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}

class _BuildingListingScene extends StatelessWidget {
  const _BuildingListingScene({required this.listing});

  final FeaturedListingData listing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  listing.imageGradient.first.withValues(alpha: 0.96),
                  Colors.white.withValues(alpha: 0.34),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 18,
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF475569).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Positioned(
          left: 18,
          bottom: 22,
          child: Container(
            height: 28,
            width: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF4E8B57),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 22,
          child: Container(
            height: 34,
            width: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF4F8D54),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Positioned(
          left: 52,
          right: 42,
          top: 16,
          bottom: 24,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.skewX(-0.08),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFDFEFF), Color(0xFFE9EEF7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 70
                      ? 6.0
                      : 10.0;
                  final verticalPadding = constraints.maxHeight < 72
                      ? 4.0
                      : 8.0;

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final availableWidth =
                            innerConstraints.maxWidth.isFinite
                            ? innerConstraints.maxWidth
                            : 36.0;
                        final availableHeight =
                            innerConstraints.maxHeight.isFinite
                            ? innerConstraints.maxHeight
                            : 48.0;
                        final rowCount = availableHeight >= 18
                            ? (availableHeight / 10).floor().clamp(2, 5)
                            : 1;
                        final columnCount = availableWidth < 22
                            ? 1
                            : (availableWidth < 42 ? 2 : 3);
                        final horizontalSpacing = columnCount == 3
                            ? 6.0
                            : (columnCount == 2 ? 4.0 : 0.0);
                        final verticalSpacing = rowCount <= 1
                            ? 0.0
                            : (rowCount >= 4 ? 4.0 : 3.0);
                        final windowWidth =
                            ((availableWidth -
                                        (horizontalSpacing *
                                            (columnCount - 1))) /
                                    columnCount)
                                .clamp(0.0, 12.0);
                        final windowHeight =
                            ((availableHeight -
                                        (verticalSpacing * (rowCount - 1))) /
                                    rowCount)
                                .clamp(0.0, 16.0);
                        final previewWidth =
                            (windowWidth * columnCount) +
                            (horizontalSpacing * (columnCount - 1));
                        final previewHeight =
                            (windowHeight * rowCount) +
                            (verticalSpacing * (rowCount - 1));

                        return Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: previewWidth,
                            height: previewHeight,
                            child: Wrap(
                              spacing: horizontalSpacing,
                              runSpacing: verticalSpacing,
                              children: List.generate(
                                rowCount * columnCount,
                                (_) => Container(
                                  height: windowHeight,
                                  width: windowWidth,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF93C5FD,
                                    ).withValues(alpha: 0.74),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListingFeatureChip extends StatelessWidget {
  const _ListingFeatureChip({
    required this.icon,
    required this.label,
    this.isCompact = false,
  });

  final IconData icon;
  final String label;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 13 : 15, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            context.demoText(label),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: isCompact ? 10 : 11,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCategoryCard extends StatelessWidget {
  const _QuickCategoryCard({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const Spacer(),
          Text(
            context.demoText(title),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _TenantPaymentHistoryCard extends StatelessWidget {
  const _TenantPaymentHistoryCard({required this.payment});

  final RentPayment payment;

  @override
  Widget build(BuildContext context) {
    final paidDate = payment.paidOn == null
        ? '-'
        : DateFormat('dd MMM yyyy').format(payment.paidOn!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.monthLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Date: $paidDate',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  context.money(payment.amount),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showComingSoonSnackBar(context, 'Download PDF'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({required this.method});

  final PaymentMethodOption method;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth.isFinite &&
            constraints.maxHeight.isFinite &&
            (constraints.maxWidth < 92 || constraints.maxHeight < 92);
        final padding = isCompact ? 10.0 : 14.0;
        final iconSize = isCompact ? 38.0 : 48.0;
        final gap = isCompact ? 6.0 : 10.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: iconSize,
                width: iconSize,
                decoration: BoxDecoration(
                  color: method.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  method.icon,
                  color: method.color,
                  size: isCompact ? 20 : 24,
                ),
              ),
              SizedBox(height: gap),
              Text(
                context.demoText(method.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: isCompact ? 12 : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MaintenanceCategoryCard extends StatelessWidget {
  const _MaintenanceCategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final MaintenanceCategoryOption category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  category.icon,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                context.demoText(category.label),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
