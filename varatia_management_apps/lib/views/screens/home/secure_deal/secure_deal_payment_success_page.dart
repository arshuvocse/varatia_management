part of 'tenant_secure_deal_screen.dart';

class SecureDealPaymentSuccessPage extends StatelessWidget {
  const SecureDealPaymentSuccessPage({
    super.key,
    this.projectTitle = 'Logo Design for Business',
    this.budget = 5000,
  });

  final String projectTitle;
  final int budget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _PaymentSuccessStep(
          onViewDetails: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SecureDealDetailsPage(
                  projectTitle: projectTitle,
                  budget: budget,
                ),
              ),
            );
          },
          onGoHome: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => const TenantSecureDealScreen(),
              ),
              (route) => false,
            );
          },
        ),
      ),
    );
  }
}
