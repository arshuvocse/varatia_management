import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class SecureDealApiService {
  final http.Client _client;

  SecureDealApiService({http.Client? client})
    : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getWallet(String userId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/secure-deal/wallet?userId=$userId',
      );
      final response = await _client.get(uri);
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return {};
  }

  Future<bool> topUpWallet(String userId, double amount) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/secure-deal/wallet/topup?amount=$amount',
      );
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'note': 'Manual TopUp'}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getDeals(String userId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/secure-deal/list?userId=$userId',
      );
      final response = await _client.get(uri);
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return {};
  }

  Future<String?> createDeal(
    String creatorId,
    String role,
    String title,
    String description,
    double amount,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/secure-deal/create');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'creatorId': creatorId,
          'role': role,
          'title': title,
          'description': description,
          'amount': amount,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['dealId'];
      }
    } catch (_) {}
    return null;
  }

  Future<bool> connectDeal(String dealId, String userId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/secure-deal/$dealId/connect');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> escrowDeal(String dealId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/secure-deal/$dealId/escrow');
      final response = await _client.post(uri);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deliverDeal(
    String dealId,
    String uploaderId,
    String proofUrl,
    String note,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/secure-deal/$dealId/deliver');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uploaderId': uploaderId,
          'proofUrl': proofUrl,
          'note': note,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> releasePayment(String dealId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/secure-deal/$dealId/release-payment',
      );
      final response = await _client.post(uri);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> raiseDispute(
    String dealId,
    String initiatorId,
    String reason,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/secure-deal/$dealId/dispute');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'initiatorId': initiatorId, 'reason': reason}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
