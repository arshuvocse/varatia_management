import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/models/user_role.dart';
import 'auth_session_service.dart';
import 'device_identity_service.dart';

class RegistrationApiService {
  static const Duration _requestTimeout = Duration(seconds: 15);

  RegistrationApiService({
    http.Client? client,
    DeviceIdentityService? deviceIdentityService,
    AuthSessionService? authSessionService,
  }) : _client = client ?? http.Client(),
       _deviceIdentityService =
           deviceIdentityService ?? DeviceIdentityService(),
       _authSessionService = authSessionService ?? AuthSessionService(),
       _ownsClient = client == null;

  final http.Client _client;
  final DeviceIdentityService _deviceIdentityService;
  final AuthSessionService _authSessionService;
  final bool _ownsClient;

  Future<RegistrationResult> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    String? role,
  }) async {
    final deviceIdentity = await _deviceIdentityService.readDeviceIdentity();
    final response = await _postJson(
      '/api/auth/register',
      body: {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'password': password,
        'confirmPassword': confirmPassword,
        if (role != null) 'role': role,
        'firebaseDeviceToken': deviceIdentity.firebaseDeviceToken,
        'imei': deviceIdentity.imei,
      },
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final result = RegistrationResult(
      userId: payload['userId'] as String,
      fullName: payload['fullName'] as String,
      phoneNumber: payload['phoneNumber'] as String,
      createdAt: _readDateTime(payload['createdAt']),
      otpRequired: payload['otpRequired'] as bool? ?? false,
      otpExpiresAt: _readDateTime(payload['otpExpiresAt']),
      debugOtpCode: payload['debugOtpCode'] as String? ?? '',
      message:
          payload['message'] as String? ??
          'Registration completed successfully.',
    );
    await _authSessionService.saveSession(
      AuthSession(
        userId: result.userId,
        fullName: result.fullName,
        phoneNumber: result.phoneNumber,
        role: null,
        isPhoneVerified: !result.otpRequired,
        createdAt: result.createdAt,
      ),
    );
    return result;
  }

  Future<LoginResult> login({
    required String phoneNumber,
    required String password,
  }) async {
    final deviceIdentity = await _deviceIdentityService.readDeviceIdentity();
    final response = await _postJson(
      '/api/auth/login',
      body: {
        'phoneNumber': phoneNumber,
        'password': password,
        'firebaseDeviceToken': deviceIdentity.firebaseDeviceToken,
        'imei': deviceIdentity.imei,
      },
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final result = LoginResult(
      userId: payload['userId'] as String,
      fullName: payload['fullName'] as String,
      phoneNumber: payload['phoneNumber'] as String,
      createdAt: _readDateTime(payload['createdAt']),
      role: payload['role'] as String?,
      isPhoneVerified: payload['isPhoneVerified'] as bool? ?? false,
      otpRequired: payload['otpRequired'] as bool? ?? false,
      otpExpiresAt: _readDateTime(payload['otpExpiresAt']),
      debugOtpCode: payload['debugOtpCode'] as String? ?? '',
      message: payload['message'] as String? ?? 'Login successful.',
    );
    await _authSessionService.saveSession(
      AuthSession(
        userId: result.userId,
        fullName: result.fullName,
        phoneNumber: result.phoneNumber,
        role: result.resolvedRole,
        isPhoneVerified: !result.otpRequired || result.isPhoneVerified,
        createdAt: result.createdAt,
      ),
    );
    return result;
  }

  Future<OtpVerificationResult> verifyOtp({
    required String userId,
    required String otpCode,
  }) async {
    final response = await _postJson(
      '/api/auth/verify-otp',
      body: {'userId': userId, 'otpCode': otpCode},
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final result = OtpVerificationResult(
      userId: payload['userId'] as String,
      fullName: payload['fullName'] as String,
      phoneNumber: payload['phoneNumber'] as String,
      isPhoneVerified: payload['isPhoneVerified'] as bool? ?? false,
      message: payload['message'] as String? ?? 'OTP verified successfully.',
    );
    final existingSession = await _authSessionService.readSession();
    await _authSessionService.saveSession(
      AuthSession(
        userId: result.userId,
        fullName: result.fullName,
        phoneNumber: result.phoneNumber,
        role: existingSession?.role,
        isPhoneVerified: result.isPhoneVerified,
        createdAt: existingSession?.createdAt,
      ),
    );
    return result;
  }

  Future<OtpResendResult> resendOtp({required String userId}) async {
    final response = await _postJson(
      '/api/auth/resend-otp',
      body: {'userId': userId},
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return OtpResendResult(
      userId: payload['userId'] as String,
      phoneNumber: payload['phoneNumber'] as String,
      otpExpiresAt: _readDateTime(payload['otpExpiresAt']),
      debugOtpCode: payload['debugOtpCode'] as String? ?? '',
      message: payload['message'] as String? ?? 'OTP code was resent.',
    );
  }

  Future<SendOtpResult> sendOtp({
    required String mobileNumber,
    required String otpCode,
  }) async {
    final response = await _postJson(
      '/api/auth/send-otp',
      body: {'mobileNumber': mobileNumber, 'otpCode': otpCode},
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return SendOtpResult(
      isSuccess: payload['isSuccess'] as bool? ?? false,
      isError: payload['isError'] as bool? ?? false,
      providerResponse: payload['providerResponse'] as String? ?? '',
      errorMessage: payload['errorMessage'] as String? ?? '',
      message: payload['message'] as String? ?? 'OTP sent successfully.',
    );
  }

  Future<ForgotPasswordResult> forgotPassword({
    required String phoneNumber,
  }) async {
    final response = await _postJson(
      '/api/auth/forgot-password',
      body: {'phoneNumber': phoneNumber},
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return ForgotPasswordResult(
      userId: payload['userId'] as String,
      phoneNumber: payload['phoneNumber'] as String,
      otpExpiresAt: _readDateTime(payload['otpExpiresAt']),
      debugOtpCode: payload['debugOtpCode'] as String? ?? '',
      message:
          payload['message'] as String? ??
          'Password reset OTP was sent successfully.',
    );
  }

  Future<ResetPasswordResult> resetPassword({
    required String userId,
    required String otpCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _postJson(
      '/api/auth/reset-password',
      body: {
        'userId': userId,
        'otpCode': otpCode,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return ResetPasswordResult(
      userId: payload['userId'] as String,
      phoneNumber: payload['phoneNumber'] as String,
      message: payload['message'] as String? ?? 'Password reset successfully.',
    );
  }

  Future<UpdateDeviceInfoResult> updateDeviceInfo({
    required String userId,
    String? firebaseDeviceToken,
    String? imei,
  }) async {
    final response = await _postJson(
      '/api/auth/device-info',
      body: {
        'userId': userId,
        'firebaseDeviceToken': firebaseDeviceToken,
        'imei': imei,
      },
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return UpdateDeviceInfoResult(
      userId: payload['userId'] as String,
      firebaseDeviceToken: payload['firebaseDeviceToken'] as String?,
      imei: payload['imei'] as String?,
      message:
          payload['message'] as String? ?? 'Device info updated successfully.',
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<http.Response> _postJson(
    String path, {
    required Map<String, Object?> body,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RegistrationApiException(
          _readErrorMessage(response.body, statusCode: response.statusCode),
        );
      }

      return response;
    } on RegistrationApiException {
      rethrow;
    } on TimeoutException {
      throw const RegistrationApiException(
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw const RegistrationApiException(
        'Unable to reach the server. Please check the API connection and try again.',
      );
    } on http.ClientException {
      throw const RegistrationApiException(
        'Unable to reach the server. Please check the API connection and try again.',
      );
    } catch (error) {
      throw RegistrationApiException(
        'Auth request failed: ${error.toString()}',
      );
    }
  }

  static String _readErrorMessage(String rawBody, {int? statusCode}) {
    final trimmedBody = rawBody.trim();

    try {
      final payload = jsonDecode(trimmedBody);
      if (payload is Map<String, dynamic>) {
        for (final key in const ['message', 'error', 'title', 'detail']) {
          final value = payload[key];
          if (value is String && value.trim().isNotEmpty) {
            return value;
          }
        }
      }
    } catch (_) {
      // Ignore JSON parsing errors and fall back to a generic message.
    }

    final normalizedBody = trimmedBody.toLowerCase();
    final looksLikeServerFailure =
        (statusCode != null && statusCode >= 500) ||
        normalizedBody.contains('sqlexception') ||
        normalizedBody.contains('server was not found') ||
        normalizedBody.contains('error locating server/instance') ||
        normalizedBody.contains('<!doctype html') ||
        normalizedBody.contains('<html');

    if (looksLikeServerFailure) {
      return 'Service is temporarily unavailable. Please try again later.';
    }

    if (trimmedBody.isNotEmpty &&
        trimmedBody.length <= 160 &&
        !trimmedBody.contains('\n')) {
      return trimmedBody;
    }

    return 'Registration request failed. Please try again.';
  }

  static DateTime? _readDateTime(Object? rawValue) {
    if (rawValue is! String || rawValue.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(rawValue);
  }
}

class RegistrationResult {
  const RegistrationResult({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.createdAt,
    required this.otpRequired,
    required this.otpExpiresAt,
    required this.debugOtpCode,
    required this.message,
  });

  final String userId;
  final String fullName;
  final String phoneNumber;
  final DateTime? createdAt;
  final bool otpRequired;
  final DateTime? otpExpiresAt;
  final String debugOtpCode;
  final String message;

  OtpSession toOtpSession({
    String? nextRouteName,
    Object? nextRouteArguments,
    bool clearStackAfterVerification = true,
  }) {
    return OtpSession(
      userId: userId,
      phoneNumber: phoneNumber,
      otpExpiresAt: otpExpiresAt,
      debugOtpCode: debugOtpCode,
      nextRouteName: nextRouteName,
      nextRouteArguments: nextRouteArguments,
      clearStackAfterVerification: clearStackAfterVerification,
    );
  }
}

class LoginResult {
  const LoginResult({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.createdAt,
    required this.role,
    required this.isPhoneVerified,
    required this.otpRequired,
    required this.otpExpiresAt,
    required this.debugOtpCode,
    required this.message,
  });

  final String userId;
  final String fullName;
  final String phoneNumber;
  final DateTime? createdAt;
  final String? role;
  final bool isPhoneVerified;
  final bool otpRequired;
  final DateTime? otpExpiresAt;
  final String debugOtpCode;
  final String message;
  EntryUserRole? get resolvedRole => entryUserRoleFromApiValue(role);

  OtpSession toOtpSession({
    String? nextRouteName,
    Object? nextRouteArguments,
    bool clearStackAfterVerification = true,
  }) {
    return OtpSession(
      userId: userId,
      phoneNumber: phoneNumber,
      role: resolvedRole,
      otpExpiresAt: otpExpiresAt,
      debugOtpCode: debugOtpCode,
      nextRouteName: nextRouteName,
      nextRouteArguments: nextRouteArguments,
      clearStackAfterVerification: clearStackAfterVerification,
    );
  }
}

class OtpVerificationResult {
  const OtpVerificationResult({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.isPhoneVerified,
    required this.message,
  });

  final String userId;
  final String fullName;
  final String phoneNumber;
  final bool isPhoneVerified;
  final String message;
}

class OtpResendResult {
  const OtpResendResult({
    required this.userId,
    required this.phoneNumber,
    required this.otpExpiresAt,
    required this.debugOtpCode,
    required this.message,
  });

  final String userId;
  final String phoneNumber;
  final DateTime? otpExpiresAt;
  final String debugOtpCode;
  final String message;
}

class ForgotPasswordResult {
  const ForgotPasswordResult({
    required this.userId,
    required this.phoneNumber,
    required this.otpExpiresAt,
    required this.debugOtpCode,
    required this.message,
  });

  final String userId;
  final String phoneNumber;
  final DateTime? otpExpiresAt;
  final String debugOtpCode;
  final String message;

  PasswordResetSession toResetPasswordSession() {
    return PasswordResetSession(
      userId: userId,
      phoneNumber: phoneNumber,
      otpExpiresAt: otpExpiresAt,
      debugOtpCode: debugOtpCode,
    );
  }
}

class OtpSession {
  const OtpSession({
    required this.userId,
    required this.phoneNumber,
    this.role,
    this.otpExpiresAt,
    required this.debugOtpCode,
    this.nextRouteName,
    this.nextRouteArguments,
    this.clearStackAfterVerification = true,
  });

  final String userId;
  final String phoneNumber;
  final EntryUserRole? role;
  final DateTime? otpExpiresAt;
  final String debugOtpCode;
  final String? nextRouteName;
  final Object? nextRouteArguments;
  final bool clearStackAfterVerification;
}

class SendOtpResult {
  const SendOtpResult({
    required this.isSuccess,
    required this.isError,
    required this.providerResponse,
    required this.errorMessage,
    required this.message,
  });

  final bool isSuccess;
  final bool isError;
  final String providerResponse;
  final String errorMessage;
  final String message;
}

class PasswordResetSession {
  const PasswordResetSession({
    required this.userId,
    required this.phoneNumber,
    this.otpExpiresAt,
    required this.debugOtpCode,
  });

  final String userId;
  final String phoneNumber;
  final DateTime? otpExpiresAt;
  final String debugOtpCode;
}

class ResetPasswordResult {
  const ResetPasswordResult({
    required this.userId,
    required this.phoneNumber,
    required this.message,
  });

  final String userId;
  final String phoneNumber;
  final String message;
}

class UpdateDeviceInfoResult {
  const UpdateDeviceInfoResult({
    required this.userId,
    required this.firebaseDeviceToken,
    required this.imei,
    required this.message,
  });

  final String userId;
  final String? firebaseDeviceToken;
  final String? imei;
  final String message;
}

class RegistrationApiException implements Exception {
  const RegistrationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
