import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/app_models.dart';
import 'auth_session_service.dart';

class PropertyManagementApiService {
  PropertyManagementApiService({
    http.Client? client,
    AuthSessionService? authSessionService,
  }) : _client = client ?? http.Client(),
       _authSessionService = authSessionService ?? AuthSessionService(),
       _ownsClient = client == null;

  final http.Client _client;
  final AuthSessionService _authSessionService;
  final bool _ownsClient;

  Future<PropertyBuildingResult> createBuilding({
    required String name,
    required String location,
    required int totalFloors,
    String? address,
    double? latitude,
    double? longitude,
    String? zoneId,
    String? stationId,
    int? wardId,
  }) async {
    if (ApiConfig.isDemoMode) {
      return PropertyBuildingResult(
        building: BuildingBlock(
          id: 'DEMO-B-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          totalFloors: totalFloors,
          location: location,
          address: address,
          latitude: latitude,
          longitude: longitude,
          zoneId: zoneId,
          stationId: stationId,
          wardId: wardId,
        ),
        message: 'Demo building created.',
      );
    }

    final userId = await _readUserId();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/property-management/buildings',
    );
    final requestBody = {
      'user_id': userId,
      'name': name,
      'location': location,
      'totalFloors': totalFloors,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'zoneId': zoneId,
      'stationId': stationId,
      'wardId': wardId,
    };

    _logAddBuildingApi('POST $uri');
    _logAddBuildingApi('Request JSON: ${jsonEncode(requestBody)}');

    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    _logAddBuildingApi('Response ${response.statusCode}: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyManagementApiException(_readErrorMessage(response.body));
    }

    final payload = _readPayload(response.body);
    return PropertyBuildingResult(
      building: _readBuilding(_readRequiredObject(payload, 'building')),
      message:
          payload['message'] as String? ?? 'Building created successfully.',
    );
  }

  Future<List<BuildingBlock>> getBuildings() async {
    if (ApiConfig.isDemoMode) {
      return [
        const BuildingBlock(
          id: 'DEMO-B-1',
          name: 'Demo Building',
          totalFloors: 5,
          location: 'Dhaka',
        ),
      ];
    }

    final userId = await _readUserId();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/property-management/buildings?user_id=$userId',
    );

    _logAddBuildingApi('GET $uri');

    final response = await _client.get(uri);

    _logAddBuildingApi('Response ${response.statusCode}: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyManagementApiException(_readErrorMessage(response.body));
    }

    final payload = _readPayload(response.body);
    final buildingsList = payload['buildings'] as List<dynamic>? ?? [];
    return buildingsList
        .map((e) => _readBuilding(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BuildingFloor>> getFloors(String buildingId) async {
    if (ApiConfig.isDemoMode) {
      return [];
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/property-management/floors?buildingId=$buildingId',
    );

    final response = await _client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyManagementApiException(_readErrorMessage(response.body));
    }

    final payload = _readPayload(response.body);
    final floorsList = payload['floors'] as List<dynamic>? ?? [];
    return floorsList
        .map((e) => _readFloor(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PropertyUnit>> getProperties() async {
    if (ApiConfig.isDemoMode) {
      return [];
    }

    final userId = await _readUserId();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/property-management/units?user_id=$userId',
    );

    final response = await _client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyManagementApiException(_readErrorMessage(response.body));
    }

    final payload = _readPayload(response.body);
    final propertiesList = payload['properties'] as List<dynamic>? ?? [];
    return propertiesList
        .map((e) => _readProperty(e as Map<String, dynamic>))
        .toList();
  }

  Future<PropertyBuildingResult> updateBuilding({
    required String buildingId,
    required String name,
    required String location,
    required int totalFloors,
    String? address,
    double? latitude,
    double? longitude,
    String? zoneId,
    String? stationId,
    int? wardId,
  }) async {
    if (ApiConfig.isDemoMode) {
      return PropertyBuildingResult(
        building: BuildingBlock(
          id: buildingId,
          name: name,
          totalFloors: totalFloors,
          location: location,
          address: address,
          latitude: latitude,
          longitude: longitude,
          zoneId: zoneId,
          stationId: stationId,
          wardId: wardId,
        ),
        message: 'Demo building updated.',
      );
    }

    final userId = await _readUserId();
    final response = await _client.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/property-management/buildings/$buildingId',
      ),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'name': name,
        'location': location,
        'totalFloors': totalFloors,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'zoneId': zoneId,
        'stationId': stationId,
        'wardId': wardId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyManagementApiException(_readErrorMessage(response.body));
    }

    final payload = _readPayload(response.body);
    return PropertyBuildingResult(
      building: _readBuilding(_readRequiredObject(payload, 'building')),
      message:
          payload['message'] as String? ?? 'Building updated successfully.',
    );
  }

  Future<String> _readUserId() async {
    final userId = await _authSessionService.readUserId();
    if (userId == null || userId.isEmpty) {
      throw const PropertyManagementApiException('Login session not found.');
    }

    return userId;
  }

  Future<PropertyBuildingDeleteResult> deleteBuilding({
    required String buildingId,
  }) async {
    if (ApiConfig.isDemoMode) {
      return PropertyBuildingDeleteResult(
        buildingId: buildingId,
        message: 'Demo building deleted.',
      );
    }

    final response = await _client.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/property-management/buildings/$buildingId',
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyManagementApiException(_readErrorMessage(response.body));
    }

    final payload = _readPayload(response.body);
    return PropertyBuildingDeleteResult(
      buildingId: payload['buildingId'] as String,
      message:
          payload['message'] as String? ?? 'Building deleted successfully.',
    );
  }

  Future<PropertyFloorResult> createFloor({
    required String buildingId,
    required String label,
    required int totalUnits,
  }) async {
    if (ApiConfig.isDemoMode) {
      return PropertyFloorResult(
        floor: BuildingFloor(
          id: 'DEMO-F-${DateTime.now().millisecondsSinceEpoch}',
          buildingId: buildingId,
          label: label,
          totalUnits: totalUnits,
        ),
        message: 'Demo floor created.',
      );
    }

    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/property-management/floors'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'buildingId': buildingId,
        'label': label,
        'totalUnits': totalUnits,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyManagementApiException(_readErrorMessage(response.body));
    }

    final payload = _readPayload(response.body);
    return PropertyFloorResult(
      floor: _readFloor(_readRequiredObject(payload, 'floor')),
      message: payload['message'] as String? ?? 'Floor created successfully.',
    );
  }

  Future<PropertyFloorResult> updateFloor({
    required String floorId,
    required String buildingId,
    required String label,
    required int totalUnits,
  }) async {
    if (ApiConfig.isDemoMode) {
      return PropertyFloorResult(
        floor: BuildingFloor(
          id: floorId,
          buildingId: buildingId,
          label: label,
          totalUnits: totalUnits,
        ),
        message: 'Demo floor updated.',
      );
    }

    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}/api/property-management/floors/$floorId'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'buildingId': buildingId,
        'label': label,
        'totalUnits': totalUnits,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyManagementApiException(_readErrorMessage(response.body));
    }

    final payload = _readPayload(response.body);
    return PropertyFloorResult(
      floor: _readFloor(_readRequiredObject(payload, 'floor')),
      message: payload['message'] as String? ?? 'Floor updated successfully.',
    );
  }

  Future<PropertyFloorDeleteResult> deleteFloor({
    required String floorId,
  }) async {
    if (ApiConfig.isDemoMode) {
      return PropertyFloorDeleteResult(
        floorId: floorId,
        buildingId: '',
        message: 'Demo floor deleted.',
      );
    }

    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/property-management/floors/$floorId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyManagementApiException(_readErrorMessage(response.body));
    }

    final payload = _readPayload(response.body);
    return PropertyFloorDeleteResult(
      floorId: payload['floorId'] as String,
      buildingId: payload['buildingId'] as String,
      message: payload['message'] as String? ?? 'Floor deleted successfully.',
    );
  }

  Future<PropertyUnitResult> createUnit({
    required String name,
    required int monthlyRent,
    required String buildingId,
    required String floorId,
  }) async {
    if (ApiConfig.isDemoMode) {
      return PropertyUnitResult(
        property: PropertyUnit(
          id: 'DEMO-P-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          location: 'Demo Location',
          monthlyRent: monthlyRent,
          status: PropertyStatus.available,
          buildingId: buildingId,
          floorId: floorId,
        ),
        message: 'Demo unit created.',
      );
    }

    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/property-management/units'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'monthlyRent': monthlyRent,
        'buildingId': buildingId,
        'floorId': floorId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyManagementApiException(_readErrorMessage(response.body));
    }

    final payload = _readPayload(response.body);
    return PropertyUnitResult(
      property: _readProperty(_readRequiredObject(payload, 'property')),
      message: payload['message'] as String? ?? 'Unit created successfully.',
    );
  }

  Future<PropertyUnitResult> updateUnit({
    required String propertyId,
    required String name,
    required int monthlyRent,
    required String buildingId,
    required String floorId,
  }) async {
    if (ApiConfig.isDemoMode) {
      return PropertyUnitResult(
        property: PropertyUnit(
          id: propertyId,
          name: name,
          location: 'Demo Location',
          monthlyRent: monthlyRent,
          status: PropertyStatus.available,
          buildingId: buildingId,
          floorId: floorId,
        ),
        message: 'Demo unit updated.',
      );
    }

    final response = await _client.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/property-management/units/$propertyId',
      ),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'monthlyRent': monthlyRent,
        'buildingId': buildingId,
        'floorId': floorId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyManagementApiException(_readErrorMessage(response.body));
    }

    final payload = _readPayload(response.body);
    return PropertyUnitResult(
      property: _readProperty(_readRequiredObject(payload, 'property')),
      message: payload['message'] as String? ?? 'Unit updated successfully.',
    );
  }

  Future<PropertyDeleteResult> deleteUnit({required String propertyId}) async {
    if (ApiConfig.isDemoMode) {
      return PropertyDeleteResult(
        propertyId: propertyId,
        message: 'Demo unit deleted.',
      );
    }

    final response = await _client.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/property-management/units/$propertyId',
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyManagementApiException(_readErrorMessage(response.body));
    }

    final payload = _readPayload(response.body);
    return PropertyDeleteResult(
      propertyId: payload['propertyId'] as String,
      message: payload['message'] as String? ?? 'Unit deleted successfully.',
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static String _readErrorMessage(String rawBody) {
    try {
      return _readPayloadMessage(jsonDecode(rawBody));
    } catch (_) {
      // Ignore JSON parsing issues and fall back to generic text.
    }

    return 'Property request failed. Please try again.';
  }

  static Map<String, dynamic> _readPayload(String rawBody) {
    try {
      final payload = jsonDecode(rawBody);
      if (payload is Map<String, dynamic>) {
        return payload;
      }

      throw const PropertyManagementApiException(
        'Property request failed. Please try again.',
      );
    } on FormatException {
      throw const PropertyManagementApiException(
        'Property request failed. Please try again.',
      );
    }
  }

  static Map<String, dynamic> _readRequiredObject(
    Map<String, dynamic> payload,
    String key,
  ) {
    final value = payload[key];
    if (value is Map<String, dynamic>) {
      return value;
    }

    throw PropertyManagementApiException(_readPayloadMessage(payload));
  }

  static String _readPayloadMessage(Object? payload) {
    if (payload is Map<String, dynamic>) {
      final message = payload['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return 'Property request failed. Please try again.';
  }

  static void _logAddBuildingApi(String message) {
    developer.log('[ADD_BUILDING_API] $message', name: 'ADD_BUILDING_API');
  }

  static BuildingBlock _readBuilding(Map<String, dynamic> payload) {
    final address = payload['address'] as String?;
    return BuildingBlock(
      id: payload['id'] as String,
      name: payload['name'] as String,
      totalFloors: (payload['totalFloors'] as num).toInt(),
      location: payload['location'] as String? ?? address ?? '',
      address: address,
      latitude: _readDouble(payload['latitude']),
      longitude: _readDouble(payload['longitude']),
      zoneId: payload['zoneId'] as String?,
      zoneName:
          payload['zoneName'] as String? ??
          payload['zoneNameEn'] as String? ??
          payload['zoneNameBn'] as String?,
      stationId: payload['stationId'] as String?,
      stationName:
          payload['stationName'] as String? ??
          payload['stationNameEn'] as String? ??
          payload['stationNameBn'] as String?,
      wardId: (payload['wardId'] as num?)?.toInt(),
      wardName:
          payload['wardName'] as String? ??
          payload['wardNameEn'] as String? ??
          payload['wardNameBn'] as String?,
    );
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static BuildingFloor _readFloor(Map<String, dynamic> payload) {
    return BuildingFloor(
      id: payload['id'] as String,
      buildingId: payload['buildingId'] as String,
      label: payload['label'] as String,
      totalUnits: (payload['totalUnits'] as num).toInt(),
    );
  }

  static PropertyUnit _readProperty(Map<String, dynamic> payload) {
    return PropertyUnit(
      id: payload['id'] as String,
      name: payload['name'] as String,
      location: payload['location'] as String,
      monthlyRent: (payload['monthlyRent'] as num).toInt(),
      status: (payload['status'] as String).toLowerCase() == 'rented'
          ? PropertyStatus.rented
          : PropertyStatus.available,
      tenantName: payload['tenantName'] as String?,
      dueAmount: (payload['dueAmount'] as num?)?.toInt() ?? 0,
      buildingId: payload['buildingId'] as String?,
      buildingName: payload['buildingName'] as String?,
      floorId: payload['floorId'] as String?,
      floorLabel: payload['floorLabel'] as String?,
    );
  }
}

class PropertyBuildingResult {
  const PropertyBuildingResult({required this.building, required this.message});

  final BuildingBlock building;
  final String message;
}

class PropertyFloorResult {
  const PropertyFloorResult({required this.floor, required this.message});

  final BuildingFloor floor;
  final String message;
}

class PropertyBuildingDeleteResult {
  const PropertyBuildingDeleteResult({
    required this.buildingId,
    required this.message,
  });

  final String buildingId;
  final String message;
}

class PropertyFloorDeleteResult {
  const PropertyFloorDeleteResult({
    required this.floorId,
    required this.buildingId,
    required this.message,
  });

  final String floorId;
  final String buildingId;
  final String message;
}

class PropertyUnitResult {
  const PropertyUnitResult({required this.property, required this.message});

  final PropertyUnit property;
  final String message;
}

class PropertyDeleteResult {
  const PropertyDeleteResult({required this.propertyId, required this.message});

  final String propertyId;
  final String message;
}

class PropertyManagementApiException implements Exception {
  const PropertyManagementApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
