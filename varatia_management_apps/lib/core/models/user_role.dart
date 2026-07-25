import 'package:flutter/widgets.dart';

import '../utils/app_context.dart';
import '../utils/local_lang.dart';

enum EntryUserRole { admin, owner, tenant }

EntryUserRole? entryUserRoleFromApiValue(String? value) {
  final normalizedValue = value?.trim().toLowerCase();
  if (normalizedValue == null || normalizedValue.isEmpty) {
    return null;
  }

  return switch (normalizedValue) {
    'admin' => EntryUserRole.admin,
    'owner' || 'propertyowner' || 'property owner' => EntryUserRole.owner,
    'tenant' => EntryUserRole.tenant,
    _ => null,
  };
}

extension EntryUserRoleX on EntryUserRole {
  String get apiValue {
    return switch (this) {
      EntryUserRole.admin => 'admin',
      EntryUserRole.owner => 'owner',
      EntryUserRole.tenant => 'tenant',
    };
  }

  String label(BuildContext context) {
    return switch (this) {
      EntryUserRole.admin => context.loc(AppLocalLang.adminRole),
      EntryUserRole.owner => context.loc(AppLocalLang.propertyOwnerRole),
      EntryUserRole.tenant => context.loc(AppLocalLang.tenantRole),
    };
  }

  String subtitle(BuildContext context) {
    return switch (this) {
      EntryUserRole.admin => context.loc(AppLocalLang.adminRoleSubtitle),
      EntryUserRole.owner => context.loc(AppLocalLang.ownerRoleSubtitle),
      EntryUserRole.tenant => context.loc(AppLocalLang.tenantRoleSubtitle),
    };
  }

  String actionTitle(BuildContext context) {
    return switch (this) {
      EntryUserRole.admin => context.loc(AppLocalLang.openAdminDashboard),
      EntryUserRole.owner => context.loc(AppLocalLang.openOwnerWorkspace),
      EntryUserRole.tenant => context.loc(AppLocalLang.openTenantApp),
    };
  }
}
