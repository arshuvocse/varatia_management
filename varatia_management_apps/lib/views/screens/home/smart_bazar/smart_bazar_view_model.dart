import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/services/smart_bazar_api_service.dart';

class SmartBazarTransaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final double cashback;
  final double commission;
  final DateTime dateTime;
  final bool isCredit;
  final String type;

  SmartBazarTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.cashback,
    required this.commission,
    required this.dateTime,
    required this.isCredit,
    required this.type,
  });

  factory SmartBazarTransaction.fromJson(Map<String, dynamic> json) {
    return SmartBazarTransaction(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      cashback: (json['cashback'] as num?)?.toDouble() ?? 0.0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'])
          : DateTime.now(),
      isCredit: json['isCredit'] ?? true,
      type: json['type'] ?? 'purchase',
    );
  }
}

class SmartBazarProductCategory {
  final String id;
  final String name;
  final double commissionPercent;

  SmartBazarProductCategory({
    required this.id,
    required this.name,
    required this.commissionPercent,
  });
}

class SmartBazarStore {
  final String name;
  final String code;
  final String ownerName;
  final String upazila;
  final String district;
  final double totalSales;
  final double commission;
  final double progress;
  final bool isActive;

  SmartBazarStore({
    required this.name,
    required this.code,
    required this.ownerName,
    required this.upazila,
    required this.district,
    required this.totalSales,
    required this.commission,
    required this.progress,
    this.isActive = true,
  });

  factory SmartBazarStore.fromJson(Map<String, dynamic> json) {
    return SmartBazarStore(
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      ownerName: json['ownerName'] ?? '',
      upazila: json['upazila'] ?? '',
      district: json['district'] ?? '',
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] ?? true,
    );
  }
}

class SmartBazarViewModel extends ChangeNotifier {
  final SmartBazarApiService _apiService = SmartBazarApiService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // --- CUSTOMER STATE ---
  double _customerWalletBalance = 0.0;
  double _customerTotalCashback = 0.0;
  double get customerWalletBalance => _customerWalletBalance;
  double get customerTotalCashback => _customerTotalCashback;

  // --- SHOPKEEPER STATE ---
  double _shopTodaySales = 0.0;
  double _shopMonthlySales = 0.0;
  double _shopCustomerCashback = 0.0;
  double _shopCompanyCommission = 0.0;
  bool _isShopPaymentDue = true; // Added for Monthly Fee payment
  double _shopWalletBalance = 0.0; // Added for Shopkeeper Wallet

  List<SmartBazarProductCategory> _productCategories = [];
  List<SmartBazarProductCategory> get productCategories {
    if (_productCategories.isEmpty) {
      // Fallback mock data if API fails or is empty
      return [
        SmartBazarProductCategory(
          id: '1',
          name: 'Electronics',
          commissionPercent: 2.0,
        ),
        SmartBazarProductCategory(
          id: '2',
          name: 'Groceries',
          commissionPercent: 1.0,
        ),
        SmartBazarProductCategory(
          id: '3',
          name: 'Clothing',
          commissionPercent: 3.0,
        ),
        SmartBazarProductCategory(
          id: '4',
          name: 'Others',
          commissionPercent: 1.5,
        ),
      ];
    }
    return _productCategories;
  }

  double get shopTodaySales => _shopTodaySales;
  double get shopMonthlySales => _shopMonthlySales;
  double get shopCustomerCashback => _shopCustomerCashback;
  double get shopCompanyCommission => _shopCompanyCommission;
  double get shopTotalCommission =>
      _shopCustomerCashback + _shopCompanyCommission;
  bool get isShopPaymentDue => _isShopPaymentDue;
  double get shopWalletBalance => _shopWalletBalance;

  Future<void> addShopWalletBalance(String shopkeeperId, double amount) async {
    _setLoading(true);
    try {
      final success = await _apiService.addShopWalletBalance(
        shopkeeperId: shopkeeperId,
        amount: amount,
      );
      if (success) {
        await loadShopkeeperDashboard(shopkeeperId);
      } else {
        _errorMessage = 'Failed to add balance via API.';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> processMonthlyPayment(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final monthKey = 'shop_payment_${now.year}_${now.month}_$userId';
    await prefs.setBool(monthKey, true);

    _isShopPaymentDue = false;
    notifyListeners();
  }

  // --- FIELD OFFICER STATE ---
  int _foTotalStores = 0;
  int _foActiveStores = 0;
  double _foTotalSales = 0.0;
  double _foOurCommission = 0.0;
  int get foTotalStores => _foTotalStores;
  int get foActiveStores => _foActiveStores;
  double get foTotalSales => _foTotalSales;
  double get foOurCommission => _foOurCommission;

  // --- SHARED LISTS ---
  List<SmartBazarTransaction> _transactions = [];
  List<SmartBazarTransaction> get transactions => _transactions;

  List<SmartBazarStore> _stores = [];
  List<SmartBazarStore> get stores => _stores;

  // --- API FETCH METHODS ---
  Future<void> loadCustomerDashboard(String userId) async {
    _setLoading(true);
    try {
      final response = await _apiService.getCustomerDashboard(userId);
      _customerWalletBalance =
          (response.summary['walletBalance'] as num?)?.toDouble() ?? 0.0;
      _customerTotalCashback =
          (response.summary['totalCashback'] as num?)?.toDouble() ?? 0.0;
      _transactions = response.items
          .map((e) => SmartBazarTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadShopkeeperDashboard(String userId) async {
    _setLoading(true);
    try {
      final response = await _apiService.getShopkeeperDashboard(userId);
      _shopTodaySales =
          (response.summary['todaySales'] as num?)?.toDouble() ?? 0.0;
      _shopMonthlySales =
          (response.summary['monthlySales'] as num?)?.toDouble() ?? 0.0;
      _shopCustomerCashback =
          (response.summary['customerCashback'] as num?)?.toDouble() ?? 0.0;
      _shopCompanyCommission =
          (response.summary['companyCommission'] as num?)?.toDouble() ?? 0.0;
      _shopWalletBalance =
          (response.summary['walletBalance'] as num?)?.toDouble() ?? 0.0;
      _transactions = response.items
          .map((e) => SmartBazarTransaction.fromJson(e as Map<String, dynamic>))
          .toList();

      if (_productCategories.isEmpty) {
        final apiCategories = await _apiService.getProductCategories();
        if (apiCategories.isNotEmpty) {
          _productCategories = apiCategories
              .map(
                (e) => SmartBazarProductCategory(
                  id: e['id']?.toString() ?? '',
                  name: e['name']?.toString() ?? '',
                  commissionPercent:
                      (e['commissionPercent'] as num?)?.toDouble() ?? 0.0,
                ),
              )
              .toList();
        }
      }

      // Check local monthly payment status
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final monthKey = 'shop_payment_${now.year}_${now.month}_$userId';
      _isShopPaymentDue = !(prefs.getBool(monthKey) ?? false);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFieldOfficerDashboard(String userId) async {
    _setLoading(true);
    try {
      final response = await _apiService.getFieldOfficerDashboard(userId);
      _foTotalStores = (response.summary['totalStores'] as num?)?.toInt() ?? 0;
      _foActiveStores =
          (response.summary['activeStores'] as num?)?.toInt() ?? 0;
      _foTotalSales =
          (response.summary['totalSales'] as num?)?.toDouble() ?? 0.0;
      _foOurCommission =
          (response.summary['ourCommission'] as num?)?.toDouble() ?? 0.0;
      _stores = response.items
          .map((e) => SmartBazarStore.fromJson(e as Map<String, dynamic>))
          .toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // --- OPERATIONS (DYNAMIC) ---
  Future<bool> addSale({
    required String shopkeeperId,
    required String customerPhone,
    required double amount,
    required String storeName,
    required SmartBazarProductCategory category,
  }) async {
    double commissionToDeduct = amount * (category.commissionPercent / 100);

    if (_shopWalletBalance < commissionToDeduct) {
      _errorMessage = 'Insufficient wallet balance for this sale.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final success = await _apiService.addSale(
        shopkeeperId: shopkeeperId,
        customerPhone: customerPhone,
        amount: amount,
        storeName: storeName,
        categoryId: category.id,
        commissionAmount: commissionToDeduct,
      );
      if (success) {
        // Refresh the shopkeeper dashboard after successful sale
        await loadShopkeeperDashboard(shopkeeperId);
        return true;
      } else {
        _errorMessage = 'Failed to add sale';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> withdrawBalance({
    required String customerId,
    required double amount,
    required String method,
    required String number,
  }) async {
    if (_customerWalletBalance < amount) return false;

    _setLoading(true);
    try {
      final success = await _apiService.withdrawBalance(
        customerId: customerId,
        amount: amount,
        method: method,
        number: number,
      );
      if (success) {
        // Refresh customer dashboard
        await loadCustomerDashboard(customerId);
        return true;
      }
      _errorMessage = 'Failed to withdraw balance';
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addStore({
    required String fieldOfficerId,
    required String name,
    required String code,
    required String ownerName,
    required String upazila,
    required String district,
  }) async {
    _setLoading(true);
    try {
      final success = await _apiService.addStore(
        fieldOfficerId: fieldOfficerId,
        name: name,
        code: code,
        ownerName: ownerName,
        upazila: upazila,
        district: district,
      );
      if (success) {
        // Refresh field officer dashboard
        await loadFieldOfficerDashboard(fieldOfficerId);
      } else {
        _errorMessage = 'Failed to add store';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }
}
