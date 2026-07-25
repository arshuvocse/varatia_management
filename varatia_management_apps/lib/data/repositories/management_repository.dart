import '../models/app_models.dart';

abstract class ManagementRepository {
  DashboardSummary get dashboardSummary;
  List<ActivityItem> get recentActivities;
  List<BuildingBlock> get buildings;
  List<BuildingFloor> get floors;
  List<PropertyUnit> get properties;
  List<TenantProfile> get tenants;
  List<RentPayment> get payments;
  List<ExpenseItem> get expenses;
  List<AppNotificationItem> get notifications;
  List<CommunicationEntry> get messages;
  List<MonthlyMetric> get incomeMetrics;
  List<MonthlyMetric> get expenseMetrics;
}

class MockManagementRepository implements ManagementRepository {
  @override
  final DashboardSummary dashboardSummary = const DashboardSummary(
    totalProperties: 10,
    totalTenants: 25,
    monthlyIncome: 50000,
    dueRent: 8000,
  );

  @override
  final List<ActivityItem> recentActivities = const [
    ActivityItem(
      title: 'ভাড়া পরিশোধ হয়েছে',
      subtitle: 'ফ্ল্যাট A এর এপ্রিল মাসের ভাড়া জমা পড়েছে',
      timeLabel: 'আজ',
    ),
    ActivityItem(
      title: 'নতুন ভাড়াটিয়া যোগ হয়েছে',
      subtitle: 'ফ্ল্যাট C তে নুসরাতের প্রোফাইল যোগ করা হয়েছে',
      timeLabel: 'আজ',
    ),
    ActivityItem(
      title: 'ডিউ রেন্ট রিমাইন্ডার পাঠানো হয়েছে',
      subtitle: 'ফ্ল্যাট B এবং ফ্ল্যাট J এর জন্য বকেয়া নোটিফিকেশন গেছে',
      timeLabel: 'গতকাল',
    ),
  ];

  @override
  final List<BuildingBlock> buildings = const [
    BuildingBlock(
      id: 'B-01',
      name: 'Building A',
      totalFloors: 5,
      location: 'ধানমন্ডি, ঢাকা',
    ),
    BuildingBlock(
      id: 'B-02',
      name: 'Building B',
      totalFloors: 3,
      location: 'মিরপুর, ঢাকা',
    ),
  ];

  @override
  final List<BuildingFloor> floors = const [
    BuildingFloor(
      id: 'F-01',
      buildingId: 'B-01',
      label: 'Floor 1',
      totalUnits: 2,
    ),
    BuildingFloor(
      id: 'F-02',
      buildingId: 'B-01',
      label: 'Floor 2',
      totalUnits: 2,
    ),
    BuildingFloor(
      id: 'F-03',
      buildingId: 'B-01',
      label: 'Floor 3',
      totalUnits: 1,
    ),
    BuildingFloor(
      id: 'F-04',
      buildingId: 'B-01',
      label: 'Floor 4',
      totalUnits: 1,
    ),
    BuildingFloor(
      id: 'F-05',
      buildingId: 'B-01',
      label: 'Floor 5',
      totalUnits: 1,
    ),
    BuildingFloor(
      id: 'F-06',
      buildingId: 'B-02',
      label: 'Floor 1',
      totalUnits: 1,
    ),
    BuildingFloor(
      id: 'F-07',
      buildingId: 'B-02',
      label: 'Floor 2',
      totalUnits: 1,
    ),
    BuildingFloor(
      id: 'F-08',
      buildingId: 'B-02',
      label: 'Floor 3',
      totalUnits: 1,
    ),
  ];

  @override
  final List<PropertyUnit> properties = const [
    PropertyUnit(
      id: 'P-01',
      name: 'Flat A',
      location: 'ধানমন্ডি, ঢাকা',
      monthlyRent: 5000,
      status: PropertyStatus.rented,
      tenantName: 'রহিম',
      buildingId: 'B-01',
      buildingName: 'Building A',
      floorId: 'F-01',
      floorLabel: 'Floor 1',
    ),
    PropertyUnit(
      id: 'P-02',
      name: 'Flat B',
      location: 'ধানমন্ডি, ঢাকা',
      monthlyRent: 4500,
      status: PropertyStatus.available,
      dueAmount: 4500,
      buildingId: 'B-01',
      buildingName: 'Building A',
      floorId: 'F-01',
      floorLabel: 'Floor 1',
    ),
    PropertyUnit(
      id: 'P-03',
      name: 'Flat C',
      location: 'ধানমন্ডি, ঢাকা',
      monthlyRent: 6000,
      status: PropertyStatus.rented,
      tenantName: 'নুসরাত',
      buildingId: 'B-01',
      buildingName: 'Building A',
      floorId: 'F-02',
      floorLabel: 'Floor 2',
    ),
    PropertyUnit(
      id: 'P-04',
      name: 'Flat D',
      location: 'ধানমন্ডি, ঢাকা',
      monthlyRent: 5500,
      status: PropertyStatus.rented,
      tenantName: 'করিম',
      buildingId: 'B-01',
      buildingName: 'Building A',
      floorId: 'F-02',
      floorLabel: 'Floor 2',
    ),
    PropertyUnit(
      id: 'P-05',
      name: 'Flat E',
      location: 'ধানমন্ডি, ঢাকা',
      monthlyRent: 4800,
      status: PropertyStatus.rented,
      tenantName: 'সালমা',
      buildingId: 'B-01',
      buildingName: 'Building A',
      floorId: 'F-03',
      floorLabel: 'Floor 3',
    ),
    PropertyUnit(
      id: 'P-06',
      name: 'Flat F',
      location: 'ধানমন্ডি, ঢাকা',
      monthlyRent: 5200,
      status: PropertyStatus.rented,
      tenantName: 'হাসান',
      buildingId: 'B-01',
      buildingName: 'Building A',
      floorId: 'F-04',
      floorLabel: 'Floor 4',
    ),
    PropertyUnit(
      id: 'P-07',
      name: 'Flat G',
      location: 'ধানমন্ডি, ঢাকা',
      monthlyRent: 6200,
      status: PropertyStatus.rented,
      tenantName: 'মিতু',
      buildingId: 'B-01',
      buildingName: 'Building A',
      floorId: 'F-05',
      floorLabel: 'Floor 5',
    ),
    PropertyUnit(
      id: 'P-08',
      name: 'Flat H',
      location: 'মিরপুর, ঢাকা',
      monthlyRent: 5300,
      status: PropertyStatus.rented,
      tenantName: 'জয়',
      buildingId: 'B-02',
      buildingName: 'Building B',
      floorId: 'F-06',
      floorLabel: 'Floor 1',
    ),
    PropertyUnit(
      id: 'P-09',
      name: 'Flat I',
      location: 'মিরপুর, ঢাকা',
      monthlyRent: 4000,
      status: PropertyStatus.rented,
      tenantName: 'মেহেদী',
      buildingId: 'B-02',
      buildingName: 'Building B',
      floorId: 'F-07',
      floorLabel: 'Floor 2',
    ),
    PropertyUnit(
      id: 'P-10',
      name: 'Flat J',
      location: 'মিরপুর, ঢাকা',
      monthlyRent: 3500,
      status: PropertyStatus.available,
      dueAmount: 3500,
      buildingId: 'B-02',
      buildingName: 'Building B',
      floorId: 'F-08',
      floorLabel: 'Floor 3',
    ),
  ];

  @override
  final List<TenantProfile> tenants = const [
    TenantProfile(
      id: 'T-01',
      name: 'রহিম',
      phone: '01711111111',
      nid: '1991234567890',
      propertyName: 'Flat A',
    ),
    TenantProfile(
      id: 'T-02',
      name: 'করিম',
      phone: '01811111111',
      nid: '1987654321234',
      propertyName: 'Flat D',
    ),
    TenantProfile(
      id: 'T-03',
      name: 'নুসরাত',
      phone: '01911111111',
      nid: '2001123412341',
      propertyName: 'Flat C',
    ),
    TenantProfile(
      id: 'T-04',
      name: 'সালমা',
      phone: '01611111111',
      nid: '1998765432198',
      propertyName: 'Flat E',
    ),
    TenantProfile(
      id: 'T-05',
      name: 'হাসান',
      phone: '01722222222',
      nid: '1994321012345',
      propertyName: 'Flat F',
    ),
    TenantProfile(
      id: 'T-06',
      name: 'মিতু',
      phone: '01822222222',
      nid: '2000234512345',
      propertyName: 'Flat G',
    ),
  ];

  @override
  final List<RentPayment> payments = [
    RentPayment(
      propertyName: 'Flat A',
      tenantName: 'রহিম',
      monthLabel: 'এপ্রিল ২০২৬',
      amount: 5000,
      status: PaymentStatus.paid,
      paidOn: DateTime(2026, 4, 3),
    ),
    const RentPayment(
      propertyName: 'Flat B',
      tenantName: 'খালি',
      monthLabel: 'এপ্রিল ২০২৬',
      amount: 4500,
      status: PaymentStatus.due,
    ),
    RentPayment(
      propertyName: 'Flat C',
      tenantName: 'নুসরাত',
      monthLabel: 'এপ্রিল ২০২৬',
      amount: 6000,
      status: PaymentStatus.paid,
      paidOn: DateTime(2026, 4, 5),
    ),
    RentPayment(
      propertyName: 'Flat D',
      tenantName: 'করিম',
      monthLabel: 'এপ্রিল ২০২৬',
      amount: 5500,
      status: PaymentStatus.paid,
      paidOn: DateTime(2026, 4, 7),
    ),
    const RentPayment(
      propertyName: 'Flat J',
      tenantName: 'খালি',
      monthLabel: 'এপ্রিল ২০২৬',
      amount: 3500,
      status: PaymentStatus.due,
    ),
  ];

  @override
  final List<ExpenseItem> expenses = const [
    ExpenseItem(
      title: 'বিদ্যুৎ বিল',
      category: 'ইউটিলিটি',
      amount: 2000,
      monthLabel: 'এপ্রিল ২০২৬',
    ),
    ExpenseItem(
      title: 'গ্যাস বিল',
      category: 'ইউটিলিটি',
      amount: 1000,
      monthLabel: 'এপ্রিল ২০২৬',
    ),
    ExpenseItem(
      title: 'সিকিউরিটি',
      category: 'সার্ভিস',
      amount: 1500,
      monthLabel: 'এপ্রিল ২০২৬',
    ),
    ExpenseItem(
      title: 'ক্লিনিং',
      category: 'মেইনটেন্যান্স',
      amount: 800,
      monthLabel: 'এপ্রিল ২০২৬',
    ),
  ];

  @override
  final List<AppNotificationItem> notifications = [
    AppNotificationItem(
      title: 'বকেয়া ভাড়ার রিমাইন্ডার পাঠানো হয়েছে',
      subtitle: 'ফ্ল্যাট B এর জন্য অটো-রিমাইন্ডার পাঠানো হয়েছে',
      createdAt: DateTime(2026, 4, 14, 9, 15),
      isUnread: true,
    ),
    AppNotificationItem(
      title: 'পেমেন্ট রিসিভড অ্যালার্ট',
      subtitle: 'ফ্ল্যাট A এর এপ্রিল মাসের পেমেন্ট নিশ্চিত হয়েছে',
      createdAt: DateTime(2026, 4, 14, 8, 30),
    ),
    AppNotificationItem(
      title: 'নতুন টেন্যান্ট প্রোফাইল সম্পন্ন হয়েছে',
      subtitle: 'নুসরাতের ডকুমেন্ট ভেরিফিকেশন শেষ হয়েছে',
      createdAt: DateTime(2026, 4, 13, 16, 20),
    ),
  ];

  @override
  final List<CommunicationEntry> messages = const [
    CommunicationEntry(
      sender: 'রহিম',
      message: 'ভাড়া পরিশোধ করা হয়েছে। দেখে নেবেন।',
      propertyName: 'Flat A',
      timeLabel: '10:15 AM',
    ),
    CommunicationEntry(
      sender: 'করিম',
      message: 'কিচেনের ট্যাপে মেইনটেন্যান্স লাগবে।',
      propertyName: 'Flat D',
      timeLabel: '09:40 AM',
    ),
    CommunicationEntry(
      sender: 'সালমা',
      message: 'গ্যাস বিলের কপি পাঠিয়ে দেবেন?',
      propertyName: 'Flat E',
      timeLabel: 'গতকাল',
    ),
  ];

  @override
  final List<MonthlyMetric> incomeMetrics = const [
    MonthlyMetric(label: 'Nov', value: 42000),
    MonthlyMetric(label: 'Dec', value: 44000),
    MonthlyMetric(label: 'Jan', value: 46000),
    MonthlyMetric(label: 'Feb', value: 47500),
    MonthlyMetric(label: 'Mar', value: 49000),
    MonthlyMetric(label: 'Apr', value: 50000),
  ];

  @override
  final List<MonthlyMetric> expenseMetrics = const [
    MonthlyMetric(label: 'Nov', value: 3200),
    MonthlyMetric(label: 'Dec', value: 3600),
    MonthlyMetric(label: 'Jan', value: 4100),
    MonthlyMetric(label: 'Feb', value: 3900),
    MonthlyMetric(label: 'Mar', value: 4500),
    MonthlyMetric(label: 'Apr', value: 5300),
  ];
}
