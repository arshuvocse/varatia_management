# varatia_management_apps

## Demo mode

The app uses built-in demo data by default, so the main admin, owner, tenant,
property, payment, expense, notification, marketplace, and owner-post screens
can be reviewed without a backend connection.

```powershell
flutter run
```

To use the live API instead:

```powershell
flutter run --dart-define=VARATIA_DEMO_MODE=false
```

To override the live API base URL:

```powershell
flutter run --dart-define=VARATIA_DEMO_MODE=false --dart-define=VARATIA_API_BASE_URL=http://your-api-host
```

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
