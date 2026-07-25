import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../../core/config/api_config.dart';

class ServiceChargePaymentApiService {
  static const Duration _requestTimeout = Duration(seconds: 15);

  ServiceChargePaymentApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  /// Checks if the monthly service charge of 50 BDT has been paid by the user for the current month.
  Future<bool> checkPaymentStatus(String userId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/payments/status',
      ).replace(queryParameters: {'userId': userId});

      final response = await _client.get(uri).timeout(_requestTimeout);

      if (kDebugMode) {
        debugPrint(
          'Payment status check: HTTP ${response.statusCode} ${response.body}',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ServiceChargePaymentApiException(
          _readErrorMessage(response.body),
        );
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return payload['accessAllowed'] as bool? ??
          payload['isPaid'] as bool? ??
          false;
    } on TimeoutException {
      throw const ServiceChargePaymentApiException(
        'The server took too long to respond. Please check your internet connection.',
      );
    } on SocketException {
      throw const ServiceChargePaymentApiException(
        'Unable to reach the server. Please check your internet connection and try again.',
      );
    } on http.ClientException {
      throw const ServiceChargePaymentApiException(
        'Unable to reach the server. Please check your internet connection and try again.',
      );
    } catch (e) {
      if (e is ServiceChargePaymentApiException) rethrow;
      throw ServiceChargePaymentApiException(
        'Failed to check payment status: ${e.toString()}',
      );
    }
  }

  /// Initiates payment and returns the SSLCommerz Gateway Page URL.
  Future<String> initiatePayment(String userId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/payments/initiate');

      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'userId': userId}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ServiceChargePaymentApiException(
          _readErrorMessage(response.body),
        );
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final gatewayPageUrl = payload['gatewayPageUrl'] as String?;

      if (gatewayPageUrl == null || gatewayPageUrl.isEmpty) {
        throw const ServiceChargePaymentApiException(
          'Gateway URL is missing from server response.',
        );
      }

      return gatewayPageUrl;
    } on TimeoutException {
      throw const ServiceChargePaymentApiException(
        'The server took too long to respond. Please check your internet connection.',
      );
    } on SocketException {
      throw const ServiceChargePaymentApiException(
        'Unable to reach the server. Please check your internet connection and try again.',
      );
    } on http.ClientException {
      throw const ServiceChargePaymentApiException(
        'Unable to reach the server. Please check your internet connection and try again.',
      );
    } catch (e) {
      if (e is ServiceChargePaymentApiException) rethrow;
      throw ServiceChargePaymentApiException(
        'Failed to initiate payment: ${e.toString()}',
      );
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
      // Ignore JSON decode error and fallback
    }
    return 'Payment request failed. Please try again.';
  }
}

class ServiceChargePaymentApiException implements Exception {
  const ServiceChargePaymentApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
