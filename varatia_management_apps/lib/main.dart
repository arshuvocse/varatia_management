import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/varatia_app.dart';
import 'data/repositories/management_repository_bootstrap.dart';
import 'data/services/push_notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseInitialized = await _initializeFirebase();
  final repository = await ManagementRepositoryBootstrap.initialize();
  runApp(VaratiaApp(repository: repository));
  if (firebaseInitialized) {
    unawaited(PushNotificationService.instance.initialize());
  }
}

Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    return true;
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'app startup',
        context: ErrorDescription('while initializing Firebase'),
      ),
    );
    return false;
  }
}
