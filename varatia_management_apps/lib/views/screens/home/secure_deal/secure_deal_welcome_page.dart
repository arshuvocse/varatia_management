part of 'tenant_secure_deal_screen.dart';

class SecureDealWelcomePage extends StatelessWidget {
  const SecureDealWelcomePage({super.key});

  void _openAuth(BuildContext context, int tabIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TenantAuthBridgeScreen(
          initialTabIndex: tabIndex,
          destination: TenantAuthDestination.secureDeal,
          authRole: EntryUserRole.tenant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _SecureDealWelcomeStep(
          onLogin: () => _openAuth(context, 0),
          onSignUp: () => _openAuth(context, 1),
        ),
      ),
    );
  }
}
