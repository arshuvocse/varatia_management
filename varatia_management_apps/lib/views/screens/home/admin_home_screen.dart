import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_context.dart';
import '../../../core/utils/local_lang.dart';
import '../../../viewmodels/role_dashboard_view_models.dart';
import '../role_dashboards.dart';
import 'role_home_scaffold.dart';
import 'admin_inbox_page.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shellViewModel = context.watch<RoleShellViewModel>();

    return RoleHomeScaffold(
      currentIndex: shellViewModel.currentIndex,
      onSelected: shellViewModel.selectTab,
      pages: const [
        AdminDashboardOverviewPage(),
        AdminInboxPage(),
        AdminVerificationRequestPage(),
        AdminSettingsPage(),
      ],
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: context.loc(AppLocalLang.home),
        ),
        NavigationDestination(
          icon: const Icon(Icons.mail_outline_rounded),
          selectedIcon: const Icon(Icons.mail_rounded),
          label: context.tr(bn: 'ইনবক্স', en: 'Inbox'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.people_outline_rounded),
          selectedIcon: const Icon(Icons.people_rounded),
          label: context.loc(AppLocalLang.users),
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: context.loc(AppLocalLang.settings),
        ),
      ],
    );
  }
}
