part of 'tenant_secure_deal_screen.dart';

class SecureDealConfirmDealPage extends StatelessWidget {
  const SecureDealConfirmDealPage({
    super.key,
    this.projectTitle = 'Logo Design for Business',
    this.category = 'Design & Creative',
    this.description = 'I need a modern and professional logo for my business.',
    this.deliveryTime = '3 Days',
    this.budget = 5000,
  });

  final String projectTitle;
  final String category;
  final String description;
  final String deliveryTime;
  final int budget;

  int get serviceFee => (budget * 0.05).round();

  int get totalPayable => budget + serviceFee;

  @override
  Widget build(BuildContext context) {
    return _SecureDealPageScaffold(
      title: context.tr(bn: 'ডিল কনফার্ম করুন', en: 'Confirm Deal'),
      body: _ConfirmDealStep(
        projectTitle: projectTitle,
        category: category,
        description: description,
        deliveryTime: deliveryTime,
        budget: budget,
        serviceFee: serviceFee,
        totalPayable: totalPayable,
      ),
      bottomAction: _SecureDealBottomAction(
        label: context.tr(bn: 'কনফার্ম ও পে', en: 'Confirm & Pay'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SecureDealPaymentPage(
                projectTitle: projectTitle,
                budget: budget,
                totalPayable: totalPayable,
              ),
            ),
          );
        },
      ),
    );
  }
}
