part of 'tenant_secure_deal_screen.dart';

class SecureDealDeliveryUploadPage extends StatelessWidget {
  const SecureDealDeliveryUploadPage({
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
    return _DeliveryUploadPage(
      dealId: dealId,
      projectTitle: projectTitle,
      budget: budget,
    );
  }
}
