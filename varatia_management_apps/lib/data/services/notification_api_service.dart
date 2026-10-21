import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/app_models.dart';

class NotificationApiService {
  NotificationApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<List<AppNotificationItem>> getAll() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NotificationApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .cast<Map<String, dynamic>>()
        .map(_readNotification)
        .toList(growable: false);
  }

  Future<NotificationSendResult> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications/send'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'title': title,
        'body': body,
        if (data != null && data.isNotEmpty) 'data': data,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NotificationApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return NotificationSendResult(
      userId: payload['userId'] as String,
      firebaseMessageId: payload['firebaseMessageId'] as String? ?? '',
      message:
          payload['message'] as String? ?? 'Notification sent successfully.',
    );
  }

  Future<NotificationSendResult> sendRentNotice({
    required String propertyName,
    required String tenantName,
    required num amount,
    String? userId,
    String? monthLabel,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications/rent-notice'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        'propertyName': propertyName,
        'tenantName': tenantName,
        'amount': amount,
        if (monthLabel != null) 'monthLabel': monthLabel,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NotificationApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return NotificationSendResult(
      userId: userId ?? '',
      firebaseMessageId: payload['notificationId']?.toString() ?? '',
      message: payload['message'] as String? ?? 'Rent notice sent successfully.',
    );
  }

  Future<NotificationReadResult> markAsRead({
    required int notificationId,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications/$notificationId/read'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NotificationApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return NotificationReadResult(
      notificationId: (payload['notificationId'] as num).toInt(),
      message: payload['message'] as String? ?? 'Notification marked as read.',
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static AppNotificationItem _readNotification(Map<String, dynamic> payload) {
    return AppNotificationItem(
      id: (payload['id'] as num?)?.toInt() ?? 0,
      title: payload['title'] as String,
      subtitle: payload['subtitle'] as String,
      createdAt: DateTime.parse(payload['createdAt'] as String),
      isUnread: payload['isUnread'] as bool? ?? false,
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
      // Ignore invalid JSON error payloads and fall back to generic text.
    }

    return 'Notification request failed. Please try again.';
  }
}

class NotificationSendResult {
  const NotificationSendResult({
    required this.userId,
    required this.firebaseMessageId,
    required this.message,
  });

  final String userId;
  final String firebaseMessageId;
  final String message;
}

class NotificationReadResult {
  const NotificationReadResult({
    required this.notificationId,
    required this.message,
  });

  final int notificationId;
  final String message;
}

class NotificationApiException implements Exception {
  const NotificationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
