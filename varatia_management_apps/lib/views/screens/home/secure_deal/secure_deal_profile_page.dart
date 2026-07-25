part of 'tenant_secure_deal_screen.dart';

class SecureDealProfilePage extends StatelessWidget {
  const SecureDealProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SecureDealPageScaffold(
      title: 'Profile',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
        children: const [
          _SecureDealProfileHeader(),
          SizedBox(height: 16),
          _SecureDealProfileStats(),
          SizedBox(height: 18),
          _SecureDealProfileInfoCard(),
          SizedBox(height: 18),
          _SecureDealProfileSecurityCard(),
          SizedBox(height: 18),
          _SecureDealProfileMenuCard(),
        ],
      ),
    );
  }
}

class _SecureDealProfileHeader extends StatelessWidget {
  const _SecureDealProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _dealBorder),
        boxShadow: _dealShadow,
      ),
      child: Row(
        children: [
          Container(
            height: 74,
            width: 74,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _dealPrimarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'R',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _dealPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rahat Hossain',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verified SecureDeal Member',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: 'KYC Verified',
                      backgroundColor: AppColors.success.withValues(
                        alpha: 0.12,
                      ),
                      textColor: AppColors.success,
                    ),
                    const _StatusChip(
                      label: 'VIP',
                      backgroundColor: Color(0xFFFFF7ED),
                      textColor: AppColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecureDealProfileStats extends StatelessWidget {
  const _SecureDealProfileStats();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _SecureDealProfileStatTile(
            label: 'Completed',
            value: '18',
            icon: Icons.work_outline_rounded,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _SecureDealProfileStatTile(
            label: 'Balance',
            value: 'Tk 24.5k',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _SecureDealProfileStatTile(
            label: 'Rating',
            value: '4.9',
            icon: Icons.star_border_rounded,
          ),
        ),
      ],
    );
  }
}

class _SecureDealProfileStatTile extends StatelessWidget {
  const _SecureDealProfileStatTile({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dealBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: _dealPrimary, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecureDealProfileInfoCard extends StatelessWidget {
  const _SecureDealProfileInfoCard();

  @override
  Widget build(BuildContext context) {
    return const _SecureDealProfileSection(
      title: 'Personal Info',
      children: [
        _SecureDealProfileInfoRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: '+880 1712-345678',
        ),
        _SecureDealProfileInfoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: 'rahat@example.com',
        ),
        _SecureDealProfileInfoRow(
          icon: Icons.location_on_outlined,
          label: 'Address',
          value: 'Dhaka, Bangladesh',
        ),
        _SecureDealProfileInfoRow(
          icon: Icons.badge_outlined,
          label: 'Member ID',
          value: 'SD-2026-0017',
        ),
        _SecureDealProfileInfoRow(
          icon: Icons.connect_without_contact_rounded,
          label: 'Connect ID',
          value: 'RAHAT-0017',
        ),
      ],
    );
  }
}

class _SecureDealProfileSecurityCard extends StatelessWidget {
  const _SecureDealProfileSecurityCard();

  @override
  Widget build(BuildContext context) {
    return const _SecureDealProfileSection(
      title: 'SecureDeal Info',
      children: [
        _SecureDealProfileInfoRow(
          icon: Icons.verified_user_outlined,
          label: 'Account status',
          value: 'Active and verified',
        ),
        _SecureDealProfileInfoRow(
          icon: Icons.lock_clock_outlined,
          label: 'Escrow protection',
          value: 'Enabled for all deals',
        ),
        _SecureDealProfileInfoRow(
          icon: Icons.payments_outlined,
          label: 'Payment method',
          value: 'bKash, Nagad, Bank',
        ),
        _SecureDealProfileInfoRow(
          icon: Icons.verified_rounded,
          label: 'Verified badge',
          value: 'Visible on posts, chat and deals',
        ),
      ],
    );
  }
}

class _SecureDealProfileMenuCard extends StatelessWidget {
  const _SecureDealProfileMenuCard();

  @override
  Widget build(BuildContext context) {
    return _SecureDealProfileSection(
      title: 'Settings',
      children: [
        _DealMenuTile(
          icon: Icons.edit_outlined,
          label: 'Edit SecureDeal Profile',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SecureDealVipSignupPage(),
              ),
            );
          },
        ),
        _DealMenuTile(
          icon: Icons.history_rounded,
          label: 'Transaction History',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SecureDealWalletPage(),
              ),
            );
          },
        ),
        _DealMenuTile(
          icon: Icons.connect_without_contact_rounded,
          label: 'Connect with ID',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SecureDealConnectPage(),
              ),
            );
          },
        ),
        _DealMenuTile(
          icon: Icons.support_agent_rounded,
          label: 'SecureDeal Support',
          onTap: () {},
        ),
      ],
    );
  }
}

class _SecureDealProfileSection extends StatelessWidget {
  const _SecureDealProfileSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _dealBorder),
        boxShadow: _dealShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _SecureDealProfileInfoRow extends StatelessWidget {
  const _SecureDealProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: _dealPrimarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _dealPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
