import 'package:flutter_test/flutter_test.dart';
import 'package:varatia_management_apps/data/models/tutor_bdjobs_profile.dart';

void main() {
  group('TutorBdjobsProfile Scoring & Logic Tests', () {
    test('Default empty profile has score of 5 (due to default city) and missing items', () {
      const profile = TutorBdjobsProfile();
      // Default city is 'Dhaka' (+5)
      expect(profile.completionScore, equals(5));
      expect(profile.missingItems.isNotEmpty, isTrue);
      expect(profile.progressRatio, equals(0.05));
    });

    test('Personal info fields calculate 20% total', () {
      const profile = TutorBdjobsProfile(
        city: '',
        fullName: 'মোঃ তানভীর হাসান',
        phoneNumber: '01712345678',
        gender: 'পুরুষ',
      );
      // 8 + 6 + 6 = 20
      expect(profile.completionScore, equals(20));
    });

    test('Higher education fields calculate 25% total', () {
      const profile = TutorBdjobsProfile(
        city: '',
        universityType: 'Public University',
        universityName: 'ঢাকা বিশ্ববিদ্যালয় (DU)',
        department: 'কম্পিউটার সায়েন্স অ্যান্ড ইঞ্জিনিয়ারিং (CSE)',
      );
      // 10 + 8 + 7 = 25
      expect(profile.completionScore, equals(25));
    });

    test('Preferred locations calculate 10% for one, 15% for two or more', () {
      const profileOne = TutorBdjobsProfile(
        city: '',
        preferredLocations: ['Airport Area'],
      );
      expect(profileOne.completionScore, equals(10));

      const profileTwo = TutorBdjobsProfile(
        city: '',
        preferredLocations: ['Airport Area', 'Mirpur 10'],
      );
      expect(profileTwo.completionScore, equals(15));
    });

    test('Fully completed profile reaches 100% score and zero missing items', () {
      final profile = const TutorBdjobsProfile(
        fullName: 'তানভীর হাসান',
        phoneNumber: '01712345678',
        gender: 'পুরুষ',
        city: 'Dhaka',
        currentLocation: 'Airport Area',
        universityType: 'Public University',
        universityName: 'ঢাকা বিশ্ববিদ্যালয় (DU)',
        department: 'গণিত (Mathematics)',
        sscMedium: 'বাংলা মাধ্যম (Bangla Medium)',
        preferredLocations: ['Airport Area', 'Uttara Sector 7', 'Mirpur 10'],
        preferredSubjects: ['সকল বিষয়', 'গণিত'],
        classesToTeach: ['৯ম-১০ম (SSC)', 'একাদশ-দ্বাদশ (HSC)'],
        expectedFee: '৳ ৫,০০০ - ৮,০০০',
        daysPerWeek: '৩ দিন / সপ্তাহ',
      );

      expect(profile.completionScore, equals(100));
      expect(profile.progressRatio, equals(1.0));
      expect(profile.scoreLevelBn, equals('সম্পূর্ণ প্রোফাইল (১০০%)'));
      expect(profile.missingItems.isEmpty, isTrue);
    });

    test('JSON serialization roundtrip works accurately', () {
      final profile = const TutorBdjobsProfile(
        fullName: 'সাবরিনা আক্তার',
        phoneNumber: '01987654321',
        gender: 'নারী',
        city: 'Dhaka',
        currentLocation: 'Dhanmondi',
        universityType: 'Private University',
        universityName: 'ব্র্যাক ইউনিভার্সিটি (BRACU)',
        department: 'ইংরেজি (English)',
        sscMedium: 'ইংলিশ ভার্সন (English Version)',
        preferredLocations: ['Dhanmondi', 'Mohammadpur'],
        preferredSubjects: ['ইংরেজি'],
        classesToTeach: ['ক্লাস ৬-৮'],
        expectedFee: '৳ ৮,০০০ - ১২,০০০',
        daysPerWeek: '৪ দিন / সপ্তাহ',
      );

      final json = profile.toJson();
      final restored = TutorBdjobsProfile.fromJson(json);

      expect(restored.fullName, equals(profile.fullName));
      expect(restored.phoneNumber, equals(profile.phoneNumber));
      expect(restored.gender, equals(profile.gender));
      expect(restored.currentLocation, equals(profile.currentLocation));
      expect(restored.universityType, equals(profile.universityType));
      expect(restored.universityName, equals(profile.universityName));
      expect(restored.department, equals(profile.department));
      expect(restored.sscMedium, equals(profile.sscMedium));
      expect(restored.preferredLocations, equals(profile.preferredLocations));
      expect(restored.preferredSubjects, equals(profile.preferredSubjects));
      expect(restored.expectedFee, equals(profile.expectedFee));
      expect(restored.completionScore, equals(profile.completionScore));
    });
  });
}
