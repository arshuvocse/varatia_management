import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class PickupApiService {
  final http.Client _client;

  PickupApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<bool> createPickupRequest({
    required String tenantId,
    required String pickupAddress,
    required String dropAddress,
    required String itemType,
    required String note,
    required bool isPaid,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/tenant/pickup');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tenantId': tenantId,
          'pickupAddress': pickupAddress,
          'dropAddress': dropAddress,
          'itemType': itemType,
          'note': note,
          'isPaid': isPaid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
