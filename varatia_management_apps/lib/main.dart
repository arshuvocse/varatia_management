import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/varatia_app.dart';
import 'data/repositories/management_repository_bootstrap.dart';
import 'data/services/push_notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = await ManagementRepositoryBootstrap.initialize();
  runApp(VaratiaApp(repository: repository));

  unawaited(() async {
    final firebaseInitialized = await _initializeFirebase();
    if (firebaseInitialized) {
      unawaited(PushNotificationService.instance.initialize());
    }
  }());
}

Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 2));

    return true;
  } catch (error) {
    debugPrint('Firebase initialization skipped/timed out: $error');
    return false;
  }
}

