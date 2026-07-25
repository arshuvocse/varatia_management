import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class HealthApiService {
  HealthApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<HealthStatusResult> getStatus() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/health'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HealthApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return HealthStatusResult(
      status: payload['status'] as String? ?? 'unknown',
      database: payload['database'] as String? ?? '',
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
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

    return 'Health check failed. Please try again.';
  }
}

class HealthStatusResult {
  const HealthStatusResult({required this.status, required this.database});

  final String status;
  final String database;
}

class HealthApiException implements Exception {
  const HealthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
