import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/management_snapshot.dart';
import 'api_management_repository.dart';
import 'management_repository.dart';

class ManagementRepositoryBootstrap {
  ManagementRepositoryBootstrap._();

  static const Duration _bootstrapTimeout = Duration(seconds: 2);

  static Future<ManagementRepository> initialize({http.Client? client}) async {
    if (ApiConfig.isDemoMode) {
      debugPrint('VARATIA_DEMO_MODE enabled. Loading mock management data.');
      return MockManagementRepository();
    }

    final effectiveClient = client ?? http.Client();

    try {
      final bootstrapFuture = _loadFromApi(effectiveClient);

      return await bootstrapFuture.timeout(_bootstrapTimeout);
    } on TimeoutException {
      debugPrint(
        'Timed out loading management data from ${ApiConfig.baseUrl}. Falling back to mock data.',
      );
      return MockManagementRepository();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to load management data from ${ApiConfig.baseUrl}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return MockManagementRepository();
    } finally {
      if (client == null) {
        effectiveClient.close();
      }
    }
  }

  static Future<ManagementRepository> _loadFromApi(http.Client client) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/management/bootstrap'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Bootstrap request failed with status ${response.statusCode}.',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final snapshot = ManagementSnapshot.fromJson(payload);
    return ApiManagementRepository(snapshot);
  }
}
