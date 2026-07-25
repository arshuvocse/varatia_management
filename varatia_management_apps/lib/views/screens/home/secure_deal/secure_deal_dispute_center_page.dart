part of 'tenant_secure_deal_screen.dart';

class SecureDealDisputeCenterPage extends StatelessWidget {
  const SecureDealDisputeCenterPage({
    super.key,
    this.dealId,
    this.projectTitle = 'Logo Design for Business',
  });

  final String? dealId;
  final String projectTitle;

  @override
  Widget build(BuildContext context) {
    return _DisputeCenterPage(dealId: dealId, projectTitle: projectTitle);
  }
}
