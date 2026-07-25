import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/app_models.dart';

class CommunicationApiService {
  CommunicationApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<List<CommunicationEntry>> getAll() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/messages'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CommunicationApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .cast<Map<String, dynamic>>()
        .map(_readMessage)
        .toList(growable: false);
  }

  Future<CreateCommunicationResult> createMessage({
    required String sender,
    required String message,
    required String propertyName,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/messages'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender': sender,
        'message': message,
        'propertyName': propertyName,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CommunicationApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return CreateCommunicationResult(
      item: _readMessage(payload['item'] as Map<String, dynamic>),
      message: payload['message'] as String? ?? 'Message created successfully.',
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static CommunicationEntry _readMessage(Map<String, dynamic> payload) {
    return CommunicationEntry(
      id: (payload['id'] as num?)?.toInt() ?? 0,
      sender: payload['sender'] as String,
      message: payload['message'] as String,
      propertyName: payload['propertyName'] as String,
      timeLabel: payload['timeLabel'] as String,
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

    return 'Message request failed. Please try again.';
  }
}

class CreateCommunicationResult {
  const CreateCommunicationResult({required this.item, required this.message});

  final CommunicationEntry item;
  final String message;
}

class CommunicationApiException implements Exception {
  const CommunicationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
