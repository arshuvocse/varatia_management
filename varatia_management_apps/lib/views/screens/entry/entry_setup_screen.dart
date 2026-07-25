import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_context.dart';
import '../../../data/services/auth_session_service.dart';
import '../../widgets/app_widgets.dart';
import 'entry_routes.dart';
import 'entry_types.dart';

class EntrySetupScreen extends StatelessWidget {
  const EntrySetupScreen({super.key, required this.selectedRole});

  final EntryUserRole selectedRole;

  @override
  Widget build(BuildContext context) {
    final roleLabel = selectedRole.label(context);

    return EntryScaffold(
      onBack: () => Navigator.of(context).pop(),
      eyebrow: context.tr(bn: 'Workspace ready', en: 'Workspace ready'),
      title: context.tr(
        bn: 'Prepare Your Dashboard',
        en: 'Prepare Your Dashboard',
      ),
      subtitle: context.tr(
        bn: 'Your $roleLabel workspace is staged. Review the quick highlights below and continue into the live dashboard.',
        en: 'Your $roleLabel workspace is staged. Review the quick highlights below and continue into the live dashboard.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SetupHintTile(
            icon: Icons.dashboard_customize_rounded,
            title: context.tr(
              bn: '$roleLabel dashboard',
              en: '$roleLabel dashboard',
            ),
            subtitle: context.tr(
              bn: 'Role-specific navigation and clean card layouts are ready.',
              en: 'Role-specific navigation and clean card layouts are ready.',
            ),
          ),
          const SizedBox(height: 12),
          _SetupHintTile(
            icon: Icons.palette_outlined,
            title: context.tr(
              bn: 'Design system applied',
              en: 'Design system applied',
            ),
            subtitle: context.tr(
              bn: 'Primary blue, accent orange, soft grey backgrounds, and Poppins typography are active.',
              en: 'Primary blue, accent orange, soft grey backgrounds, and Poppins typography are active.',
            ),
          ),
          const SizedBox(height: 12),
          _SetupHintTile(
            icon: Icons.route_rounded,
            title: context.tr(bn: 'Next step', en: 'Next step'),
            subtitle: context.tr(
              bn: 'Open the dashboard and explore the dedicated pages for your role.',
              en: 'Open the dashboard and explore the dedicated pages for your role.',
            ),
          ),
          const SizedBox(height: 18),
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
            child: Text(selectedRole.actionTitle(context)),
          ),
        ],
      ),
    );
  }
}

class _SetupHintTile extends StatelessWidget {
  const _SetupHintTile({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
