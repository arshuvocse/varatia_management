import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:varatia_management_apps/app/varatia_app.dart';
import 'package:varatia_management_apps/core/models/user_role.dart';
import 'package:varatia_management_apps/data/repositories/management_repository.dart';
import 'package:varatia_management_apps/data/services/auth_session_service.dart';
import 'package:varatia_management_apps/data/services/device_identity_service.dart';
import 'package:varatia_management_apps/data/services/registration_api_service.dart';
import 'package:varatia_management_apps/viewmodels/role_dashboard_view_models.dart';
import 'package:varatia_management_apps/views/screens/app_shell.dart';
import 'package:varatia_management_apps/views/screens/entry/entry_login_screen.dart';
import 'package:varatia_management_apps/views/screens/entry/entry_splash_screen.dart';
import 'package:varatia_management_apps/views/screens/home/tenant_pickup_service_screen.dart';
import 'package:varatia_management_apps/views/screens/role_dashboards.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    await AuthSessionService().clear();
  });

  testWidgets('app flows from splash to login without a saved session', (
    tester,
  ) async {
    await tester.pumpWidget(VaratiaApp(repository: MockManagementRepository()));

    expect(find.byType(EntrySplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(EntryLoginScreen), findsOneWidget);
  });

  testWidgets('app skips login when a verified SQLite session exists', (
    tester,
  ) async {
    await AuthSessionService().saveSession(
      AuthSession(
        userId: 'test-user',
        fullName: 'Test Admin',
        phoneNumber: '01711111111',
        role: EntryUserRole.admin,
        isPhoneVerified: true,
      ),
    );

    await tester.pumpWidget(VaratiaApp(repository: MockManagementRepository()));

    expect(find.byType(EntrySplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(EntryLoginScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(AdminDashboardOverviewPage), findsOneWidget);
  });

  testWidgets('app restores the saved home tab from the local session', (
    tester,
  ) async {
    await AuthSessionService().saveSession(
      AuthSession(
        userId: 'test-user',
        fullName: 'Test Admin',
        phoneNumber: '01711111111',
        role: EntryUserRole.admin,
        isPhoneVerified: true,
        lastHomeTabIndex: 2,
      ),
    );

    await tester.pumpWidget(VaratiaApp(repository: MockManagementRepository()));

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(EntryLoginScreen), findsNothing);
    expect(find.byType(AdminVerificationRequestPage), findsOneWidget);
  });

  test('login without an OTP challenge persists a verified session', () async {
    const createdAtRaw = '2026-04-25T11:22:11.8078772';
    final createdAt = DateTime.parse(createdAtRaw);
    final service = RegistrationApiService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/login');

        return http.Response(
          jsonEncode({
            'userId': 'test-user',
            'fullName': 'Test User',
            'phoneNumber': '01711111111',
            'createdAt': createdAtRaw,
            'role': 'tenant',
            'otpRequired': false,
            'message': 'Login successful.',
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
      deviceIdentityService: _FakeDeviceIdentityService(),
    );

    final result = await service.login(
      phoneNumber: '01711111111',
      password: 'password',
    );
    final session = await AuthSessionService().readSession(forceRefresh: true);

    expect(result.otpRequired, isFalse);
    expect(result.isPhoneVerified, isFalse);
    expect(result.createdAt, createdAt);
    expect(session?.isPhoneVerified, isTrue);
    expect(session?.role, EntryUserRole.tenant);
    expect(session?.createdAt, createdAt.toUtc());
  });

  test('pickup service eligibility starts after three calendar months', () {
    final joinedAt = DateTime.utc(2026, 1, 31, 10);

    expect(
      isPickupServiceFreeEligible(
        joinedAt,
        now: DateTime.utc(2026, 4, 30, 9, 59),
      ),
      isFalse,
    );
    expect(
      isPickupServiceFreeEligible(joinedAt, now: DateTime.utc(2026, 4, 30, 10)),
      isTrue,
    );
    expect(
      pickupFreeRemainingDays(joinedAt, now: DateTime.utc(2026, 4, 29, 10)),
      1,
    );
    expect(isPickupServiceFreeEligible(null), isFalse);
  });

  test('admin shell can restore the settings tab', () {
    final viewModel = RoleShellViewModel(
      EntryUserRole.admin,
      initialTabIndex: 3,
    );

    expect(viewModel.currentIndex, 3);
  });

  test(
    'tenant experience resolves the active tenant from the saved session',
    () async {
      await AuthSessionService().saveSession(
        AuthSession(
          userId: 'T-04',
          fullName: 'Session Salma',
          phoneNumber: '01611111111',
          role: EntryUserRole.tenant,
          isPhoneVerified: true,
        ),
      );

      final viewModel = TenantExperienceViewModel(MockManagementRepository());
      await viewModel.refreshAuthSession();

      expect(viewModel.activeTenant.id, 'T-04');
      expect(viewModel.activeTenant.name, 'Session Salma');
      expect(viewModel.activeTenant.phone, '01611111111');
      expect(viewModel.activeTenant.propertyName, 'Flat E');
    },
  );
}

class _FakeDeviceIdentityService extends DeviceIdentityService {
  @override
  Future<DeviceIdentity> readDeviceIdentity({
    String? firebaseDeviceTokenOverride,
  }) async {
    return const DeviceIdentity(
      firebaseDeviceToken: 'test-firebase-token',
      imei: 'test-device-id',
    );
  }
}
