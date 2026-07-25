part of 'tenant_secure_deal_screen.dart';

class SecureDealHomePage extends StatelessWidget {
  const SecureDealHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _SecureDealHomeStep(
          onCreateDeal: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SecureDealCreateDealPage(),
              ),
            );
          },
          onOpenDeal: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SecureDealDetailsPage(),
              ),
            );
          },
          onOpenChat: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SecureDealChatPage(),
              ),
            );
          },
          onOpenWallet: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SecureDealWalletPage(),
              ),
            );
          },
          onOpenConnect: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SecureDealConnectPage(),
              ),
            );
          },
          onOpenPosts: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SecureDealPostsPage(),
              ),
            );
          },
          onOpenNotifications: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SecureDealNotificationsPage(),
              ),
            );
          },
          onOpenVip: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SecureDealVipSignupPage(),
              ),
            );
          },
          onOpenAdmin: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const _SecureDealAdminDashboardPage(),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const _SecureDealHomeNavBar(),
    );
  }
}
