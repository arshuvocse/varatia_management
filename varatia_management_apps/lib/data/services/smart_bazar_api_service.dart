import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class SmartBazarDashboardResponse {
  final Map<String, dynamic> summary;
  final List<dynamic> items; // Can be transactions or stores

  SmartBazarDashboardResponse({required this.summary, required this.items});
}

class SmartBazarAuthResponse {
  const SmartBazarAuthResponse({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.createdAt,
    required this.message,
    this.shopCode,
  });

  final String userId;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String? shopCode;
  final DateTime? createdAt;
  final String message;

  factory SmartBazarAuthResponse.fromJson(Map<String, dynamic> json) {
    return SmartBazarAuthResponse(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      role: json['role'] as String? ?? '',
      shopCode: json['shopCode'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      message: json['message'] as String? ?? '',
    );
  }
}

class SmartBazarApiService {
  // Uses the global API config base URL
  String get _baseUrl => '${ApiConfig.baseUrl}/api/SmartBazar';

  Future<SmartBazarAuthResponse> login({
    required String phoneNumber,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phoneNumber': phoneNumber,
        'password': password,
        'role': role,
      }),
    );

    final payload =
        json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return SmartBazarAuthResponse.fromJson(payload);
    }

    throw Exception(
      payload['message'] as String? ?? 'Smart Bazar login failed.',
    );
  }

  Future<SmartBazarAuthResponse> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required String role,
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'password': password,
        'confirmPassword': confirmPassword,
        'role': role,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      }),
    );

    final payload =
        json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return SmartBazarAuthResponse.fromJson(payload);
    }

    throw Exception(
      payload['message'] as String? ?? 'Smart Bazar registration failed.',
    );
  }

  Future<SmartBazarDashboardResponse> getCustomerDashboard(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/customer/dashboard/$userId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return SmartBazarDashboardResponse(
          summary: {
            'walletBalance': data['walletBalance'] ?? 0.0,
            'totalCashback': data['totalCashback'] ?? 0.0,
          },
          items: data['transactions'] ?? [],
        );
      } else {
        throw Exception('Failed to load customer dashboard');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<SmartBazarDashboardResponse> getShopkeeperDashboard(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/shopkeeper/dashboard/$userId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return SmartBazarDashboardResponse(
          summary: {
            'todaySales': data['todaySales'] ?? 0.0,
            'monthlySales': data['monthlySales'] ?? 0.0,
            'customerCashback': data['customerCashback'] ?? 0.0,
            'companyCommission': data['companyCommission'] ?? 0.0,
            'walletBalance': data['walletBalance'] ?? 0.0,
          },
          items: data['transactions'] ?? [],
        );
      } else {
        throw Exception('Failed to load shopkeeper dashboard');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<SmartBazarDashboardResponse> getFieldOfficerDashboard(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fieldofficer/dashboard/$userId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return SmartBazarDashboardResponse(
          summary: {
            'totalStores': data['totalStores'] ?? 0,
            'activeStores': data['activeStores'] ?? 0,
            'totalSales': data['totalSales'] ?? 0.0,
            'ourCommission': data['ourCommission'] ?? 0.0,
          },
          items: data['stores'] ?? [],
        );
      } else {
        throw Exception('Failed to load field officer dashboard');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProductCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/categories'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- POST OPERATIONS ---

  Future<bool> addSale({
    required String shopkeeperId,
    required String customerPhone,
    required double amount,
    required String storeName,
    required String categoryId,
    required double commissionAmount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sale'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'shopkeeperId': shopkeeperId,
          'customerPhone': customerPhone,
          'amount': amount,
          'storeName': storeName,
          'categoryId': categoryId,
          'commissionAmount': commissionAmount,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<bool> addShopWalletBalance({
    required String shopkeeperId,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/shopkeeper/add-balance'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'shopkeeperId': shopkeeperId, 'amount': amount}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> withdrawBalance({
    required String customerId,
    required double amount,
    required String method,
    required String number,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/withdraw'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerId': customerId,
          'amount': amount,
          'method': method,
          'number': number,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<bool> addStore({
    required String fieldOfficerId,
    required String name,
    required String code,
    required String ownerName,
    required String upazila,
    required String district,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/store'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fieldOfficerId': fieldOfficerId,
          'name': name,
          'code': code,
          'ownerName': ownerName,
          'upazila': upazila,
          'district': district,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
