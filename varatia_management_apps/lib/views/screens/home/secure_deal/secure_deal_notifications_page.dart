part of 'tenant_secure_deal_screen.dart';

class SecureDealNotificationsPage extends StatelessWidget {
  const SecureDealNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SecureDealPageScaffold(
      title: 'Notifications',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
        children: const [
          _NotificationTile(
            icon: Icons.lock_clock_outlined,
            title: 'Escrow payment received',
            subtitle: 'Logo Design deal is funded and ready to start.',
            time: '5 min ago',
            color: _dealPrimary,
          ),
          _NotificationTile(
            icon: Icons.timer_off_outlined,
            title: 'Delivery time reminder',
            subtitle:
                'Facebook Cover Design has 1 day left before cancel option.',
            time: '1 hour ago',
            color: AppColors.warning,
          ),
          _NotificationTile(
            icon: Icons.payments_outlined,
            title: 'Cash out available',
            subtitle: 'Both parties approved. Seller payout can be withdrawn.',
            time: 'Yesterday',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Text(time, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
