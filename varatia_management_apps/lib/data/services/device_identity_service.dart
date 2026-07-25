import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class DeviceIdentity {
  const DeviceIdentity({this.firebaseDeviceToken, this.imei});

  final String? firebaseDeviceToken;
  final String? imei;
}

class DeviceIdentityService {
  static const Duration _firebaseTokenTimeout = Duration(seconds: 5);

  DeviceIdentityService({
    FirebaseMessaging? firebaseMessaging,
    DeviceInfoPlugin? deviceInfoPlugin,
  }) : _firebaseMessaging = firebaseMessaging,
       _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  final FirebaseMessaging? _firebaseMessaging;
  final DeviceInfoPlugin _deviceInfoPlugin;

  Future<DeviceIdentity> readDeviceIdentity({
    String? firebaseDeviceTokenOverride,
  }) async {
    String? firebaseDeviceToken;
    try {
      firebaseDeviceToken = _normalize(firebaseDeviceTokenOverride);
      if (firebaseDeviceToken == null) {
        final firebaseMessaging =
            _firebaseMessaging ?? FirebaseMessaging.instance;
        firebaseDeviceToken = await firebaseMessaging.getToken().timeout(
          _firebaseTokenTimeout,
        );
      }
    } catch (_) {
      firebaseDeviceToken = null;
    }

    return DeviceIdentity(
      firebaseDeviceToken: _normalize(firebaseDeviceToken),
      imei: await readDeviceIdentifier(),
    );
  }

  Future<String?> readDeviceIdentifier() async {
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await _deviceInfoPlugin.androidInfo;
          return _normalize(info.serialNumber) ??
              _normalize('${info.manufacturer}-${info.model}-${info.id}');
        case TargetPlatform.iOS:
          final info = await _deviceInfoPlugin.iosInfo;
          return _normalize(info.identifierForVendor);
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  String? _normalize(String? value) {
    final normalizedValue = value?.trim();
    if (normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }

    return normalizedValue;
  }
}
