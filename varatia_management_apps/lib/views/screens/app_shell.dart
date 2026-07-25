import 'package:flutter/material.dart';

import '../../core/models/user_role.dart';
import 'home/admin_home_screen.dart';
import 'home/tenant_home_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.selectedRole});

  final EntryUserRole selectedRole;

  @override
  Widget build(BuildContext context) {
    return switch (selectedRole) {
      EntryUserRole.admin => const AdminHomeScreen(),
      EntryUserRole.owner => const TenantHomeScreen(),
      EntryUserRole.tenant => const TenantHomeScreen(),
    };
  }
}
