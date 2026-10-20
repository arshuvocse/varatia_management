import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class PostingEntitlement {
  const PostingEntitlement({
    required this.userId,
    this.freePostsAllowed = 4,
    this.freePostsUsed = 0,
    this.remainingFreePosts = 4,
    this.paidCreditsBalance = 0,
    this.totalPaidAmount = 0.0,
    this.canPost = true,
    this.requiresPayment = false,
    this.minimumPaymentAmount = 100.0,
  });

  final String userId;
  final int freePostsAllowed;
  final int freePostsUsed;
  final int remainingFreePosts;
  final int paidCreditsBalance;
  final double totalPaidAmount;
  final bool canPost;
  final bool requiresPayment;
  final double minimumPaymentAmount;

  factory PostingEntitlement.fromJson(Map<String, dynamic> json) {
    return PostingEntitlement(
      userId: json['userId'] as String? ?? '',
      freePostsAllowed: json['freePostsAllowed'] as int? ?? 4,
      freePostsUsed: json['freePostsUsed'] as int? ?? 0,
      remainingFreePosts: json['remainingFreePosts'] as int? ?? 4,
      paidCreditsBalance: json['paidCreditsBalance'] as int? ?? 0,
      totalPaidAmount: (json['totalPaidAmount'] as num?)?.toDouble() ?? 0.0,
      canPost: json['canPost'] as bool? ?? true,
      requiresPayment: json['requiresPayment'] as bool? ?? false,
      minimumPaymentAmount:
          (json['minimumPaymentAmount'] as num?)?.toDouble() ?? 100.0,
    );
  }

  factory PostingEntitlement.initial(String userId) {
    return PostingEntitlement(userId: userId);
  }
}

class PostingPaymentSession {
  const PostingPaymentSession({
    required this.transactionId,
    required this.gatewayUrl,
    required this.amount,
  });

  final String transactionId;
  final String gatewayUrl;
  final double amount;

  factory PostingPaymentSession.fromJson(Map<String, dynamic> json) {
    return PostingPaymentSession(
      transactionId: json['transactionId'] as String? ?? '',
      gatewayUrl:
          json['gatewayUrl'] as String? ??
          json['gatewayPageUrl'] as String? ??
          '',
      amount: (json['amount'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

class PostingEntitlementService {
  PostingEntitlementService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<PostingEntitlement> getEntitlement(String userId) async {
    if (userId.isEmpty) {
      return const PostingEntitlement(userId: '');
    }

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/posting-entitlements/$userId'),
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PostingEntitlement.fromJson(data);
      }
    } catch (_) {
      // Fallback
    }

    return PostingEntitlement.initial(userId);
  }

  Future<PostingPaymentSession> initiatePayment({
    required String userId,
    double amount = 100.0,
  }) async {
    if (amount < 100.0) {
      amount = 100.0;
    }

    final response = await _client.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/posting-entitlements/initiate-payment',
      ),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'amount': amount}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PostingPaymentSession.fromJson(data);
    } else {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to initiate payment');
    }
  }

  void dispose() {
    _client.close();
  }
}
