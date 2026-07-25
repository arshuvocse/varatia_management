import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/app_models.dart';

class ExpenseApiService {
  ExpenseApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<List<ExpenseItem>> getAll(String userId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/expenses?user_id=$userId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ExpenseApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .cast<Map<String, dynamic>>()
        .map(_readExpense)
        .toList(growable: false);
  }

  Future<CreateExpenseResult> createExpense({
    required String title,
    required String category,
    required int amount,
    required String monthLabel,
    required String userId,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/expenses'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'category': category,
        'amount': amount,
        'monthLabel': monthLabel,
        'userId': userId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ExpenseApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return CreateExpenseResult(
      expense: _readExpense(payload['expense'] as Map<String, dynamic>),
      message: payload['message'] as String? ?? 'Expense created successfully.',
    );
  }

  Future<UpdateExpenseResult> updateExpense({
    required int expenseId,
    required String title,
    required String category,
    required int amount,
    required String monthLabel,
    required String userId,
  }) async {
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}/api/expenses/$expenseId'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'category': category,
        'amount': amount,
        'monthLabel': monthLabel,
        'userId': userId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ExpenseApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return UpdateExpenseResult(
      expense: _readExpense(payload['expense'] as Map<String, dynamic>),
      message: payload['message'] as String? ?? 'Expense updated successfully.',
    );
  }

  Future<DeleteExpenseResult> deleteExpense({required int expenseId}) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/expenses/$expenseId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ExpenseApiException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return DeleteExpenseResult(
      expenseId: (payload['expenseId'] as num).toInt(),
      message: payload['message'] as String? ?? 'Expense deleted successfully.',
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static ExpenseItem _readExpense(Map<String, dynamic> payload) {
    return ExpenseItem(
      id: (payload['id'] as num?)?.toInt() ?? 0,
      title: payload['title'] as String,
      category: payload['category'] as String,
      amount: (payload['amount'] as num).toInt(),
      monthLabel: payload['monthLabel'] as String,
    );
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

    return 'Expense request failed. Please try again.';
  }
}

class CreateExpenseResult {
  const CreateExpenseResult({required this.expense, required this.message});

  final ExpenseItem expense;
  final String message;
}

class UpdateExpenseResult {
  const UpdateExpenseResult({required this.expense, required this.message});

  final ExpenseItem expense;
  final String message;
}

class DeleteExpenseResult {
  const DeleteExpenseResult({required this.expenseId, required this.message});

  final int expenseId;
  final String message;
}

class ExpenseApiException implements Exception {
  const ExpenseApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
