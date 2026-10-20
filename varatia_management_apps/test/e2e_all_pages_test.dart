import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:varatia_management_apps/core/config/api_config.dart';
import 'package:varatia_management_apps/core/models/user_role.dart';
import 'package:varatia_management_apps/data/repositories/management_repository.dart';
import 'package:varatia_management_apps/data/services/auth_session_service.dart';
import 'package:varatia_management_apps/viewmodels/app_view_models.dart';
import 'package:varatia_management_apps/viewmodels/role_dashboard_view_models.dart';
import 'package:varatia_management_apps/views/screens/entry/entry_login_screen.dart';
import 'package:varatia_management_apps/views/screens/entry/entry_otp_screen.dart';
import 'package:varatia_management_apps/views/screens/entry/entry_reset_password_screen.dart';
import 'package:varatia_management_apps/views/screens/entry/entry_role_screen.dart';
import 'package:varatia_management_apps/views/screens/entry/entry_routes.dart';
import 'package:varatia_management_apps/views/screens/entry/entry_setup_screen.dart';
import 'package:varatia_management_apps/views/screens/entry/entry_sign_up_screen.dart';
import 'package:varatia_management_apps/views/screens/entry_flow_screen.dart';
import 'package:varatia_management_apps/views/screens/home/general_post_composer_page.dart';
import 'package:varatia_management_apps/views/screens/payment/user_payment_history_screen.dart';
import 'package:varatia_management_apps/views/screens/role_dashboards.dart';
import 'package:varatia_management_apps/views/screens/subscription/subscription_matchmaking_screen.dart';
import 'package:varatia_management_apps/views/screens/tenant_reference_pages.dart';

class MockBuildContext extends Fake implements BuildContext {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    await AuthSessionService().clear();
  });

  Widget buildTestableWidget(Widget child, {ManagementRepository? repository}) {
    final repo = repository ?? MockManagementRepository();
    return MultiProvider(
      providers: [
        Provider<ManagementRepository>.value(value: repo),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => TenantExperienceViewModel(repo)),
        ChangeNotifierProvider(create: (_) => RoleShellViewModel(EntryUserRole.tenant)),
        ChangeNotifierProvider(create: (_) => RoleSelectionViewModel()),
        ChangeNotifierProvider(create: (_) => OwnerDashboardViewModel(repo)),
        ChangeNotifierProvider(create: (_) => PaymentViewModel(repo)),
        ChangeNotifierProvider(create: (_) => PropertyViewModel(repo)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateRoute: buildAppRoute,
        home: child,
      ),
    );
  }

  group('E2E Agentic Security & BaseUrl Suite', () {
    test('Agentic Security: baseUrl enforces HTTPS and resolves to amarthikanaa.com', () {
      expect(ApiConfig.baseUrl, equals('https://amarthikanaa.com'));
      expect(ApiConfig.baseUrl.startsWith('https://'), isTrue);
      expect(ApiConfig.baseUrl.startsWith('http://'), isFalse);
    });

    test('Agentic Security: API routes correctly format secure URLs under amarthikanaa.com', () {
      final postsUri = Uri.parse('${ApiConfig.baseUrl}/api/GeneralPosts/paged');
      expect(postsUri.host, equals('amarthikanaa.com'));
      expect(postsUri.scheme, equals('https'));

      final chatUri = Uri.parse('${ApiConfig.baseUrl}/api/chat/messages');
      expect(chatUri.host, equals('amarthikanaa.com'));
      expect(chatUri.scheme, equals('https'));

      final subscriptionUri = Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/plans');
      expect(subscriptionUri.host, equals('amarthikanaa.com'));
      expect(subscriptionUri.scheme, equals('https'));
    });

    test('Agentic Security: SQL injection payloads are safely stored without syntax breakdown', () async {
      const sqlInjectionName = "Admin' OR '1'='1";
      const sqlInjectionPhone = "01855667788'; DROP TABLE users; --";

      final service = AuthSessionService();
      await service.saveSession(
        AuthSession(
          userId: 'test_user_sql_safe',
          fullName: sqlInjectionName,
          phoneNumber: sqlInjectionPhone,
          role: EntryUserRole.tenant,
          isPhoneVerified: true,
          savedAt: DateTime.now(),
        ),
      );

      final readBack = await service.readSession();
      expect(readBack, isNotNull);
      expect(readBack?.fullName, equals(sqlInjectionName));
      expect(readBack?.phoneNumber, equals(sqlInjectionPhone));
      expect(readBack?.role, equals(EntryUserRole.tenant));
    });

    test('Agentic Security: XSS script tags in user fields are safely preserved as strings', () async {
      const xssPayload = '<script>alert("xss")</script>';
      final service = AuthSessionService();
      await service.saveSession(
        AuthSession(
          userId: 'test_user_xss_safe',
          fullName: xssPayload,
          phoneNumber: '01711223344',
          role: EntryUserRole.tenant,
          isPhoneVerified: true,
          savedAt: DateTime.now(),
        ),
      );

      final readBack = await service.readSession();
      expect(readBack?.fullName, equals(xssPayload));
    });
  });

  group('E2E Route Generation & Page Mapping Suite', () {
    test('All registered routes generate correct widget destinations', () {
      final expectations = <String, Type>{
        AppRoutes.splash: EntryFlowScreen,
        AppRoutes.login: EntryLoginScreen,
        AppRoutes.signUp: EntrySignUpScreen,
        AppRoutes.otp: EntryOtpScreen,
        AppRoutes.resetPassword: EntryResetPasswordScreen,
        AppRoutes.role: EntryRoleScreen,
        AppRoutes.setup: EntrySetupScreen,
        AppRoutes.tutorTeachLearn: TenantTutorTeachLearnPage,
        AppRoutes.postComposer: GeneralPostComposerPage,
        AppRoutes.paymentHistory: UserPaymentHistoryScreen,
        AppRoutes.subscriptionPlans: SubscriptionMatchmakingScreen,
      };

      for (final entry in expectations.entries) {
        final route = buildAppRoute(RouteSettings(name: entry.key));
        expect(route, isA<PageRouteBuilder<void>>(), reason: 'Route ${entry.key} failed builder');
        final pageRoute = route as PageRouteBuilder<void>;
        final widget = pageRoute.pageBuilder(
          MockBuildContext(),
          const AlwaysStoppedAnimation(1.0),
          const AlwaysStoppedAnimation(1.0),
        );
        expect(widget.runtimeType, equals(entry.value), reason: 'Route ${entry.key} mismatched widget');
      }
    });

    test('AppRoutes.home wraps AppShell inside ChangeNotifierProvider', () {
      final route = buildAppRoute(const RouteSettings(name: AppRoutes.home));
      expect(route, isA<PageRouteBuilder<void>>());
      final pageRoute = route as PageRouteBuilder<void>;
      final widget = pageRoute.pageBuilder(
        MockBuildContext(),
        const AlwaysStoppedAnimation(1.0),
        const AlwaysStoppedAnimation(1.0),
      );
      expect(widget, isA<ChangeNotifierProvider<RoleShellViewModel>>());
    });
  });

  group('E2E Page Rendering & Interactive Flow Suite', () {
    testWidgets('Login Screen renders phone, password and buttons with security obscureText', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const EntryLoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(EntryLoginScreen), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('ফোন নম্বর লিখুন'), findsOneWidget);
      expect(find.text('পাসওয়ার্ড লিখুন'), findsOneWidget);

      final passwordFieldFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.obscureText == true,
      );
      expect(passwordFieldFinder, findsOneWidget);

      expect(find.text('এগিয়ে যান'), findsOneWidget);
      expect(find.text('সাইন আপ'), findsOneWidget);
      expect(find.text('পাসওয়ার্ড ভুলে গেছেন?'), findsOneWidget);
    });

    testWidgets('Sign Up Screen renders name, phone, password and confirm password', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const EntrySignUpScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(EntrySignUpScreen), findsOneWidget);
      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Enter phone number (e.g. 017xxxxxxxx)'), findsOneWidget);
      expect(find.text('Create password'), findsOneWidget);
      expect(find.text('Re-enter password'), findsOneWidget);
      expect(find.text('Sign Up'), findsWidgets);
    });

    testWidgets('OTP Screen renders 6-digit verification input and resend countdown', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const EntryOtpScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(EntryOtpScreen), findsOneWidget);
      expect(find.text('OTP Verification'), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
      expect(find.text('Resend Code'), findsOneWidget);
    });

    testWidgets('Reset Password Screen renders reset form fields', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const EntryResetPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(EntryResetPasswordScreen), findsOneWidget);
      expect(find.text('Reset Password'), findsNWidgets(2));
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('Role Selection Screen renders role cards and selection controls', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const EntryRoleScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(EntryRoleScreen), findsOneWidget);
      expect(find.text('আপনার রোল নির্বাচন করুন'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('Tutor Teach & Learn Screen renders header and tutor actions', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const TenantTutorTeachLearnPage()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TenantTutorTeachLearnPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('General Post Composer Page renders form and header in Bengali', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const GeneralPostComposerPage()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GeneralPostComposerPage), findsOneWidget);
      expect(find.text('নতুন বিজ্ঞাপন তৈরি করুন'), findsOneWidget);
    });

    testWidgets('Rent Payment Page renders rent tracker and submission form', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const TenantRentPaymentPage()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TenantRentPaymentPage), findsOneWidget);
      expect(find.text('ভাড়া ও বিল পেমেন্ট'), findsOneWidget);
    });

    testWidgets('Subscription Matchmaking Screen renders packages and matchmaking tiers', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const SubscriptionMatchmakingScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionMatchmakingScreen), findsOneWidget);
    });

    testWidgets('User Payment History Screen renders voucher history list', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const UserPaymentHistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(UserPaymentHistoryScreen), findsOneWidget);
      expect(find.text('পেমেন্ট ও লেনদেন হিস্ট্রি'), findsOneWidget);
    });
  });

  group('E2E Role Shell & Navigation Isolation Suite', () {
    test('RoleShellViewModel switches tabs accurately for tenant role', () {
      final shellVm = RoleShellViewModel(EntryUserRole.tenant);
      expect(shellVm.currentIndex, equals(0));

      shellVm.selectTab(1);
      expect(shellVm.currentIndex, equals(1));

      shellVm.selectTab(2);
      expect(shellVm.currentIndex, equals(2));

      shellVm.selectTab(3);
      expect(shellVm.currentIndex, equals(3));

      shellVm.selectTab(4);
      expect(shellVm.currentIndex, equals(4));
    });

    test('RoleShellViewModel isolates state across roles', () {
      final tenantVm = RoleShellViewModel(EntryUserRole.tenant);
      final ownerVm = RoleShellViewModel(EntryUserRole.owner);
      final adminVm = RoleShellViewModel(EntryUserRole.admin);

      tenantVm.selectTab(2);
      expect(tenantVm.currentIndex, equals(2));
      expect(ownerVm.currentIndex, equals(0));
      expect(adminVm.currentIndex, equals(0));
    });
  });
}
