import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/app_models.dart';

class AnnouncementApiService {
  AnnouncementApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<List<AnnouncementItem>> getActiveAnnouncements() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/announcements'),
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AnnouncementApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(_readAnnouncement)
        .toList(growable: false);
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static AnnouncementItem _readAnnouncement(Map<String, dynamic> payload) {
    return AnnouncementItem(
      id: (payload['id'] as num?)?.toInt() ?? 0,
      message: payload['message'] as String? ?? '',
      linkUrl: payload['linkUrl'] as String?,
      createdAt: DateTime.parse(payload['createdAt'] as String),
      isActive: payload['isActive'] as bool? ?? true,
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

    return 'Announcement request failed. Please try again.';
  }
}

class AnnouncementApiException implements Exception {
  const AnnouncementApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
