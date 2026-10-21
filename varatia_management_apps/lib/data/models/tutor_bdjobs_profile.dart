import 'package:flutter/material.dart';

class MissingProfileItem {
  const MissingProfileItem({
    required this.key,
    required this.titleBn,
    required this.titleEn,
    required this.weight,
    required this.icon,
  });

  final String key;
  final String titleBn;
  final String titleEn;
  final int weight;
  final IconData icon;
}

class TutorBdjobsProfile {
  const TutorBdjobsProfile({
    this.fullName = '',
    this.phoneNumber = '',
    this.gender = '',
    this.city = 'Dhaka',
    this.currentLocation = '',
    this.universityType = '',
    this.universityName = '',
    this.department = '',
    this.sscMedium = '',
    this.preferredLocations = const <String>[],
    this.preferredSubjects = const <String>[],
    this.classesToTeach = const <String>[],
    this.expectedFee = '',
    this.daysPerWeek = '',
    this.updatedAt,
  });

  final String fullName;
  final String phoneNumber;
  final String gender;
  final String city;
  final String currentLocation;
  final String universityType;
  final String universityName;
  final String department;
  final String sscMedium;
  final List<String> preferredLocations;
  final List<String> preferredSubjects;
  final List<String> classesToTeach;
  final String expectedFee;
  final String daysPerWeek;
  final DateTime? updatedAt;

  /// BDJobs-style completion score from 0 to 100.
  int get completionScore {
    int score = 0;

    // 1. Personal Information (Total: 20%)
    if (fullName.trim().isNotEmpty) score += 8;
    if (phoneNumber.trim().isNotEmpty) score += 6;
    if (gender.trim().isNotEmpty) score += 6;

    // 2. City & Current Location (Total: 15%)
    if (city.trim().isNotEmpty) score += 5;
    if (currentLocation.trim().isNotEmpty) score += 10;

    // 3. Higher Education & University Details (Total: 25%)
    if (universityType.trim().isNotEmpty) score += 10;
    if (universityName.trim().isNotEmpty) score += 8;
    if (department.trim().isNotEmpty) score += 7;

    // 4. Secondary Education / SSC Medium (Total: 15%)
    if (sscMedium.trim().isNotEmpty) score += 15;

    // 5. Preferred Locations (Total: 15%)
    if (preferredLocations.isNotEmpty) {
      score += 10;
      if (preferredLocations.length >= 2) {
        score += 5;
      }
    }

    // 6. Tuition Preferences & Subjects (Total: 10%)
    if (preferredSubjects.isNotEmpty) score += 5;
    if (expectedFee.trim().isNotEmpty || daysPerWeek.trim().isNotEmpty) {
      score += 5;
    }

    if (score > 100) return 100;
    if (score < 0) return 0;
    return score;
  }

  double get progressRatio => completionScore / 100.0;

  String get scoreLevelBn {
    final score = completionScore;
    if (score >= 100) return 'সম্পূর্ণ প্রোফাইল (১০০%)';
    if (score >= 80) return 'খুব ভালো মান';
    if (score >= 60) return 'উন্নত মান';
    if (score >= 40) return 'মাঝারি মান';
    if (score >= 20) return 'প্রাথমিক ধাপ';
    return 'অসম্পূর্ণ প্রোফাইল';
  }

  String get scoreLevelEn {
    final score = completionScore;
    if (score >= 100) return 'Completed Profile (100%)';
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Average';
    if (score >= 20) return 'Basic';
    return 'Incomplete';
  }

  Color get scoreColor {
    final score = completionScore;
    if (score >= 90) return const Color(0xFF059669); // Emerald
    if (score >= 70) return const Color(0xFF2563EB); // Blue
    if (score >= 45) return const Color(0xFFEA580C); // Warm Orange
    return const Color(0xFFE11D48); // Rose
  }

  List<Color> get scoreGradientColors {
    final score = completionScore;
    if (score >= 90) {
      return const [Color(0xFF059669), Color(0xFF10B981)];
    }
    if (score >= 70) {
      return const [Color(0xFF2563EB), Color(0xFF3B82F6)];
    }
    if (score >= 45) {
      return const [Color(0xFFEA580C), Color(0xFFF59E0B)];
    }
    return const [Color(0xFFE11D48), Color(0xFFF43F5E)];
  }

  List<MissingProfileItem> get missingItems {
    final list = <MissingProfileItem>[];

    if (universityType.trim().isEmpty ||
        universityName.trim().isEmpty ||
        department.trim().isEmpty) {
      list.add(
        const MissingProfileItem(
          key: 'university',
          titleBn: 'বিশ্ববিদ্যালয় ও ডিপার্টমেন্ট যুক্ত করুন',
          titleEn: 'Add University & Department',
          weight: 25,
          icon: Icons.school_rounded,
        ),
      );
    }

    if (preferredLocations.isEmpty) {
      list.add(
        const MissingProfileItem(
          key: 'preferred_locations',
          titleBn: 'পছন্দের টিউশন এলাকা যোগ করুন',
          titleEn: 'Add Preferred Tuition Locations',
          weight: 15,
          icon: Icons.place_rounded,
        ),
      );
    } else if (preferredLocations.length < 2) {
      list.add(
        const MissingProfileItem(
          key: 'more_locations',
          titleBn: 'আরও পছন্দের এলাকা যোগ করুন',
          titleEn: 'Add More Preferred Locations',
          weight: 5,
          icon: Icons.add_location_alt_rounded,
        ),
      );
    }

    if (sscMedium.trim().isEmpty) {
      list.add(
        const MissingProfileItem(
          key: 'ssc_medium',
          titleBn: 'এসএসসি / ও-লেভেল মাধ্যম নির্বাচন করুন',
          titleEn: 'Select SSC / O-Level Medium',
          weight: 15,
          icon: Icons.menu_book_rounded,
        ),
      );
    }

    if (currentLocation.trim().isEmpty) {
      list.add(
        const MissingProfileItem(
          key: 'current_location',
          titleBn: 'আপনার বর্তমান লোকেশন নির্বাচন করুন',
          titleEn: 'Select Current Location',
          weight: 10,
          icon: Icons.my_location_rounded,
        ),
      );
    }

    if (fullName.trim().isEmpty ||
        phoneNumber.trim().isEmpty ||
        gender.trim().isEmpty) {
      list.add(
        const MissingProfileItem(
          key: 'personal',
          titleBn: 'নাম, ফোন ও জেন্ডার সম্পন্ন করুন',
          titleEn: 'Complete Name, Phone & Gender',
          weight: 20,
          icon: Icons.person_rounded,
        ),
      );
    }

    if (preferredSubjects.isEmpty ||
        expectedFee.trim().isEmpty ||
        daysPerWeek.trim().isEmpty) {
      list.add(
        const MissingProfileItem(
          key: 'preferences',
          titleBn: 'পছন্দের বিষয় ও পারিশ্রমিক নির্ধারণ করুন',
          titleEn: 'Set Preferred Subjects & Expected Fee',
          weight: 10,
          icon: Icons.payments_rounded,
        ),
      );
    }

    return list;
  }

  TutorBdjobsProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? gender,
    String? city,
    String? currentLocation,
    String? universityType,
    String? universityName,
    String? department,
    String? sscMedium,
    List<String>? preferredLocations,
    List<String>? preferredSubjects,
    List<String>? classesToTeach,
    String? expectedFee,
    String? daysPerWeek,
    DateTime? updatedAt,
  }) {
    return TutorBdjobsProfile(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      currentLocation: currentLocation ?? this.currentLocation,
      universityType: universityType ?? this.universityType,
      universityName: universityName ?? this.universityName,
      department: department ?? this.department,
      sscMedium: sscMedium ?? this.sscMedium,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      preferredSubjects: preferredSubjects ?? this.preferredSubjects,
      classesToTeach: classesToTeach ?? this.classesToTeach,
      expectedFee: expectedFee ?? this.expectedFee,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'city': city,
      'currentLocation': currentLocation,
      'universityType': universityType,
      'universityName': universityName,
      'department': department,
      'sscMedium': sscMedium,
      'preferredLocations': preferredLocations,
      'preferredSubjects': preferredSubjects,
      'classesToTeach': classesToTeach,
      'expectedFee': expectedFee,
      'daysPerWeek': daysPerWeek,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory TutorBdjobsProfile.fromJson(Map<String, dynamic> json) {
    return TutorBdjobsProfile(
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      city: json['city'] as String? ?? 'Dhaka',
      currentLocation: json['currentLocation'] as String? ?? '',
      universityType: json['universityType'] as String? ?? '',
      universityName: json['universityName'] as String? ?? '',
      department: json['department'] as String? ?? '',
      sscMedium: json['sscMedium'] as String? ?? '',
      preferredLocations:
          (json['preferredLocations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      preferredSubjects:
          (json['preferredSubjects'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      classesToTeach:
          (json['classesToTeach'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      expectedFee: json['expectedFee'] as String? ?? '',
      daysPerWeek: json['daysPerWeek'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
