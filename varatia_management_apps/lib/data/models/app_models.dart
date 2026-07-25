enum PropertyStatus { rented, available }

enum PaymentStatus { paid, due }

class DashboardSummary {
  const DashboardSummary({
    required this.totalProperties,
    required this.totalTenants,
    required this.monthlyIncome,
    required this.dueRent,
  });

  final int totalProperties;
  final int totalTenants;
  final int monthlyIncome;
  final int dueRent;
}

class ActivityItem {
  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
}

class BuildingBlock {
  const BuildingBlock({
    required this.id,
    required this.name,
    required this.totalFloors,
    required this.location,
    this.address,
    this.latitude,
    this.longitude,
    this.zoneId,
    this.zoneName,
    this.stationId,
    this.stationName,
    this.wardId,
    this.wardName,
  });

  final String id;
  final String name;
  final int totalFloors;
  final String location;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? zoneId;
  final String? zoneName;
  final String? stationId;
  final String? stationName;
  final int? wardId;
  final String? wardName;
}

class BuildingFloor {
  const BuildingFloor({
    required this.id,
    required this.buildingId,
    required this.label,
    required this.totalUnits,
  });

  final String id;
  final String buildingId;
  final String label;
  final int totalUnits;
}

class PropertyUnit {
  const PropertyUnit({
    required this.id,
    required this.name,
    required this.location,
    required this.monthlyRent,
    required this.status,
    this.tenantName,
    this.dueAmount = 0,
    this.buildingId,
    this.buildingName,
    this.floorId,
    this.floorLabel,
  });

  final String id;
  final String name;
  final String location;
  final int monthlyRent;
  final PropertyStatus status;
  final String? tenantName;
  final int dueAmount;
  final String? buildingId;
  final String? buildingName;
  final String? floorId;
  final String? floorLabel;
}

class TenantProfile {
  const TenantProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.nid,
    required this.propertyName,
    this.propertyId,
    this.location,
    this.buildingId,
    this.buildingName,
    this.floorId,
    this.floorLabel,
  });

  final String id;
  final String name;
  final String phone;
  final String nid;
  final String propertyName;
  final String? propertyId;
  final String? location;
  final String? buildingId;
  final String? buildingName;
  final String? floorId;
  final String? floorLabel;
}

class RentPayment {
  const RentPayment({
    required this.propertyName,
    required this.tenantName,
    required this.monthLabel,
    required this.amount,
    required this.status,
    this.paidOn,
  });

  final String propertyName;
  final String tenantName;
  final String monthLabel;
  final int amount;
  final PaymentStatus status;
  final DateTime? paidOn;
}

class ExpenseItem {
  const ExpenseItem({
    this.id = 0,
    required this.title,
    required this.category,
    required this.amount,
    required this.monthLabel,
  });

  final int id;
  final String title;
  final String category;
  final int amount;
  final String monthLabel;
}

class AppNotificationItem {
  const AppNotificationItem({
    this.id = 0,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.isUnread = false,
  });

  final int id;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final bool isUnread;
}

class AnnouncementItem {
  const AnnouncementItem({
    this.id = 0,
    required this.message,
    this.linkUrl,
    required this.createdAt,
    this.isActive = true,
  });

  final int id;
  final String message;
  final String? linkUrl;
  final DateTime createdAt;
  final bool isActive;
}

class CommunicationEntry {
  const CommunicationEntry({
    this.id = 0,
    required this.sender,
    required this.message,
    required this.propertyName,
    required this.timeLabel,
  });

  final int id;
  final String sender;
  final String message;
  final String propertyName;
  final String timeLabel;
}

class MonthlyMetric {
  const MonthlyMetric({required this.label, required this.value});

  final String label;
  final double value;
}

class GeneralPostItem {
  const GeneralPostItem({
    required this.id,
    required this.userId,
    required this.category,
    this.tenantType,
    required this.title,
    required this.price,
    this.advance,
    required this.utilityIncluded,
    required this.divisionId,
    required this.divisionNameBn,
    required this.areaId,
    required this.areaNameBn,
    this.fullAddress,
    this.street,
    this.latitude,
    this.longitude,
    required this.bedrooms,
    required this.bathrooms,
    required this.kitchens,
    required this.balconies,
    required this.hasGas,
    required this.hasLift,
    required this.hasGenerator,
    required this.hasParking,
    this.description,
    this.mediaInfo,
    required this.status,
    required this.createdOn,
  });

  final int id;
  final String userId;
  final String category;
  final String? tenantType;
  final String title;
  final double price;
  final double? advance;
  final bool utilityIncluded;
  final String divisionId;
  final String divisionNameBn;
  final String areaId;
  final String areaNameBn;
  final String? fullAddress;
  final String? street;
  final double? latitude;
  final double? longitude;
  final int bedrooms;
  final int bathrooms;
  final int kitchens;
  final int balconies;
  final bool hasGas;
  final bool hasLift;
  final bool hasGenerator;
  final bool hasParking;
  final String? description;
  final String? mediaInfo;
  final String status;
  final DateTime createdOn;
}
