import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/models/user_role.dart';
import '../core/theme/app_theme.dart';
import '../data/models/app_models.dart';
import '../data/repositories/management_repository.dart';
import '../data/services/auth_session_service.dart';
import '../data/services/communication_api_service.dart';
import '../data/services/property_management_api_service.dart';
import '../data/services/dhaka_location_api_service.dart';
import '../data/services/owner_post_api_service.dart';
import '../data/services/owner_tenant_api_service.dart';
import '../data/services/tenant_payment_api_service.dart';
import '../data/services/announcement_api_service.dart';
import '../data/services/general_post_api_service.dart';
import '../data/services/chat_api_service.dart';
import '../data/services/saved_posts_api_service.dart';
import '../core/utils/bangla_formatter.dart';

class RoleSelectionViewModel extends ChangeNotifier {
  EntryUserRole _selectedRole = EntryUserRole.owner;

  EntryUserRole get selectedRole => _selectedRole;

  void selectRole(EntryUserRole role) {
    if (_selectedRole == role) {
      return;
    }

    _selectedRole = role;
    notifyListeners();
  }
}

class RoleShellViewModel extends ChangeNotifier {
  RoleShellViewModel(
    this._selectedRole, {
    int initialTabIndex = 0,
    AuthSessionService? authSessionService,
  }) : _authSessionService = authSessionService ?? AuthSessionService() {
    _tabIndexes[_selectedRole] = _normalizeTabIndex(
      _selectedRole,
      initialTabIndex,
    );
  }

  final EntryUserRole _selectedRole;
  final AuthSessionService _authSessionService;
  final Map<EntryUserRole, int> _tabIndexes = {
    EntryUserRole.admin: 0,
    EntryUserRole.owner: 0,
    EntryUserRole.tenant: 0,
  };

  EntryUserRole get selectedRole => _selectedRole;
  int get currentIndex => _tabIndexes[_selectedRole] ?? 0;

  void selectTab(int index) {
    final normalizedIndex = _normalizeTabIndex(_selectedRole, index);
    if (currentIndex == normalizedIndex) {
      return;
    }

    _tabIndexes[_selectedRole] = normalizedIndex;
    unawaited(_authSessionService.saveLastHomeTabIndex(normalizedIndex));
    notifyListeners();
  }

  static int _normalizeTabIndex(EntryUserRole role, int index) {
    final maxIndex = switch (role) {
      EntryUserRole.admin => 3,
      EntryUserRole.owner => 4,
      EntryUserRole.tenant => 4,
    };

    if (index < 0) {
      return 0;
    }

    if (index > maxIndex) {
      return maxIndex;
    }

    return index;
  }
}

class DashboardStatItem {
  const DashboardStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class AdminActivityLog {
  const AdminActivityLog({
    required this.userName,
    required this.action,
    required this.timestampLabel,
  });

  final String userName;
  final String action;
  final String timestampLabel;
}

class VerificationRequestDetails {
  const VerificationRequestDetails({
    required this.name,
    required this.roleLabel,
    required this.photoInitials,
  });

  final String name;
  final String roleLabel;
  final String photoInitials;
}

class OwnerPropertyCardData {
  const OwnerPropertyCardData({
    required this.title,
    required this.location,
    required this.rent,
    required this.status,
  });

  final String title;
  final String location;
  final int rent;
  final PropertyStatus status;
}

class FeaturedListingData {
  const FeaturedListingData({
    required this.title,
    required this.location,
    required this.address,
    required this.division,
    required this.district,
    required this.upazila,
    required this.keywords,
    required this.badgeLabel,
    required this.priceLabel,
    required this.priceSuffix,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqft,
    required this.tagColor,
    required this.imageGradient,
    required this.imageIcon,
  });

  final String title;
  final String location;
  final String address;
  final String division;
  final String district;
  final String upazila;
  final List<String> keywords;
  final String badgeLabel;
  final String priceLabel;
  final String priceSuffix;
  final int bedrooms;
  final int bathrooms;
  final int areaSqft;
  final Color tagColor;
  final List<Color> imageGradient;
  final IconData imageIcon;
}

enum HomeShortcutType { createPost, myPosts }

class HomeShortcutData {
  const HomeShortcutData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.isPrimary = false,
  });

  final HomeShortcutType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final bool isPrimary;
}

class PostCategoryTemplate {
  const PostCategoryTemplate({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class PostChecklistItem {
  const PostChecklistItem({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
  });

  final String title;
  final String subtitle;
  final bool isCompleted;
}

class ManagedPostData {
  const ManagedPostData({
    required this.title,
    required this.categoryLabel,
    required this.location,
    required this.priceLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.fulfillmentLabel,
    required this.fulfillmentColor,
    required this.remarks,
    required this.icon,
    required this.inquiryCount,
    required this.updatedLabel,
  });

  final String title;
  final String categoryLabel;
  final String location;
  final String priceLabel;
  final String statusLabel;
  final Color statusColor;
  final String fulfillmentLabel;
  final Color fulfillmentColor;
  final String remarks;
  final IconData icon;
  final int inquiryCount;
  final String updatedLabel;
}

enum MarketplaceCategory { rent, sale }

class MarketplaceActionData {
  const MarketplaceActionData({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.quickFilters,
  });

  final MarketplaceCategory category;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final List<String> quickFilters;
}

class PopularAreaData {
  const PopularAreaData({required this.name, required this.icon});

  final String name;
  final IconData icon;
}

class PersonOverviewData {
  const PersonOverviewData({
    required this.name,
    required this.identifier,
    required this.subtitle,
    required this.phone,
    required this.badgeLabel,
    this.isVerified = true,
  });

  final String name;
  final String identifier;
  final String subtitle;
  final String phone;
  final String badgeLabel;
  final bool isVerified;
}

class AgreementFieldData {
  const AgreementFieldData({
    required this.label,
    required this.primaryValue,
    this.secondaryValue,
  });

  final String label;
  final String primaryValue;
  final String? secondaryValue;
}

class MonthlyBillEntryData {
  const MonthlyBillEntryData({
    required this.title,
    required this.amountLabel,
    required this.timeLabel,
    required this.icon,
    required this.color,
  });

  final String title;
  final String amountLabel;
  final String timeLabel;
  final IconData icon;
  final Color color;
}

class ContactShortcutData {
  const ContactShortcutData({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
}

class PaymentMethodOption {
  const PaymentMethodOption({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class TenantRentPaymentEntry {
  const TenantRentPaymentEntry({
    required this.ownerName,
    required this.monthName,
    required this.year,
    required this.paymentTypes,
    required this.amount,
    required this.method,
    required this.paidAt,
  });

  final String ownerName;
  final String monthName;
  final int year;
  final List<String> paymentTypes;
  final int amount;
  final String method;
  final DateTime paidAt;

  String get monthLabel => '$monthName $year';
  String get paymentTypeLabel => paymentTypes.join(', ');
}

class MaintenanceCategoryOption {
  const MaintenanceCategoryOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class AdminDashboardViewModel extends ChangeNotifier {
  List<DashboardStatItem> get summaryItems => const [
    DashboardStatItem(
      label: 'Total Users',
      value: '1,248',
      icon: Icons.people_alt_rounded,
      color: Color(0xFF1E40AF),
    ),
    DashboardStatItem(
      label: 'Active Listings',
      value: '342',
      icon: Icons.home_work_rounded,
      color: Color(0xFFF97316),
    ),
    DashboardStatItem(
      label: 'Pending Approvals',
      value: '18',
      icon: Icons.verified_user_rounded,
      color: Color(0xFFF59E0B),
    ),
    DashboardStatItem(
      label: 'Monthly Revenue',
      value: 'BDT 275,000',
      icon: Icons.payments_rounded,
      color: Color(0xFF16A34A),
    ),
  ];

  List<AdminActivityLog> get recentActivities => const [
    AdminActivityLog(
      userName: 'Ayesha Rahman',
      action: 'submitted rent payment for April',
      timestampLabel: '09:15 AM',
    ),
    AdminActivityLog(
      userName: 'Rakib Hasan',
      action: 'requested owner verification',
      timestampLabel: '10:40 AM',
    ),
    AdminActivityLog(
      userName: 'Green Villa',
      action: 'listed a new 3-bed apartment',
      timestampLabel: '11:25 AM',
    ),
    AdminActivityLog(
      userName: 'Nabila Akter',
      action: 'downloaded receipt archive',
      timestampLabel: '12:05 PM',
    ),
    AdminActivityLog(
      userName: 'Rafiul Karim',
      action: 'updated tenant profile details',
      timestampLabel: '01:20 PM',
    ),
  ];

  VerificationRequestDetails get verificationRequest =>
      const VerificationRequestDetails(
        name: 'Tasnim Jahan',
        roleLabel: 'Owner',
        photoInitials: 'TJ',
      );
}

class OwnerDashboardViewModel extends ChangeNotifier {
  OwnerDashboardViewModel(
    ManagementRepository repository, {
    AuthSessionService? authSessionService,
  }) : _properties = List<PropertyUnit>.from(repository.properties),
       _tenants = List<TenantProfile>.from(repository.tenants),
       _payments = List<RentPayment>.from(repository.payments),
       _authSessionService = authSessionService ?? AuthSessionService() {
    if (_tenants.isNotEmpty) {
      _selectedTenantId = _tenants.first.id;
    }
    _syncHouseRentForSelectedTenant();
    unawaited(refreshAuthSession());
  }

  final AuthSessionService _authSessionService;

  final OwnerTenantApiService _ownerTenantApiService = OwnerTenantApiService();
  final CommunicationApiService _communicationApiService =
      CommunicationApiService();
  final PropertyManagementApiService _propertyManagementApiService =
      PropertyManagementApiService();
  final TenantPaymentApiService _tenantPaymentApiService =
      TenantPaymentApiService();
  final List<PropertyUnit> _properties;
  final List<TenantProfile> _tenants;
  final List<RentPayment> _payments;

  String? _selectedTenantId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 12));
  double _houseRent = 0;
  double _electricityBill = 0;
  double _waterBill = 0;
  double _gasBill = 0;
  double _serviceCharge = 0;
  bool _hasLoadedTenantsFromApi = false;
  bool _isLoadingTenants = false;
  bool _isLoadingProperties = false;
  bool _hasLoadedPropertiesFromApi = false;
  bool _isLoadingPayments = false;
  bool _hasLoadedPaymentsFromApi = false;
  bool _isCreatingTenant = false;
  AuthSession? _authSession;

  Future<void> refreshAuthSession() async {
    try {
      _authSession = await _authSessionService.readSession();
      notifyListeners();
    } catch (_) {
      // Ignore
    }
  }

  PersonOverviewData get ownerProfile {
    final name = _authSession?.fullName.trim() ?? '';
    final phone = _authSession?.phoneNumber.trim() ?? '';
    return PersonOverviewData(
      name: name.isEmpty ? 'Owner' : name,
      identifier: _authSession?.userId ?? '',
      subtitle: 'Flat Owner',
      phone: phone,
      badgeLabel: 'Owner',
    );
  }

  bool _isUpdatingTenant = false;
  bool _isDeletingTenant = false;
  bool _isSendingBill = false;
  String? _tenantListError;
  String? _propertyListError;
  String? _paymentListError;
  String? _tenantCreationError;
  String? _tenantUpdateError;
  String? _tenantDeleteError;
  String? _billSubmitError;

  List<OwnerPropertyCardData> get properties => _properties
      .take(4)
      .map(
        (property) => OwnerPropertyCardData(
          title: property.name == 'Flat A'
              ? 'Green Villa'
              : property.name == 'Flat C'
              ? 'Blue Haven'
              : property.name == 'Flat D'
              ? 'Lake Point'
              : property.name,
          location: property.location,
          rent: property.monthlyRent,
          status: property.status,
        ),
      )
      .toList(growable: false);

  List<TenantProfile> get tenants => List.unmodifiable(_tenants);
  List<RentPayment> get rentPayments => List.unmodifiable(_payments);
  List<PropertyUnit> get availableProperties => _properties
      .where((property) => property.status == PropertyStatus.available)
      .toList(growable: false);
  String? get selectedTenantId => _selectedTenantId;
  TenantProfile? get selectedTenant {
    final tenantId = _selectedTenantId;
    if (tenantId == null) {
      return null;
    }

    for (final tenant in _tenants) {
      if (tenant.id == tenantId) {
        return tenant;
      }
    }

    return null;
  }

  PropertyUnit? get selectedTenantProperty {
    final tenant = selectedTenant;
    if (tenant == null) {
      return null;
    }

    return propertyForTenant(tenant);
  }

  PropertyUnit? propertyForTenant(TenantProfile tenant) {
    final propertyId = tenant.propertyId?.trim();
    if (propertyId != null && propertyId.isNotEmpty) {
      for (final property in _properties) {
        if (property.id == propertyId) {
          return property;
        }
      }
    }

    final propertyName = tenant.propertyName.trim();
    if (propertyName.isEmpty) {
      return null;
    }

    for (final property in _properties) {
      if (property.name == propertyName) {
        return property;
      }
    }

    return null;
  }

  DateTime get dueDate => _dueDate;
  double get houseRent => _houseRent;
  bool get isLoadingTenants => _isLoadingTenants;
  bool get isCreatingTenant => _isCreatingTenant;
  bool get isUpdatingTenant => _isUpdatingTenant;
  bool get isDeletingTenant => _isDeletingTenant;
  bool get isSendingBill => _isSendingBill;
  String? get tenantListError => _tenantListError;
  String? get propertyListError => _propertyListError;
  String? get paymentListError => _paymentListError;
  String? get tenantCreationError => _tenantCreationError;
  String? get tenantUpdateError => _tenantUpdateError;
  String? get tenantDeleteError => _tenantDeleteError;
  String? get billSubmitError => _billSubmitError;
  double get totalAmount =>
      _houseRent + _electricityBill + _waterBill + _gasBill + _serviceCharge;

  int get collectedRent => _payments
      .where((payment) => payment.status == PaymentStatus.paid)
      .fold<int>(0, (sum, item) => sum + item.amount);

  int get dueBills => _payments
      .where((payment) => payment.status == PaymentStatus.due)
      .fold<int>(0, (sum, item) => sum + item.amount);

  List<RentPayment> get confirmedPaymentsForLatestMonth {
    final paidPayments =
        _payments
            .where(
              (payment) =>
                  payment.status == PaymentStatus.paid &&
                  payment.paidOn != null,
            )
            .toList()
          ..sort((left, right) => right.paidOn!.compareTo(left.paidOn!));

    if (paidPayments.isEmpty) {
      return const [];
    }

    final latestMonthLabel = paidPayments.first.monthLabel;
    return paidPayments
        .where((payment) => payment.monthLabel == latestMonthLabel)
        .toList(growable: false);
  }

  String? get confirmedPaymentsMonthLabel {
    final payments = confirmedPaymentsForLatestMonth;
    if (payments.isEmpty) {
      return null;
    }

    return payments.first.monthLabel;
  }

  int get confirmedPaymentsThisMonthCount =>
      confirmedPaymentsForLatestMonth.length;

  int get confirmedPaymentsThisMonthTotal => confirmedPaymentsForLatestMonth
      .fold<int>(0, (sum, item) => sum + item.amount);

  Future<void> loadTenantsFromApi({bool forceRefresh = false}) async {
    if (_isLoadingTenants || (_hasLoadedTenantsFromApi && !forceRefresh)) {
      return;
    }

    _isLoadingTenants = true;
    _tenantListError = null;
    notifyListeners();

    try {
      final tenants = await _ownerTenantApiService.getTenants();
      _tenants
        ..clear()
        ..addAll(tenants);

      if (_tenants.isEmpty) {
        _selectedTenantId = null;
      } else if (_selectedTenantId == null ||
          !_tenants.any((tenant) => tenant.id == _selectedTenantId)) {
        _selectedTenantId = _tenants.first.id;
      }
      _syncHouseRentForSelectedTenant();

      _hasLoadedTenantsFromApi = true;
    } on OwnerTenantApiException catch (error) {
      _tenantListError = error.message;
    } catch (_) {
      _tenantListError = 'Unable to load tenants right now. Please try again.';
    } finally {
      _isLoadingTenants = false;
      notifyListeners();
    }
  }

  Future<void> loadPropertiesFromApi({bool forceRefresh = false}) async {
    if (_isLoadingProperties ||
        (_hasLoadedPropertiesFromApi && !forceRefresh)) {
      return;
    }

    _isLoadingProperties = true;
    _propertyListError = null;
    notifyListeners();

    try {
      final properties = await _propertyManagementApiService.getProperties();
      _properties
        ..clear()
        ..addAll(properties);

      _hasLoadedPropertiesFromApi = true;
    } catch (_) {
      _propertyListError =
          'Unable to load properties right now. Please try again.';
    } finally {
      _isLoadingProperties = false;
      notifyListeners();
    }
  }

  Future<void> loadPaymentsFromApi({bool forceRefresh = false}) async {
    if (_isLoadingPayments || (_hasLoadedPaymentsFromApi && !forceRefresh)) {
      return;
    }

    _isLoadingPayments = true;
    _paymentListError = null;
    notifyListeners();

    try {
      final userId = await _authSessionService.readUserId() ?? '';
      final payments = await _tenantPaymentApiService.getRentPayments(userId);
      _payments
        ..clear()
        ..addAll(payments);

      _hasLoadedPaymentsFromApi = true;
    } catch (e) {
      _paymentListError =
          'Unable to load payments right now. Please try again.';
    } finally {
      _isLoadingPayments = false;
      notifyListeners();
    }
  }

  void clearTenantCreationError() {
    if (_tenantCreationError == null) {
      return;
    }

    _tenantCreationError = null;
    notifyListeners();
  }

  void clearTenantUpdateError() {
    if (_tenantUpdateError == null) {
      return;
    }

    _tenantUpdateError = null;
    notifyListeners();
  }

  void clearTenantDeleteError() {
    if (_tenantDeleteError == null) {
      return;
    }

    _tenantDeleteError = null;
    notifyListeners();
  }

  void selectTenant(String? tenantId) {
    if (tenantId == null || tenantId == _selectedTenantId) {
      return;
    }

    _selectedTenantId = tenantId;
    _syncHouseRentForSelectedTenant();
    _billSubmitError = null;
    notifyListeners();
  }

  void setDueDate(DateTime date) {
    _dueDate = date;
    _billSubmitError = null;
    notifyListeners();
  }

  void updateHouseRent(String value) {
    _houseRent = _parseAmount(value);
    _billSubmitError = null;
    notifyListeners();
  }

  void updateElectricityBill(String value) {
    _electricityBill = _parseAmount(value);
    _billSubmitError = null;
    notifyListeners();
  }

  void updateWaterBill(String value) {
    _waterBill = _parseAmount(value);
    _billSubmitError = null;
    notifyListeners();
  }

  void updateGasBill(String value) {
    _gasBill = _parseAmount(value);
    _billSubmitError = null;
    notifyListeners();
  }

  void updateServiceCharge(String value) {
    _serviceCharge = _parseAmount(value);
    _billSubmitError = null;
    notifyListeners();
  }

  Future<OwnerMonthlyBillSubmitResult?> submitMonthlyBill() async {
    if (_isSendingBill) {
      return null;
    }

    final tenant = selectedTenant;
    if (tenant == null) {
      _billSubmitError = 'Select a tenant first.';
      notifyListeners();
      return null;
    }

    final propertyName = tenant.propertyName.trim();
    if (propertyName.isEmpty) {
      _billSubmitError = 'Selected tenant has no assigned property.';
      notifyListeners();
      return null;
    }

    final amount = totalAmount;
    if (amount <= 0) {
      _billSubmitError = 'Enter at least one bill amount.';
      notifyListeners();
      return null;
    }

    _isSendingBill = true;
    _billSubmitError = null;
    notifyListeners();

    try {
      final response = await _communicationApiService.createMessage(
        sender: 'Owner',
        message: _buildMonthlyBillMessage(amount),
        propertyName: propertyName,
      );

      return OwnerMonthlyBillSubmitResult(
        tenant: tenant,
        propertyName: propertyName,
        totalAmount: amount,
        message: response.message,
      );
    } on CommunicationApiException catch (error) {
      _billSubmitError = error.message;
      return null;
    } catch (_) {
      _billSubmitError = 'Unable to send bill right now. Please try again.';
      return null;
    } finally {
      _isSendingBill = false;
      notifyListeners();
    }
  }

  Future<OwnerTenantCreateResult?> createTenant({
    required String fullName,
    required String phoneNumber,
    required String nid,
    required String propertyId,
  }) async {
    _isCreatingTenant = true;
    _tenantCreationError = null;
    notifyListeners();

    try {
      final result = await _ownerTenantApiService.createTenant(
        fullName: fullName,
        phoneNumber: phoneNumber,
        nid: nid,
        propertyId: propertyId,
      );

      _tenants.insert(0, result.tenant);
      _selectedTenantId = result.tenant.id;

      final propertyIndex = _properties.indexWhere(
        (property) => property.id == result.propertyId,
      );
      if (propertyIndex != -1) {
        final property = _properties[propertyIndex];
        _properties[propertyIndex] = PropertyUnit(
          id: property.id,
          name: property.name,
          location: property.location,
          monthlyRent: property.monthlyRent,
          status: PropertyStatus.rented,
          tenantName: result.tenant.name,
          dueAmount: 0,
          buildingId: property.buildingId,
          buildingName: property.buildingName,
          floorId: property.floorId,
          floorLabel: property.floorLabel,
        );
      }

      _payments.removeWhere(
        (payment) =>
            payment.propertyName == result.propertyName &&
            payment.status == PaymentStatus.due,
      );
      _syncHouseRentForSelectedTenant();

      return result;
    } on OwnerTenantApiException catch (error) {
      _tenantCreationError = error.message;
      return null;
    } catch (_) {
      _tenantCreationError =
          'Unable to create tenant right now. Please try again.';
      return null;
    } finally {
      _isCreatingTenant = false;
      notifyListeners();
    }
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
      final existingTenantIndex = _tenants.indexWhere(
        (tenant) => tenant.id == tenantId,
      );
      if (existingTenantIndex == -1) {
        _tenantUpdateError = 'Tenant was not found.';
        return null;
      }

      final existingTenant = _tenants[existingTenantIndex];
      final result = await _ownerTenantApiService.updateTenant(
        tenantId: tenantId,
        fullName: fullName,
        phoneNumber: phoneNumber,
        nid: nid,
      );

      _tenants[existingTenantIndex] = result.tenant;
      _replacePropertyTenantName(
        propertyName: existingTenant.propertyName,
        tenantName: result.tenant.name,
      );
      _replacePaymentTenantName(
        propertyName: result.propertyName,
        previousTenantName: existingTenant.name,
        nextTenantName: result.tenant.name,
      );

      return result.tenant;
    } on OwnerTenantApiException catch (error) {
      _tenantUpdateError = error.message;
      return null;
    } catch (_) {
      _tenantUpdateError =
          'Unable to update tenant right now. Please try again.';
      return null;
    } finally {
      _isUpdatingTenant = false;
      notifyListeners();
    }
  }

  Future<TenantProfile?> deleteTenant({required String tenantId}) async {
    _isDeletingTenant = true;
    _tenantDeleteError = null;
    notifyListeners();

    try {
      final existingTenantIndex = _tenants.indexWhere(
        (tenant) => tenant.id == tenantId,
      );
      if (existingTenantIndex == -1) {
        _tenantDeleteError = 'Tenant was not found.';
        return null;
      }

      final existingTenant = _tenants[existingTenantIndex];
      final result = await _ownerTenantApiService.deleteTenant(
        tenantId: tenantId,
      );

      _tenants.removeAt(existingTenantIndex);
      if (_selectedTenantId == tenantId) {
        _selectedTenantId = _tenants.isEmpty ? null : _tenants.first.id;
      }

      _replacePropertyWithVacantState(propertyName: result.propertyName);
      _replaceDuePaymentsWithVacant(propertyName: result.propertyName);
      _syncHouseRentForSelectedTenant();

      return existingTenant;
    } on OwnerTenantApiException catch (error) {
      _tenantDeleteError = error.message;
      return null;
    } catch (_) {
      _tenantDeleteError =
          'Unable to delete tenant right now. Please try again.';
      return null;
    } finally {
      _isDeletingTenant = false;
      notifyListeners();
    }
  }

  void syncConfirmedPayment({
    required RentPayment payment,
    required int dueAmount,
  }) {
    final paymentIndex = _payments.indexWhere(
      (item) =>
          item.propertyName == payment.propertyName &&
          item.monthLabel == payment.monthLabel,
    );

    if (paymentIndex == -1) {
      _payments.insert(0, payment);
    } else {
      _payments[paymentIndex] = payment;
    }

    final propertyIndex = _properties.indexWhere(
      (property) => property.name == payment.propertyName,
    );
    if (propertyIndex != -1) {
      final property = _properties[propertyIndex];
      _properties[propertyIndex] = PropertyUnit(
        id: property.id,
        name: property.name,
        location: property.location,
        monthlyRent: property.monthlyRent,
        status: PropertyStatus.rented,
        tenantName: payment.tenantName,
        dueAmount: dueAmount,
        buildingId: property.buildingId,
        buildingName: property.buildingName,
        floorId: property.floorId,
        floorLabel: property.floorLabel,
      );
    }

    notifyListeners();
  }

  double _parseAmount(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  void _syncHouseRentForSelectedTenant() {
    _houseRent = selectedTenantProperty?.monthlyRent.toDouble() ?? 0;
  }

  String _buildMonthlyBillMessage(double amount) {
    final now = DateTime.now();
    final todayFormatted = BanglaFormatter.fullDate(now, bangla: true);
    final property = selectedTenant?.propertyName.trim();
    final flatName = (property != null && property.isNotEmpty) ? property : 'ফ্ল্যাট';
    final monthLabel = _formatBillMonth(now);
    return '📢 ভাড়ার নোটিশ: আপনার আজকে $todayFormatted, আপনাকে $flatName-এর $monthLabel মাসের ভাড়া ৳${_formatAmount(amount)} পেমেন্ট করতে হবে।\n'
        'বিল বিবরণ: ভাড়া ৳${_formatAmount(_houseRent)}, '
        'বিদ্যুৎ ৳${_formatAmount(_electricityBill)}, '
        'পানি ৳${_formatAmount(_waterBill)}, '
        'গ্যাস ৳${_formatAmount(_gasBill)}, '
        'সার্ভিস ৳${_formatAmount(_serviceCharge)}। '
        'মোট ৳${_formatAmount(amount)}। '
        'পরিশোধের শেষ তারিখ: ${_formatBillDate(_dueDate)}।';
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  String _formatBillDate(DateTime date) {
    const monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${monthNames[date.month - 1]} ${date.year}';
  }

  String _formatBillMonth(DateTime date) {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${monthNames[date.month - 1]} ${date.year}';
  }

  void _replacePropertyTenantName({
    required String propertyName,
    required String tenantName,
  }) {
    final propertyIndex = _properties.indexWhere(
      (property) => property.name == propertyName,
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
      status: property.status,
      tenantName: tenantName,
      dueAmount: property.dueAmount,
      buildingId: property.buildingId,
      buildingName: property.buildingName,
      floorId: property.floorId,
      floorLabel: property.floorLabel,
    );
  }

  void _replacePropertyWithVacantState({required String propertyName}) {
    final propertyIndex = _properties.indexWhere(
      (property) => property.name == propertyName,
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
      tenantName: null,
      dueAmount: property.monthlyRent,
      buildingId: property.buildingId,
      buildingName: property.buildingName,
      floorId: property.floorId,
      floorLabel: property.floorLabel,
    );
  }

  void _replacePaymentTenantName({
    required String propertyName,
    required String previousTenantName,
    required String nextTenantName,
  }) {
    for (var index = 0; index < _payments.length; index++) {
      final payment = _payments[index];
      if (payment.propertyName != propertyName ||
          payment.tenantName != previousTenantName) {
        continue;
      }

      _payments[index] = RentPayment(
        propertyName: payment.propertyName,
        tenantName: nextTenantName,
        monthLabel: payment.monthLabel,
        amount: payment.amount,
        status: payment.status,
        paidOn: payment.paidOn,
      );
    }
  }

  void _replaceDuePaymentsWithVacant({required String propertyName}) {
    for (var index = 0; index < _payments.length; index++) {
      final payment = _payments[index];
      if (payment.propertyName != propertyName ||
          payment.status != PaymentStatus.due) {
        continue;
      }

      _payments[index] = RentPayment(
        propertyName: payment.propertyName,
        tenantName: 'Vacant',
        monthLabel: payment.monthLabel,
        amount: payment.amount,
        status: payment.status,
        paidOn: payment.paidOn,
      );
    }
  }

  @override
  void dispose() {
    _ownerTenantApiService.dispose();
    _communicationApiService.dispose();
    super.dispose();
  }
}

class OwnerMonthlyBillSubmitResult {
  const OwnerMonthlyBillSubmitResult({
    required this.tenant,
    required this.propertyName,
    required this.totalAmount,
    required this.message,
  });

  final TenantProfile tenant;
  final String propertyName;
  final double totalAmount;
  final String message;
}

class TenantExperienceViewModel extends ChangeNotifier {
  TenantExperienceViewModel(
    this._repository, {
    AuthSessionService? authSessionService,
  }) : _authSessionService = authSessionService ?? AuthSessionService() {
    unawaited(refreshAuthSession());
  }

  final ManagementRepository _repository;
  final AuthSessionService _authSessionService;
  final TenantPaymentApiService _tenantPaymentApiService =
      TenantPaymentApiService();
  final OwnerPostApiService _ownerPostApiService = OwnerPostApiService();
  final DhakaLocationApiService _dhakaLocationApiService =
      DhakaLocationApiService();
  final AnnouncementApiService _announcementApiService =
      AnnouncementApiService();
  final GeneralPostApiService _generalPostApiService = GeneralPostApiService();
  final TenantChatApiService _tenantChatApiService = TenantChatApiService();
  final SavedPostsApiService _savedPostsApiService = SavedPostsApiService();

  List<SavedPostDto> _savedPosts = [];
  List<TenantChatConversationDto> _chatConversations = [];
  bool _isLoadingSavedPosts = false;
  bool _isLoadingChats = false;

  List<SavedPostDto> get savedPosts => _savedPosts;
  List<TenantChatConversationDto> get chatConversations => _chatConversations;
  bool get isLoadingSavedPosts => _isLoadingSavedPosts;
  bool get isLoadingChats => _isLoadingChats;

  bool isPostSaved(String postId, String postType) {
    return _savedPosts.any((p) => p.postId == postId && p.postType == postType);
  }

  Future<void> loadSavedPostsAndChats() async {
    final userId = await _authSessionService.readUserId();
    if (userId == null || userId.isEmpty) return;

    _isLoadingSavedPosts = true;
    _isLoadingChats = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _savedPostsApiService.getSavedPosts(userId),
        _tenantChatApiService.getConversations(userId),
      ]);

      final rawSaved = results[0];
      final rawChats = results[1];
      _savedPosts = rawSaved is List<SavedPostDto>
          ? rawSaved
          : (rawSaved as List<dynamic>?)?.cast<SavedPostDto>().toList() ?? const <SavedPostDto>[];
      _chatConversations = rawChats is List<TenantChatConversationDto>
          ? rawChats
          : (rawChats as List<dynamic>?)?.cast<TenantChatConversationDto>().toList() ?? const <TenantChatConversationDto>[];
    } catch (e) {
      debugPrint('Error loading saved posts or chats: $e');
    } finally {
      _isLoadingSavedPosts = false;
      _isLoadingChats = false;
      notifyListeners();
    }
  }

  Future<void> toggleSavedPost(String postId, String postType) async {
    final userId = await _authSessionService.readUserId();
    if (userId == null || userId.isEmpty) return;

    // Optimistic update
    final isCurrentlySaved = isPostSaved(postId, postType);
    if (isCurrentlySaved) {
      _savedPosts.removeWhere(
        (p) => p.postId == postId && p.postType == postType,
      );
    } else {
      _savedPosts.add(
        SavedPostDto(
          id: 0,
          postId: postId,
          postType: postType,
          savedAt: DateTime.now(),
        ),
      );
    }
    notifyListeners();

    try {
      final isSaved = await _savedPostsApiService.toggleSavedPost(
        userId: userId,
        postId: postId,
        postType: postType,
      );

      // Update actual state based on API response
      if (isSaved != !isCurrentlySaved) {
        if (isSaved) {
          if (!isPostSaved(postId, postType)) {
            _savedPosts.add(
              SavedPostDto(
                id: 0,
                postId: postId,
                postType: postType,
                savedAt: DateTime.now(),
              ),
            );
          }
        } else {
          _savedPosts.removeWhere(
            (p) => p.postId == postId && p.postType == postType,
          );
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling saved post: $e');
      // Revert optimistic update
      if (isCurrentlySaved) {
        _savedPosts.add(
          SavedPostDto(
            id: 0,
            postId: postId,
            postType: postType,
            savedAt: DateTime.now(),
          ),
        );
      } else {
        _savedPosts.removeWhere(
          (p) => p.postId == postId && p.postType == postType,
        );
      }
      notifyListeners();
    }
  }

  Future<List<TenantChatMessageDto>> getChatMessages(int conversationId) async {
    return _tenantChatApiService.getMessages(conversationId);
  }

  Future<void> sendChatMessage({
    int? conversationId,
    required String ownerUserId,
    required String messageText,
  }) async {
    final userId = await _authSessionService.readUserId();
    if (userId == null || userId.isEmpty) return;

    await _tenantChatApiService.sendMessage(
      conversationId: conversationId,
      tenantUserId: userId,
      ownerUserId: ownerUserId,
      senderUserId: userId,
      messageText: messageText,
    );
    // Reload conversations to update the last message and timestamp
    unawaited(loadSavedPostsAndChats());
  }

  String _selectedMaintenanceCategory = 'plumbing';
  String _issueDescription = '';
  String _marketplaceSearchQuery = '';
  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedUpazila;
  List<DhakaDivisionOption> _dhakaDivisions = const [];
  List<DhakaAreaOption> _dhakaAreas = const [];
  final Map<MarketplaceCategory, String?> _selectedQuickFilters = {};
  final List<TenantRentPaymentEntry> _rentPaymentEntries = [];
  List<ManagedPostData> _managedPosts = const [];
  bool _isSubmittingRentPayment = false;
  bool _isLoadingOwnerPosts = false;
  bool _isLoadingDhakaDivisions = false;
  bool _isLoadingDhakaAreas = false;
  bool _hasLoadedOwnerPosts = false;
  bool _hasLoadedDhakaDivisions = false;
  String? _rentPaymentSubmitError;
  String? _ownerPostListError;
  String? _dhakaLocationError;
  String? _ownerPostStatusFilter;
  AuthSession? _authSession;
  bool _isDisposed = false;
  List<AnnouncementItem> _announcements = const [];
  bool _isLoadingAnnouncements = false;
  String? _announcementError;
  List<GeneralPostItem> _generalPosts = const [];
  bool _isLoadingGeneralPosts = false;
  String? _generalPostError;
  bool _isNearMeActive = false;
  Position? _userLocation;

  Future<void> toggleNearMe() async {
    if (_isNearMeActive) {
      _isNearMeActive = false;
      notifyListeners();
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isNearMeActive = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _isNearMeActive = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _isNearMeActive = false;
        notifyListeners();
        return;
      }

      _userLocation = await Geolocator.getCurrentPosition();
      _isNearMeActive = true;
      notifyListeners();
    } catch (e) {
      _isNearMeActive = false;
      notifyListeners();
    }
  }

  Future<void> refreshAuthSession() async {
    AuthSession? session;
    try {
      session = await _authSessionService.readSession();
    } catch (_) {
      session = null;
    }

    if (_isDisposed) {
      return;
    }

    _authSession = session;
    notifyListeners();
    unawaited(loadAnnouncements());
    unawaited(loadGeneralPosts());
    unawaited(loadSavedPostsAndChats());
  }

  Future<void> loadAnnouncements() async {
    _isLoadingAnnouncements = true;
    _announcementError = null;
    notifyListeners();

    try {
      final items = await _announcementApiService.getActiveAnnouncements();
      if (!_isDisposed) {
        _announcements = items;
      }
    } on AnnouncementApiException catch (e) {
      _announcementError = e.message;
    } catch (_) {
      _announcementError = 'Failed to load announcements';
    } finally {
      if (!_isDisposed) {
        _isLoadingAnnouncements = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadGeneralPosts() async {
    _isLoadingGeneralPosts = true;
    _generalPostError = null;
    notifyListeners();

    try {
      final items = await _generalPostApiService.getGeneralPosts();
      if (!_isDisposed) {
        _generalPosts = items;
      }
    } on GeneralPostApiException catch (e) {
      _generalPostError = e.message;
    } catch (_) {
      _generalPostError = 'Failed to load general posts';
    } finally {
      if (!_isDisposed) {
        _isLoadingGeneralPosts = false;
        notifyListeners();
      }
    }
  }

  TenantProfile get activeTenant {
    final sessionTenant = _activeTenantFromSession();
    if (sessionTenant != null) {
      return sessionTenant;
    }

    if (_repository.tenants.isEmpty) {
      return const TenantProfile(
        id: '',
        name: 'Tenant',
        phone: '',
        nid: '',
        propertyName: '',
      );
    }

    return _repository.tenants.first;
  }

  PropertyUnit? get activeTenantProperty {
    final tenant = activeTenant;
    final propertyId = tenant.propertyId?.trim();
    if (propertyId != null && propertyId.isNotEmpty) {
      for (final property in _repository.properties) {
        if (property.id == propertyId) {
          return property;
        }
      }
    }

    final propertyName = tenant.propertyName;
    for (final property in _repository.properties) {
      if (property.name == propertyName) {
        return property;
      }
    }

    if (_repository.properties.isNotEmpty) {
      return _repository.properties.first;
    }

    return null;
  }

  TenantProfile? _activeTenantFromSession() {
    final session = _authSession;
    if (session == null || session.role != EntryUserRole.tenant) {
      return null;
    }

    final matchedTenant = _findTenantForSession(session);
    if (matchedTenant != null) {
      return _mergeTenantWithSession(matchedTenant, session);
    }

    return _tenantProfileFromSession(session);
  }

  TenantProfile? _findTenantForSession(AuthSession session) {
    final sessionUserId = _normalizeLookupText(session.userId);
    final sessionPhone = _normalizePhone(session.phoneNumber);
    final sessionName = _normalizeLookupText(session.fullName);

    for (final tenant in _repository.tenants) {
      if (sessionUserId.isNotEmpty &&
          _normalizeLookupText(tenant.id) == sessionUserId) {
        return tenant;
      }
    }

    for (final tenant in _repository.tenants) {
      if (sessionPhone.isNotEmpty &&
          _normalizePhone(tenant.phone) == sessionPhone) {
        return tenant;
      }
    }

    for (final tenant in _repository.tenants) {
      if (sessionName.isNotEmpty &&
          _normalizeLookupText(tenant.name) == sessionName) {
        return tenant;
      }
    }

    return null;
  }

  TenantProfile _mergeTenantWithSession(
    TenantProfile tenant,
    AuthSession session,
  ) {
    final sessionUserId = session.userId.trim();
    final sessionName = session.fullName.trim();
    final sessionPhone = session.phoneNumber.trim();

    return TenantProfile(
      id: tenant.id.trim().isEmpty ? sessionUserId : tenant.id,
      name: sessionName.isEmpty ? tenant.name : sessionName,
      phone: sessionPhone.isEmpty ? tenant.phone : sessionPhone,
      nid: tenant.nid,
      propertyName: tenant.propertyName,
      propertyId: tenant.propertyId,
      location: tenant.location,
      buildingId: tenant.buildingId,
      buildingName: tenant.buildingName,
      floorId: tenant.floorId,
      floorLabel: tenant.floorLabel,
    );
  }

  TenantProfile _tenantProfileFromSession(AuthSession session) {
    final sessionName = session.fullName.trim();
    final defaultProperty = _repository.properties.isNotEmpty
        ? _repository.properties.first
        : null;

    return TenantProfile(
      id: session.userId.trim(),
      name: sessionName.isEmpty ? 'Tenant' : sessionName,
      phone: session.phoneNumber.trim(),
      nid: '',
      propertyName: defaultProperty?.name ?? 'Flat A',
      propertyId: defaultProperty?.id ?? 'P-01',
    );
  }

  static String _normalizeLookupText(String value) {
    return value.trim().toLowerCase();
  }

  static String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  PersonOverviewData get tenantProfile {
    final tenant = activeTenant;
    final property = activeTenantProperty;

    return PersonOverviewData(
      name: tenant.name,
      identifier: tenant.id.isEmpty ? 'TTEN-00000' : tenant.id,
      subtitle: property?.location ?? tenant.propertyName,
      phone: tenant.phone,
      badgeLabel: 'Active Tenant',
    );
  }

  PersonOverviewData get ownerProfile => const PersonOverviewData(
    name: 'Omer Hasan',
    identifier: 'OWN-10938',
    subtitle: 'Flat Owner • Dhanmondi',
    phone: '01812 340990',
    badgeLabel: 'Owner',
  );

  PersonOverviewData get managerProfile => const PersonOverviewData(
    name: 'Kamal Uddin',
    identifier: 'MAN-99284',
    subtitle: 'Property Manager • Mirpur',
    phone: '01931 778899',
    badgeLabel: 'Manager',
  );

  PersonOverviewData get brokerProfile => const PersonOverviewData(
    name: 'Minhied Exbed',
    identifier: 'BR-55810',
    subtitle: 'Move-in Assistant',
    phone: '01733 903344',
    badgeLabel: 'Support',
    isVerified: false,
  );

  FeaturedListingData get highlightedListing => featuredListings.first;

  String get marketplaceSearchQuery => _marketplaceSearchQuery;
  String? get selectedDivision => _selectedDivision;
  String? get selectedDistrict => _selectedDistrict;
  String? get selectedUpazila => _selectedUpazila;
  bool get hasSearchQuery => _marketplaceSearchQuery.trim().isNotEmpty;
  bool get isSubmittingRentPayment => _isSubmittingRentPayment;
  bool get isLoadingOwnerPosts => _isLoadingOwnerPosts;
  bool get hasLoadedOwnerPosts => _hasLoadedOwnerPosts;
  String? get rentPaymentSubmitError => _rentPaymentSubmitError;
  String? get ownerPostListError => _ownerPostListError;
  String? get ownerPostStatusFilter => _ownerPostStatusFilter;
  bool get isLoadingDhakaDivisions => _isLoadingDhakaDivisions;
  bool get isLoadingDhakaAreas => _isLoadingDhakaAreas;
  String? get dhakaLocationError => _dhakaLocationError;
  List<AnnouncementItem> get announcements => _announcements;
  bool get isLoadingAnnouncements => _isLoadingAnnouncements;
  String? get announcementError => _announcementError;
  bool get isNearMeActive => _isNearMeActive;

  List<GeneralPostItem> get savedGeneralPosts {
    return _generalPosts
        .where((post) => isPostSaved(post.id.toString(), 'general'))
        .toList();
  }

  List<GeneralPostItem> get myGeneralPosts {
    final currentUserId = _authSession?.userId;
    if (currentUserId == null || currentUserId.isEmpty) return const [];
    return _generalPosts.where((post) => post.userId == currentUserId).toList();
  }

  List<GeneralPostItem> get generalPosts {
    var filteredPosts = List<GeneralPostItem>.from(_generalPosts);

    if (_selectedDivision != null) {
      filteredPosts.retainWhere((post) => post.divisionId == _selectedDivision);
    }

    if (_selectedDistrict != null) {
      filteredPosts.retainWhere((post) => post.areaId == _selectedDistrict);
    }

    if (!_isNearMeActive || _userLocation == null) {
      return filteredPosts;
    }

    filteredPosts.sort((a, b) {
      if (a.latitude == null || a.longitude == null) return 1;
      if (b.latitude == null || b.longitude == null) return -1;

      final distA = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        a.latitude!,
        a.longitude!,
      );
      final distB = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        b.latitude!,
        b.longitude!,
      );
      return distA.compareTo(distB);
    });

    return filteredPosts;
  }

  bool get isLoadingGeneralPosts => _isLoadingGeneralPosts;
  String? get generalPostError => _generalPostError;

  List<MarketplaceLocationOption> get availableDivisionOptions {
    if (_dhakaDivisions.isNotEmpty) {
      return _dhakaDivisions
          .map(
            (division) => MarketplaceLocationOption(
              id: division.id,
              labelBn: division.nameBn,
            ),
          )
          .where((option) => option.id.isNotEmpty)
          .toList(growable: false);
    }

    return _sortedValues(featuredListings.map((listing) => listing.division))
        .map((value) => MarketplaceLocationOption(id: value, labelBn: value))
        .toList(growable: false);
  }

  List<MarketplaceLocationOption> get availableAreaOptions {
    if (_selectedDivision == null) {
      return const [];
    }

    return _dhakaAreas
        .map(
          (area) =>
              MarketplaceLocationOption(id: area.id, labelBn: area.nameBn),
        )
        .where((option) => option.id.isNotEmpty)
        .toList(growable: false);
  }

  List<String> get availableDivisions => availableDivisionOptions
      .map((option) => option.id)
      .toList(growable: false);

  List<String> get availableDistricts {
    if (_selectedDivision == null) {
      return const [];
    }

    if (_dhakaDivisions.isNotEmpty) {
      return availableAreaOptions
          .map((option) => option.id)
          .toList(growable: false);
    }

    return _sortedValues(
      featuredListings
          .where((listing) => listing.division == _selectedDivision)
          .map((listing) => listing.district),
    );
  }

  List<String> get availableUpazilas {
    if (_dhakaDivisions.isNotEmpty) {
      return const [];
    }

    if (_selectedDivision == null || _selectedDistrict == null) {
      return const [];
    }

    return _sortedValues(
      featuredListings
          .where(
            (listing) =>
                listing.division == _selectedDivision &&
                listing.district == _selectedDistrict,
          )
          .map((listing) => listing.upazila),
    );
  }

  bool get hasActiveLocationFilter =>
      _selectedDivision != null ||
      _selectedDistrict != null ||
      _selectedUpazila != null;

  bool get hasActiveSearchFilters => hasSearchQuery || hasActiveLocationFilter;

  List<HomeShortcutData> get quickActions => const [
    HomeShortcutData(
      type: HomeShortcutType.createPost,
      title: 'পোস্ট করুন',
      subtitle: 'ফ্ল্যাট / বাসা অ্যাড করুন',
      icon: Icons.add_home_rounded,
      gradient: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
      isPrimary: true,
    ),
    HomeShortcutData(
      type: HomeShortcutType.myPosts,
      title: 'My Posts',
      subtitle: 'আপনার পোস্ট দেখুন',
      icon: Icons.edit_note_rounded,
      gradient: [Color(0xFFFFF3E8), Color(0xFFFFE6D2)],
    ),
  ];

  List<MarketplaceActionData> get marketplaceActions => const [
    MarketplaceActionData(
      category: MarketplaceCategory.rent,
      title: 'For Rent',
      subtitle: 'ভাড়ার জন্য',
      icon: Icons.apartment_rounded,
      gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      quickFilters: ['Family', 'Bachelor', 'Sublet', 'Ready Flat'],
    ),
    MarketplaceActionData(
      category: MarketplaceCategory.sale,
      title: 'For Sale',
      subtitle: 'বিক্রয়ের জন্য',
      icon: Icons.house_rounded,
      gradient: [Color(0xFFF59E0B), Color(0xFFF97316)],
      quickFilters: ['Apartment', 'Ready Flat', 'New Project', 'Commercial'],
    ),
  ];

  List<FeaturedListingData> get featuredListings => const [
    FeaturedListingData(
      title: '2 Bed Flat - Mirpur 10',
      location: 'Mirpur, Dhaka',
      address: 'Mirpur 10, Dhaka',
      division: 'Dhaka',
      district: 'Dhaka',
      upazila: 'Mirpur',
      keywords: ['Family', 'Ready Flat', 'Flat'],
      badgeLabel: 'For Rent',
      priceLabel: '৳15,000',
      priceSuffix: '/ month',
      bedrooms: 2,
      bathrooms: 2,
      areaSqft: 900,
      tagColor: Color(0xFFF59E0B),
      imageGradient: [Color(0xFFE6C9A6), Color(0xFFB08968)],
      imageIcon: Icons.chair_alt_rounded,
    ),
    FeaturedListingData(
      title: '3 Bed Apartment - Dhanmondi',
      location: 'Dhanmondi 27, Dhaka',
      address: 'Dhanmondi 27, Dhaka',
      division: 'Dhaka',
      district: 'Dhaka',
      upazila: 'Dhanmondi',
      keywords: ['Apartment', 'Ready Flat'],
      badgeLabel: 'For Sale',
      priceLabel: '৳95,00,000',
      priceSuffix: '',
      bedrooms: 3,
      bathrooms: 3,
      areaSqft: 1250,
      tagColor: Color(0xFF2563EB),
      imageGradient: [Color(0xFF93C5FD), Color(0xFFBFDBFE)],
      imageIcon: Icons.apartment_rounded,
    ),
    FeaturedListingData(
      title: 'Family Flat - Uttara',
      location: 'Sector 11, Uttara',
      address: 'Sector 11, Uttara',
      division: 'Dhaka',
      district: 'Dhaka',
      upazila: 'Uttara',
      keywords: ['Family', 'Flat'],
      badgeLabel: 'For Rent',
      priceLabel: '৳28,000',
      priceSuffix: '/ month',
      bedrooms: 3,
      bathrooms: 2,
      areaSqft: 1400,
      tagColor: Color(0xFFF59E0B),
      imageGradient: [Color(0xFFDDD6FE), Color(0xFFC4B5FD)],
      imageIcon: Icons.weekend_rounded,
    ),
    FeaturedListingData(
      title: 'Luxury Apartment - Gulshan',
      location: 'Gulshan 2, Dhaka',
      address: 'Gulshan 2, Dhaka',
      division: 'Dhaka',
      district: 'Dhaka',
      upazila: 'Gulshan',
      keywords: ['Apartment', 'New Project'],
      badgeLabel: 'For Sale',
      priceLabel: '৳2,10,00,000',
      priceSuffix: '',
      bedrooms: 4,
      bathrooms: 4,
      areaSqft: 2200,
      tagColor: Color(0xFF2563EB),
      imageGradient: [Color(0xFFFDE68A), Color(0xFFFCA5A5)],
      imageIcon: Icons.location_city_rounded,
    ),
    FeaturedListingData(
      title: 'Bachelor Flat - Agrabad',
      location: 'Agrabad, Chattogram',
      address: 'Agrabad CDA Avenue, Chattogram',
      division: 'Chattogram',
      district: 'Chattogram',
      upazila: 'Agrabad',
      keywords: ['Bachelor', 'Flat'],
      badgeLabel: 'For Rent',
      priceLabel: 'BDT 18,500',
      priceSuffix: '/ month',
      bedrooms: 2,
      bathrooms: 2,
      areaSqft: 980,
      tagColor: Color(0xFFF59E0B),
      imageGradient: [Color(0xFFBFDBFE), Color(0xFF60A5FA)],
      imageIcon: Icons.apartment_rounded,
    ),
    FeaturedListingData(
      title: 'Sea View Apartment - Cox\'s Bazar',
      location: 'Cox\'s Bazar Sadar, Cox\'s Bazar',
      address: 'Kolatoli Road, Cox\'s Bazar',
      division: 'Chattogram',
      district: 'Cox\'s Bazar',
      upazila: 'Cox\'s Bazar Sadar',
      keywords: ['Apartment', 'Commercial'],
      badgeLabel: 'For Sale',
      priceLabel: 'BDT 12,500,000',
      priceSuffix: '',
      bedrooms: 3,
      bathrooms: 3,
      areaSqft: 1500,
      tagColor: Color(0xFF2563EB),
      imageGradient: [Color(0xFFA7F3D0), Color(0xFF38BDF8)],
      imageIcon: Icons.beach_access_rounded,
    ),
  ];

  List<PopularAreaData> get popularAreas => const [
    PopularAreaData(name: 'Mirpur', icon: Icons.park_outlined),
    PopularAreaData(name: 'Dhanmondi', icon: Icons.place_outlined),
    PopularAreaData(name: 'Agrabad', icon: Icons.business_rounded),
    PopularAreaData(name: 'Uttara', icon: Icons.apartment_rounded),
    PopularAreaData(name: 'Cox\'s Bazar', icon: Icons.house_siding_rounded),
  ];

  Future<void> loadDhakaDivisions({bool forceRefresh = false}) async {
    if (_isLoadingDhakaDivisions ||
        (_hasLoadedDhakaDivisions && !forceRefresh)) {
      return;
    }

    _isLoadingDhakaDivisions = true;
    _dhakaLocationError = null;
    notifyListeners();

    try {
      final divisions = await _dhakaLocationApiService.getDivisions();
      _dhakaDivisions = _sortDhakaDivisions(divisions);
      _hasLoadedDhakaDivisions = true;
      if (_selectedDivision != null &&
          !availableDivisions.contains(_selectedDivision)) {
        _selectedDivision = null;
        _selectedDistrict = null;
        _selectedUpazila = null;
        _dhakaAreas = const [];
      }
    } on DhakaLocationApiException catch (error) {
      _dhakaLocationError = error.message;
    } catch (_) {
      _dhakaLocationError = 'Unable to load Dhaka location options.';
    } finally {
      _isLoadingDhakaDivisions = false;
      notifyListeners();
    }
  }

  Future<void> loadDhakaAreas(String? divisionId) async {
    final normalizedDivisionId = divisionId?.trim();
    if (normalizedDivisionId == null || normalizedDivisionId.isEmpty) {
      _dhakaAreas = const [];
      return;
    }

    _isLoadingDhakaAreas = true;
    _dhakaLocationError = null;
    notifyListeners();

    try {
      final areas = await _dhakaLocationApiService.getAreas(
        divisionId: normalizedDivisionId,
      );
      _dhakaAreas = _sortDhakaAreas(areas);
      if (_selectedDistrict != null &&
          !availableDistricts.contains(_selectedDistrict)) {
        _selectedDistrict = null;
      }
    } on DhakaLocationApiException catch (error) {
      _dhakaLocationError = error.message;
      _dhakaAreas = const [];
      _selectedDistrict = null;
    } catch (_) {
      _dhakaLocationError = 'Unable to load Dhaka area options.';
      _dhakaAreas = const [];
      _selectedDistrict = null;
    } finally {
      _isLoadingDhakaAreas = false;
      notifyListeners();
    }
  }

  List<PostCategoryTemplate> get postTemplates => const [
    PostCategoryTemplate(
      title: 'Flat',
      subtitle: 'Family or bachelor listing',
      icon: Icons.apartment_rounded,
      color: AppColors.primary,
    ),
    PostCategoryTemplate(
      title: 'Sublet',
      subtitle: 'Shared or furnished setup',
      icon: Icons.weekend_rounded,
      color: Color(0xFF2563EB),
    ),
    PostCategoryTemplate(
      title: 'Hostel',
      subtitle: 'Seat-based accommodation',
      icon: Icons.hotel_rounded,
      color: AppColors.accent,
    ),
    PostCategoryTemplate(
      title: 'Office',
      subtitle: 'Commercial workspace',
      icon: Icons.business_center_rounded,
      color: Color(0xFF0F766E),
    ),
  ];

  List<PostChecklistItem> get postChecklist => const [
    PostChecklistItem(
      title: 'Property photos',
      subtitle: 'Add front view and room photos for better reach.',
      isCompleted: true,
    ),
    PostChecklistItem(
      title: 'Location details',
      subtitle: 'Mention area, road, and nearby landmark clearly.',
      isCompleted: true,
    ),
    PostChecklistItem(
      title: 'Price and rules',
      subtitle: 'Share rent, advance, and preferred tenant details.',
      isCompleted: false,
    ),
  ];

  List<ManagedPostData> get managedPosts => List.unmodifiable(_managedPosts);

  int get publishedPostCount =>
      managedPosts.where((post) => post.statusLabel == 'Published').length;

  int get draftPostCount =>
      managedPosts.where((post) => post.statusLabel == 'Draft').length;

  int get totalPostInquiries =>
      managedPosts.fold(0, (total, post) => total + post.inquiryCount);

  Future<void> loadOwnerPosts({
    String? status,
    bool forceRefresh = false,
  }) async {
    final normalizedStatus = _normalizeOwnerPostStatus(status);
    if (!forceRefresh &&
        _hasLoadedOwnerPosts &&
        _ownerPostStatusFilter == normalizedStatus) {
      return;
    }

    _ownerPostStatusFilter = normalizedStatus;
    _isLoadingOwnerPosts = true;
    _ownerPostListError = null;
    notifyListeners();

    try {
      final result = await _ownerPostApiService.getPosts(
        status: normalizedStatus,
      );
      _managedPosts = result.posts
          .map(_mapOwnerPostToManagedPost)
          .toList(growable: false);
      _hasLoadedOwnerPosts = true;
    } on OwnerPostApiException catch (error) {
      _ownerPostListError = error.message;
    } catch (_) {
      _ownerPostListError = 'Unable to load owner posts right now.';
    } finally {
      _isLoadingOwnerPosts = false;
      notifyListeners();
    }
  }

  String? _normalizeOwnerPostStatus(String? status) {
    final normalizedStatus = status?.trim().toLowerCase();
    if (normalizedStatus == null || normalizedStatus.isEmpty) {
      return null;
    }

    return normalizedStatus;
  }

  ManagedPostData _mapOwnerPostToManagedPost(OwnerPostRecord post) {
    final statusLabel = _ownerPostStatusLabel(post.status);
    return ManagedPostData(
      title: post.title,
      categoryLabel: _ownerPostCategoryLabel(post.postType),
      location: post.location.isEmpty ? 'Location not set' : post.location,
      priceLabel: _ownerPostPriceLabel(post),
      statusLabel: statusLabel,
      statusColor: _ownerPostStatusColor(statusLabel),
      fulfillmentLabel: _ownerPostFulfillmentLabel(post.fulfillmentStatus),
      fulfillmentColor: _ownerPostFulfillmentColor(post.fulfillmentStatus),
      remarks: post.remarks,
      icon: _ownerPostIcon(post.postType),
      inquiryCount: post.inquiryCount,
      updatedLabel: _ownerPostUpdatedLabel(post),
    );
  }

  String _ownerPostCategoryLabel(String postType) {
    final normalizedType = postType.trim().toLowerCase();
    return switch (normalizedType) {
      'rent' => 'For Rent',
      'sale' => 'For Sale',
      _ => _titleCase(normalizedType.isEmpty ? 'Post' : normalizedType),
    };
  }

  String _ownerPostPriceLabel(OwnerPostRecord post) {
    if (post.monthlyRent <= 0) {
      return 'Price not set';
    }

    final suffix = post.postType.trim().toLowerCase() == 'rent'
        ? ' / month'
        : '';
    return 'BDT ${post.monthlyRent}$suffix';
  }

  String _ownerPostStatusLabel(String status) {
    final normalizedStatus = status.trim().toLowerCase();
    return switch (normalizedStatus) {
      'published' => 'Published',
      'draft' => 'Draft',
      'under_review' || 'under-review' || 'review' => 'Under Review',
      _ => _titleCase(normalizedStatus.isEmpty ? 'Draft' : normalizedStatus),
    };
  }

  Color _ownerPostStatusColor(String statusLabel) {
    return switch (statusLabel) {
      'Published' => AppColors.success,
      'Draft' => AppColors.textMuted,
      'Under Review' => AppColors.warning,
      _ => AppColors.primary,
    };
  }

  String _ownerPostFulfillmentLabel(String status) {
    final normalizedStatus = status.trim().toLowerCase();
    return normalizedStatus == 'got' ? 'Got' : 'Not got yet';
  }

  Color _ownerPostFulfillmentColor(String status) {
    final normalizedStatus = status.trim().toLowerCase();
    return normalizedStatus == 'got' ? AppColors.success : AppColors.warning;
  }

  IconData _ownerPostIcon(String postType) {
    return switch (postType.trim().toLowerCase()) {
      'sale' => Icons.location_city_rounded,
      'rent' => Icons.apartment_rounded,
      _ => Icons.home_work_rounded,
    };
  }

  String _ownerPostUpdatedLabel(OwnerPostRecord post) {
    final sourceDate = post.updatedAt ?? post.createdAt;
    if (sourceDate == null) {
      return 'Updated recently';
    }

    final updatedAt = sourceDate.toLocal();
    final elapsed = DateTime.now().difference(updatedAt);
    if (elapsed.inMinutes < 1) {
      return 'Updated just now';
    }
    if (elapsed.inHours < 1) {
      return 'Updated ${elapsed.inMinutes}m ago';
    }
    if (elapsed.inDays < 1) {
      return 'Updated ${elapsed.inHours}h ago';
    }
    if (elapsed.inDays < 7) {
      return 'Updated ${elapsed.inDays}d ago';
    }

    final month = updatedAt.month.toString().padLeft(2, '0');
    final day = updatedAt.day.toString().padLeft(2, '0');
    return 'Updated ${updatedAt.year}-$month-$day';
  }

  String _titleCase(String value) {
    final words = value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((word) => word.trim().isNotEmpty);
    return words
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  List<FeaturedListingData> get filteredFeaturedListings => featuredListings
      .where(_matchesSearchAndLocationFilters)
      .toList(growable: false);

  MarketplaceActionData actionFor(MarketplaceCategory category) {
    return marketplaceActions.firstWhere((item) => item.category == category);
  }

  String? selectedQuickFilterFor(MarketplaceCategory category) {
    return _selectedQuickFilters[category];
  }

  bool hasActiveFiltersFor(MarketplaceCategory category) {
    return hasActiveSearchFilters || selectedQuickFilterFor(category) != null;
  }

  List<FeaturedListingData> listingsFor(MarketplaceCategory category) {
    final badgeLabel = switch (category) {
      MarketplaceCategory.rent => 'For Rent',
      MarketplaceCategory.sale => 'For Sale',
    };

    return filteredFeaturedListings
        .where(
          (listing) =>
              listing.badgeLabel == badgeLabel &&
              _matchesQuickFilter(listing, selectedQuickFilterFor(category)),
        )
        .toList(growable: false);
  }

  void updateMarketplaceSearchQuery(String value) {
    if (_marketplaceSearchQuery == value) {
      return;
    }

    _marketplaceSearchQuery = value;
    notifyListeners();
  }

  void clearSearchAndLocationFilters() {
    if (!hasActiveSearchFilters) {
      return;
    }

    _marketplaceSearchQuery = '';
    _selectedDivision = null;
    _selectedDistrict = null;
    _selectedUpazila = null;
    notifyListeners();
  }

  void clearFiltersForCategory(MarketplaceCategory category) {
    if (!hasActiveFiltersFor(category)) {
      return;
    }

    _marketplaceSearchQuery = '';
    _selectedDivision = null;
    _selectedDistrict = null;
    _selectedUpazila = null;
    _selectedQuickFilters.remove(category);
    notifyListeners();
  }

  void toggleQuickFilter(MarketplaceCategory category, String filter) {
    if (_selectedQuickFilters[category] == filter) {
      _selectedQuickFilters.remove(category);
    } else {
      _selectedQuickFilters[category] = filter;
    }
    notifyListeners();
  }

  void selectDivision(String? division) {
    if (_selectedDivision == division) {
      return;
    }

    _selectedDivision = division;
    _selectedDistrict = null;
    _selectedUpazila = null;
    if (_dhakaDivisions.isNotEmpty) {
      _dhakaAreas = const [];
      notifyListeners();
      unawaited(loadDhakaAreas(division));
      return;
    }
    if (_selectedDistrict != null &&
        !availableDistricts.contains(_selectedDistrict)) {
      _selectedDistrict = null;
    }
    if (_selectedUpazila != null &&
        !availableUpazilas.contains(_selectedUpazila)) {
      _selectedUpazila = null;
    }
    notifyListeners();
  }

  void selectDistrict(String? district) {
    if (_selectedDistrict == district) {
      return;
    }

    _selectedDistrict = district;
    if (_selectedUpazila != null &&
        !availableUpazilas.contains(_selectedUpazila)) {
      _selectedUpazila = null;
    }
    notifyListeners();
  }

  void selectUpazila(String? upazila) {
    if (_selectedUpazila == upazila) {
      return;
    }

    _selectedUpazila = upazila;
    notifyListeners();
  }

  void clearLocationFilters() {
    if (!hasActiveLocationFilter) {
      return;
    }

    _selectedDivision = null;
    _selectedDistrict = null;
    _selectedUpazila = null;
    notifyListeners();
  }

  bool _matchesSearchAndLocationFilters(FeaturedListingData listing) {
    if (!_matchesSearchQuery(listing)) {
      return false;
    }

    return _matchesLocationFilter(listing);
  }

  bool _matchesSearchQuery(FeaturedListingData listing) {
    final query = _marketplaceSearchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final searchableText = [
      listing.title,
      listing.location,
      listing.address,
      listing.division,
      listing.district,
      listing.upazila,
      ...listing.keywords,
    ].join(' ').toLowerCase();

    return searchableText.contains(query);
  }

  bool _matchesLocationFilter(FeaturedListingData listing) {
    if (_selectedDivision != null &&
        !_matchesLocationValue(listing.division, _selectedDivision!)) {
      return false;
    }
    if (_selectedDistrict != null &&
        !_matchesLocationValue(listing.district, _selectedDistrict!)) {
      return false;
    }
    if (_selectedUpazila != null &&
        !_matchesLocationValue(listing.upazila, _selectedUpazila!)) {
      return false;
    }

    return true;
  }

  bool _matchesLocationValue(String listingValue, String selectedValue) {
    final normalizedListing = listingValue.trim().toLowerCase();
    final normalizedSelected = selectedValue.trim().toLowerCase();
    if (normalizedListing == normalizedSelected) {
      return true;
    }

    final selectedLabel = _locationLabelForId(
      selectedValue,
    ).trim().toLowerCase();
    return selectedLabel.isNotEmpty && normalizedListing == selectedLabel;
  }

  bool _matchesQuickFilter(FeaturedListingData listing, String? filter) {
    if (filter == null || filter.isEmpty) {
      return true;
    }

    final normalizedFilter = filter.toLowerCase();
    final listingKeywords = [
      ...listing.keywords,
      listing.title,
      listing.location,
      listing.address,
    ].map((value) => value.toLowerCase());

    return listingKeywords.any((value) => value.contains(normalizedFilter));
  }

  List<String> _sortedValues(Iterable<String> values) {
    final uniqueValues = values.toSet().toList(growable: false)..sort();
    return uniqueValues;
  }

  List<DhakaDivisionOption> _sortDhakaDivisions(
    List<DhakaDivisionOption> divisions,
  ) {
    return [...divisions]..sort(
      (first, second) => first.displayOrder.compareTo(second.displayOrder),
    );
  }

  List<DhakaAreaOption> _sortDhakaAreas(List<DhakaAreaOption> areas) {
    return [...areas]..sort(
      (first, second) => first.displayOrder.compareTo(second.displayOrder),
    );
  }

  String locationLabelForFilter(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }

    return _locationLabelForId(value);
  }

  String _locationLabelForId(String value) {
    for (final division in _dhakaDivisions) {
      if (division.id == value) {
        return division.nameBn.isEmpty ? division.id : division.nameBn;
      }
    }

    for (final area in _dhakaAreas) {
      if (area.id == value) {
        return area.nameBn.isEmpty ? area.id : area.nameBn;
      }
    }

    return value;
  }

  List<PaymentMethodOption> get paymentMethods => const [
    PaymentMethodOption(
      label: 'bKash',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFFE2136E),
    ),
    PaymentMethodOption(
      label: 'Nagad',
      icon: Icons.wallet_rounded,
      color: Color(0xFFF97316),
    ),
    PaymentMethodOption(
      label: 'Card',
      icon: Icons.credit_card_rounded,
      color: Color(0xFF1E40AF),
    ),
  ];

  List<String> get rentPaymentMethodLabels => const [
    'Cash',
    'bKash',
    'Nagad',
    'Rocket',
  ];

  List<String> get rentPaymentTypeLabels => const [
    'Vara',
    'Advance',
    'Utility Bill',
    'Gas Bill',
    'Pani Bill',
  ];

  List<String> get rentPaymentMonthNames => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  List<int> get rentPaymentYears {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - 2 + index);
  }

  List<TenantRentPaymentEntry> get rentPaymentEntries =>
      List.unmodifiable(_rentPaymentEntries);

  List<MaintenanceCategoryOption> get maintenanceCategories => const [
    MaintenanceCategoryOption(
      id: 'plumbing',
      label: 'Plumbing',
      icon: Icons.plumbing_rounded,
    ),
    MaintenanceCategoryOption(
      id: 'electrical',
      label: 'Electrical',
      icon: Icons.electrical_services_rounded,
    ),
    MaintenanceCategoryOption(
      id: 'cleaning',
      label: 'Cleaning',
      icon: Icons.cleaning_services_rounded,
    ),
    MaintenanceCategoryOption(
      id: 'others',
      label: 'Others',
      icon: Icons.more_horiz_rounded,
    ),
  ];

  List<RentPayment> get paymentHistory => _repository.payments
      .where((payment) => payment.status == PaymentStatus.paid)
      .where(
        (payment) =>
            payment.propertyName == activeTenant.propertyName ||
            payment.tenantName == activeTenant.name,
      )
      .toList(growable: false);

  List<AgreementFieldData> get paymentBreakdown => const [
    AgreementFieldData(
      label: 'Rent',
      primaryValue: '৳15,000 / month',
      secondaryValue: 'Due on 05 Mar',
    ),
    AgreementFieldData(
      label: 'Advance Payment',
      primaryValue: '৳45,000',
      secondaryValue: 'Paid on 01 Mar',
    ),
    AgreementFieldData(
      label: 'Duration',
      primaryValue: '11 months',
      secondaryValue: 'Renewable',
    ),
    AgreementFieldData(
      label: 'Utility Deposit',
      primaryValue: '৳8,000',
      secondaryValue: 'Refundable',
    ),
  ];

  List<AgreementFieldData> get agreementPreviewFields => const [
    AgreementFieldData(
      label: 'Property',
      primaryValue: '2 Bed Flat - Mirpur 10',
      secondaryValue: 'Floor 4B, Road 12',
    ),
    AgreementFieldData(
      label: 'Tenant',
      primaryValue: 'Rafiq Ahmed',
      secondaryValue: 'NID verified',
    ),
    AgreementFieldData(
      label: 'Owner',
      primaryValue: 'Omer Hasan',
      secondaryValue: 'Verified profile',
    ),
    AgreementFieldData(
      label: 'Monthly Rent',
      primaryValue: '৳15,000',
      secondaryValue: 'Service charge included',
    ),
    AgreementFieldData(
      label: 'Advance',
      primaryValue: '৳45,000',
      secondaryValue: '3 months equivalent',
    ),
    AgreementFieldData(
      label: 'Move-in',
      primaryValue: '01 March 2026',
      secondaryValue: 'Agreement period active',
    ),
  ];

  List<MonthlyBillEntryData> get monthlyBillEntries => const [
    MonthlyBillEntryData(
      title: 'Electricity Bill',
      amountLabel: '৳29.00',
      timeLabel: '18:55',
      icon: Icons.bolt_rounded,
      color: Color(0xFFF59E0B),
    ),
    MonthlyBillEntryData(
      title: 'Water Bills',
      amountLabel: '৳29.00',
      timeLabel: '17:18',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0EA5E9),
    ),
    MonthlyBillEntryData(
      title: 'Gas Bill',
      amountLabel: '৳29.00',
      timeLabel: '19:18',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFF97316),
    ),
    MonthlyBillEntryData(
      title: 'Security Guard',
      amountLabel: '৳29.00',
      timeLabel: '13:51',
      icon: Icons.shield_outlined,
      color: Color(0xFF2563EB),
    ),
    MonthlyBillEntryData(
      title: 'Other Charges',
      amountLabel: '৳29.00',
      timeLabel: '15:50',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF8B5CF6),
    ),
  ];

  List<ContactShortcutData> get ownerActions => const [
    ContactShortcutData(
      label: 'Call Room',
      icon: Icons.call_rounded,
      color: Colors.white,
      backgroundColor: AppColors.primary,
    ),
    ContactShortcutData(
      label: 'WhatsApp',
      icon: Icons.chat_rounded,
      color: AppColors.primary,
      backgroundColor: Color(0xFFEFF4FF),
    ),
  ];

  List<ContactShortcutData> get moveInActions => const [
    ContactShortcutData(
      label: 'Location',
      icon: Icons.map_rounded,
      color: AppColors.primary,
      backgroundColor: Color(0xFFEFF4FF),
    ),
    ContactShortcutData(
      label: 'Chat',
      icon: Icons.chat_bubble_rounded,
      color: AppColors.primary,
      backgroundColor: Color(0xFFEFF4FF),
    ),
    ContactShortcutData(
      label: 'Call',
      icon: Icons.call_rounded,
      color: AppColors.primary,
      backgroundColor: Color(0xFFEFF4FF),
    ),
  ];

  int get totalPaidThisYear =>
      paymentHistory.fold<int>(0, (sum, item) => sum + item.amount);

  String get selectedMaintenanceCategory => _selectedMaintenanceCategory;
  String get issueDescription => _issueDescription;

  void selectMaintenanceCategory(String categoryId) {
    if (_selectedMaintenanceCategory == categoryId) {
      return;
    }

    _selectedMaintenanceCategory = categoryId;
    notifyListeners();
  }

  void updateIssueDescription(String value) {
    _issueDescription = value;
    notifyListeners();
  }

  Future<TenantPaymentConfirmationResult?> confirmRentPayment({
    required String ownerName,
    required String monthName,
    required int year,
    required List<String> paymentTypes,
    required int amount,
    required String method,
  }) async {
    final tenant = activeTenant;
    if (tenant.id.isEmpty) {
      _rentPaymentSubmitError = 'Active tenant profile was not found.';
      notifyListeners();
      return null;
    }

    _isSubmittingRentPayment = true;
    _rentPaymentSubmitError = null;
    notifyListeners();

    try {
      final result = await _tenantPaymentApiService.confirmPayment(
        tenantId: tenant.id,
        monthLabel: '$monthName $year',
        amount: amount,
        paymentMethod: method,
        paymentTypes: paymentTypes,
      );

      _upsertRepositoryPayment(result.payment);
      _updateRepositoryProperty(
        propertyName: result.propertyName,
        dueAmount: result.dueAmount,
        tenantName: result.payment.tenantName,
      );

      _rentPaymentEntries.insert(
        0,
        TenantRentPaymentEntry(
          ownerName: ownerName,
          monthName: monthName,
          year: year,
          paymentTypes: List.unmodifiable(paymentTypes),
          amount: amount,
          method: method,
          paidAt: result.payment.paidOn ?? DateTime.now(),
        ),
      );

      return result;
    } on TenantPaymentApiException catch (error) {
      _rentPaymentSubmitError = error.message;
      return null;
    } catch (e) {
      _rentPaymentSubmitError =
          'Unable to confirm payment: $e';
      return null;
    } finally {
      _isSubmittingRentPayment = false;
      notifyListeners();
    }
  }

  void _upsertRepositoryPayment(RentPayment payment) {
    final paymentIndex = _repository.payments.indexWhere(
      (item) =>
          item.propertyName == payment.propertyName &&
          item.monthLabel == payment.monthLabel,
    );

    if (paymentIndex == -1) {
      _repository.payments.insert(0, payment);
      return;
    }

    _repository.payments[paymentIndex] = payment;
  }

  void _updateRepositoryProperty({
    required String propertyName,
    required int dueAmount,
    required String tenantName,
  }) {
    final propertyIndex = _repository.properties.indexWhere(
      (property) => property.name == propertyName,
    );
    if (propertyIndex == -1) {
      return;
    }

    final property = _repository.properties[propertyIndex];
    _repository.properties[propertyIndex] = PropertyUnit(
      id: property.id,
      name: property.name,
      location: property.location,
      monthlyRent: property.monthlyRent,
      status: PropertyStatus.rented,
      tenantName: tenantName,
      dueAmount: dueAmount,
      buildingId: property.buildingId,
      buildingName: property.buildingName,
      floorId: property.floorId,
      floorLabel: property.floorLabel,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tenantPaymentApiService.dispose();
    _ownerPostApiService.dispose();
    _dhakaLocationApiService.dispose();
    _announcementApiService.dispose();
    _generalPostApiService.dispose();
    super.dispose();
  }
}

class MarketplaceLocationOption {
  const MarketplaceLocationOption({required this.id, required this.labelBn});

  final String id;
  final String labelBn;
}
