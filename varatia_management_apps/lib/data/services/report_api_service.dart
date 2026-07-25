import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/app_models.dart';

class ReportApiService {
  ReportApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<ReportSummaryResult> getSummary(String userId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/reports/summary?user_id=$userId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReportApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return ReportSummaryResult(
      dashboardSummary: DashboardSummary(
        totalProperties: (payload['dashboardSummary']['totalProperties'] as num)
            .toInt(),
        totalTenants: (payload['dashboardSummary']['totalTenants'] as num)
            .toInt(),
        monthlyIncome: (payload['dashboardSummary']['monthlyIncome'] as num)
            .toInt(),
        dueRent: (payload['dashboardSummary']['dueRent'] as num).toInt(),
      ),
      incomeMetrics: _readMetricList(payload['incomeMetrics']),
      expenseMetrics: _readMetricList(payload['expenseMetrics']),
      generatedAtUtc: DateTime.parse(payload['generatedAtUtc'] as String),
    );
  }

  Future<ReportExportResult> exportPaymentsCsv(String userId) async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/reports/payments-export?user_id=$userId',
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReportApiException(_readErrorMessage(response.body));
    }

    return ReportExportResult(
      fileName:
          _readFileName(response.headers['content-disposition']) ??
          'payment-report.csv',
      csvContent: utf8.decode(response.bodyBytes),
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static List<MonthlyMetric> _readMetricList(Object? rawValue) {
    final payload = rawValue as List<dynamic>? ?? const [];
    return payload
        .cast<Map<String, dynamic>>()
        .map(
          (item) => MonthlyMetric(
            label: item['label'] as String,
            value: (item['value'] as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }

  static String? _readFileName(String? contentDisposition) {
    if (contentDisposition == null || contentDisposition.trim().isEmpty) {
      return null;
    }

    for (final segment in contentDisposition.split(';')) {
      final normalized = segment.trim();
      if (!normalized.toLowerCase().startsWith('filename=')) {
        continue;
      }

      return normalized
          .substring('filename='.length)
          .replaceAll('"', '')
          .trim();
    }

    return null;
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

    return 'Report request failed. Please try again.';
  }
}

class ReportSummaryResult {
  const ReportSummaryResult({
    required this.dashboardSummary,
    required this.incomeMetrics,
    required this.expenseMetrics,
    required this.generatedAtUtc,
  });

  final DashboardSummary dashboardSummary;
  final List<MonthlyMetric> incomeMetrics;
  final List<MonthlyMetric> expenseMetrics;
  final DateTime generatedAtUtc;
}

class ReportExportResult {
  const ReportExportResult({required this.fileName, required this.csvContent});

  final String fileName;
  final String csvContent;
}

class ReportApiException implements Exception {
  const ReportApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
