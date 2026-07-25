part of 'tenant_secure_deal_screen.dart';

class SecureDealPostsPage extends StatelessWidget {
  const SecureDealPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SecureDealPageScaffold(
      title: 'Deal Posts',
      body: Consumer<SecureDealViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final deals = vm.deals;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
            itemCount: deals.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SecureDealCreateDealPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.post_add_rounded),
                    label: const Text('Create Post'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: _dealPrimary,
                    ),
                  ),
                );
              }

              final deal = deals[index - 1];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SecureDealDetailsPage(
                        dealId: deal['id'],
                        projectTitle: deal['title'] ?? 'Untitled Deal',
                        budget: deal['amount']?.toInt() ?? 0,
                      ),
                    ),
                  );
                },
                child: _DealPostCard(
                  title: deal['title'] ?? 'Untitled Deal',
                  budget: '৳ ${deal['amount'] ?? 0}',
                  author: 'User ID: ${deal['creatorId']}',
                  meta: '${deal['role']} · ${deal['status']}',
                  status: deal['status'] ?? 'Pending',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DealPostCard extends StatelessWidget {
  const _DealPostCard({
    required this.title,
    required this.budget,
    required this.author,
    required this.meta,
    required this.status,
  });

  final String title;
  final String budget;
  final String author;
  final String meta;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _dealBorder),
        boxShadow: _dealShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusChip(
                label: status,
                backgroundColor: status == 'VIP'
                    ? const Color(0xFFFFF7ED)
                    : AppColors.success.withValues(alpha: 0.12),
                textColor: status == 'VIP'
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(meta, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: AppColors.success,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  author,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                budget,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _dealPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.connect_without_contact_rounded),
                  label: const Text('Connect'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SecureDealCreateDealPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text('Create Deal'),
                  style: FilledButton.styleFrom(backgroundColor: _dealPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
