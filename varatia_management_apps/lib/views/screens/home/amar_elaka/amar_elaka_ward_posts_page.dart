import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'amar_elaka_profile_page.dart';

const _areaGreen = Color(0xFF079455);
const _areaDark = Color(0xFF101828);
const _areaBorder = Color(0xFFE5EAF2);
const _areaBackground = Color(0xFFF7F9FC);

class AmarElakaWardPostsPage extends StatefulWidget {
  const AmarElakaWardPostsPage({super.key, required this.wardName});

  final String wardName;

  @override
  State<AmarElakaWardPostsPage> createState() => _AmarElakaWardPostsPageState();
}

class _AmarElakaWardPostsPageState extends State<AmarElakaWardPostsPage> {
  int _tabIndex = 0;
  int _bottomIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _areaBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _showComposerSheet,
        backgroundColor: _areaGreen,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      bottomNavigationBar: _AreaBottomNav(
        selectedIndex: _bottomIndex,
        onChanged: (index) {
          setState(() => _bottomIndex = index);
          if (index != 0) {
            _showMessage(_bottomItems[index].label);
          }
        },
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _AreaHeader(
                wardName: widget.wardName,
                onMenuTap: () => Navigator.maybePop(context),
                onBellTap: () => _showMessage('নোটিফিকেশন'),
                onProfileTap: _openProfile,
              ),
            ),
            SliverToBoxAdapter(
              child: _QuickActionStrip(
                onActionTap: (action) {
                  if (action.title == 'পোস্ট') {
                    _showOptionsSheet();
                  } else {
                    _showMessage(action.title);
                  }
                },
              ),
            ),
            const SliverToBoxAdapter(child: _StoryStrip()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: _CountryPostPrompt(onTap: _showComposerSheet),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: _FeedTabs(
                  selectedIndex: _tabIndex,
                  onChanged: (index) => setState(() => _tabIndex = index),
                  onFilterTap: _showFilterSheet,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 92),
              sliver: SliverList.separated(
                itemBuilder: (context, index) {
                  final posts = _filteredPosts;
                  return _AreaPostCard(post: posts[index]);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: _filteredPosts.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_AreaFeedPost> get _filteredPosts {
    final selected = _feedTabs[_tabIndex];
    if (selected == 'সকল পোস্ট') {
      return _posts;
    }
    return _posts.where((post) => post.type == selected).toList();
  }

  void _showComposerSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'পোস্ট এনাউন্সমেন্ট',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'শিরোনাম লিখুন',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'এনাউন্সমেন্ট বিস্তারিত লিখুন...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _ComposerPrivacyTile(
              selected: true,
              label: 'সকল ওয়ার্ডে পাঠান',
              onTap: () {},
            ),
            _ComposerPrivacyTile(
              selected: false,
              label: 'নির্দিষ্ট ওয়ার্ডে পাঠান',
              onTap: () {},
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _showMessage('পোস্ট প্রস্তুত');
              },
              style: FilledButton.styleFrom(backgroundColor: _areaGreen),
              child: const Text('পোস্ট করুন'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        itemCount: _optionActions.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'সব অপশন',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            );
          }
          final option = _optionActions[index - 1];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _IconBadge(icon: option.icon, color: option.color),
            title: Text(
              option.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: option.subtitle == null ? null : Text(option.subtitle!),
            onTap: () {
              Navigator.pop(context);
              if (option.title == 'সারা দেশ থেকে পোস্ট করুন') {
                _showComposerSheet();
              } else if (option.title == 'এডিট প্রোফাইল') {
                _openProfile();
              } else {
                _showMessage(option.title);
              }
            },
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'পোস্ট ফিল্টার',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _feedTabs.length; i++)
              RadioListTile<int>(
                value: i,
                groupValue: _tabIndex,
                activeColor: _areaGreen,
                title: Text(_feedTabs[i]),
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() => _tabIndex = value ?? 0);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title চালু হচ্ছে')));
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AmarElakaProfilePage(
          wardName: widget.wardName,
          location: '${widget.wardName}, ঢাকা',
        ),
      ),
    );
  }
}

class _AreaHeader extends StatelessWidget {
  const _AreaHeader({
    required this.wardName,
    required this.onMenuTap,
    required this.onBellTap,
    required this.onProfileTap,
  });

  final String wardName;
  final VoidCallback onMenuTap;
  final VoidCallback onBellTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 10, 10, 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'মেনু',
            onPressed: onMenuTap,
            icon: const Icon(Icons.menu_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'আমার এলাকা',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on, size: 18, color: _areaDark),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$wardName, ঢাকা',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'নোটিফিকেশন',
            onPressed: onBellTap,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          GestureDetector(
            onTap: onProfileTap,
            child: const CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFFFE7C2),
              child: Text('র', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionStrip extends StatelessWidget {
  const _QuickActionStrip({required this.onActionTap});

  final ValueChanged<_AreaAction> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _quickActions
            .map(
              (action) => _QuickActionButton(
                action: action,
                onTap: () => onActionTap(action),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action, required this.onTap});

  final _AreaAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 52,
        child: Column(
          children: [
            _IconBadge(icon: action.icon, color: action.color, size: 42),
            const SizedBox(height: 6),
            Text(
              action.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _areaDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryStrip extends StatelessWidget {
  const _StoryStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const _StoryItem(
              title: 'Add Story',
              color: Color(0xFFEFF4FF),
              initial: 'র',
              add: true,
            ),
            for (final story in _stories) _StoryItem.fromData(story),
          ],
        ),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({
    required this.title,
    required this.color,
    required this.initial,
    this.add = false,
  });

  factory _StoryItem.fromData(_StoryData story) {
    return _StoryItem(
      title: story.title,
      color: story.color,
      initial: story.initial,
    );
  }

  final String title;
  final Color color;
  final String initial;
  final bool add;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 62,
        child: Column(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: add ? Colors.white : AppColors.primary,
                  width: add ? 0 : 2,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (add)
                    const Positioned(
                      right: 3,
                      bottom: 3,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: _areaGreen,
                        child: Icon(Icons.add, color: Colors.white, size: 15),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _areaDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryPostPrompt extends StatelessWidget {
  const _CountryPostPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _areaBorder),
          ),
          child: Row(
            children: [
              const _IconBadge(
                icon: Icons.shield_rounded,
                color: Color(0xFFF04438),
                size: 42,
                soft: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'সারা দেশ থেকে পোস্ট করুন',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'শুধুমাত্র "আমার এলাকা" হোমপেজে দেখাবে',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.public_rounded, color: _areaGreen),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedTabs extends StatelessWidget {
  const _FeedTabs({
    required this.selectedIndex,
    required this.onChanged,
    required this.onFilterTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  for (var i = 0; i < _feedTabs.length; i++)
                    _FeedTabButton(
                      label: _feedTabs[i],
                      selected: selectedIndex == i,
                      onTap: () => onChanged(i),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'ফিল্টার',
            onPressed: onFilterTap,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }
}

class _FeedTabButton extends StatelessWidget {
  const _FeedTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? _areaGreen : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? _areaGreen : _areaDark,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AreaPostCard extends StatelessWidget {
  const _AreaPostCard({required this.post});

  final _AreaFeedPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _areaBorder),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: post.avatarColor,
                child: Text(
                  post.initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _PostScopeChip(label: post.ward),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      post.time,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'আরও',
                visualDensity: VisualDensity.compact,
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _areaDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          _PostMediaGrid(post: post),
          const SizedBox(height: 10),
          Row(
            children: [
              const _ReactionStack(),
              const SizedBox(width: 6),
              Text(
                post.likes,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${post.comments} মন্তব্য',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostScopeChip extends StatelessWidget {
  const _PostScopeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F8EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _areaGreen,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PostMediaGrid extends StatelessWidget {
  const _PostMediaGrid({required this.post});

  final _AreaFeedPost post;

  @override
  Widget build(BuildContext context) {
    if (post.mediaCount == 1) {
      return _PostMediaTile(
        height: 178,
        colors: post.mediaColors.first,
        icon: post.mediaIcon,
      );
    }
    return Row(
      children: [
        Expanded(
          child: _PostMediaTile(
            height: 148,
            colors: post.mediaColors.first,
            icon: post.mediaIcon,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PostMediaTile(
            height: 148,
            colors: post.mediaColors.last,
            icon: Icons.construction_rounded,
          ),
        ),
      ],
    );
  }
}

class _PostMediaTile extends StatelessWidget {
  const _PostMediaTile({
    required this.height,
    required this.colors,
    required this.icon,
  });

  final double height;
  final List<Color> colors;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              bottom: -8,
              child: Icon(
                Icons.apartment_rounded,
                size: 88,
                color: Colors.white.withValues(alpha: 0.32),
              ),
            ),
            Center(child: Icon(icon, color: Colors.white, size: 46)),
          ],
        ),
      ),
    );
  }
}

class _ReactionStack extends StatelessWidget {
  const _ReactionStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 18,
      child: Stack(
        children: const [
          _ReactionDot(icon: Icons.thumb_up, color: Color(0xFF1877F2)),
          Positioned(
            left: 14,
            child: _ReactionDot(icon: Icons.favorite, color: Color(0xFFE11D48)),
          ),
          Positioned(
            left: 28,
            child: _ReactionDot(
              icon: Icons.chat_bubble,
              color: Color(0xFF06B6D4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionDot extends StatelessWidget {
  const _ReactionDot({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 9,
      backgroundColor: color,
      child: Icon(icon, color: Colors.white, size: 10),
    );
  }
}

class _ComposerPrivacyTile extends StatelessWidget {
  const _ComposerPrivacyTile({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? _areaGreen : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _AreaBottomNav extends StatelessWidget {
  const _AreaBottomNav({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onChanged,
      height: 64,
      destinations: _bottomItems
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    this.size = 36,
    this.soft = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: soft ? color.withValues(alpha: 0.12) : color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: soft ? color : Colors.white, size: size * 0.54),
    );
  }
}

class _AreaAction {
  const _AreaAction({
    required this.title,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? subtitle;
}

class _StoryData {
  const _StoryData({
    required this.title,
    required this.initial,
    required this.color,
  });

  final String title;
  final String initial;
  final Color color;
}

class _AreaFeedPost {
  const _AreaFeedPost({
    required this.author,
    required this.initial,
    required this.avatarColor,
    required this.ward,
    required this.time,
    required this.type,
    required this.body,
    required this.likes,
    required this.comments,
    required this.mediaIcon,
    required this.mediaCount,
    required this.mediaColors,
  });

  final String author;
  final String initial;
  final Color avatarColor;
  final String ward;
  final String time;
  final String type;
  final String body;
  final String likes;
  final String comments;
  final IconData mediaIcon;
  final int mediaCount;
  final List<List<Color>> mediaColors;
}

class _BottomItem {
  const _BottomItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _feedTabs = ['সকল পোস্ট', 'ওয়ার্ড ভিত্তিক', 'ঘোষণা', 'ইভেন্ট'];

const _quickActions = [
  _AreaAction(
    title: 'সাইন',
    icon: Icons.sign_language_rounded,
    color: _areaGreen,
  ),
  _AreaAction(
    title: 'ব্লক',
    icon: Icons.grid_view_rounded,
    color: Color(0xFF9C27B0),
  ),
  _AreaAction(title: 'অডিও', icon: Icons.mic_rounded, color: Color(0xFF2E90FA)),
  _AreaAction(
    title: 'ছবি',
    icon: Icons.photo_rounded,
    color: Color(0xFFF79009),
  ),
  _AreaAction(
    title: 'ভিডিও',
    icon: Icons.videocam_rounded,
    color: Color(0xFFF04438),
  ),
  _AreaAction(
    title: 'পোস্ট',
    icon: Icons.edit_square,
    color: Color(0xFF3B82F6),
  ),
];

const _optionActions = [
  _AreaAction(
    title: 'সাইন',
    icon: Icons.sign_language_rounded,
    color: _areaGreen,
  ),
  _AreaAction(
    title: 'ব্লক',
    icon: Icons.grid_view_rounded,
    color: Color(0xFF9C27B0),
  ),
  _AreaAction(
    title: 'অডিও মেসেজ পাঠান',
    icon: Icons.mic_rounded,
    color: Color(0xFF2E90FA),
  ),
  _AreaAction(
    title: 'ছবি পোস্ট করুন',
    icon: Icons.photo_rounded,
    color: Color(0xFFF79009),
  ),
  _AreaAction(
    title: 'ভিডিও পোস্ট করুন',
    icon: Icons.videocam_rounded,
    color: Color(0xFFF04438),
  ),
  _AreaAction(
    title: 'হাই কোয়ালিটি পোস্ট',
    icon: Icons.hd_rounded,
    color: Color(0xFF2E90FA),
  ),
  _AreaAction(
    title: 'পোস্ট এনাউন্সমেন্ট',
    icon: Icons.campaign_rounded,
    color: Color(0xFFF97316),
  ),
  _AreaAction(
    title: 'লাইভ করুন',
    icon: Icons.live_tv_rounded,
    color: Color(0xFFF04438),
  ),
  _AreaAction(title: 'অডিও কল', icon: Icons.call_rounded, color: _areaGreen),
  _AreaAction(
    title: 'ভিডিও কল',
    icon: Icons.video_call_rounded,
    color: Color(0xFF2E90FA),
  ),
  _AreaAction(
    title: 'ডাক মুভ',
    icon: Icons.mail_rounded,
    color: Color(0xFF2E90FA),
  ),
  _AreaAction(
    title: 'এডিট প্রোফাইল',
    icon: Icons.person_rounded,
    color: Color(0xFF64748B),
  ),
  _AreaAction(
    title: 'লোকেশন সেট',
    subtitle: 'উত্তরা, ঢাকা',
    icon: Icons.location_on_rounded,
    color: _areaGreen,
  ),
  _AreaAction(
    title: 'সারা দেশ থেকে পোস্ট করুন',
    subtitle: 'শুধুমাত্র আমার এলাকা হোমপেজে দেখাবে',
    icon: Icons.public_rounded,
    color: Color(0xFF2E90FA),
  ),
];

const _stories = [
  _StoryData(title: 'হাতিরঝিল', initial: 'হা', color: Color(0xFF0F766E)),
  _StoryData(title: 'ওয়ার্ড-০৭', initial: '০৭', color: Color(0xFF2563EB)),
  _StoryData(title: 'সেক্টর-০১', initial: '০১', color: Color(0xFF475569)),
  _StoryData(title: 'নিয়ার বাই', initial: 'নে', color: Color(0xFF16A34A)),
];

const _bottomItems = [
  _BottomItem(
    label: 'হোম',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  _BottomItem(
    label: 'চ্যাট',
    icon: Icons.chat_bubble_outline_rounded,
    selectedIcon: Icons.chat_bubble_rounded,
  ),
  _BottomItem(
    label: 'লাইভ',
    icon: Icons.live_tv_outlined,
    selectedIcon: Icons.live_tv_rounded,
  ),
  _BottomItem(
    label: 'ফ্রেন্ড',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
  ),
];

const _posts = [
  _AreaFeedPost(
    author: 'রফিকুল ইসলাম',
    initial: 'র',
    avatarColor: Color(0xFF0F766E),
    ward: 'ওয়ার্ড-০৭',
    time: '১০ মিনিট আগে',
    type: 'ওয়ার্ড ভিত্তিক',
    body: 'আমাদের ওয়ার্ডের রাস্তার কাজ শুরু হয়েছে। সবাইকে ধন্যবাদ।',
    likes: '১২৬',
    comments: '২০',
    mediaIcon: Icons.construction_rounded,
    mediaCount: 2,
    mediaColors: [
      [Color(0xFF78350F), Color(0xFFF59E0B)],
      [Color(0xFF0F766E), Color(0xFF94A3B8)],
    ],
  ),
  _AreaFeedPost(
    author: 'মাসুমা আক্তার',
    initial: 'ম',
    avatarColor: Color(0xFF9C27B0),
    ward: 'ঘোষণা',
    time: '৩০ মিনিট আগে',
    type: 'ঘোষণা',
    body:
        'আগামীকাল সকাল ১০টায় ওয়ার্ড পরিচ্ছন্নতা কর্মসূচি হবে। সবাই উপস্থিত থাকুন।',
    likes: '৮৮',
    comments: '১২',
    mediaIcon: Icons.campaign_rounded,
    mediaCount: 1,
    mediaColors: [
      [Color(0xFF14532D), Color(0xFF22C55E)],
      [Color(0xFF14532D), Color(0xFF22C55E)],
    ],
  ),
  _AreaFeedPost(
    author: 'ইমরান হোসেন',
    initial: 'ই',
    avatarColor: Color(0xFF2563EB),
    ward: 'ইভেন্ট',
    time: '১ ঘন্টা আগে',
    type: 'ইভেন্ট',
    body:
        'শুক্রবার বিকেলে এলাকার মাঠে শিশুদের ফুটবল ম্যাচ। অংশ নিতে ইনবক্স করুন।',
    likes: '৬৪',
    comments: '৯',
    mediaIcon: Icons.sports_soccer_rounded,
    mediaCount: 1,
    mediaColors: [
      [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
      [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
    ],
  ),
];
