part of 'tenant_secure_deal_screen.dart';

class SecureDealReviewApprovePage extends StatelessWidget {
  const SecureDealReviewApprovePage({
    super.key,
    this.dealId,
    this.projectTitle = 'Logo Design for Business',
    this.budget = 5000,
  });

  final String? dealId;
  final String projectTitle;
  final int budget;

  @override
  Widget build(BuildContext context) {
    return _ReviewApprovePage(
      dealId: dealId,
      projectTitle: projectTitle,
      budget: budget,
    );
  }
}
