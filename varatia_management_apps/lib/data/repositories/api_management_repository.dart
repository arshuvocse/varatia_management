import '../models/app_models.dart';
import '../models/management_snapshot.dart';
import 'management_repository.dart';

class ApiManagementRepository implements ManagementRepository {
  ApiManagementRepository(this._snapshot);

  final ManagementSnapshot _snapshot;

  @override
  DashboardSummary get dashboardSummary => _snapshot.dashboardSummary;

  @override
  List<ActivityItem> get recentActivities => _snapshot.recentActivities;

  @override
  List<BuildingBlock> get buildings => _snapshot.buildings;

  @override
  List<BuildingFloor> get floors => _snapshot.floors;

  @override
  List<PropertyUnit> get properties => _snapshot.properties;

  @override
  List<TenantProfile> get tenants => _snapshot.tenants;

  @override
  List<RentPayment> get payments => _snapshot.payments;

  @override
  List<ExpenseItem> get expenses => _snapshot.expenses;

  @override
  List<AppNotificationItem> get notifications => _snapshot.notifications;

  @override
  List<CommunicationEntry> get messages => _snapshot.messages;

  @override
  List<MonthlyMetric> get incomeMetrics => _snapshot.incomeMetrics;

  @override
  List<MonthlyMetric> get expenseMetrics => _snapshot.expenseMetrics;
}
