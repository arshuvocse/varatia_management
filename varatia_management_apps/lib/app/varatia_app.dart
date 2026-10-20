import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/management_repository.dart';
import '../viewmodels/app_view_models.dart';
import '../viewmodels/secure_deal_view_model.dart';

import '../data/services/admin_chat_api_service.dart';
import '../viewmodels/admin_chat_view_model.dart';
import '../viewmodels/role_dashboard_view_models.dart';
import '../views/screens/entry/entry_routes.dart';
import '../views/screens/home/smart_bazar/smart_bazar_view_model.dart';

class VaratiaApp extends StatefulWidget {
  const VaratiaApp({super.key, required this.repository});

  final ManagementRepository repository;

  @override
  State<VaratiaApp> createState() => _VaratiaAppState();
}

class _VaratiaAppState extends State<VaratiaApp> with WidgetsBindingObserver {
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    _lastLifecycleState = WidgetsBinding.instance.lifecycleState;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lastLifecycleState == state) {
      return;
    }

    _lastLifecycleState = state;

    switch (state) {
      case AppLifecycleState.resumed:
        // Keep resume side-effect free so the existing Navigator stack is kept.
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        return;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AdminChatApiService>(create: (_) => AdminChatApiService()),
        Provider<ManagementRepository>(create: (_) => widget.repository),
        ChangeNotifierProvider(create: (_) => ShellViewModel()),
        ChangeNotifierProvider(create: (_) => RoleSelectionViewModel()),
        ChangeNotifierProvider(create: (_) => SecureDealViewModel()),
        ChangeNotifierProvider(
          create: (context) =>
              DashboardViewModel(context.read<ManagementRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              PropertyViewModel(context.read<ManagementRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              TenantViewModel(context.read<ManagementRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              PaymentViewModel(context.read<ManagementRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ExpenseViewModel(context.read<ManagementRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              NotificationViewModel(context.read<ManagementRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ReportViewModel(context.read<ManagementRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CommunicationViewModel(context.read<ManagementRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AdminChatViewModel(context.read<AdminChatApiService>()),
        ),
        ChangeNotifierProvider(create: (_) => AdminDashboardViewModel()),
        ChangeNotifierProvider(
          create: (context) =>
              OwnerDashboardViewModel(context.read<ManagementRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              TenantExperienceViewModel(context.read<ManagementRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => SmartBazarViewModel()),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Amar Thikanaa',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            locale: settings.locale,
            supportedLocales: const [Locale('bn', 'BD'), Locale('en', 'US')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppRoutes.splash,
            onGenerateRoute: buildAppRoute,
          );
        },
      ),
    );
  }
}
