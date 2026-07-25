import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class DhakaPoliceZoneApiService {
  DhakaPoliceZoneApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<DhakaPoliceCascadingOptions> getCascadingOptions({
    String? zoneId,
    String? stationId,
  }) async {
    final queryParameters = <String, String>{
      if (zoneId != null && zoneId.isNotEmpty) 'zoneId': zoneId,
      if (stationId != null && stationId.isNotEmpty) 'stationId': stationId,
    };
    final uri =
        Uri.parse(
          '${ApiConfig.baseUrl}/api/dhaka-police-zones/cascading-options',
        ).replace(
          queryParameters: queryParameters.isEmpty ? null : queryParameters,
        );
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DhakaPoliceZoneApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return DhakaPoliceCascadingOptions.fromJson(payload);
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
      // Ignore JSON parsing issues and fall back to generic text.
    }

    return 'Unable to load area options. Please try again.';
  }
}

class DhakaPoliceCascadingOptions {
  const DhakaPoliceCascadingOptions({
    required this.zones,
    required this.stations,
    required this.wards,
  });

  factory DhakaPoliceCascadingOptions.fromJson(Map<String, dynamic> json) {
    return DhakaPoliceCascadingOptions(
      zones: _readList(json['zones'], PoliceZoneOption.fromJson),
      stations: _readList(json['stations'], PoliceStationOption.fromJson),
      wards: _readList(json['wards'], PoliceWardOption.fromJson),
    );
  }

  final List<PoliceZoneOption> zones;
  final List<PoliceStationOption> stations;
  final List<PoliceWardOption> wards;

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

class PoliceZoneOption {
  const PoliceZoneOption({
    required this.id,
    required this.nameBn,
    required this.nameEn,
  });

  factory PoliceZoneOption.fromJson(Map<String, dynamic> json) {
    return PoliceZoneOption(
      id: json['id'] as String,
      nameBn: json['nameBn'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
    );
  }

  final String id;
  final String nameBn;
  final String nameEn;
}

class PoliceStationOption {
  const PoliceStationOption({
    required this.id,
    required this.zoneId,
    required this.nameBn,
    required this.nameEn,
  });

  factory PoliceStationOption.fromJson(Map<String, dynamic> json) {
    return PoliceStationOption(
      id: json['id'] as String,
      zoneId: json['zoneId'] as String,
      nameBn: json['nameBn'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
    );
  }

  final String id;
  final String zoneId;
  final String nameBn;
  final String nameEn;
}

class PoliceWardOption {
  const PoliceWardOption({
    required this.id,
    required this.stationId,
    required this.wardNo,
    required this.nameBn,
    required this.nameEn,
  });

  factory PoliceWardOption.fromJson(Map<String, dynamic> json) {
    return PoliceWardOption(
      id: (json['id'] as num).toInt(),
      stationId: json['stationId'] as String,
      wardNo: (json['wardNo'] as num).toInt(),
      nameBn: json['nameBn'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
    );
  }

  final int id;
  final String stationId;
  final int wardNo;
  final String nameBn;
  final String nameEn;
}

class DhakaPoliceZoneApiException implements Exception {
  const DhakaPoliceZoneApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
