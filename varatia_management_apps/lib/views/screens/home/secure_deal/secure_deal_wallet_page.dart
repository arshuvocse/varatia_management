part of 'tenant_secure_deal_screen.dart';

class SecureDealWalletPage extends StatefulWidget {
  const SecureDealWalletPage({super.key});

  @override
  State<SecureDealWalletPage> createState() => _SecureDealWalletPageState();
}

class _SecureDealWalletPageState extends State<SecureDealWalletPage> {
  bool _showBalance = true;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SecureDealViewModel>();
    final balance = vm.walletData['balance'] ?? 0.0;

    return _SecureDealPageScaffold(
      title: 'Wallet',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: _dealShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Total Balance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        setState(() => _showBalance = !_showBalance);
                      },
                      icon: Icon(
                        _showBalance
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  _showBalance
                      ? '৳ ${balance.toStringAsFixed(2)}'
                      : '৳ •••••••',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: vm.isLoading
                            ? null
                            : () async {
                                final success = await context
                                    .read<SecureDealViewModel>()
                                    .topUpWallet(5000);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? '5000 BDT Added for Demo!'
                                          : 'TopUp Failed',
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Demo Fund'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _dealPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.outbox_rounded),
                        label: const Text('Withdraw'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _WalletMetricCard(
                  label: 'Escrow hold',
                  value: '৳ 8,500',
                  icon: Icons.lock_outline_rounded,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _WalletMetricCard(
                  label: 'Cash out ready',
                  value: '৳ 16,060',
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Transactions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const _TransactionTile(
            title: 'Fund added by bKash',
            subtitle: 'Today, 10:42 AM',
            amount: '+৳ 10,000',
            color: AppColors.success,
          ),
          const _TransactionTile(
            title: 'Deal escrow payment',
            subtitle: 'Logo Design for Business',
            amount: '-৳ 5,250',
            color: AppColors.warning,
          ),
          const _TransactionTile(
            title: 'Seller cash out',
            subtitle: 'Released after approval',
            amount: '-৳ 3,500',
            color: _dealPrimary,
          ),
        ],
      ),
    );
  }
}

class _WalletMetricCard extends StatelessWidget {
  const _WalletMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dealBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _dealPrimary),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dealBorder),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
