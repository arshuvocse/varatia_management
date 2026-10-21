import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tutor_bdjobs_profile.dart';
import 'auth_session_service.dart';
import 'tenant_tutor_api_service.dart';

class TutorProfileStorageService {
  factory TutorProfileStorageService() => _instance;
  TutorProfileStorageService._internal();
  static final TutorProfileStorageService _instance =
      TutorProfileStorageService._internal();

  static const String _storageKeyPrefix = 'varatia_tutor_bdjobs_profile_';
  final TenantTutorApiService _tutorApiService = TenantTutorApiService();

  final ValueNotifier<TutorBdjobsProfile?> profileNotifier =
      ValueNotifier<TutorBdjobsProfile?>(null);

  Future<String> _resolveKey() async {
    final session = await AuthSessionService().readSession();
    final userId = session?.userId.trim();
    if (userId != null && userId.isNotEmpty) {
      return '$_storageKeyPrefix$userId';
    }
    return '${_storageKeyPrefix}guest';
  }

  Future<TutorBdjobsProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _resolveKey();
    final rawJson = prefs.getString(key);

    TutorBdjobsProfile profile;
    if (rawJson != null && rawJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        profile = TutorBdjobsProfile.fromJson(decoded);
      } catch (e) {
        debugPrint('Error parsing saved tutor profile: $e');
        profile = const TutorBdjobsProfile();
      }
    } else {
      profile = const TutorBdjobsProfile();
    }

    // Pre-populate name & phone from session if not filled yet
    final session = await AuthSessionService().readSession();
    if (session != null) {
      bool shouldUpdate = false;
      String name = profile.fullName;
      String phone = profile.phoneNumber;

      if (name.isEmpty && session.fullName.trim().isNotEmpty) {
        name = session.fullName.trim();
        shouldUpdate = true;
      }
      if (phone.isEmpty && session.phoneNumber.trim().isNotEmpty) {
        phone = session.phoneNumber.trim();
        shouldUpdate = true;
      }

      if (shouldUpdate) {
        profile = profile.copyWith(fullName: name, phoneNumber: phone);
      }

      // Background sync from backend database
      final userId = session.userId.trim();
      if (userId.isNotEmpty) {
        unawaited(_syncFromBackend(userId, key, prefs));
      }
    }

    profileNotifier.value = profile;
    return profile;
  }

  Future<void> _syncFromBackend(
    String userId,
    String key,
    SharedPreferences prefs,
  ) async {
    try {
      final backendProfile = await _tutorApiService.getProfile(userId);
      if (backendProfile != null) {
        final rawJson = jsonEncode(backendProfile.toJson());
        await prefs.setString(key, rawJson);
        profileNotifier.value = backendProfile;
      }
    } catch (e) {
      debugPrint('Background sync tutor profile failed: $e');
    }
  }

  Future<void> saveProfile(TutorBdjobsProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _resolveKey();

    final profileWithTime = profile.copyWith(updatedAt: DateTime.now());
    final rawJson = jsonEncode(profileWithTime.toJson());
    await prefs.setString(key, rawJson);

    profileNotifier.value = profileWithTime;

    // Asynchronously sync to backend SQL Server via API
    final session = await AuthSessionService().readSession();
    final userId = session?.userId.trim();
    if (userId != null && userId.isNotEmpty) {
      try {
        await _tutorApiService.saveProfile(
          userId: userId,
          profile: profileWithTime,
        );
      } catch (e) {
        debugPrint('Error syncing tutor profile to API: $e');
      }
    }
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _resolveKey();
    await prefs.remove(key);
    profileNotifier.value = const TutorBdjobsProfile();
  }
}
