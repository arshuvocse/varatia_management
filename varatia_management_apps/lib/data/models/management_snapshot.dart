import 'app_models.dart';

class ManagementSnapshot {
  const ManagementSnapshot({
    required this.dashboardSummary,
    required this.recentActivities,
    required this.buildings,
    required this.floors,
    required this.properties,
    required this.tenants,
    required this.payments,
    required this.expenses,
    required this.notifications,
    required this.messages,
    required this.incomeMetrics,
    required this.expenseMetrics,
  });

  factory ManagementSnapshot.fromJson(Map<String, dynamic> json) {
    return ManagementSnapshot(
      dashboardSummary: DashboardSummary(
        totalProperties: _readInt(json['dashboardSummary'], 'totalProperties'),
        totalTenants: _readInt(json['dashboardSummary'], 'totalTenants'),
        monthlyIncome: _readInt(json['dashboardSummary'], 'monthlyIncome'),
        dueRent: _readInt(json['dashboardSummary'], 'dueRent'),
      ),
      recentActivities: _readList(
        json,
        'recentActivities',
        (item) => ActivityItem(
          title: item['title'] as String,
          subtitle: item['subtitle'] as String,
          timeLabel: item['timeLabel'] as String,
        ),
      ),
      buildings: _readList(
        json,
        'buildings',
        (item) => BuildingBlock(
          id: item['id'] as String,
          name: item['name'] as String,
          totalFloors: (item['totalFloors'] as num).toInt(),
          location: item['location'] as String,
        ),
      ),
      floors: _readList(
        json,
        'floors',
        (item) => BuildingFloor(
          id: item['id'] as String,
          buildingId: item['buildingId'] as String,
          label: item['label'] as String,
          totalUnits: (item['totalUnits'] as num).toInt(),
        ),
      ),
      properties: _readList(
        json,
        'properties',
        (item) => PropertyUnit(
          id: item['id'] as String,
          name: item['name'] as String,
          location: item['location'] as String,
          monthlyRent: (item['monthlyRent'] as num).toInt(),
          status: _propertyStatusFromValue(item['status'] as String),
          tenantName: item['tenantName'] as String?,
          dueAmount: (item['dueAmount'] as num?)?.toInt() ?? 0,
          buildingId: item['buildingId'] as String?,
          buildingName: item['buildingName'] as String?,
          floorId: item['floorId'] as String?,
          floorLabel: item['floorLabel'] as String?,
        ),
      ),
      tenants: _readList(
        json,
        'tenants',
        (item) => TenantProfile(
          id: item['id'] as String,
          name: item['name'] as String,
          phone: item['phone'] as String,
          nid: item['nid'] as String,
          propertyName: item['propertyName'] as String,
          propertyId: _readOptionalString(item, 'propertyId'),
          location: _readOptionalString(item, 'location'),
          buildingId: _readOptionalString(item, 'buildingId'),
          buildingName: _readOptionalString(item, 'buildingName'),
          floorId: _readOptionalString(item, 'floorId'),
          floorLabel: _readOptionalString(item, 'floorLabel'),
        ),
      ),
      payments: _readList(
        json,
        'payments',
        (item) => RentPayment(
          propertyName: item['propertyName'] as String,
          tenantName: item['tenantName'] as String,
          monthLabel: item['monthLabel'] as String,
          amount: (item['amount'] as num).toInt(),
          status: _paymentStatusFromValue(item['status'] as String),
          paidOn: item['paidOn'] == null
              ? null
              : DateTime.parse(item['paidOn'] as String),
        ),
      ),
      expenses: _readList(
        json,
        'expenses',
        (item) => ExpenseItem(
          id: (item['id'] as num?)?.toInt() ?? 0,
          title: item['title'] as String,
          category: item['category'] as String,
          amount: (item['amount'] as num).toInt(),
          monthLabel: item['monthLabel'] as String,
        ),
      ),
      notifications: _readList(
        json,
        'notifications',
        (item) => AppNotificationItem(
          id: (item['id'] as num?)?.toInt() ?? 0,
          title: item['title'] as String,
          subtitle: item['subtitle'] as String,
          createdAt: DateTime.parse(item['createdAt'] as String),
          isUnread: item['isUnread'] as bool? ?? false,
        ),
      ),
      messages: _readList(
        json,
        'messages',
        (item) => CommunicationEntry(
          id: (item['id'] as num?)?.toInt() ?? 0,
          sender: item['sender'] as String,
          message: item['message'] as String,
          propertyName: item['propertyName'] as String,
          timeLabel: item['timeLabel'] as String,
        ),
      ),
      incomeMetrics: _readList(
        json,
        'incomeMetrics',
        (item) => MonthlyMetric(
          label: item['label'] as String,
          value: (item['value'] as num).toDouble(),
        ),
      ),
      expenseMetrics: _readList(
        json,
        'expenseMetrics',
        (item) => MonthlyMetric(
          label: item['label'] as String,
          value: (item['value'] as num).toDouble(),
        ),
      ),
    );
  }

  final DashboardSummary dashboardSummary;
  final List<ActivityItem> recentActivities;
  final List<BuildingBlock> buildings;
  final List<BuildingFloor> floors;
  final List<PropertyUnit> properties;
  final List<TenantProfile> tenants;
  final List<RentPayment> payments;
  final List<ExpenseItem> expenses;
  final List<AppNotificationItem> notifications;
  final List<CommunicationEntry> messages;
  final List<MonthlyMetric> incomeMetrics;
  final List<MonthlyMetric> expenseMetrics;

  static List<T> _readList<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic> item) mapper,
  ) {
    final rawList = json[key] as List<dynamic>? ?? const [];
    return rawList.cast<Map<String, dynamic>>().map(mapper).toList();
  }

  static int _readInt(Object? rawObject, String key) {
    final map = rawObject as Map<String, dynamic>;
    return (map[key] as num).toInt();
  }

  static String? _readOptionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    return null;
  }

  static PropertyStatus _propertyStatusFromValue(String value) {
    return switch (value.toLowerCase()) {
      'rented' => PropertyStatus.rented,
      _ => PropertyStatus.available,
    };
  }

  static PaymentStatus _paymentStatusFromValue(String value) {
    return switch (value.toLowerCase()) {
      'paid' => PaymentStatus.paid,
      _ => PaymentStatus.due,
    };
  }
}
