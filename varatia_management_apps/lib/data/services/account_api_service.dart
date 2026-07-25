import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'auth_session_service.dart';

class AccountApiService {
  AccountApiService({
    http.Client? client,
    AuthSessionService? authSessionService,
  }) : _client = client ?? http.Client(),
       _authSessionService = authSessionService ?? AuthSessionService(),
       _ownsClient = client == null;

  final http.Client _client;
  final AuthSessionService _authSessionService;
  final bool _ownsClient;

  Future<AccountProfile> getProfile() async {
    final userId = await _readUserId();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/account/profile/$userId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AccountApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return _readProfile(payload);
  }

  Future<UpdateAccountProfileResult> updateProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    final userId = await _readUserId();
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}/api/account/profile/$userId'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'fullName': fullName, 'phoneNumber': phoneNumber}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AccountApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return UpdateAccountProfileResult(
      profile: _readProfile(payload['profile'] as Map<String, dynamic>),
      message: payload['message'] as String? ?? 'Profile updated successfully.',
    );
  }

  Future<ChangePasswordResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final userId = await _readUserId();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/account/change-password'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AccountApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return ChangePasswordResult(
      userId: payload['userId'] as String,
      message:
          payload['message'] as String? ?? 'Password changed successfully.',
    );
  }

  Future<String> _readUserId() async {
    final userId = await _authSessionService.readUserId();
    if (userId == null || userId.isEmpty) {
      throw const AccountApiException('Login session not found.');
    }

    return userId;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static AccountProfile _readProfile(Map<String, dynamic> payload) {
    return AccountProfile(
      userId: payload['userId'] as String,
      fullName: payload['fullName'] as String,
      phoneNumber: payload['phoneNumber'] as String,
      role: payload['role'] as String?,
      isPhoneVerified: payload['isPhoneVerified'] as bool? ?? false,
      firebaseDeviceToken: payload['firebaseDeviceToken'] as String?,
      imei: payload['imei'] as String?,
    );
  }

  static String _readErrorMessage(String rawBody) {
    try {
      final payload = jsonDecode(rawBody) as Map<String, dynamic>;
      final message = payload['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    } catch (_) {
      // Ignore JSON parsing errors and fall back to generic text.
    }

    return 'Account request failed. Please try again.';
  }
}

class AccountProfile {
  const AccountProfile({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.isPhoneVerified,
    required this.firebaseDeviceToken,
    required this.imei,
  });

  final String userId;
  final String fullName;
  final String phoneNumber;
  final String? role;
  final bool isPhoneVerified;
  final String? firebaseDeviceToken;
  final String? imei;
}

class UpdateAccountProfileResult {
  const UpdateAccountProfileResult({
    required this.profile,
    required this.message,
  });

  final AccountProfile profile;
  final String message;
}

class ChangePasswordResult {
  const ChangePasswordResult({required this.userId, required this.message});

  final String userId;
  final String message;
}

class AccountApiException implements Exception {
  const AccountApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
