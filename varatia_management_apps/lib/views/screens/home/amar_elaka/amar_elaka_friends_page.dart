import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AmarElakaFriendsPage extends StatelessWidget {
  const AmarElakaFriendsPage({super.key, required this.wardName});

  final String wardName;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          title: const Text('Friends'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Suggest'),
              Tab(text: 'Friends'),
              Tab(text: 'Nearby'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FriendList(
              wardName: wardName,
              people: _suggestedFriends,
              primaryAction: 'Add',
            ),
            _FriendList(
              wardName: wardName,
              people: _currentFriends,
              primaryAction: 'Message',
            ),
            _FriendList(
              wardName: wardName,
              people: _nearbyFriends,
              primaryAction: 'Connect',
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendList extends StatelessWidget {
  const _FriendList({
    required this.wardName,
    required this.people,
    required this.primaryAction,
  });

  final String wardName;
  final List<_AreaFriend> people;
  final String primaryAction;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: people.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _InfoCard(
            icon: Icons.groups_2_rounded,
            title: '$wardName community',
            subtitle: 'Suggested friends, existing friends and nearby people.',
          );
        }

        final friend = people[index - 1];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration,
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: friend.color,
                    child: Text(
                      friend.name.characters.first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: 1,
                    child: _PresenceDot(active: friend.active),
                  ),
                ],
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
                            friend.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (friend.verified) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF079455),
                            size: 17,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${friend.distance} away - ${friend.active ? 'Active now' : 'Inactive'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Friend options',
                onSelected: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$value: ${friend.name}')),
                  );
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: primaryAction,
                    child: Text(primaryAction),
                  ),
                  const PopupMenuItem(value: 'Block', child: Text('Block')),
                  const PopupMenuItem(value: 'Report', child: Text('Report')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF079455), size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
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

class _PresenceDot extends StatelessWidget {
  const _PresenceDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 13,
      width: 13,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF12B76A) : const Color(0xFF94A3B8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _AreaFriend {
  const _AreaFriend({
    required this.name,
    required this.distance,
    required this.color,
    this.active = false,
    this.verified = false,
  });

  final String name;
  final String distance;
  final Color color;
  final bool active;
  final bool verified;
}

const _suggestedFriends = <_AreaFriend>[
  _AreaFriend(
    name: 'Rafi Ahmed',
    distance: '450m',
    color: Color(0xFF0EA5E9),
    active: true,
    verified: true,
  ),
  _AreaFriend(name: 'Nusrat Jahan', distance: '700m', color: Color(0xFF7C3AED)),
  _AreaFriend(
    name: 'Sabbir Hossain',
    distance: '1.1km',
    color: Color(0xFFEA580C),
    active: true,
  ),
];

const _currentFriends = <_AreaFriend>[
  _AreaFriend(
    name: 'Ayesha Akter',
    distance: 'same road',
    color: Color(0xFF079455),
    active: true,
    verified: true,
  ),
  _AreaFriend(
    name: 'Tanvir Hasan',
    distance: 'near market',
    color: Color(0xFF475467),
  ),
];

const _nearbyFriends = <_AreaFriend>[
  _AreaFriend(
    name: 'Mehedi Hasan',
    distance: '250m',
    color: Color(0xFFD92D20),
    active: true,
  ),
  _AreaFriend(
    name: 'Farzana Islam',
    distance: '500m',
    color: Color(0xFF155EEF),
  ),
];

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: const Color(0xFFE5EAF2)),
  boxShadow: AppShadows.card,
);
