import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class RegistrationFeeInfo {
  final double fee;
  final bool isActive;
  final String currency;

  const RegistrationFeeInfo({
    required this.fee,
    required this.isActive,
    required this.currency,
  });

  factory RegistrationFeeInfo.fromJson(Map<String, dynamic> json) {
    return RegistrationFeeInfo(
      fee: (json['fee'] as num?)?.toDouble() ?? 50.0,
      isActive: json['isActive'] as bool? ?? true,
      currency: json['currency'] as String? ?? 'BDT',
    );
  }
}

class RegistrationStatus {
  final String userId;
  final bool isPaid;
  final bool isRequired;
  final double fee;
  final String currency;
  final String? transactionId;
  final DateTime? paidAt;

  const RegistrationStatus({
    required this.userId,
    required this.isPaid,
    required this.isRequired,
    required this.fee,
    required this.currency,
    this.transactionId,
    this.paidAt,
  });

  factory RegistrationStatus.fromJson(Map<String, dynamic> json) {
    DateTime? paidDate;
    if (json['paidAt'] != null) {
      paidDate = DateTime.tryParse(json['paidAt'].toString());
    }

    return RegistrationStatus(
      userId: json['userId'] as String? ?? '',
      isPaid: json['isPaid'] as bool? ?? false,
      isRequired: json['isRequired'] as bool? ?? true,
      fee: (json['fee'] as num?)?.toDouble() ?? 50.0,
      currency: json['currency'] as String? ?? 'BDT',
      transactionId: json['transactionId'] as String?,
      paidAt: paidDate,
    );
  }
}

class PaymentHistoryItem {
  final int id;
  final String transactionId;
  final String paymentType;
  final String title;
  final double amount;
  final String status;
  final String monthYear;
  final String gateway;
  final DateTime? paymentDate;
  final DateTime createdOn;

  const PaymentHistoryItem({
    required this.id,
    required this.transactionId,
    required this.paymentType,
    required this.title,
    required this.amount,
    required this.status,
    required this.monthYear,
    required this.gateway,
    this.paymentDate,
    required this.createdOn,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? payDate;
    if (json['paymentDate'] != null) {
      payDate = DateTime.tryParse(json['paymentDate'].toString());
    }
    DateTime createDate = DateTime.now();
    if (json['createdOn'] != null) {
      createDate = DateTime.tryParse(json['createdOn'].toString()) ?? DateTime.now();
    }

    return PaymentHistoryItem(
      id: json['id'] as int? ?? 0,
      transactionId: json['transactionId'] as String? ?? '',
      paymentType: json['paymentType'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      monthYear: json['monthYear'] as String? ?? '',
      gateway: json['gateway'] as String? ?? 'SSLCommerz',
      paymentDate: payDate,
      createdOn: createDate,
    );
  }

  bool get isSuccess =>
      status.toLowerCase() == 'success' || status.toLowerCase() == 'paid';
  bool get isPending => status.toLowerCase() == 'pending';
}

class UserPaymentHistory {
  final String userId;
  final double totalPaid;
  final List<PaymentHistoryItem> payments;

  const UserPaymentHistory({
    required this.userId,
    required this.totalPaid,
    required this.payments,
  });

  factory UserPaymentHistory.fromJson(Map<String, dynamic> json) {
    final rawList = json['payments'] as List<dynamic>? ?? [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => PaymentHistoryItem.fromJson(e))
        .toList();

    return UserPaymentHistory(
      userId: json['userId'] as String? ?? '',
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
      payments: items,
    );
  }
}

class RegistrationPaymentApiService {
  static const Duration _requestTimeout = Duration(seconds: 15);

  RegistrationPaymentApiService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  /// Fetch general registration fee configuration
  Future<RegistrationFeeInfo> getRegistrationFeeInfo() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/payments/registration-fee');
      final response = await _client.get(uri).timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RegistrationPaymentApiException(_readErrorMessage(response.body));
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return RegistrationFeeInfo.fromJson(payload);
    } catch (e) {
      if (e is RegistrationPaymentApiException) rethrow;
      throw RegistrationPaymentApiException(
          'Failed to load registration fee info: ${e.toString()}');
    }
  }

  /// Check user's registration fee status
  Future<RegistrationStatus> getRegistrationStatus(String userId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/payments/registration-status')
          .replace(queryParameters: {'userId': userId});

      final response = await _client.get(uri).timeout(_requestTimeout);

      if (kDebugMode) {
        debugPrint(
            'Registration fee check: HTTP ${response.statusCode} ${response.body}');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RegistrationPaymentApiException(_readErrorMessage(response.body));
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return RegistrationStatus.fromJson(payload);
    } on TimeoutException {
      throw const RegistrationPaymentApiException(
          'The server took too long to respond. Please check your internet connection.');
    } on SocketException {
      throw const RegistrationPaymentApiException(
          'Unable to reach server. Please check your internet connection and try again.');
    } catch (e) {
      if (e is RegistrationPaymentApiException) rethrow;
      throw RegistrationPaymentApiException(
          'Failed to check registration fee status: ${e.toString()}');
    }
  }

  /// Initiate registration fee payment via SSLCommerz
  Future<String> initiateRegistrationPayment(String userId) async {
    try {
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/api/payments/registration-fee/initiate');

      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'userId': userId}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RegistrationPaymentApiException(_readErrorMessage(response.body));
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final gatewayPageUrl = payload['gatewayPageUrl'] as String?;

      if (gatewayPageUrl == null || gatewayPageUrl.isEmpty) {
        throw const RegistrationPaymentApiException(
            'Gateway URL is missing from server response.');
      }

      return gatewayPageUrl;
    } on TimeoutException {
      throw const RegistrationPaymentApiException(
          'The server took too long to respond. Please check your internet connection.');
    } on SocketException {
      throw const RegistrationPaymentApiException(
          'Unable to reach the server. Please check your internet connection and try again.');
    } catch (e) {
      if (e is RegistrationPaymentApiException) rethrow;
      throw RegistrationPaymentApiException(
          'Failed to initiate registration payment: ${e.toString()}');
    }
  }

  /// Fetch user payment history
  Future<UserPaymentHistory> getUserPaymentHistory(String userId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/payments/user-history')
          .replace(queryParameters: {'userId': userId});

      final response = await _client.get(uri).timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RegistrationPaymentApiException(_readErrorMessage(response.body));
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return UserPaymentHistory.fromJson(payload);
    } on TimeoutException {
      throw const RegistrationPaymentApiException(
          'The server took too long to respond. Please check your internet connection.');
    } on SocketException {
      throw const RegistrationPaymentApiException(
          'Unable to reach the server. Please check your internet connection.');
    } catch (e) {
      if (e is RegistrationPaymentApiException) rethrow;
      throw RegistrationPaymentApiException(
          'Failed to fetch payment history: ${e.toString()}');
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
      // Fallback
    }
    return 'Payment request failed. Please try again.';
  }
}

class RegistrationPaymentApiException implements Exception {
  const RegistrationPaymentApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
