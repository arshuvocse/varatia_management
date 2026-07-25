import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class DhakaLocationApiService {
  DhakaLocationApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<List<DhakaDivisionOption>> getDivisions() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/dhaka-locations/divisions');
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    _throwIfFailed(response);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return _readList(payload['data'], DhakaDivisionOption.fromJson);
  }

  Future<List<DhakaAreaOption>> getAreas({required String divisionId}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/dhaka-locations/areas',
    ).replace(queryParameters: {'divisionId': divisionId});
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    _throwIfFailed(response);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return _readList(payload['data'], DhakaAreaOption.fromJson);
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw DhakaLocationApiException(_readErrorMessage(response.body));
  }

  static String _readErrorMessage(String rawBody) {
    try {
      final payload = jsonDecode(rawBody) as Map<String, dynamic>;
      final message = payload['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    } catch (_) {
      // Fall through to the generic message.
    }

    return 'Unable to load Dhaka location options. Please try again.';
  }

  static List<T> _readList<T>(
    Object? value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }
}

class DhakaDivisionOption {
  const DhakaDivisionOption({
    required this.id,
    required this.nameBn,
    required this.displayOrder,
  });

  factory DhakaDivisionOption.fromJson(Map<String, dynamic> json) {
    return DhakaDivisionOption(
      id: json['id'] as String? ?? '',
      nameBn: json['nameBn'] as String? ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String nameBn;
  final int displayOrder;
}

class DhakaAreaOption {
  const DhakaAreaOption({
    required this.id,
    required this.divisionId,
    required this.nameBn,
    required this.displayOrder,
  });

  factory DhakaAreaOption.fromJson(Map<String, dynamic> json) {
    return DhakaAreaOption(
      id: json['id'] as String? ?? '',
      divisionId: json['divisionId'] as String? ?? '',
      nameBn: json['nameBn'] as String? ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String divisionId;
  final String nameBn;
  final int displayOrder;
}

class DhakaLocationApiException implements Exception {
  const DhakaLocationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
