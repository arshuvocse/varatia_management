import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class SosApiService {
  SosApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  static const Duration _requestTimeout = Duration(seconds: 15);

  final http.Client _client;
  final bool _ownsClient;

  Future<int> triggerAlert(
    String userId, {
    double? latitude,
    double? longitude,
  }) async {
    final payload = await _postJson('/api/sos/trigger', {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
    });

    return _readInt(payload['alertId']) ?? 0;
  }

  Future<List<SosEmergencyContact>> getContacts(String userId) async {
    final payload = await _getJson('/api/sos/contacts/$userId');
    final data = payload['data'] as List<dynamic>? ?? [];

    return data
        .map(
          (json) => SosEmergencyContact.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<SosEmergencyContact> addContact({
    required String userId,
    required String name,
    required String phone,
    String? relation,
    String? imageUrl,
  }) async {
    final payload = await _postJson('/api/sos/contacts', {
      'userId': userId,
      'name': name,
      'phone': phone,
      'relation': relation,
      'imageUrl': imageUrl,
    });

    return SosEmergencyContact.fromJson(
      payload['data'] as Map<String, dynamic>,
    );
  }

  Future<void> removeContact({
    required String userId,
    required int contactId,
  }) async {
    await _send(
      () => _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/sos/contacts/$userId/$contactId'),
      ),
    );
  }

  Future<void> updateLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    await _postJson('/api/sos/location', {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<List<SosEmergencyService>> getEmergencyServices() async {
    final payload = await _getJson('/api/sos/services');
    final data = payload['data'] as List<dynamic>? ?? [];

    return data
        .map(
          (json) => SosEmergencyService.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<SosSafetyTip>> getSafetyTips() async {
    final payload = await _getJson('/api/sos/safety-tips');
    final data = payload['data'] as List<dynamic>? ?? [];

    return data
        .map((json) => SosSafetyTip.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveEvidence({
    required String userId,
    required String fileUrl,
    required String fileType,
  }) async {
    await _postJson('/api/sos/evidence', {
      'userId': userId,
      'fileUrl': fileUrl,
      'fileType': fileType,
    });
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _send(
      () => _client.get(Uri.parse('${ApiConfig.baseUrl}$path')),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<http.Response> _send(Future<http.Response> Function() send) async {
    try {
      final response = await send().timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SosApiException(_readErrorMessage(response.body));
      }

      return response;
    } on TimeoutException {
      throw const SosApiException('Server took too long to respond.');
    } on SocketException {
      throw const SosApiException('Unable to reach server.');
    } on http.ClientException {
      throw const SosApiException('Unable to reach server.');
    }
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

    return 'SOS API request failed. Please try again.';
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class SosEmergencyContact {
  const SosEmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.relation,
    this.imageUrl,
  });

  final int id;
  final String userId;
  final String name;
  final String phone;
  final String? relation;
  final String? imageUrl;

  factory SosEmergencyContact.fromJson(Map<String, dynamic> json) {
    return SosEmergencyContact(
      id: SosApiService._readInt(json['id']) ?? 0,
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      relation: json['relation']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class SosEmergencyService {
  const SosEmergencyService({
    required this.id,
    required this.title,
    required this.phone,
    required this.type,
  });

  final int id;
  final String title;
  final String phone;
  final String type;

  factory SosEmergencyService.fromJson(Map<String, dynamic> json) {
    return SosEmergencyService(
      id: SosApiService._readInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }
}

class SosSafetyTip {
  const SosSafetyTip({
    required this.id,
    required this.title,
    required this.description,
  });

  final int id;
  final String title;
  final String description;

  factory SosSafetyTip.fromJson(Map<String, dynamic> json) {
    return SosSafetyTip(
      id: SosApiService._readInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class SosApiException implements Exception {
  const SosApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
