part of 'tenant_secure_deal_screen.dart';

class SecureDealPaymentPage extends StatefulWidget {
  const SecureDealPaymentPage({
    super.key,
    this.projectTitle = 'Logo Design for Business',
    this.budget = 5000,
    this.totalPayable = 5250,
  });

  final String projectTitle;
  final int budget;
  final int totalPayable;

  @override
  State<SecureDealPaymentPage> createState() => _SecureDealPaymentPageState();
}

class _SecureDealPaymentPageState extends State<SecureDealPaymentPage> {
  int _selectedPaymentIndex = 0;

  static const _paymentMethods = <_PaymentMethodData>[
    _PaymentMethodData(
      label: 'bKash',
      icon: Icons.send_rounded,
      color: Color(0xFFE2136E),
    ),
    _PaymentMethodData(
      label: 'Nagad',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFF97316),
    ),
    _PaymentMethodData(
      label: 'Rocket',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFF6D28D9),
    ),
    _PaymentMethodData(
      label: 'Card Payment',
      icon: Icons.credit_card_rounded,
      color: Color(0xFF2563EB),
    ),
    _PaymentMethodData(
      label: 'Bank Transfer',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF1D4ED8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SecureDealPageScaffold(
      title: context.tr(bn: 'পেমেন্ট', en: 'Payment'),
      body: _PaymentStep(
        totalPayable: widget.totalPayable,
        paymentMethods: _paymentMethods,
        selectedPaymentIndex: _selectedPaymentIndex,
        onPaymentSelected: (index) => setState(() {
          _selectedPaymentIndex = index;
        }),
      ),
      bottomAction: _SecureDealBottomAction(
        label: context.tr(bn: 'এখন পে করুন', en: 'Pay Now'),
        onPressed: () async {
          final vm = context.read<SecureDealViewModel>();
          final dealId = await vm.createDeal(
            'Buyer',
            widget.projectTitle,
            'Created from app',
            widget.budget.toDouble(),
          );

          if (dealId != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SecureDealPaymentSuccessPage(
                  projectTitle: widget.projectTitle,
                  budget: widget.budget,
                ),
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to create deal.')),
            );
          }
        },
      ),
    );
  }
}
