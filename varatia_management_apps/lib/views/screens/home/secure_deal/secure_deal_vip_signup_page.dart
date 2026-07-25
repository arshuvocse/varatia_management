part of 'tenant_secure_deal_screen.dart';

class SecureDealVipSignupPage extends StatelessWidget {
  const SecureDealVipSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SecureDealPageScaffold(
      title: 'VIP Sign Up',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upgrade to SecureDeal VIP',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _VipBenefit(
                  text: 'Verified badge on profile, posts and chat',
                ),
                const _VipBenefit(
                  text: 'Higher trust score and rating visibility',
                ),
                const _VipBenefit(
                  text: 'Priority deal posts and faster support',
                ),
                const _VipBenefit(text: 'Higher cash out and withdraw limits'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _DealFieldLabel(text: 'Profile setup'),
          TextField(decoration: _dealInputDecoration(context, 'Full name')),
          const SizedBox(height: 12),
          TextField(
            decoration: _dealInputDecoration(context, 'NID or passport number'),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: _dealInputDecoration(
              context,
              'Business or service type',
            ),
          ),
          const SizedBox(height: 18),
          const _DealFieldLabel(text: 'Current rating'),
          Row(
            children: List.generate(
              5,
              (index) => const Icon(
                Icons.star_rounded,
                color: AppColors.warning,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      bottomAction: _SecureDealBottomAction(
        label: 'Submit VIP Verification',
        onPressed: () {},
      ),
    );
  }
}

class _VipBenefit extends StatelessWidget {
  const _VipBenefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
