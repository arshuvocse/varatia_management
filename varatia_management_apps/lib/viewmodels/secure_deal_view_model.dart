import 'package:flutter/foundation.dart';
import '../../data/services/auth_session_service.dart';
import '../../data/services/secure_deal_api_service.dart';

class SecureDealViewModel extends ChangeNotifier {
  final SecureDealApiService _apiService = SecureDealApiService();
  final AuthSessionService _authSessionService = AuthSessionService();

  Map<String, dynamic> walletData = {};
  List<dynamic> transactions = [];
  List<dynamic> deals = [];
  bool isLoading = false;
  String? userId;

  SecureDealViewModel() {
    _init();
  }

  Future<void> _init() async {
    final session = await _authSessionService.readSession();
    userId = session?.userId ?? 'unknown';
    await fetchAll();
  }

  Future<void> fetchAll() async {
    if (userId == null) return;
    isLoading = true;
    notifyListeners();

    try {
      final wData = await _apiService.getWallet(userId!);
      if (wData['success'] == true) {
        walletData = wData['wallet'] ?? {};
        transactions = wData['transactions'] ?? [];
      }

      final dData = await _apiService.getDeals(userId!);
      if (dData['success'] == true) {
        deals = dData['deals'] ?? [];
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> topUpWallet(double amount) async {
    if (userId == null) return false;
    final success = await _apiService.topUpWallet(userId!, amount);
    if (success) await fetchAll();
    return success;
  }

  Future<String?> createDeal(
    String role,
    String title,
    String description,
    double amount,
  ) async {
    if (userId == null) return null;
    final dealId = await _apiService.createDeal(
      userId!,
      role,
      title,
      description,
      amount,
    );
    if (dealId != null) await fetchAll();
    return dealId;
  }

  Future<bool> connectDeal(String dealId) async {
    if (userId == null) return false;
    final success = await _apiService.connectDeal(dealId, userId!);
    if (success) await fetchAll();
    return success;
  }

  Future<bool> escrowDeal(String dealId) async {
    final success = await _apiService.escrowDeal(dealId);
    if (success) await fetchAll();
    return success;
  }

  Future<bool> deliverDeal(String dealId, String proofUrl, String note) async {
    if (userId == null) return false;
    final success = await _apiService.deliverDeal(
      dealId,
      userId!,
      proofUrl,
      note,
    );
    if (success) await fetchAll();
    return success;
  }

  Future<bool> releasePayment(String dealId) async {
    final success = await _apiService.releasePayment(dealId);
    if (success) await fetchAll();
    return success;
  }

  Future<bool> raiseDispute(String dealId, String reason) async {
    if (userId == null) return false;
    final success = await _apiService.raiseDispute(dealId, userId!, reason);
    if (success) await fetchAll();
    return success;
  }
}
