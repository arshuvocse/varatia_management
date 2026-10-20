import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class SubscriptionPlanItem {
  final int id;
  final String serviceCode;
  final String title;
  final String targetRole;
  final String description;
  final double fee;
  final int deliveryDays;
  final bool isActive;

  const SubscriptionPlanItem({
    required this.id,
    required this.serviceCode,
    required this.title,
    required this.targetRole,
    required this.description,
    required this.fee,
    required this.deliveryDays,
    required this.isActive,
  });

  factory SubscriptionPlanItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanItem(
      id: json['id'] as int? ?? 0,
      serviceCode: json['serviceCode'] as String? ?? '',
      title: json['title'] as String? ?? '',
      targetRole: json['targetRole'] as String? ?? '',
      description: json['description'] as String? ?? '',
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      deliveryDays: json['deliveryDays'] as int? ?? 7,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class UserSubscriptionItem {
  final int id;
  final String userId;
  final String userName;
  final String userPhone;
  final String userRole;
  final String serviceCode;
  final String title;
  final double amount;
  final String transactionId;
  final String paymentStatus;
  final String subscriptionStatus;
  final String? userRequirements;
  final int deliveryDays;
  final DateTime subscribedAt;
  final DateTime deadlineAt;
  final int remainingDays;
  final bool isExpired;
  final DateTime? fulfilledAt;
  final String? adminNotes;
  final DateTime createdAt;

  const UserSubscriptionItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userRole,
    required this.serviceCode,
    required this.title,
    required this.amount,
    required this.transactionId,
    required this.paymentStatus,
    required this.subscriptionStatus,
    this.userRequirements,
    required this.deliveryDays,
    required this.subscribedAt,
    required this.deadlineAt,
    required this.remainingDays,
    required this.isExpired,
    this.fulfilledAt,
    this.adminNotes,
    required this.createdAt,
  });

  factory UserSubscriptionItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return UserSubscriptionItem(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      userRole: json['userRole'] as String? ?? '',
      serviceCode: json['serviceCode'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionId: json['transactionId'] as String? ?? '',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      subscriptionStatus: json['subscriptionStatus'] as String? ?? 'in_progress',
      userRequirements: json['userRequirements'] as String?,
      deliveryDays: json['deliveryDays'] as int? ?? 7,
      subscribedAt: parseDate(json['subscribedAt']),
      deadlineAt: parseDate(json['deadlineAt']),
      remainingDays: json['remainingDays'] as int? ?? 0,
      isExpired: json['isExpired'] as bool? ?? false,
      fulfilledAt: json['fulfilledAt'] != null ? DateTime.tryParse(json['fulfilledAt'].toString()) : null,
      adminNotes: json['adminNotes'] as String?,
      createdAt: parseDate(json['createdAt']),
    );
  }

  bool get isPaid => paymentStatus.toLowerCase() == 'success' || paymentStatus.toLowerCase() == 'paid';
  bool get isMatched => subscriptionStatus.toLowerCase() == 'matched';
  bool get isInProgress => subscriptionStatus.toLowerCase() == 'in_progress';
  bool get isCancelled => subscriptionStatus.toLowerCase() == 'cancelled';
}

class SubscriptionPaymentInitiationResult {
  final bool success;
  final String transactionId;
  final double amount;
  final String currency;
  final String gatewayPageUrl;
  final DateTime? deadlineAt;
  final int deliveryDays;
  final String? message;

  const SubscriptionPaymentInitiationResult({
    required this.success,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.gatewayPageUrl,
    this.deadlineAt,
    required this.deliveryDays,
    this.message,
  });

  factory SubscriptionPaymentInitiationResult.fromJson(Map<String, dynamic> json) {
    DateTime? deadline;
    if (json['deadlineAt'] != null) {
      deadline = DateTime.tryParse(json['deadlineAt'].toString());
    }

    return SubscriptionPaymentInitiationResult(
      success: json['success'] as bool? ?? true,
      transactionId: json['transactionId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'BDT',
      gatewayPageUrl: json['gatewayPageUrl'] as String? ?? '',
      deadlineAt: deadline,
      deliveryDays: json['deliveryDays'] as int? ?? 7,
      message: json['message'] as String?,
    );
  }
}

class SubscriptionApiService {
  static const Duration _requestTimeout = Duration(seconds: 15);

  SubscriptionApiService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  /// Fetch all active subscription plans configured by admin
  Future<List<SubscriptionPlanItem>> getPlans() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/plans');
      final response = await _client.get(uri).timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SubscriptionApiException(_readErrorMessage(response.body));
      }

      final payload = jsonDecode(response.body) as List<dynamic>;
      return payload
          .whereType<Map<String, dynamic>>()
          .map((e) => SubscriptionPlanItem.fromJson(e))
          .toList();
    } on TimeoutException {
      throw const SubscriptionApiException('সার্ভার থেকে সাড়া পেতে দেরি হচ্ছে। অনুগ্রহ করে ইন্টারনেট সংযোগ চেক করুন।');
    } on SocketException {
      throw const SubscriptionApiException('সার্ভারের সাথে সংযোগ স্থাপন করা সম্ভব হয়নি। ইন্টারনেট চেক করুন।');
    } catch (e) {
      if (e is SubscriptionApiException) rethrow;
      throw SubscriptionApiException('সাবস্ক্রিপশন প্ল্যান লোড করা সম্ভব হয়নি: ${e.toString()}');
    }
  }

  /// Initiate subscription payment via SSLCommerz
  Future<SubscriptionPaymentInitiationResult> initiateSubscriptionPayment({
    required String userId,
    required String serviceCode,
    String? userRequirements,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/initiate');
      final bodyData = jsonEncode({
        'userId': userId,
        'serviceCode': serviceCode,
        'userRequirements': userRequirements ?? '',
      });

      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: bodyData,
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SubscriptionApiException(_readErrorMessage(response.body));
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final result = SubscriptionPaymentInitiationResult.fromJson(payload);

      if (result.gatewayPageUrl.isEmpty) {
        throw const SubscriptionApiException('SSLCommerz গেটওয়ে লিংক পাওয়া যায়নি।');
      }

      return result;
    } on TimeoutException {
      throw const SubscriptionApiException('সার্ভার থেকে সাড়া পেতে দেরি হচ্ছে। অনুগ্রহ করে পুনরায় চেষ্টা করুন।');
    } on SocketException {
      throw const SubscriptionApiException('সার্ভার সংযোগ ত্রুটি। ইন্টারনেট চেক করুন।');
    } catch (e) {
      if (e is SubscriptionApiException) rethrow;
      throw SubscriptionApiException('পেমেন্ট শুরু করা যায়নি: ${e.toString()}');
    }
  }

  /// Fetch user's subscription matchmaking history & live SLA countdown
  Future<List<UserSubscriptionItem>> getUserSubscriptions(String userId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/user-subscriptions')
          .replace(queryParameters: {'userId': userId});

      final response = await _client.get(uri).timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SubscriptionApiException(_readErrorMessage(response.body));
      }

      final payload = jsonDecode(response.body) as List<dynamic>;
      return payload
          .whereType<Map<String, dynamic>>()
          .map((e) => UserSubscriptionItem.fromJson(e))
          .toList();
    } on TimeoutException {
      throw const SubscriptionApiException('সার্ভার থেকে সাড়া পেতে দেরি হচ্ছে।');
    } on SocketException {
      throw const SubscriptionApiException('সার্ভার সংযোগ ত্রুটি।');
    } catch (e) {
      if (e is SubscriptionApiException) rethrow;
      throw SubscriptionApiException('সাবস্ক্রিপশন হিস্ট্রি লোড করা সম্ভব হয়নি: ${e.toString()}');
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
    } catch (_) {}
    return 'অনুরোধটি ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';
  }
}

class SubscriptionApiException implements Exception {
  const SubscriptionApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
