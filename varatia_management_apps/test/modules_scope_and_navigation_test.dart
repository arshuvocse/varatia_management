import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:varatia_management_apps/core/models/user_role.dart';
import 'package:varatia_management_apps/data/repositories/management_repository.dart';
import 'package:varatia_management_apps/data/services/auth_session_service.dart';
import 'package:varatia_management_apps/viewmodels/app_view_models.dart';
import 'package:varatia_management_apps/viewmodels/role_dashboard_view_models.dart';
import 'package:varatia_management_apps/views/screens/entry/entry_routes.dart';
import 'package:varatia_management_apps/views/screens/entry_flow_screen.dart';
import 'package:varatia_management_apps/views/screens/tenant_reference_pages.dart';
import 'package:varatia_management_apps/views/screens/role_dashboards.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    await AuthSessionService().clear();
  });

  group('Module Scope and Route Navigation Tests', () {
    test('AppRoutes.tutorTeachLearn resolves to TenantTutorTeachLearnPage', () {
      final route = buildAppRoute(
        const RouteSettings(name: AppRoutes.tutorTeachLearn),
      );

      expect(route, isA<PageRouteBuilder<void>>());
      final pageRoute = route as PageRouteBuilder<void>;
      final widget = pageRoute.pageBuilder(
        MockBuildContext(),
        const AlwaysStoppedAnimation(1.0),
        const AlwaysStoppedAnimation(1.0),
      );

      expect(widget, isA<TenantTutorTeachLearnPage>());
    });

    test(
      'Disabled route AppRoutes.amarElaka redirects safely to EntryFlowScreen fallback',
      () {
        final route = buildAppRoute(
          const RouteSettings(name: AppRoutes.amarElaka),
        );

        expect(route, isA<PageRouteBuilder<void>>());
        final pageRoute = route as PageRouteBuilder<void>;
        final widget = pageRoute.pageBuilder(
          MockBuildContext(),
          const AlwaysStoppedAnimation(1.0),
          const AlwaysStoppedAnimation(1.0),
        );

        expect(widget, isA<EntryFlowScreen>());
      },
    );

    test('Unknown or disabled routes resolve safely to EntryFlowScreen', () {
      final route = buildAppRoute(
        const RouteSettings(name: '/unsupported/disabled-feature'),
      );

      expect(route, isA<PageRouteBuilder<void>>());
      final pageRoute = route as PageRouteBuilder<void>;
      final widget = pageRoute.pageBuilder(
        MockBuildContext(),
        const AlwaysStoppedAnimation(1.0),
        const AlwaysStoppedAnimation(1.0),
      );

      expect(widget, isA<EntryFlowScreen>());
    });

    testWidgets(
      'Owner dashboard renders property management and tutor quick actions',
      (tester) async {
        await AuthSessionService().saveSession(
          AuthSession(
            userId: 'O-01',
            fullName: 'Rahim Landlord',
            phoneNumber: '01700000000',
            role: EntryUserRole.owner,
            isPhoneVerified: true,
          ),
        );

        final mockRepo = MockManagementRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ManagementRepository>.value(value: mockRepo),
                ChangeNotifierProvider(create: (_) => SettingsViewModel()),
                ChangeNotifierProvider(
                  create: (_) => RoleShellViewModel(EntryUserRole.owner),
                ),
                ChangeNotifierProvider(
                  create: (_) => OwnerDashboardViewModel(mockRepo),
                ),
                ChangeNotifierProvider(
                  create: (_) => TenantExperienceViewModel(mockRepo),
                ),
              ],
              child: const Scaffold(body: OwnerHomePage()),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        // Verify Varatia Management Owner quick actions & Teach/Learn card are present
        expect(find.text('Teach / Learn'), findsOneWidget);
        expect(find.text('Tenants'), findsOneWidget);
        expect(find.text('Send Bill'), findsOneWidget);
      },
    );
  });
}

class MockBuildContext extends Fake implements BuildContext {}
