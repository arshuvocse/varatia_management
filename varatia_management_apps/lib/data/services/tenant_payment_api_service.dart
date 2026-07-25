import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/app_models.dart';

class TenantPaymentApiService {
  TenantPaymentApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<List<RentPayment>> getRentPayments(String userId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/tenant/payments?user_id=$userId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TenantPaymentApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final paymentsList = payload['payments'] as List<dynamic>? ?? [];

    return paymentsList.map((e) {
      final paymentPayload = e as Map<String, dynamic>;
      final statusString = paymentPayload['status'] as String? ?? '';

      PaymentStatus status = PaymentStatus.due;
      if (statusString.toLowerCase() == 'paid') {
        status = PaymentStatus.paid;
      }

      return RentPayment(
        propertyName: paymentPayload['propertyName'] as String? ?? '',
        tenantName: paymentPayload['tenantName'] as String? ?? '',
        monthLabel: paymentPayload['monthLabel'] as String? ?? '',
        amount: (paymentPayload['amount'] as num?)?.toInt() ?? 0,
        status: status,
        paidOn: paymentPayload['paidOn'] == null
            ? null
            : DateTime.tryParse(paymentPayload['paidOn'] as String),
      );
    }).toList();
  }

  Future<TenantPaymentConfirmationResult> confirmPayment({
    required String tenantId,
    required String monthLabel,
    required int amount,
    required String paymentMethod,
    required List<String> paymentTypes,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/tenant/payments/confirm'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenantId': tenantId,
        'monthLabel': monthLabel,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'paymentTypes': paymentTypes,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TenantPaymentApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final paymentPayload = payload['payment'] as Map<String, dynamic>;
    final tenantPayload = payload['tenant'] as Map<String, dynamic>;

    return TenantPaymentConfirmationResult(
      tenant: TenantProfile(
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
      ),
      payment: RentPayment(
        propertyName: paymentPayload['propertyName'] as String,
        tenantName: paymentPayload['tenantName'] as String,
        monthLabel: paymentPayload['monthLabel'] as String,
        amount: (paymentPayload['amount'] as num).toInt(),
        status: PaymentStatus.paid,
        paidOn: paymentPayload['paidOn'] == null
            ? null
            : DateTime.parse(paymentPayload['paidOn'] as String),
      ),
      propertyId: payload['propertyId'] as String,
      propertyName: payload['propertyName'] as String,
      dueAmount: (payload['dueAmount'] as num).toInt(),
      message:
          payload['message'] as String? ?? 'Payment confirmed successfully.',
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

    return 'Payment confirmation failed. Please try again.';
  }

  static String? _readOptionalString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    return null;
  }
}

class TenantPaymentConfirmationResult {
  const TenantPaymentConfirmationResult({
    required this.tenant,
    required this.payment,
    required this.propertyId,
    required this.propertyName,
    required this.dueAmount,
    required this.message,
  });

  final TenantProfile tenant;
  final RentPayment payment;
  final String propertyId;
  final String propertyName;
  final int dueAmount;
  final String message;
}

class TenantPaymentApiException implements Exception {
  const TenantPaymentApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
