part of 'tenant_secure_deal_screen.dart';

class SecureDealDetailsPage extends StatelessWidget {
  const SecureDealDetailsPage({
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
    return _SecureDealPageScaffold(
      title: context.tr(bn: 'ডিল ডিটেইলস', en: 'Deal Details'),
      body: _DealDetailsStep(projectTitle: projectTitle, budget: budget),
      bottomAction: _SecureDealBottomAction(
        label: context.tr(
          bn: 'সম্পন্ন হিসেবে মার্ক করুন',
          en: 'Mark as Completed (Release Escrow)',
        ),
        color: AppColors.success,
        onPressed: () async {
          if (dealId != null) {
            final vm = context.read<SecureDealViewModel>();
            final success = await vm.releasePayment(dealId!);
            if (success && context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SecureDealPaymentReleasedPage(amount: budget),
                ),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to release payment.')),
              );
            }
          }
        },
      ),
    );
  }
}
