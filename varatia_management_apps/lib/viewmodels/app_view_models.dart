import 'package:flutter/widgets.dart';

import '../core/utils/app_language.dart';
import '../data/models/app_models.dart';
import '../data/repositories/management_repository.dart';
import '../data/services/communication_api_service.dart';
import '../data/services/expense_api_service.dart';
import '../data/services/notification_api_service.dart';
import '../data/services/owner_tenant_api_service.dart';
import '../data/services/property_management_api_service.dart';
import '../data/services/report_api_service.dart';
import '../data/services/auth_session_service.dart';
import '../data/services/tenant_payment_api_service.dart';

class ShellViewModel extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void selectTab(int index) {
    if (_currentIndex == index) {
      return;
    }
    _currentIndex = index;
    notifyListeners();
  }
}

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._repository);

  final ManagementRepository _repository;

  DashboardSummary get summary => _repository.dashboardSummary;
  List<ActivityItem> get recentActivities => _repository.recentActivities;

  void refresh() {
    notifyListeners();
  }

  List<PropertyUnit> get dueProperties {
    return _repository.properties
        .where((property) => property.dueAmount > 0)
        .toList(growable: false);
  }
}

class PropertyViewModel extends ChangeNotifier {
  PropertyViewModel(ManagementRepository repository)
    : _repository = repository,
      _buildings = List<BuildingBlock>.from(repository.buildings),
      _floors = List<BuildingFloor>.from(repository.floors),
      _properties = List<PropertyUnit>.from(repository.properties);

  final ManagementRepository _repository;
  final PropertyManagementApiService _propertyManagementApiService =
      PropertyManagementApiService();
  final List<BuildingBlock> _buildings;
  final List<BuildingFloor> _floors;
  final List<PropertyUnit> _properties;

  List<BuildingBlock> get buildings => List.unmodifiable(_buildings);
  List<BuildingFloor> get floors => List.unmodifiable(_floors);
  List<PropertyUnit> get properties => List.unmodifiable(_properties);

  void refresh() {
    notifyListeners();
  }

  List<BuildingFloor> floorsForBuilding(String buildingId) {
    return floors
        .where((floor) => floor.buildingId == buildingId)
        .toList(growable: false);
  }

  List<PropertyUnit> unitsForFloor(String floorId) {
    return properties
        .where((unit) => unit.floorId == floorId)
        .toList(growable: false);
  }

  List<PropertyUnit> unitsForBuilding(String buildingId) {
    return properties
        .where((unit) => unit.buildingId == buildingId)
        .toList(growable: false);
  }

  Future<PropertyBuildingResult> createBuilding({
    required String name,
    required String location,
    required int totalFloors,
    String? address,
    double? latitude,
    double? longitude,
    String? zoneId,
    String? stationId,
    int? wardId,
  }) async {
    final result = await _propertyManagementApiService.createBuilding(
      name: name,
      location: location,
      totalFloors: totalFloors,
      address: address,
      latitude: latitude,
      longitude: longitude,
      zoneId: zoneId,
      stationId: stationId,
      wardId: wardId,
    );

    _buildings.add(result.building);
    _syncRepositoryCollections();
    notifyListeners();
    return result;
  }

  Future<PropertyBuildingResult> updateBuilding({
    required String buildingId,
    required String name,
    required String location,
    required int totalFloors,
    String? address,
    double? latitude,
    double? longitude,
    String? zoneId,
    String? stationId,
    int? wardId,
  }) async {
    final result = await _propertyManagementApiService.updateBuilding(
      buildingId: buildingId,
      name: name,
      location: location,
      totalFloors: totalFloors,
      address: address,
      latitude: latitude,
      longitude: longitude,
      zoneId: zoneId,
      stationId: stationId,
      wardId: wardId,
    );

    final buildingIndex = _buildings.indexWhere(
      (building) => building.id == buildingId,
    );
    if (buildingIndex != -1) {
      _buildings[buildingIndex] = result.building;
    }

    _syncRepositoryCollections();
    notifyListeners();
    return result;
  }

  Future<PropertyBuildingDeleteResult> deleteBuilding({
    required String buildingId,
  }) async {
    final result = await _propertyManagementApiService.deleteBuilding(
      buildingId: buildingId,
    );

    _buildings.removeWhere((building) => building.id == buildingId);
    _floors.removeWhere((floor) => floor.buildingId == buildingId);
    _properties.removeWhere((property) => property.buildingId == buildingId);
    _syncRepositoryCollections();
    notifyListeners();
    return result;
  }

  Future<PropertyFloorResult> createFloor({
    required String buildingId,
    required String label,
    required int totalUnits,
  }) async {
    final result = await _propertyManagementApiService.createFloor(
      buildingId: buildingId,
      label: label,
      totalUnits: totalUnits,
    );

    _floors.add(result.floor);
    _syncRepositoryCollections();
    notifyListeners();
    return result;
  }

  Future<PropertyFloorResult> updateFloor({
    required String floorId,
    required String buildingId,
    required String label,
    required int totalUnits,
  }) async {
    final result = await _propertyManagementApiService.updateFloor(
      floorId: floorId,
      buildingId: buildingId,
      label: label,
      totalUnits: totalUnits,
    );

    final floorIndex = _floors.indexWhere((floor) => floor.id == floorId);
    if (floorIndex != -1) {
      _floors[floorIndex] = result.floor;
    }

    _syncRepositoryCollections();
    notifyListeners();
    return result;
  }

  Future<PropertyFloorDeleteResult> deleteFloor({
    required String floorId,
  }) async {
    final result = await _propertyManagementApiService.deleteFloor(
      floorId: floorId,
    );

    _floors.removeWhere((floor) => floor.id == floorId);
    _properties.removeWhere((property) => property.floorId == floorId);
    _syncRepositoryCollections();
    notifyListeners();
    return result;
  }

  Future<PropertyUnitResult> createProperty({
    required String name,
    required int monthlyRent,
    required String buildingId,
    required String floorId,
  }) async {
    final result = await _propertyManagementApiService.createUnit(
      name: name,
      monthlyRent: monthlyRent,
      buildingId: buildingId,
      floorId: floorId,
    );

    _properties.add(result.property);
    _syncRepositoryCollections();
    notifyListeners();
    return result;
  }

  Future<PropertyUnitResult> updateProperty({
    required String propertyId,
    required String name,
    required int monthlyRent,
    required String buildingId,
    required String floorId,
  }) async {
    final result = await _propertyManagementApiService.updateUnit(
      propertyId: propertyId,
      name: name,
      monthlyRent: monthlyRent,
      buildingId: buildingId,
      floorId: floorId,
    );

    final propertyIndex = _properties.indexWhere(
      (property) => property.id == propertyId,
    );
    if (propertyIndex != -1) {
      _properties[propertyIndex] = result.property;
    }

    _syncRepositoryCollections();
    notifyListeners();
    return result;
  }

  Future<PropertyDeleteResult> deleteProperty({
    required String propertyId,
  }) async {
    final result = await _propertyManagementApiService.deleteUnit(
      propertyId: propertyId,
    );

    _properties.removeWhere((property) => property.id == propertyId);
    _syncRepositoryCollections();
    notifyListeners();
    return result;
  }

  void markPropertyVacant({required String propertyId}) {
    final propertyIndex = _properties.indexWhere(
      (property) => property.id == propertyId,
    );
    if (propertyIndex == -1) {
      return;
    }

    final property = _properties[propertyIndex];
    _properties[propertyIndex] = PropertyUnit(
      id: property.id,
      name: property.name,
      location: property.location,
      monthlyRent: property.monthlyRent,
      status: PropertyStatus.available,
      dueAmount: property.monthlyRent,
      buildingId: property.buildingId,
      buildingName: property.buildingName,
      floorId: property.floorId,
      floorLabel: property.floorLabel,
    );

    try {
      final repositoryProperties = _repository.properties;
      final repositoryIndex = repositoryProperties.indexWhere(
        (item) => item.id == propertyId,
      );
      if (repositoryIndex != -1) {
        repositoryProperties[repositoryIndex] = _properties[propertyIndex];
      }
    } catch (_) {
      // Ignore immutable mock repository lists.
    }

    notifyListeners();
  }

  void _syncRepositoryCollections() {
    try {
      _replaceRepositoryList(_repository.buildings, _buildings);
      _replaceRepositoryList(_repository.floors, _floors);
      _replaceRepositoryList(_repository.properties, _properties);
    } catch (_) {
      // Ignore immutable mock repository lists.
    }
  }

  static void _replaceRepositoryList<T>(List<T> target, List<T> source) {
    target
      ..clear()
      ..addAll(source);
  }

  @override
  void dispose() {
    _propertyManagementApiService.dispose();
    super.dispose();
  }
}

class TenantViewModel extends ChangeNotifier {
  TenantViewModel(ManagementRepository repository)
    : _repository = repository,
      _tenants = List<TenantProfile>.from(repository.tenants);

  final ManagementRepository _repository;
  final OwnerTenantApiService _ownerTenantApiService = OwnerTenantApiService();
  final List<TenantProfile> _tenants;
  bool _isLoadingTenants = false;
  bool _hasLoadedTenantsFromApi = false;
  bool _isUpdatingTenant = false;
  String? _tenantUpdateError;

  List<TenantProfile> get tenants => List.unmodifiable(_tenants);
  bool get isUpdatingTenant => _isUpdatingTenant;
  bool get isLoadingTenants => _isLoadingTenants;
  String? get tenantUpdateError => _tenantUpdateError;

  Future<void> loadTenantsFromApi({bool forceRefresh = false}) async {
    if (_isLoadingTenants || (_hasLoadedTenantsFromApi && !forceRefresh)) {
      return;
    }

    _isLoadingTenants = true;
    notifyListeners();

    try {
      final tenants = await _ownerTenantApiService.getTenants();
      _tenants
        ..clear()
        ..addAll(tenants);

      _hasLoadedTenantsFromApi = true;
    } catch (_) {
      // Handle error gracefully or ignore
    } finally {
      _isLoadingTenants = false;
      notifyListeners();
    }
  }

  void clearTenantUpdateError() {
    if (_tenantUpdateError == null) {
      return;
    }

    _tenantUpdateError = null;
    notifyListeners();
  }

  Future<TenantProfile?> updateTenant({
    required String tenantId,
    required String fullName,
    required String phoneNumber,
    required String nid,
  }) async {
    _isUpdatingTenant = true;
    _tenantUpdateError = null;
    notifyListeners();

    try {
      final tenantIndex = _tenants.indexWhere(
        (tenant) => tenant.id == tenantId,
      );
      if (tenantIndex == -1) {
        _tenantUpdateError = 'Tenant was not found.';
        return null;
      }

      final result = await _ownerTenantApiService.updateTenant(
        tenantId: tenantId,
        fullName: fullName,
        phoneNumber: phoneNumber,
        nid: nid,
      );

      _tenants[tenantIndex] = result.tenant;
      _syncRepositoryTenant(result.tenant);
      return result.tenant;
    } on OwnerTenantApiException catch (error) {
      _tenantUpdateError = error.message;
      return null;
    } catch (_) {
      _tenantUpdateError = 'Unable to update tenant right now.';
      return null;
    } finally {
      _isUpdatingTenant = false;
      notifyListeners();
    }
  }

  Future<OwnerTenantMoveOutResult> moveOutTenant({
    required String tenantId,
  }) async {
    final result = await _ownerTenantApiService.moveOutTenant(
      tenantId: tenantId,
    );

    final tenantIndex = _tenants.indexWhere((tenant) => tenant.id == tenantId);
    if (tenantIndex != -1) {
      final existingTenant = _tenants[tenantIndex];
      _tenants[tenantIndex] = TenantProfile(
        id: existingTenant.id,
        name: existingTenant.name,
        phone: existingTenant.phone,
        nid: existingTenant.nid,
        propertyName: '',
      );
    }

    try {
      final repositoryTenants = _repository.tenants;
      final repositoryIndex = repositoryTenants.indexWhere(
        (tenant) => tenant.id == tenantId,
      );
      if (repositoryIndex != -1 && tenantIndex != -1) {
        repositoryTenants[repositoryIndex] = _tenants[tenantIndex];
      }
    } catch (_) {
      // Ignore immutable mock repository lists.
    }

    notifyListeners();
    return result;
  }

  void _syncRepositoryTenant(TenantProfile tenant) {
    try {
      final repositoryTenants = _repository.tenants;
      final repositoryIndex = repositoryTenants.indexWhere(
        (item) => item.id == tenant.id,
      );
      if (repositoryIndex != -1) {
        repositoryTenants[repositoryIndex] = tenant;
      }
    } catch (_) {
      // Ignore immutable mock repository lists.
    }
  }

  void refresh() {
    notifyListeners();
  }

  @override
  void dispose() {
    _ownerTenantApiService.dispose();
    super.dispose();
  }
}

class PaymentViewModel extends ChangeNotifier {
  PaymentViewModel(ManagementRepository repository)
    : _payments = List<RentPayment>.from(repository.payments);

  final TenantPaymentApiService _tenantPaymentApiService =
      TenantPaymentApiService();
  final List<RentPayment> _payments;
  bool _isLoadingPayments = false;
  bool _hasLoadedPaymentsFromApi = false;

  List<RentPayment> get payments => List.unmodifiable(_payments);
  bool get isLoadingPayments => _isLoadingPayments;

  int get totalDue {
    return payments
        .where((payment) => payment.status == PaymentStatus.due)
        .fold<int>(0, (sum, item) => sum + item.amount);
  }

  Future<void> loadPaymentsFromApi({bool forceRefresh = false}) async {
    if (_isLoadingPayments || (_hasLoadedPaymentsFromApi && !forceRefresh)) {
      return;
    }

    _isLoadingPayments = true;
    notifyListeners();

    try {
      final userId = await AuthSessionService().readUserId() ?? '';
      final apiPayments = await _tenantPaymentApiService.getRentPayments(
        userId,
      );
      _payments
        ..clear()
        ..addAll(apiPayments);

      _hasLoadedPaymentsFromApi = true;
    } catch (_) {
      // Ignore or handle
    } finally {
      _isLoadingPayments = false;
      notifyListeners();
    }
  }

  void refresh() {
    notifyListeners();
  }
}

class ExpenseViewModel extends ChangeNotifier {
  ExpenseViewModel(ManagementRepository repository)
    : _repository = repository,
      _expenses = List<ExpenseItem>.from(repository.expenses) {
    Future<void>.microtask(refresh);
  }

  final ManagementRepository _repository;
  final ExpenseApiService _expenseApiService = ExpenseApiService();
  final List<ExpenseItem> _expenses;
  bool _isLoading = false;
  String? _errorMessage;

  List<ExpenseItem> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalExpenses {
    return _expenses.fold<int>(0, (sum, item) => sum + item.amount);
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = await AuthSessionService().readUserId() ?? '';
      final items = await _expenseApiService.getAll(userId);
      _expenses
        ..clear()
        ..addAll(items);
      _syncRepositoryExpenses();
    } on ExpenseApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load expenses right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CreateExpenseResult> createExpense({
    required String title,
    required String category,
    required int amount,
    required String monthLabel,
  }) async {
    final userId = await AuthSessionService().readUserId() ?? '';
    final result = await _expenseApiService.createExpense(
      title: title,
      category: category,
      amount: amount,
      monthLabel: monthLabel,
      userId: userId,
    );

    _expenses.insert(0, result.expense);
    _syncRepositoryExpenses();
    notifyListeners();
    return result;
  }

  Future<UpdateExpenseResult> updateExpense({
    required int expenseId,
    required String title,
    required String category,
    required int amount,
    required String monthLabel,
  }) async {
    final userId = await AuthSessionService().readUserId() ?? '';
    final result = await _expenseApiService.updateExpense(
      expenseId: expenseId,
      title: title,
      category: category,
      amount: amount,
      monthLabel: monthLabel,
      userId: userId,
    );

    final expenseIndex = _expenses.indexWhere(
      (expense) => expense.id == expenseId,
    );
    if (expenseIndex != -1) {
      _expenses[expenseIndex] = result.expense;
    }

    _syncRepositoryExpenses();
    notifyListeners();
    return result;
  }

  Future<DeleteExpenseResult> deleteExpense({required int expenseId}) async {
    final result = await _expenseApiService.deleteExpense(expenseId: expenseId);
    _expenses.removeWhere((expense) => expense.id == expenseId);
    _syncRepositoryExpenses();
    notifyListeners();
    return result;
  }

  void _syncRepositoryExpenses() {
    try {
      _repository.expenses
        ..clear()
        ..addAll(_expenses);
    } catch (_) {
      // Ignore immutable mock repository lists.
    }
  }

  @override
  void dispose() {
    _expenseApiService.dispose();
    super.dispose();
  }
}

class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel(this._repository)
    : _notifications = List<AppNotificationItem>.from(
        _repository.notifications,
      ) {
    Future<void>.microtask(refresh);
  }

  final ManagementRepository _repository;
  final NotificationApiService _notificationApiService =
      NotificationApiService();
  final List<AppNotificationItem> _notifications;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  List<AppNotificationItem> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _notificationApiService.getAll();
      _notifications
        ..clear()
        ..addAll(items);
      _syncRepositoryNotifications();
    } on NotificationApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load notifications right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<NotificationSendResult> sendNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _notificationApiService.sendToUser(
        userId: userId,
        title: title,
        body: body,
      );
      await refresh();
      return result;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<NotificationReadResult?> markAsRead({
    required int notificationId,
  }) async {
    final notificationIndex = _notifications.indexWhere(
      (item) => item.id == notificationId,
    );
    if (notificationIndex == -1) {
      return null;
    }

    final current = _notifications[notificationIndex];
    if (!current.isUnread) {
      return null;
    }

    final result = await _notificationApiService.markAsRead(
      notificationId: notificationId,
    );

    _notifications[notificationIndex] = AppNotificationItem(
      id: current.id,
      title: current.title,
      subtitle: current.subtitle,
      createdAt: current.createdAt,
      isUnread: false,
    );
    _syncRepositoryNotifications();
    notifyListeners();
    return result;
  }

  void _syncRepositoryNotifications() {
    try {
      _repository.notifications
        ..clear()
        ..addAll(_notifications);
    } catch (_) {
      // Ignore immutable mock repository lists.
    }
  }

  @override
  void dispose() {
    _notificationApiService.dispose();
    super.dispose();
  }
}

class ReportViewModel extends ChangeNotifier {
  ReportViewModel(this._repository)
    : _dashboardSummary = _repository.dashboardSummary,
      _incomeMetrics = List<MonthlyMetric>.from(_repository.incomeMetrics),
      _expenseMetrics = List<MonthlyMetric>.from(_repository.expenseMetrics) {
    Future<void>.microtask(refresh);
  }

  final ManagementRepository _repository;
  final ReportApiService _reportApiService = ReportApiService();
  DashboardSummary _dashboardSummary;
  List<MonthlyMetric> _incomeMetrics;
  List<MonthlyMetric> _expenseMetrics;
  DateTime? _generatedAtUtc;
  bool _isLoading = false;
  bool _isExporting = false;
  String? _errorMessage;

  DashboardSummary get dashboardSummary => _dashboardSummary;
  List<MonthlyMetric> get incomeMetrics => List.unmodifiable(_incomeMetrics);
  List<MonthlyMetric> get expenseMetrics => List.unmodifiable(_expenseMetrics);
  DateTime? get generatedAtUtc => _generatedAtUtc;
  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;
  String? get errorMessage => _errorMessage;

  double get latestIncome =>
      _incomeMetrics.isEmpty ? 0 : _incomeMetrics.last.value;
  double get latestExpense =>
      _expenseMetrics.isEmpty ? 0 : _expenseMetrics.last.value;

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = await AuthSessionService().readUserId() ?? '';
      final result = await _reportApiService.getSummary(userId);
      _dashboardSummary = result.dashboardSummary;
      _incomeMetrics = List<MonthlyMetric>.from(result.incomeMetrics);
      _expenseMetrics = List<MonthlyMetric>.from(result.expenseMetrics);
      _generatedAtUtc = result.generatedAtUtc;

      try {
        _repository.incomeMetrics
          ..clear()
          ..addAll(_incomeMetrics);
        _repository.expenseMetrics
          ..clear()
          ..addAll(_expenseMetrics);
      } catch (_) {
        // Ignore immutable mock repository lists.
      }
    } on ReportApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load report summary right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ReportExportResult> exportPaymentsCsv() async {
    _isExporting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = await AuthSessionService().readUserId() ?? '';
      return await _reportApiService.exportPaymentsCsv(userId);
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _reportApiService.dispose();
    super.dispose();
  }
}

class CommunicationViewModel extends ChangeNotifier {
  CommunicationViewModel(this._repository)
    : _messages = List<CommunicationEntry>.from(_repository.messages) {
    Future<void>.microtask(refresh);
  }

  final ManagementRepository _repository;
  final CommunicationApiService _communicationApiService =
      CommunicationApiService();
  final List<CommunicationEntry> _messages;
  bool _isLoading = false;
  bool _isCreating = false;
  String? _errorMessage;

  List<CommunicationEntry> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get errorMessage => _errorMessage;

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _communicationApiService.getAll();
      _messages
        ..clear()
        ..addAll(items);
      _syncRepositoryMessages();
    } on CommunicationApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load messages right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CreateCommunicationResult> createMessage({
    required String sender,
    required String message,
    required String propertyName,
  }) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _communicationApiService.createMessage(
        sender: sender,
        message: message,
        propertyName: propertyName,
      );
      _messages.insert(0, result.item);
      _syncRepositoryMessages();
      notifyListeners();
      return result;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  void _syncRepositoryMessages() {
    try {
      _repository.messages
        ..clear()
        ..addAll(_messages);
    } catch (_) {
      // Ignore immutable mock repository lists.
    }
  }

  @override
  void dispose() {
    _communicationApiService.dispose();
    super.dispose();
  }
}

class SettingsViewModel extends ChangeNotifier {
  AppLanguage _language = AppLanguage.bangla;

  AppLanguage get language => _language;
  bool get isBanglaFirst => _language == AppLanguage.bangla;
  Locale get locale =>
      isBanglaFirst ? const Locale('bn', 'BD') : const Locale('en', 'US');

  void selectLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
  }
}
