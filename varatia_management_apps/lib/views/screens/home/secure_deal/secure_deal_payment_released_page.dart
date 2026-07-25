part of 'tenant_secure_deal_screen.dart';

class SecureDealPaymentReleasedPage extends StatelessWidget {
  const SecureDealPaymentReleasedPage({super.key, this.amount = 5000});

  final int amount;

  @override
  Widget build(BuildContext context) => _PaymentReleasedPage(amount: amount);
}
