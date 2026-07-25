import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../models/app_models.dart';
import 'auth_session_service.dart';

class GeneralPostApiService {
  GeneralPostApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<List<GeneralPostItem>> getGeneralPosts() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/general-posts'),
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeneralPostApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(_readGeneralPost)
        .toList(growable: false);
  }

  Future<void> createPost({
    required String category,
    required String title,
    required double price,
    required String divisionId,
    required String areaId,
    String? tenantType,
    double? advance,
    required bool utilityIncluded,
    String? fullAddress,
    String? street,
    double? latitude,
    double? longitude,
    required int bedrooms,
    required int bathrooms,
    required int kitchens,
    required int balconies,
    required bool hasGas,
    required bool hasLift,
    required bool hasGenerator,
    required bool hasParking,
    String? description,
    required List<PlatformFile> mediaFiles,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/general-posts');
    final request = http.MultipartRequest('POST', uri);

    if (kDebugMode) {
      final totalBytes = mediaFiles.fold<int>(
        0,
        (total, file) => total + file.size,
      );
      debugPrint(
        'General post media: files=${mediaFiles.length}, bytes=$totalBytes',
      );
    }

    final authSessionService = AuthSessionService();
    final userId = await authSessionService.readUserId() ?? '';

    request.fields['UserId'] = userId;
    request.fields['Category'] = category;
    if (tenantType != null) request.fields['TenantType'] = tenantType;
    request.fields['Title'] = title;
    request.fields['Price'] = price.toString();
    if (advance != null) request.fields['Advance'] = advance.toString();
    request.fields['UtilityIncluded'] = utilityIncluded.toString();
    request.fields['DivisionId'] = divisionId;
    request.fields['AreaId'] = areaId;
    if (fullAddress != null) request.fields['FullAddress'] = fullAddress;
    if (street != null) request.fields['Street'] = street;
    if (latitude != null) request.fields['Latitude'] = latitude.toString();
    if (longitude != null) request.fields['Longitude'] = longitude.toString();
    request.fields['Bedrooms'] = bedrooms.toString();
    request.fields['Bathrooms'] = bathrooms.toString();
    request.fields['Kitchens'] = kitchens.toString();
    request.fields['Balconies'] = balconies.toString();
    request.fields['HasGas'] = hasGas.toString();
    request.fields['HasLift'] = hasLift.toString();
    request.fields['HasGenerator'] = hasGenerator.toString();
    request.fields['HasParking'] = hasParking.toString();
    if (description != null) request.fields['Description'] = description;

    for (final file in mediaFiles) {
      if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Files', file.path!),
        );
      }
    }

    request.headers['Accept'] = 'application/json';

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (kDebugMode) {
      debugPrint(
        'General post submit: HTTP ${response.statusCode} ${response.body}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeneralPostApiException(_readErrorMessage(response.body));
    }
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static GeneralPostItem _readGeneralPost(Map<String, dynamic> payload) {
    return GeneralPostItem(
      id: (payload['id'] as num?)?.toInt() ?? 0,
      userId: payload['userId'] as String? ?? '',
      category: payload['category'] as String? ?? '',
      tenantType: payload['tenantType'] as String?,
      title: payload['title'] as String? ?? '',
      price: (payload['price'] as num?)?.toDouble() ?? 0.0,
      advance: (payload['advance'] as num?)?.toDouble(),
      utilityIncluded: payload['utilityIncluded'] as bool? ?? false,
      divisionId: payload['divisionId'] as String? ?? '',
      divisionNameBn: payload['divisionNameBn'] as String? ?? '',
      areaId: payload['areaId'] as String? ?? '',
      areaNameBn: payload['areaNameBn'] as String? ?? '',
      fullAddress: payload['fullAddress'] as String?,
      street: payload['street'] as String?,
      latitude: (payload['latitude'] as num?)?.toDouble(),
      longitude: (payload['longitude'] as num?)?.toDouble(),
      bedrooms: (payload['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (payload['bathrooms'] as num?)?.toInt() ?? 0,
      kitchens: (payload['kitchens'] as num?)?.toInt() ?? 0,
      balconies: (payload['balconies'] as num?)?.toInt() ?? 0,
      hasGas: payload['hasGas'] as bool? ?? false,
      hasLift: payload['hasLift'] as bool? ?? false,
      hasGenerator: payload['hasGenerator'] as bool? ?? false,
      hasParking: payload['hasParking'] as bool? ?? false,
      description: payload['description'] as String?,
      mediaInfo: payload['mediaInfo'] as String?,
      status: payload['status'] as String? ?? '',
      createdOn: DateTime.parse(payload['createdOn'] as String),
    );
  }

  static String _readErrorMessage(String rawBody) {
    try {
      final payload = jsonDecode(rawBody) as Map<String, dynamic>;
      final message = payload['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    } catch (_) {}
    return 'General posts request failed. Please try again.';
  }
}

class GeneralPostApiException implements Exception {
  const GeneralPostApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
