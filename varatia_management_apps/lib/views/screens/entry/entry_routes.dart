import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/role_dashboard_view_models.dart';
import '../app_shell.dart';
import '../entry_flow_screen.dart';
import '../home/tenant_amar_elaka_screen.dart';
import '../home/tenant_auth_bridge_screen.dart';
import '../home/general_post_composer_page.dart';
import 'entry_login_screen.dart';
import 'entry_otp_screen.dart';
import 'entry_reset_password_screen.dart';
import 'entry_role_screen.dart';
import 'entry_setup_screen.dart';
import 'entry_sign_up_screen.dart';
import 'entry_types.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/entry/login';
  static const signUp = '/entry/sign-up';
  static const otp = '/entry/otp';
  static const resetPassword = '/entry/reset-password';
  static const role = '/entry/role';
  static const setup = '/entry/setup';
  static const home = '/home';
  static const amarElaka = '/home/amar-elaka';
  static const tenantAuthBridge = '/home/tenant-auth-bridge';
  static const postComposer = '/home/post-composer';
}

class HomeRouteArguments {
  const HomeRouteArguments({required this.role, this.initialTabIndex = 0});

  final EntryUserRole role;
  final int initialTabIndex;

  static HomeRouteArguments from(Object? arguments) {
    if (arguments is HomeRouteArguments) {
      return arguments;
    }

    if (arguments is EntryUserRole) {
      return HomeRouteArguments(role: arguments);
    }

    return const HomeRouteArguments(role: EntryUserRole.admin);
  }
}

Route<dynamic> buildAppRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      final autoNavigate = settings.arguments is bool
          ? settings.arguments as bool
          : true;
      return _buildRoute(settings, EntryFlowScreen(autoNavigate: autoNavigate));
    case AppRoutes.login:
      return _buildRoute(settings, const EntryLoginScreen());
    case AppRoutes.signUp:
      return _buildRoute(settings, const EntrySignUpScreen());
    case AppRoutes.otp:
      return _buildRoute(settings, const EntryOtpScreen());
    case AppRoutes.resetPassword:
      return _buildRoute(settings, const EntryResetPasswordScreen());
    case AppRoutes.role:
      return _buildRoute(settings, const EntryRoleScreen());
    case AppRoutes.setup:
      final selectedRole = settings.arguments is EntryUserRole
          ? settings.arguments as EntryUserRole
          : EntryUserRole.owner;
      return _buildRoute(
        settings,
        EntrySetupScreen(selectedRole: selectedRole),
      );
    case AppRoutes.home:
      final homeArguments = HomeRouteArguments.from(settings.arguments);
      final selectedRole = homeArguments.role;
      return _buildRoute(
        settings,
        ChangeNotifierProvider(
          create: (_) => RoleShellViewModel(
            selectedRole,
            initialTabIndex: homeArguments.initialTabIndex,
          ),
          child: AppShell(selectedRole: selectedRole),
        ),
      );
    case AppRoutes.amarElaka:
      return _buildRoute(settings, const TenantAmarElakaScreen());
    case AppRoutes.tenantAuthBridge:
      return _buildRoute(settings, const TenantAuthBridgeScreen());
    case AppRoutes.postComposer:
      return _buildRoute(settings, const GeneralPostComposerPage());
    default:
      return _buildRoute(settings, const EntryFlowScreen());
  }
}

PageRouteBuilder<void> _buildRoute(RouteSettings settings, Widget child) {
  return PageRouteBuilder<void>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, animation, __) => child,
    transitionsBuilder: (_, animation, __, routeChild) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(curve),
          child: routeChild,
        ),
      );
    },
  );
}
