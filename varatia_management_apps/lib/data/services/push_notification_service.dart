import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'auth_session_service.dart';
import 'device_identity_service.dart';
import '../../firebase_options.dart';
import 'registration_api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const String channelId = 'high_importance_channel';
  static const String channelName = 'High Priority Notifications';
  static const String channelDescription =
      'Heads-up alerts with sound and vibration for Amar Thikanaa.';

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AuthSessionService _authSessionService = AuthSessionService();
  final DeviceIdentityService _deviceIdentityService = DeviceIdentityService();
  final RegistrationApiService _registrationApiService =
      RegistrationApiService();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
    await _createAndroidChannel();
    await _requestPermissions();

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.instance.onTokenRefresh.listen(_syncRefreshedToken);
    await _syncCurrentDeviceIdentity();

    _isInitialized = true;
  }

  Future<void> _createAndroidChannel() async {
    const notificationChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(notificationChannel);
  }

  Future<void> _requestPermissions() async {
    final firebaseMessaging = FirebaseMessaging.instance;

    await firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final remoteNotification = message.notification;
    final title =
        remoteNotification?.title ?? _normalizeString(message.data['title']);
    final body =
        remoteNotification?.body ?? _normalizeString(message.data['body']);

    if (title == null && body == null) {
      return;
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        ticker: 'Amar Thikanaa',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotificationsPlugin.show(
      id: message.messageId?.hashCode ?? message.hashCode,
      title: title ?? 'Amar Thikanaa',
      body: body ?? '',
      notificationDetails: notificationDetails,
    );
  }

  Future<void> _syncCurrentDeviceIdentity() async {
    try {
      final userId = await _authSessionService.readUserId();
      if (userId == null) {
        return;
      }

      final deviceIdentity = await _deviceIdentityService.readDeviceIdentity();
      if (deviceIdentity.firebaseDeviceToken == null &&
          deviceIdentity.imei == null) {
        return;
      }

      await _registrationApiService.updateDeviceInfo(
        userId: userId,
        firebaseDeviceToken: deviceIdentity.firebaseDeviceToken,
        imei: deviceIdentity.imei,
      );
    } catch (_) {
      // Ignore token sync failures and allow the app to continue running.
    }
  }

  Future<void> _syncRefreshedToken(String refreshedToken) async {
    try {
      final userId = await _authSessionService.readUserId();
      if (userId == null) {
        return;
      }

      final imei = await _deviceIdentityService.readDeviceIdentifier();
      await _registrationApiService.updateDeviceInfo(
        userId: userId,
        firebaseDeviceToken: refreshedToken,
        imei: imei,
      );
    } catch (_) {
      // Ignore token refresh sync failures and allow retry on next app open.
    }
  }

  String? _normalizeString(Object? value) {
    if (value is! String) {
      return null;
    }

    final normalizedValue = value.trim();
    return normalizedValue.isEmpty ? null : normalizedValue;
  }
}
