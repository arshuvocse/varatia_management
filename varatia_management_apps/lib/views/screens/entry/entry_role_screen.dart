import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_context.dart';
import '../../../data/services/auth_session_service.dart';
import '../../../viewmodels/role_dashboard_view_models.dart';
import '../../widgets/app_widgets.dart';
import 'entry_routes.dart';
import 'entry_types.dart';

class EntryRoleScreen extends StatelessWidget {
  const EntryRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectionViewModel = context.watch<RoleSelectionViewModel>();
    final selectedRole = selectionViewModel.selectedRole;

    return EntryScaffold(
      compact: true,
      onBack: () => Navigator.of(context).pop(),
      eyebrow: context.tr(bn: 'রোল সেটআপ', en: 'Role setup'),
      title: context.tr(bn: 'আপনার রোল নির্বাচন করুন', en: 'Select Your Role'),
      subtitle: context.tr(
        bn: 'একটি রোল বেছে নিয়ে এগিয়ে যান।',
        en: 'Choose a role to continue.',
      ),
      child: Column(
        children: [
          _RoleCard(
            compact: true,
            title: EntryUserRole.owner.label(context),
            subtitle: EntryUserRole.owner.subtitle(context),
            icon: Icons.home_work_rounded,
            accentColor: AppColors.accent,
            isSelected: selectedRole == EntryUserRole.owner,
            onTap: () => selectionViewModel.selectRole(EntryUserRole.owner),
          ),
          const SizedBox(height: 10),
          _RoleCard(
            compact: true,
            title: EntryUserRole.tenant.label(context),
            subtitle: EntryUserRole.tenant.subtitle(context),
            icon: Icons.apartment_rounded,
            accentColor: AppColors.success,
            isSelected: selectedRole == EntryUserRole.tenant,
            onTap: () => selectionViewModel.selectRole(EntryUserRole.tenant),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () async {
              try {
                await AuthSessionService().saveRole(selectedRole);
              } catch (_) {
                // Local session persistence should not block dashboard access.
              }

              if (!context.mounted) {
                return;
              }

              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.home,
                (route) => false,
                arguments: selectedRole,
              );
            },
            child: Text(context.tr(bn: 'এগিয়ে যান', en: 'Continue')),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.primary : AppColors.border;
    final backgroundColor = isSelected
        ? AppColors.surfaceSoft
        : AppColors.surface;
    final cardPadding = compact ? 14.0 : 18.0;
    final iconGap = compact ? 12.0 : 14.0;
    final subtitleGap = compact ? 2.0 : 4.0;
    final titleStyle = compact
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.titleMedium;
    final subtitleStyle = compact
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Ink(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              _RoleIconStack(
                icon: icon,
                accentColor: accentColor,
                compact: compact,
              ),
              SizedBox(width: iconGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle),
                    SizedBox(height: subtitleGap),
                    Text(
                      subtitle,
                      maxLines: compact ? 2 : null,
                      overflow: compact ? TextOverflow.ellipsis : null,
                      style: subtitleStyle,
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleIconStack extends StatelessWidget {
  const _RoleIconStack({
    required this.icon,
    required this.accentColor,
    this.compact = false,
  });

  final IconData icon;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final stackSize = compact ? 54.0 : 62.0;
    final backBoxSize = compact ? 42.0 : 48.0;
    final frontBoxSize = compact ? 46.0 : 52.0;
    final radius = compact ? 16.0 : 18.0;

    return SizedBox(
      height: stackSize,
      width: stackSize,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: backBoxSize,
              width: backBoxSize,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              height: frontBoxSize,
              width: frontBoxSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.72)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(radius),
                boxShadow: AppShadows.card,
              ),
              child: Icon(icon, color: Colors.white, size: compact ? 22 : 24),
            ),
          ),
        ],
      ),
    );
  }
}
