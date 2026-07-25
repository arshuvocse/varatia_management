part of 'tenant_secure_deal_screen.dart';

class SecureDealConnectPage extends StatelessWidget {
  const SecureDealConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SecureDealPageScaffold(
      title: 'Connect by ID',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _dealPrimarySoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your SecureDeal ID',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'RAHAT-0017',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: _dealPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.copy_rounded),
                      color: _dealPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _DealFieldLabel(text: 'Find another user'),
          TextField(
            decoration: _dealInputDecoration(
              context,
              'Enter ID, phone or username',
            ).copyWith(prefixIcon: const Icon(Icons.search_rounded)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Send Connect Request'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _dealPrimary,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Connected users',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const _ConnectedUserTile(
            name: 'Jannatul Islam',
            id: 'JANNA-0184',
            subtitle: 'Verified seller, 21 completed deals',
            color: Color(0xFF10B981),
          ),
          const _ConnectedUserTile(
            name: 'Ahmed Khan',
            id: 'AHMED-0442',
            subtitle: 'VIP member, 12 completed deals',
            color: Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}

class _ConnectedUserTile extends StatelessWidget {
  const _ConnectedUserTile({
    required this.name,
    required this.id,
    required this.subtitle,
    required this.color,
  });

  final String name;
  final String id;
  final String subtitle;
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
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Text(
              name.substring(0, 1),
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.success,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$id · $subtitle',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SecureDealChatPage(),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            color: _dealPrimary,
          ),
        ],
      ),
    );
  }
}
