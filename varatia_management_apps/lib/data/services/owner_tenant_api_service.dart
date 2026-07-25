import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/app_models.dart';
import '../repositories/management_repository.dart';

class OwnerTenantApiService {
  OwnerTenantApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<List<TenantProfile>> getTenants() async {
    if (ApiConfig.isDemoMode) {
      return List<TenantProfile>.from(MockManagementRepository().tenants);
    }

    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/owner/tenants'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OwnerTenantApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body);
    final tenantsPayload = payload is Map<String, dynamic>
        ? payload['tenants'] as List<dynamic>? ?? const []
        : payload as List<dynamic>? ?? const [];

    return tenantsPayload
        .cast<Map<String, dynamic>>()
        .map(_readTenantProfile)
        .toList(growable: false);
  }

  Future<OwnerTenantCreateResult> createTenant({
    required String fullName,
    required String phoneNumber,
    required String nid,
    required String propertyId,
  }) async {
    if (ApiConfig.isDemoMode) {
      final property = MockManagementRepository().properties.firstWhere(
        (item) => item.id == propertyId,
        orElse: () => MockManagementRepository().properties.first,
      );
      final tenant = TenantProfile(
        id: 'DEMO-T-${DateTime.now().millisecondsSinceEpoch}',
        name: fullName,
        phone: phoneNumber,
        nid: nid,
        propertyName: property.name,
        propertyId: property.id,
        location: property.location,
        buildingId: property.buildingId,
        buildingName: property.buildingName,
        floorId: property.floorId,
        floorLabel: property.floorLabel,
      );

      return OwnerTenantCreateResult(
        tenant: tenant,
        propertyId: property.id,
        propertyName: property.name,
        loginPhoneNumber: phoneNumber,
        temporaryPassword: '123456',
        credentialSmsSent: false,
        credentialSmsError: '',
        message: 'Demo tenant created.',
      );
    }

    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/owner/tenants'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'nid': nid,
        'propertyId': propertyId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OwnerTenantApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    return OwnerTenantCreateResult(
      tenant: _readTenantResponse(payload),
      propertyId: payload['propertyId'] as String,
      propertyName: payload['propertyName'] as String,
      loginPhoneNumber: payload['loginPhoneNumber'] as String? ?? '',
      temporaryPassword: payload['temporaryPassword'] as String? ?? '',
      credentialSmsSent: payload['credentialSmsSent'] as bool? ?? false,
      credentialSmsError: payload['credentialSmsError'] as String? ?? '',
      message: payload['message'] as String? ?? 'Tenant created successfully.',
    );
  }

  Future<OwnerTenantUpdateResult> updateTenant({
    required String tenantId,
    required String fullName,
    required String phoneNumber,
    required String nid,
  }) async {
    if (ApiConfig.isDemoMode) {
      final existingTenant = MockManagementRepository().tenants.firstWhere(
        (item) => item.id == tenantId,
        orElse: () => TenantProfile(
          id: tenantId,
          name: fullName,
          phone: phoneNumber,
          nid: nid,
          propertyName: 'Demo Flat',
        ),
      );
      final tenant = TenantProfile(
        id: tenantId,
        name: fullName,
        phone: phoneNumber,
        nid: nid,
        propertyName: existingTenant.propertyName,
        propertyId: existingTenant.propertyId,
        location: existingTenant.location,
        buildingId: existingTenant.buildingId,
        buildingName: existingTenant.buildingName,
        floorId: existingTenant.floorId,
        floorLabel: existingTenant.floorLabel,
      );

      return OwnerTenantUpdateResult(
        tenant: tenant,
        propertyId: tenant.propertyId ?? '',
        propertyName: tenant.propertyName,
        message: 'Demo tenant updated.',
      );
    }

    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}/api/owner/tenants/$tenantId'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'nid': nid,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OwnerTenantApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    return OwnerTenantUpdateResult(
      tenant: _readTenantResponse(payload),
      propertyId: payload['propertyId'] as String,
      propertyName: payload['propertyName'] as String,
      message: payload['message'] as String? ?? 'Tenant updated successfully.',
    );
  }

  Future<OwnerTenantDeleteResult> deleteTenant({
    required String tenantId,
  }) async {
    if (ApiConfig.isDemoMode) {
      final tenant = MockManagementRepository().tenants.firstWhere(
        (item) => item.id == tenantId,
        orElse: () => TenantProfile(
          id: tenantId,
          name: 'Demo Tenant',
          phone: '',
          nid: '',
          propertyName: 'Demo Flat',
        ),
      );

      return OwnerTenantDeleteResult(
        tenantId: tenantId,
        propertyId: tenant.propertyId ?? '',
        propertyName: tenant.propertyName,
        location: tenant.location,
        buildingId: tenant.buildingId,
        buildingName: tenant.buildingName,
        floorId: tenant.floorId,
        floorLabel: tenant.floorLabel,
        message: 'Demo tenant deleted.',
      );
    }

    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/owner/tenants/$tenantId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OwnerTenantApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    return OwnerTenantDeleteResult(
      tenantId: payload['tenantId'] as String,
      propertyId: payload['propertyId'] as String,
      propertyName: payload['propertyName'] as String,
      location: _readOptionalString(payload, 'location'),
      buildingId: _readOptionalString(payload, 'buildingId'),
      buildingName: _readOptionalString(payload, 'buildingName'),
      floorId: _readOptionalString(payload, 'floorId'),
      floorLabel: _readOptionalString(payload, 'floorLabel'),
      message: payload['message'] as String? ?? 'Tenant deleted successfully.',
    );
  }

  Future<OwnerTenantMoveOutResult> moveOutTenant({
    required String tenantId,
  }) async {
    if (ApiConfig.isDemoMode) {
      final existingTenant = MockManagementRepository().tenants.firstWhere(
        (item) => item.id == tenantId,
        orElse: () => TenantProfile(
          id: tenantId,
          name: 'Demo Tenant',
          phone: '',
          nid: '',
          propertyName: 'Demo Flat',
        ),
      );
      final tenant = TenantProfile(
        id: tenantId,
        name: existingTenant.name,
        phone: existingTenant.phone,
        nid: existingTenant.nid,
        propertyName: 'Moved out',
      );

      return OwnerTenantMoveOutResult(
        tenant: tenant,
        previousPropertyId: existingTenant.propertyId ?? '',
        previousPropertyName: existingTenant.propertyName,
        message: 'Demo tenant moved out.',
      );
    }

    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/owner/tenants/$tenantId/move-out'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OwnerTenantApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    return OwnerTenantMoveOutResult(
      tenant: _readTenantResponse(payload),
      previousPropertyId: payload['previousPropertyId'] as String,
      previousPropertyName: payload['previousPropertyName'] as String,
      message:
          payload['message'] as String? ?? 'Tenant moved out successfully.',
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

    return 'Tenant request failed. Please try again.';
  }

  static TenantProfile _readTenantResponse(Map<String, dynamic> payload) {
    final tenantPayload = Map<String, dynamic>.from(
      payload['tenant'] as Map<String, dynamic>,
    );
    tenantPayload.putIfAbsent('propertyId', () => payload['propertyId']);
    tenantPayload.putIfAbsent('propertyName', () => payload['propertyName']);
    return _readTenantProfile(tenantPayload);
  }

  static TenantProfile _readTenantProfile(Map<String, dynamic> tenantPayload) {
    return TenantProfile(
      id: tenantPayload['id'] as String,
      name: tenantPayload['name'] as String,
      phone: tenantPayload['phone'] as String,
      nid: tenantPayload['nid'] as String,
      propertyName: tenantPayload['propertyName'] as String,
      propertyId: _readOptionalString(tenantPayload, 'propertyId'),
      location: _readOptionalString(tenantPayload, 'location'),
      buildingId: _readOptionalString(tenantPayload, 'buildingId'),
      buildingName: _readOptionalString(tenantPayload, 'buildingName'),
      floorId: _readOptionalString(tenantPayload, 'floorId'),
      floorLabel: _readOptionalString(tenantPayload, 'floorLabel'),
    );
  }

  static String? _readOptionalString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    return null;
  }
}

class OwnerTenantCreateResult {
  const OwnerTenantCreateResult({
    required this.tenant,
    required this.propertyId,
    required this.propertyName,
    required this.loginPhoneNumber,
    required this.temporaryPassword,
    required this.credentialSmsSent,
    required this.credentialSmsError,
    required this.message,
  });

  final TenantProfile tenant;
  final String propertyId;
  final String propertyName;
  final String loginPhoneNumber;
  final String temporaryPassword;
  final bool credentialSmsSent;
  final String credentialSmsError;
  final String message;
}

class OwnerTenantUpdateResult {
  const OwnerTenantUpdateResult({
    required this.tenant,
    required this.propertyId,
    required this.propertyName,
    required this.message,
  });

  final TenantProfile tenant;
  final String propertyId;
  final String propertyName;
  final String message;
}

class OwnerTenantDeleteResult {
  const OwnerTenantDeleteResult({
    required this.tenantId,
    required this.propertyId,
    required this.propertyName,
    required this.message,
    this.location,
    this.buildingId,
    this.buildingName,
    this.floorId,
    this.floorLabel,
  });

  final String tenantId;
  final String propertyId;
  final String propertyName;
  final String message;
  final String? location;
  final String? buildingId;
  final String? buildingName;
  final String? floorId;
  final String? floorLabel;
}

class OwnerTenantMoveOutResult {
  const OwnerTenantMoveOutResult({
    required this.tenant,
    required this.previousPropertyId,
    required this.previousPropertyName,
    required this.message,
  });

  final TenantProfile tenant;
  final String previousPropertyId;
  final String previousPropertyName;
  final String message;
}

class OwnerTenantApiException implements Exception {
  const OwnerTenantApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
