import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:varatia_management_apps/core/config/api_config.dart';
import 'package:varatia_management_apps/data/models/management_snapshot.dart';
import 'package:varatia_management_apps/data/services/account_api_service.dart';
import 'package:varatia_management_apps/data/services/auth_session_service.dart';
import 'package:varatia_management_apps/data/services/communication_api_service.dart';
import 'package:varatia_management_apps/data/services/device_identity_service.dart';
import 'package:varatia_management_apps/data/services/expense_api_service.dart';
import 'package:varatia_management_apps/data/services/health_api_service.dart';
import 'package:varatia_management_apps/data/services/notification_api_service.dart';
import 'package:varatia_management_apps/data/services/owner_tenant_api_service.dart';
import 'package:varatia_management_apps/data/services/property_management_api_service.dart';
import 'package:varatia_management_apps/data/services/registration_api_service.dart';
import 'package:varatia_management_apps/data/services/report_api_service.dart';
import 'package:varatia_management_apps/data/services/tenant_payment_api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final runTag = _buildRunTag();
  final random = Random(DateTime.now().microsecondsSinceEpoch);
  final state = _SmokeState(
    runTag: runTag,
    authNameInitial: 'App Smoke Auth $runTag',
    authNameUpdated: 'App Smoke Auth Updated $runTag',
    authPhoneInitial: _newPhone(random),
    authPhoneUpdated: _newPhone(random),
    authPasswordInitial: 'AppSmokePass1!',
    authPasswordReset: 'AppSmokePass2!',
    authPasswordFinal: 'AppSmokePass3!',
    authDeviceToken: 'app-smoke-device-token-$runTag',
    authImei: 'APP-IMEI-$runTag',
    tenantNameInitial: 'App Smoke Tenant $runTag',
    tenantNameUpdated: 'App Smoke Tenant Updated $runTag',
    tenantPhoneInitial: _newPhone(random),
    tenantPhoneUpdated: _newPhone(random),
    tenantNidInitial: _newNid(random),
    tenantNidUpdated: _newNid(random),
    buildingNameInitial: 'App Smoke Tower $runTag',
    buildingNameUpdated: 'App Smoke Tower Updated $runTag',
    buildingLocationInitial: 'App Smoke Location $runTag',
    buildingLocationUpdated: 'App Smoke Location Updated $runTag',
    propertyNameInitial: 'App Smoke Unit $runTag',
    propertyNameUpdated: 'App Smoke Unit Updated $runTag',
    floorLabelInitial: '1',
    floorLabelUpdated: '2',
    expenseTitleInitial: 'App Smoke Expense $runTag',
    expenseTitleUpdated: 'App Smoke Expense Updated $runTag',
    expenseMonth: 'April 2026',
    notificationTitle: 'App Smoke Notification $runTag',
    notificationBody: 'App smoke notification body $runTag',
    messageText: 'App smoke message $runTag',
  );

  final client = http.Client();
  final authSession = _InMemoryAuthSessionService();
  final deviceIdentityService = _StubDeviceIdentityService(
    DeviceIdentity(
      firebaseDeviceToken: state.authDeviceToken,
      imei: state.authImei,
    ),
  );

  final registrationApiService = RegistrationApiService(
    client: client,
    deviceIdentityService: deviceIdentityService,
    authSessionService: authSession,
  );
  final accountApiService = AccountApiService(
    client: client,
    authSessionService: authSession,
  );
  final propertyApiService = PropertyManagementApiService(client: client);
  final ownerTenantApiService = OwnerTenantApiService(client: client);
  final tenantPaymentApiService = TenantPaymentApiService(client: client);
  final communicationApiService = CommunicationApiService(client: client);
  final expenseApiService = ExpenseApiService(client: client);
  final reportApiService = ReportApiService(client: client);
  final notificationApiService = NotificationApiService(client: client);
  final healthApiService = HealthApiService(client: client);

  stdout.writeln('Using API base URL: ${ApiConfig.baseUrl}');

  Object? failure;
  StackTrace? failureStackTrace;

  try {
    final health = await healthApiService.getStatus();
    _ensure(
      health.status.toLowerCase() == 'ok',
      'Health endpoint returned ${health.status}.',
    );
    _pass('GET /api/health', '${health.status}:${health.database}');

    final bootstrapResponse = await client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/management/bootstrap'),
    );
    _ensure(
      bootstrapResponse.statusCode == 200,
      'Bootstrap endpoint returned HTTP ${bootstrapResponse.statusCode}.',
    );
    final snapshot = ManagementSnapshot.fromJson(
      jsonDecode(bootstrapResponse.body) as Map<String, dynamic>,
    );
    _ensure(
      snapshot.dashboardSummary.totalProperties >= 0,
      'Bootstrap dashboard summary was not parsed.',
    );
    _pass(
      'GET /api/management/bootstrap',
      snapshot.dashboardSummary.totalTenants,
    );

    final register = await registrationApiService.register(
      fullName: state.authNameInitial,
      phoneNumber: state.authPhoneInitial,
      password: state.authPasswordInitial,
      confirmPassword: state.authPasswordInitial,
    );
    state.authUserId = register.userId;
    _ensure(register.otpRequired, 'Register response did not require OTP.');
    _ensure(
      register.otpExpiresAt != null,
      'Register response missed otpExpiresAt.',
    );
    _pass('POST /api/auth/register', register.userId);

    final resendOtp = await registrationApiService.resendOtp(
      userId: register.userId,
    );
    _ensure(
      resendOtp.debugOtpCode.isNotEmpty,
      'Resend OTP response did not include debugOtpCode.',
    );
    _ensure(
      resendOtp.otpExpiresAt != null,
      'Resend OTP response missed otpExpiresAt.',
    );
    var latestOtp = resendOtp.debugOtpCode;
    _pass('POST /api/auth/resend-otp', latestOtp);

    final loginBeforeVerify = await registrationApiService.login(
      phoneNumber: state.authPhoneInitial,
      password: state.authPasswordInitial,
    );
    _ensure(
      loginBeforeVerify.otpRequired,
      'Pre-verification login should require OTP.',
    );
    _ensure(
      loginBeforeVerify.otpExpiresAt != null,
      'Pre-verification login missed otpExpiresAt.',
    );
    if (loginBeforeVerify.debugOtpCode.isNotEmpty) {
      latestOtp = loginBeforeVerify.debugOtpCode;
    }
    _pass('POST /api/auth/login (pre-verify)', loginBeforeVerify.message);

    final verifyOtp = await registrationApiService.verifyOtp(
      userId: register.userId,
      otpCode: latestOtp,
    );
    _ensure(
      verifyOtp.isPhoneVerified,
      'OTP verification did not return isPhoneVerified=true.',
    );
    _pass('POST /api/auth/verify-otp', verifyOtp.message);

    final profile = await accountApiService.getProfile();
    _ensure(
      profile.userId == register.userId,
      'Profile userId does not match the registered user.',
    );
    _pass('GET /api/account/profile/{userId}', profile.fullName);

    final profileUpdate = await accountApiService.updateProfile(
      fullName: state.authNameUpdated,
      phoneNumber: state.authPhoneUpdated,
    );
    _ensure(
      profileUpdate.profile.phoneNumber == state.authPhoneUpdated,
      'Profile update did not return the updated phone number.',
    );
    _pass('PUT /api/account/profile/{userId}', profileUpdate.message);

    final loginAfterVerify = await registrationApiService.login(
      phoneNumber: state.authPhoneUpdated,
      password: state.authPasswordInitial,
    );
    _ensure(
      !loginAfterVerify.otpRequired,
      'Verified login should not require OTP.',
    );
    _pass('POST /api/auth/login (verified)', loginAfterVerify.message);

    final forgotPassword = await registrationApiService.forgotPassword(
      phoneNumber: state.authPhoneUpdated,
    );
    _ensure(
      forgotPassword.otpExpiresAt != null,
      'Forgot password response missed otpExpiresAt.',
    );
    _ensure(
      forgotPassword.debugOtpCode.isNotEmpty,
      'Forgot password response did not include debugOtpCode.',
    );
    _pass('POST /api/auth/forgot-password', forgotPassword.debugOtpCode);

    final resetPassword = await registrationApiService.resetPassword(
      userId: register.userId,
      otpCode: forgotPassword.debugOtpCode,
      newPassword: state.authPasswordReset,
      confirmPassword: state.authPasswordReset,
    );
    _pass('POST /api/auth/reset-password', resetPassword.message);

    final updateDeviceInfo = await registrationApiService.updateDeviceInfo(
      userId: register.userId,
      firebaseDeviceToken: state.authDeviceToken,
      imei: state.authImei,
    );
    _ensure(
      updateDeviceInfo.firebaseDeviceToken == state.authDeviceToken,
      'Device info response did not return the updated Firebase token.',
    );
    _ensure(
      updateDeviceInfo.imei == state.authImei,
      'Device info response did not return the updated IMEI.',
    );
    _pass('POST /api/auth/device-info', updateDeviceInfo.message);

    final changePassword = await accountApiService.changePassword(
      currentPassword: state.authPasswordReset,
      newPassword: state.authPasswordFinal,
      confirmPassword: state.authPasswordFinal,
    );
    _pass('POST /api/account/change-password', changePassword.message);

    final loginFinal = await registrationApiService.login(
      phoneNumber: state.authPhoneUpdated,
      password: state.authPasswordFinal,
    );
    _ensure(loginFinal.userId == register.userId, 'Final login user mismatch.');
    _pass('POST /api/auth/login (final)', loginFinal.message);

    final sendOtp = await registrationApiService.sendOtp(
      mobileNumber: state.authPhoneUpdated,
      otpCode: '123456',
    );
    _ensure(sendOtp.isSuccess, 'Send OTP did not report success.');
    _pass('POST /api/auth/send-otp', sendOtp.message);

    final buildingCreate = await propertyApiService.createBuilding(
      name: state.buildingNameInitial,
      location: state.buildingLocationInitial,
      totalFloors: 2,
    );
    state.buildingId = buildingCreate.building.id;
    _pass('POST /api/property-management/buildings', state.buildingId!);

    final buildingUpdate = await propertyApiService.updateBuilding(
      buildingId: state.buildingId!,
      name: state.buildingNameUpdated,
      location: state.buildingLocationUpdated,
      totalFloors: 3,
    );
    _ensure(
      buildingUpdate.building.name == state.buildingNameUpdated,
      'Building update response did not include the updated name.',
    );
    _pass(
      'PUT /api/property-management/buildings/{buildingId}',
      buildingUpdate.message,
    );

    final floorCreate = await propertyApiService.createFloor(
      buildingId: state.buildingId!,
      label: state.floorLabelInitial,
      totalUnits: 4,
    );
    state.floorId = floorCreate.floor.id;
    _pass('POST /api/property-management/floors', state.floorId!);

    final floorUpdate = await propertyApiService.updateFloor(
      floorId: state.floorId!,
      buildingId: state.buildingId!,
      label: state.floorLabelUpdated,
      totalUnits: 5,
    );
    _ensure(
      floorUpdate.floor.label == state.floorLabelUpdated,
      'Floor update response did not include the updated label.',
    );
    _pass('PUT /api/property-management/floors/{floorId}', floorUpdate.message);

    final propertyCreate = await propertyApiService.createUnit(
      name: state.propertyNameInitial,
      monthlyRent: 12000,
      buildingId: state.buildingId!,
      floorId: state.floorId!,
    );
    state.propertyId = propertyCreate.property.id;
    _pass('POST /api/property-management/units', state.propertyId!);

    final propertyUpdate = await propertyApiService.updateUnit(
      propertyId: state.propertyId!,
      name: state.propertyNameUpdated,
      monthlyRent: 13500,
      buildingId: state.buildingId!,
      floorId: state.floorId!,
    );
    _ensure(
      propertyUpdate.property.name == state.propertyNameUpdated,
      'Unit update response did not include the updated name.',
    );
    _pass(
      'PUT /api/property-management/units/{propertyId}',
      propertyUpdate.message,
    );

    final tenantCreate = await ownerTenantApiService.createTenant(
      fullName: state.tenantNameInitial,
      phoneNumber: state.tenantPhoneInitial,
      nid: state.tenantNidInitial,
      propertyId: state.propertyId!,
    );
    state.tenantId = tenantCreate.tenant.id;
    _ensure(
      tenantCreate.loginPhoneNumber.isNotEmpty,
      'Tenant create response missed loginPhoneNumber.',
    );
    _ensure(
      tenantCreate.temporaryPassword.isNotEmpty,
      'Tenant create response missed temporaryPassword.',
    );
    _pass('POST /api/owner/tenants', state.tenantId!);

    final tenantUpdate = await ownerTenantApiService.updateTenant(
      tenantId: state.tenantId!,
      fullName: state.tenantNameUpdated,
      phoneNumber: state.tenantPhoneUpdated,
      nid: state.tenantNidUpdated,
    );
    _ensure(
      tenantUpdate.tenant.phone == state.tenantPhoneUpdated,
      'Tenant update response did not include the updated phone number.',
    );
    _pass('PUT /api/owner/tenants/{tenantId}', tenantUpdate.message);

    final ownerTenants = await ownerTenantApiService.getTenants();
    _ensure(
      ownerTenants.any((tenant) => tenant.id == state.tenantId),
      'Owner tenant list did not include the created tenant.',
    );
    _pass('GET /api/owner/tenants', ownerTenants.length);

    final paymentConfirm = await tenantPaymentApiService.confirmPayment(
      tenantId: state.tenantId!,
      monthLabel: 'April 2026',
      amount: 13500,
      paymentMethod: 'Bank Transfer',
      paymentTypes: const ['rent'],
    );
    _ensure(
      paymentConfirm.tenant.id == state.tenantId,
      'Payment confirmation did not return the expected tenant payload.',
    );
    _pass('POST /api/tenant/payments/confirm', paymentConfirm.message);

    final createMessage = await communicationApiService.createMessage(
      sender: state.tenantNameUpdated,
      message: state.messageText,
      propertyName: state.propertyNameUpdated,
    );
    _ensure(
      createMessage.item.message == state.messageText,
      'Message create response did not include the created message.',
    );
    _pass('POST /api/messages', createMessage.message);

    final messages = await communicationApiService.getAll();
    _ensure(
      messages.any((item) => item.message == state.messageText),
      'Message list did not include the app smoke message.',
    );
    _pass('GET /api/messages', messages.length);

    final expensesBefore = await expenseApiService.getAll('TEST-USER-ID');
    _pass('GET /api/expenses (before create)', expensesBefore.length);

    final createExpense = await expenseApiService.createExpense(
      title: state.expenseTitleInitial,
      category: 'Maintenance',
      amount: 3200,
      monthLabel: state.expenseMonth,
      userId: 'TEST-USER-ID',
    );
    state.expenseId = createExpense.expense.id;
    _pass('POST /api/expenses', state.expenseId!);

    final updateExpense = await expenseApiService.updateExpense(
      expenseId: state.expenseId!,
      title: state.expenseTitleUpdated,
      category: 'Maintenance',
      amount: 3600,
      monthLabel: state.expenseMonth,
      userId: 'TEST-USER-ID',
    );
    _ensure(
      updateExpense.expense.title == state.expenseTitleUpdated,
      'Expense update response did not include the updated title.',
    );
    _pass('PUT /api/expenses/{expenseId}', updateExpense.message);

    final summary = await reportApiService.getSummary('TEST-USER-ID');
    _ensure(
      summary.dashboardSummary.totalProperties >= 0,
      'Report summary did not parse dashboardSummary.',
    );
    _pass('GET /api/reports/summary', summary.dashboardSummary.totalProperties);

    final paymentsExport = await reportApiService.exportPaymentsCsv('TEST-USER-ID');
    _ensure(
      paymentsExport.csvContent.startsWith(
        'PropertyName,TenantName,MonthLabel,Amount,Status,PaidOn',
      ),
      'Payment export CSV header did not match expectations.',
    );
    _pass('GET /api/reports/payments-export', paymentsExport.fileName);

    final sendNotification = await notificationApiService.sendToUser(
      userId: register.userId,
      title: state.notificationTitle,
      body: state.notificationBody,
      data: <String, String>{'source': 'app-api-smoke', 'runTag': state.runTag},
    );
    _pass('POST /api/notifications/send', sendNotification.message);

    final notifications = await notificationApiService.getAll();
    final notification = notifications.cast<dynamic>().firstWhere(
      (item) =>
          item.title == state.notificationTitle ||
          item.subtitle.contains(state.runTag),
      orElse: () => null,
    );
    _ensure(
      notification != null,
      'Notification list did not include the app smoke notification.',
    );
    _pass('GET /api/notifications', notifications.length);

    if (notification.id > 0) {
      final markAsRead = await notificationApiService.markAsRead(
        notificationId: notification.id,
      );
      _pass(
        'POST /api/notifications/{notificationId}/read',
        markAsRead.message,
      );
    }

    final moveOut = await ownerTenantApiService.moveOutTenant(
      tenantId: state.tenantId!,
    );
    _pass('POST /api/owner/tenants/{tenantId}/move-out', moveOut.message);
    state.tenantMovedOut = true;

    final deleteTenant = await ownerTenantApiService.deleteTenant(
      tenantId: state.tenantId!,
    );
    _pass('DELETE /api/owner/tenants/{tenantId}', deleteTenant.message);
    state.tenantDeleted = true;

    final deleteUnit = await propertyApiService.deleteUnit(
      propertyId: state.propertyId!,
    );
    _pass(
      'DELETE /api/property-management/units/{propertyId}',
      deleteUnit.message,
    );
    state.propertyDeleted = true;

    final deleteFloor = await propertyApiService.deleteFloor(
      floorId: state.floorId!,
    );
    _pass(
      'DELETE /api/property-management/floors/{floorId}',
      deleteFloor.message,
    );
    state.floorDeleted = true;

    final deleteBuilding = await propertyApiService.deleteBuilding(
      buildingId: state.buildingId!,
    );
    _pass(
      'DELETE /api/property-management/buildings/{buildingId}',
      deleteBuilding.message,
    );
    state.buildingDeleted = true;

    final deleteExpense = await expenseApiService.deleteExpense(
      expenseId: state.expenseId!,
    );
    _pass('DELETE /api/expenses/{expenseId}', deleteExpense.message);
    state.expenseDeleted = true;
  } catch (error, stackTrace) {
    failure = error;
    failureStackTrace = stackTrace;
    stderr.writeln('APP API smoke failed: $error');
    stderr.writeln(stackTrace);
  } finally {
    await _cleanupCreatedEntities(
      state: state,
      propertyApiService: propertyApiService,
      ownerTenantApiService: ownerTenantApiService,
      expenseApiService: expenseApiService,
    );
    client.close();
    stdout.writeln('APP_SMOKE_SUMMARY:${jsonEncode(state.toJson())}');
  }

  if (failure != null) {
    stderr.writeln('APP API smoke summary emitted for cleanup.');
    if (failureStackTrace != null) {
      stderr.writeln(failureStackTrace);
    }
    exitCode = 1;
  }
}

Future<void> _cleanupCreatedEntities({
  required _SmokeState state,
  required PropertyManagementApiService propertyApiService,
  required OwnerTenantApiService ownerTenantApiService,
  required ExpenseApiService expenseApiService,
}) async {
  if (!state.tenantDeleted && state.tenantId != null) {
    if (!state.tenantMovedOut) {
      try {
        await ownerTenantApiService.moveOutTenant(tenantId: state.tenantId!);
      } catch (_) {}
    }

    try {
      await ownerTenantApiService.deleteTenant(tenantId: state.tenantId!);
    } catch (_) {}
  }

  if (!state.propertyDeleted && state.propertyId != null) {
    try {
      await propertyApiService.deleteUnit(propertyId: state.propertyId!);
    } catch (_) {}
  }

  if (!state.floorDeleted && state.floorId != null) {
    try {
      await propertyApiService.deleteFloor(floorId: state.floorId!);
    } catch (_) {}
  }

  if (!state.buildingDeleted && state.buildingId != null) {
    try {
      await propertyApiService.deleteBuilding(buildingId: state.buildingId!);
    } catch (_) {}
  }

  if (!state.expenseDeleted && state.expenseId != null) {
    try {
      await expenseApiService.deleteExpense(expenseId: state.expenseId!);
    } catch (_) {}
  }
}

void _ensure(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

void _pass(String step, Object outcome) {
  stdout.writeln('[PASS] $step -> $outcome');
}

String _buildRunTag() {
  final utc = DateTime.now().toUtc();
  return utc
      .toIso8601String()
      .replaceAll(RegExp(r'[^0-9]'), '')
      .substring(0, 14);
}

String _newPhone(Random random, [String prefix = '019']) {
  return '$prefix${random.nextInt(100000000).toString().padLeft(8, '0')}';
}

String _newNid(Random random) {
  final buffer = StringBuffer('9');
  for (var index = 0; index < 11; index += 1) {
    buffer.write(random.nextInt(10));
  }
  return buffer.toString();
}

class _InMemoryAuthSessionService extends AuthSessionService {
  String? _userId;

  @override
  Future<void> saveUserId(String userId) async {
    final normalizedUserId = userId.trim();
    _userId = normalizedUserId.isEmpty ? null : normalizedUserId;
  }

  @override
  Future<String?> readUserId() async => _userId;

  @override
  Future<void> clear() async {
    _userId = null;
  }
}

class _StubDeviceIdentityService extends DeviceIdentityService {
  _StubDeviceIdentityService(this._identity);

  final DeviceIdentity _identity;

  @override
  Future<DeviceIdentity> readDeviceIdentity({
    String? firebaseDeviceTokenOverride,
  }) async {
    return DeviceIdentity(
      firebaseDeviceToken:
          firebaseDeviceTokenOverride ?? _identity.firebaseDeviceToken,
      imei: _identity.imei,
    );
  }

  @override
  Future<String?> readDeviceIdentifier() async => _identity.imei;
}

class _SmokeState {
  _SmokeState({
    required this.runTag,
    required this.authNameInitial,
    required this.authNameUpdated,
    required this.authPhoneInitial,
    required this.authPhoneUpdated,
    required this.authPasswordInitial,
    required this.authPasswordReset,
    required this.authPasswordFinal,
    required this.authDeviceToken,
    required this.authImei,
    required this.tenantNameInitial,
    required this.tenantNameUpdated,
    required this.tenantPhoneInitial,
    required this.tenantPhoneUpdated,
    required this.tenantNidInitial,
    required this.tenantNidUpdated,
    required this.buildingNameInitial,
    required this.buildingNameUpdated,
    required this.buildingLocationInitial,
    required this.buildingLocationUpdated,
    required this.propertyNameInitial,
    required this.propertyNameUpdated,
    required this.floorLabelInitial,
    required this.floorLabelUpdated,
    required this.expenseTitleInitial,
    required this.expenseTitleUpdated,
    required this.expenseMonth,
    required this.notificationTitle,
    required this.notificationBody,
    required this.messageText,
  });

  final String runTag;
  final String authNameInitial;
  final String authNameUpdated;
  final String authPhoneInitial;
  final String authPhoneUpdated;
  final String authPasswordInitial;
  final String authPasswordReset;
  final String authPasswordFinal;
  final String authDeviceToken;
  final String authImei;
  final String tenantNameInitial;
  final String tenantNameUpdated;
  final String tenantPhoneInitial;
  final String tenantPhoneUpdated;
  final String tenantNidInitial;
  final String tenantNidUpdated;
  final String buildingNameInitial;
  final String buildingNameUpdated;
  final String buildingLocationInitial;
  final String buildingLocationUpdated;
  final String propertyNameInitial;
  final String propertyNameUpdated;
  final String floorLabelInitial;
  final String floorLabelUpdated;
  final String expenseTitleInitial;
  final String expenseTitleUpdated;
  final String expenseMonth;
  final String notificationTitle;
  final String notificationBody;
  final String messageText;

  String? authUserId;
  String? buildingId;
  String? floorId;
  String? propertyId;
  String? tenantId;
  int? expenseId;
  bool tenantMovedOut = false;
  bool tenantDeleted = false;
  bool propertyDeleted = false;
  bool floorDeleted = false;
  bool buildingDeleted = false;
  bool expenseDeleted = false;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runTag': runTag,
      'authUserId': authUserId,
      'authNameInitial': authNameInitial,
      'authNameUpdated': authNameUpdated,
      'authPhoneInitial': authPhoneInitial,
      'authPhoneUpdated': authPhoneUpdated,
      'tenantNameInitial': tenantNameInitial,
      'tenantNameUpdated': tenantNameUpdated,
      'tenantPhoneInitial': tenantPhoneInitial,
      'tenantPhoneUpdated': tenantPhoneUpdated,
      'tenantNidInitial': tenantNidInitial,
      'tenantNidUpdated': tenantNidUpdated,
      'buildingNameInitial': buildingNameInitial,
      'buildingNameUpdated': buildingNameUpdated,
      'buildingLocationInitial': buildingLocationInitial,
      'buildingLocationUpdated': buildingLocationUpdated,
      'propertyNameInitial': propertyNameInitial,
      'propertyNameUpdated': propertyNameUpdated,
      'expenseTitleInitial': expenseTitleInitial,
      'expenseTitleUpdated': expenseTitleUpdated,
      'notificationTitle': notificationTitle,
      'messageText': messageText,
      'buildingId': buildingId,
      'floorId': floorId,
      'propertyId': propertyId,
      'tenantId': tenantId,
      'expenseId': expenseId,
    };
  }
}
