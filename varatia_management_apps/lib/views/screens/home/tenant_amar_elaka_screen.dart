import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as speech;

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_context.dart';
import '../../../core/utils/local_lang.dart';
import '../../../data/services/tenant_area_api_service.dart';
import '../../widgets/app_widgets.dart';
import 'amar_elaka/amar_elaka_announcement_page.dart';
import 'amar_elaka/amar_elaka_call_page.dart';
import 'amar_elaka/amar_elaka_friends_page.dart';
import 'amar_elaka/amar_elaka_live_page.dart';
import 'amar_elaka/amar_elaka_profile_page.dart';
import 'amar_elaka/amar_elaka_ward_chat_page.dart';
import 'amar_elaka/amar_elaka_ward_posts_page.dart';

const _areaBackground = Color(0xFFF6F8FB);
const _areaGreen = Color(0xFF079455);
const _areaDarkGreen = Color(0xFF047857);
const _areaSoftGreen = Color(0xFFEFFAF3);
const _areaBorder = Color(0xFFE5EAF2);
const _areaShadow = <BoxShadow>[
  BoxShadow(color: Color(0x120F172A), blurRadius: 18, offset: Offset(0, 8)),
  BoxShadow(color: Color(0x080F172A), blurRadius: 6, offset: Offset(0, 2)),
];
const _showLegacyAreaDashboard = false;

class TenantAmarElakaScreen extends StatefulWidget {
  const TenantAmarElakaScreen({super.key});

  @override
  State<TenantAmarElakaScreen> createState() => _TenantAmarElakaScreenState();
}

class _TenantAmarElakaScreenState extends State<TenantAmarElakaScreen> {
  final TenantAreaApiService _areaApiService = TenantAreaApiService();

  late Future<_AreaHomeUiData> _homeFuture;
  int _promoTabIndex = 0;
  int _promoBottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHome();
  }

  @override
  void dispose() {
    _areaApiService.dispose();
    super.dispose();
  }

  Future<_AreaHomeUiData> _loadHome() async {
    final home = await _areaApiService.getHome();
    return _AreaHomeUiData.fromApi(home);
  }

  void _reloadHome() {
    setState(() => _homeFuture = _loadHome());
  }

  void _openWardFeed(BuildContext context, _AreaWardData ward) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AmarElakaWardPostsPage(wardName: ward.titleEn),
      ),
    );
  }

  Future<void> _openPostComposer(
    BuildContext context,
    _AreaHomeUiData data, [
    _AreaPostType? type,
  ]) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _AreaPostComposerScreen(
          initialType: type,
          activeWard: data.activeWard,
          locationOptions: data.locationOptions,
        ),
      ),
    );

    if (created == true && mounted) {
      _reloadHome();
    }
  }

  void _openAllWards(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const _AllWardsScreen()));
  }

  void _openFeatureCenter(BuildContext context, _AreaHomeUiData data) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AmarElakaFriendsPage(wardName: data.activeWard.titleEn),
      ),
    );
  }

  void _openWardChat(BuildContext context, _AreaWardData ward) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AmarElakaWardChatPage(wardName: ward.titleEn),
      ),
    );
  }

  void _openLive(BuildContext context, _AreaWardData ward) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AmarElakaLivePage(wardName: ward.titleEn),
      ),
    );
  }

  void _openCall(
    BuildContext context,
    _AreaWardData ward,
    AmarElakaCallType callType,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AmarElakaCallPage(wardName: ward.titleEn, callType: callType),
      ),
    );
  }

  void _openProfile(BuildContext context, _AreaWardData ward) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AmarElakaProfilePage(
          wardName: ward.titleEn,
          location: '${ward.titleEn}, ${ward.area}',
        ),
      ),
    );
  }

  void _openAnnouncement(BuildContext context, _AreaWardData ward) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AmarElakaAnnouncementPage(wardName: ward.titleEn),
      ),
    );
  }

  void _showWardRules(BuildContext context, List<LocalizedText> rules) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _WardRulesSheet(rules: rules),
    );
  }

  void _showSoon(BuildContext context, String title) {
    showComingSoonSnackBar(context, title);
  }

  List<_PromoPostData> get _promoPostsForTab {
    final selected = _promoTabs[_promoTabIndex];
    if (selected == 'সকল পোস্ট') {
      return _promoPosts;
    }
    return _promoPosts.where((post) => post.type == selected).toList();
  }

  Future<void> _showPromoOptionsSheet(_AreaHomeUiData data) async {
    final option = await Navigator.of(context).push<_PromoOptionData>(
      MaterialPageRoute<_PromoOptionData>(
        builder: (_) => const _PromoOptionsPage(),
      ),
    );

    if (!mounted || option == null) {
      return;
    }

    _handlePromoOption(data, option);
  }

  void _handlePromoOption(_AreaHomeUiData data, _PromoOptionData option) {
    switch (option.kind) {
      case _PromoOptionKind.chat:
        _openWardChat(context, data.activeWard);
      case _PromoOptionKind.live:
        _openLive(context, data.activeWard);
      case _PromoOptionKind.audioCall:
        _openCall(context, data.activeWard, AmarElakaCallType.audio);
      case _PromoOptionKind.videoCall:
        _openCall(context, data.activeWard, AmarElakaCallType.video);
      case _PromoOptionKind.profile:
        _openProfile(context, data.activeWard);
      case _PromoOptionKind.announcement:
        _openAnnouncement(context, data.activeWard);
      case _PromoOptionKind.post:
        _openPostComposer(context, data);
      case _PromoOptionKind.soon:
        _showSoon(context, option.label);
    }
  }

  void _showPromoFilterSheet() {
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
            for (var index = 0; index < _promoTabs.length; index++)
              RadioListTile<int>(
                value: index,
                groupValue: _promoTabIndex,
                activeColor: _areaGreen,
                title: Text(_promoTabs[index]),
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() => _promoTabIndex = value ?? 0);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _areaBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPostComposer(context, _fallbackAreaHomeUiData),
        backgroundColor: _areaGreen,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 34),
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _promoBottomIndex,
        onDestinationSelected: (index) {
          setState(() => _promoBottomIndex = index);
          final data = _fallbackAreaHomeUiData;
          switch (index) {
            case 1:
              _openWardChat(context, data.activeWard);
            case 2:
              _openLive(context, data.activeWard);
            case 3:
              _openFeatureCenter(context, data);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'হোম',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'চ্যাট',
          ),
          NavigationDestination(
            icon: Icon(Icons.live_tv_outlined),
            selectedIcon: Icon(Icons.live_tv_rounded),
            label: 'লাইভ',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'ফ্রেন্ড',
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: FutureBuilder<_AreaHomeUiData>(
              future: _homeFuture,
              builder: (context, snapshot) {
                final data = snapshot.data ?? _fallbackAreaHomeUiData;

                return RefreshIndicator(
                  onRefresh: () async {
                    _reloadHome();
                    await _homeFuture;
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 92),
                    children: [
                      _PromoAreaHeader(
                        wardName: data.activeWard.titleEn,
                        notificationCount: data.notificationUnreadCount,
                        onMenu: () => _showPromoOptionsSheet(data),
                        onNotify: () => _showSoon(context, 'নোটিফিকেশন'),
                        onProfile: () => _openProfile(context, data.activeWard),
                      ),
                      _PromoQuickActions(
                        onAction: (type) {
                          switch (type) {
                            case _PromoActionType.sign:
                              _showWardRules(context, data.wardRules);
                            case _PromoActionType.block:
                              _openAllWards(context);
                            case _PromoActionType.audio:
                              _openCall(
                                context,
                                data.activeWard,
                                AmarElakaCallType.audio,
                              );
                            case _PromoActionType.photo:
                              _openPostComposer(
                                context,
                                data,
                                _AreaPostType.problem,
                              );
                            case _PromoActionType.video:
                              _openPostComposer(
                                context,
                                data,
                                _AreaPostType.service,
                              );
                            case _PromoActionType.post:
                              _showPromoOptionsSheet(data);
                          }
                        },
                      ),
                      _PromoStoryStrip(
                        wards: data.wards,
                        onAddStory: () => _showSoon(context, 'Add Story'),
                        onWardTap: (ward) => _openWardFeed(context, ward),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                        child: _PromoCountryPostCard(
                          onTap: () => _openPostComposer(context, data),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _PromoFeedTabs(
                        selectedIndex: _promoTabIndex,
                        onChanged: (index) =>
                            setState(() => _promoTabIndex = index),
                        onFilter: _showPromoFilterSheet,
                      ),
                      const SizedBox(height: 12),
                      ..._promoPostsForTab.map(
                        (post) => Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: _PromoPostCard(post: post),
                        ),
                      ),
                      if (_showLegacyAreaDashboard) ...[
                        const SizedBox(height: 4),
                        _AreaHubHeader(
                          notificationCount: data.notificationUnreadCount,
                          onBack: () => Navigator.of(context).maybePop(),
                          onNotify: () => _showSoon(
                            context,
                            context.tr(bn: 'নোটিফিকেশন', en: 'Notifications'),
                          ),
                        ),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        if (snapshot.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _AreaApiStatusTile(
                              message: snapshot.error.toString(),
                              onRetry: _reloadHome,
                            ),
                          ),
                        const SizedBox(height: 14),
                        _ActiveWardCard(
                          ward: data.activeWard,
                          onTap: () => _openWardFeed(context, data.activeWard),
                        ),
                        const SizedBox(height: 12),
                        _AreaSocialDashboardCard(
                          activeWard: data.activeWard,
                          onOpenFeatures: () =>
                              _openFeatureCenter(context, data),
                          onOpenChat: () =>
                              _openWardChat(context, data.activeWard),
                          onGoLive: () => _openLive(context, data.activeWard),
                          onAudioCall: () => _openCall(
                            context,
                            data.activeWard,
                            AmarElakaCallType.audio,
                          ),
                          onVideoCall: () => _openCall(
                            context,
                            data.activeWard,
                            AmarElakaCallType.video,
                          ),
                          onOpenProfile: () =>
                              _openProfile(context, data.activeWard),
                        ),
                        const SizedBox(height: 12),
                        _WardRulesTile(
                          onTap: () => _showWardRules(context, data.wardRules),
                        ),
                        const SizedBox(height: 14),
                        _QuickPostHubCard(
                          onAction: (type) {
                            if (type == _AreaPostType.announcement) {
                              _openAnnouncement(context, data.activeWard);
                              return;
                            }
                            _openPostComposer(context, data, type);
                          },
                        ),
                        const SizedBox(height: 14),
                        _AreaUpdatesCard(
                          wards: data.wards,
                          onSeeAll: () => _openAllWards(context),
                          onWardTap: (ward) => _openWardFeed(context, ward),
                        ),
                        const SizedBox(height: 14),
                        _EmergencyHelplineCard(
                          helpline: data.emergencyHelpline,
                          onCall: () => _showSoon(
                            context,
                            context.tr(bn: 'জরুরি কল', en: 'Emergency call'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _WardFeedPreviewCard(
                          posts: data.feedPosts,
                          onOpenFeed: () =>
                              _openWardFeed(context, data.activeWard),
                          onCreatePost: () => _openPostComposer(context, data),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoOptionsPage extends StatelessWidget {
  const _PromoOptionsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _areaBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'ফিরুন',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'সব অপশন',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemBuilder: (context, index) {
                final option = _promoOptions[index];
                return Material(
                  color: Colors.white,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          _PromoIconBubble(
                            icon: option.icon,
                            color: option.color,
                            soft: true,
                            size: 34,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                if (option.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    option.subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 60,
                endIndent: 12,
                color: _areaBorder,
              ),
              itemCount: _promoOptions.length,
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoAreaHeader extends StatelessWidget {
  const _PromoAreaHeader({
    required this.wardName,
    required this.notificationCount,
    required this.onMenu,
    required this.onNotify,
    required this.onProfile,
  });

  final String wardName;
  final int notificationCount;
  final VoidCallback onMenu;
  final VoidCallback onNotify;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 10, 10, 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'মেনু',
            onPressed: onMenu,
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
                    const Icon(Icons.location_on, size: 18),
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'নোটিফিকেশন',
                onPressed: onNotify,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: onProfile,
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

class _PromoQuickActions extends StatelessWidget {
  const _PromoQuickActions({required this.onAction});

  final ValueChanged<_PromoActionType> onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _promoActions
            .map(
              (action) => InkWell(
                onTap: () => onAction(action.type),
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  child: Column(
                    children: [
                      _PromoIconBubble(
                        icon: action.icon,
                        color: action.color,
                        size: 42,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PromoStoryStrip extends StatelessWidget {
  const _PromoStoryStrip({
    required this.wards,
    required this.onAddStory,
    required this.onWardTap,
  });

  final List<_AreaWardData> wards;
  final VoidCallback onAddStory;
  final ValueChanged<_AreaWardData> onWardTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _PromoStoryItem(
              title: 'Add Story',
              initial: 'র',
              color: const Color(0xFF2563EB),
              add: true,
              onTap: onAddStory,
            ),
            for (final ward in wards.take(4))
              _PromoStoryItem(
                title: ward.titleEn,
                initial: ward.titleEn.replaceAll('Ward ', ''),
                color: ward.selected ? _areaGreen : const Color(0xFF475569),
                onTap: () => onWardTap(ward),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromoStoryItem extends StatelessWidget {
  const _PromoStoryItem({
    required this.title,
    required this.initial,
    required this.color,
    required this.onTap,
    this.add = false,
  });

  final String title;
  final String initial;
  final Color color;
  final VoidCallback onTap;
  final bool add;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
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
                    color: add ? Colors.transparent : AppColors.primary,
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
                          fontSize: 18,
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
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCountryPostCard extends StatelessWidget {
  const _PromoCountryPostCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AreaSurfaceCard(
      radius: 12,
      padding: const EdgeInsets.all(12),
      boxShadow: const [],
      onTap: onTap,
      child: Row(
        children: [
          const _PromoIconBubble(
            icon: Icons.shield_rounded,
            color: AppColors.danger,
            soft: true,
            size: 42,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'সারা দেশ থেকে পোস্ট করুন',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'শুধুমাত্র "আমার এলাকা" হোমপেজে দেখাবে',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.public_rounded, color: _areaGreen),
        ],
      ),
    );
  }
}

class _PromoFeedTabs extends StatelessWidget {
  const _PromoFeedTabs({
    required this.selectedIndex,
    required this.onChanged,
    required this.onFilter,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onFilter;

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
                  for (var index = 0; index < _promoTabs.length; index++)
                    InkWell(
                      onTap: () => onChanged(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: selectedIndex == index
                                  ? _areaGreen
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          _promoTabs[index],
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: selectedIndex == index
                                    ? _areaGreen
                                    : AppColors.textPrimary,
                                fontWeight: selectedIndex == index
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'ফিল্টার',
            onPressed: onFilter,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }
}

class _PromoPostCard extends StatelessWidget {
  const _PromoPostCard({required this.post});

  final _PromoPostData post;

  @override
  Widget build(BuildContext context) {
    return _AreaSurfaceCard(
      radius: 12,
      padding: const EdgeInsets.all(12),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F8EF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            post.type,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: _areaGreen,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
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
              const Icon(Icons.more_horiz_rounded),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _PromoMediaTile(colors: post.colors.first)),
              if (post.colors.length > 1) ...[
                const SizedBox(width: 6),
                Expanded(child: _PromoMediaTile(colors: post.colors.last)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const _PromoReactionStack(),
              const SizedBox(width: 6),
              Text(post.likes),
              const Spacer(),
              Text('${post.comments} মন্তব্য'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoMediaTile extends StatelessWidget {
  const _PromoMediaTile({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 148,
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
            const Center(
              child: Icon(
                Icons.construction_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoReactionStack extends StatelessWidget {
  const _PromoReactionStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 18,
      child: Stack(
        children: const [
          _PromoReactionDot(icon: Icons.thumb_up, color: Color(0xFF1877F2)),
          Positioned(
            left: 14,
            child: _PromoReactionDot(
              icon: Icons.favorite,
              color: Color(0xFFE11D48),
            ),
          ),
          Positioned(
            left: 28,
            child: _PromoReactionDot(
              icon: Icons.chat_bubble,
              color: Color(0xFF06B6D4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoReactionDot extends StatelessWidget {
  const _PromoReactionDot({required this.icon, required this.color});

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

class _PromoIconBubble extends StatelessWidget {
  const _PromoIconBubble({
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

enum _PromoActionType { sign, block, audio, photo, video, post }

enum _PromoOptionKind {
  soon,
  chat,
  live,
  audioCall,
  videoCall,
  profile,
  announcement,
  post,
}

class _PromoActionData {
  const _PromoActionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.type,
  });

  final String label;
  final IconData icon;
  final Color color;
  final _PromoActionType type;
}

class _PromoOptionData {
  const _PromoOptionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.kind,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final Color color;
  final _PromoOptionKind kind;
  final String? subtitle;
}

class _PromoPostData {
  const _PromoPostData({
    required this.author,
    required this.initial,
    required this.avatarColor,
    required this.time,
    required this.type,
    required this.body,
    required this.likes,
    required this.comments,
    required this.colors,
  });

  final String author;
  final String initial;
  final Color avatarColor;
  final String time;
  final String type;
  final String body;
  final String likes;
  final String comments;
  final List<List<Color>> colors;
}

const _promoTabs = ['সকল পোস্ট', 'ওয়ার্ড ভিত্তিক', 'ঘোষণা', 'ইভেন্ট'];

const _promoActions = [
  _PromoActionData(
    label: 'সাইন',
    icon: Icons.sign_language_rounded,
    color: _areaGreen,
    type: _PromoActionType.sign,
  ),
  _PromoActionData(
    label: 'ব্লক',
    icon: Icons.grid_view_rounded,
    color: Color(0xFF9C27B0),
    type: _PromoActionType.block,
  ),
  _PromoActionData(
    label: 'অডিও',
    icon: Icons.mic_rounded,
    color: Color(0xFF2E90FA),
    type: _PromoActionType.audio,
  ),
  _PromoActionData(
    label: 'ছবি',
    icon: Icons.photo_rounded,
    color: Color(0xFFF79009),
    type: _PromoActionType.photo,
  ),
  _PromoActionData(
    label: 'ভিডিও',
    icon: Icons.videocam_rounded,
    color: Color(0xFFF04438),
    type: _PromoActionType.video,
  ),
  _PromoActionData(
    label: 'পোস্ট',
    icon: Icons.edit_square,
    color: Color(0xFF3B82F6),
    type: _PromoActionType.post,
  ),
];

const _promoOptions = [
  _PromoOptionData(
    label: 'সাইন',
    icon: Icons.sign_language_rounded,
    color: _areaGreen,
    kind: _PromoOptionKind.soon,
  ),
  _PromoOptionData(
    label: 'ব্লক',
    icon: Icons.grid_view_rounded,
    color: Color(0xFF9C27B0),
    kind: _PromoOptionKind.soon,
  ),
  _PromoOptionData(
    label: 'অডিও মেসেজ পাঠান',
    icon: Icons.mic_rounded,
    color: Color(0xFF2E90FA),
    kind: _PromoOptionKind.chat,
  ),
  _PromoOptionData(
    label: 'ছবি পোস্ট করুন',
    icon: Icons.photo_rounded,
    color: Color(0xFFF79009),
    kind: _PromoOptionKind.post,
  ),
  _PromoOptionData(
    label: 'ভিডিও পোস্ট করুন',
    icon: Icons.videocam_rounded,
    color: Color(0xFFF04438),
    kind: _PromoOptionKind.post,
  ),
  _PromoOptionData(
    label: 'পোস্ট এনাউন্সমেন্ট',
    icon: Icons.campaign_rounded,
    color: Color(0xFFF97316),
    kind: _PromoOptionKind.announcement,
  ),
  _PromoOptionData(
    label: 'লাইভ করুন',
    icon: Icons.live_tv_rounded,
    color: Color(0xFFF04438),
    kind: _PromoOptionKind.live,
  ),
  _PromoOptionData(
    label: 'অডিও কল',
    icon: Icons.call_rounded,
    color: _areaGreen,
    kind: _PromoOptionKind.audioCall,
  ),
  _PromoOptionData(
    label: 'ভিডিও কল',
    icon: Icons.video_call_rounded,
    color: Color(0xFF2E90FA),
    kind: _PromoOptionKind.videoCall,
  ),
  _PromoOptionData(
    label: 'এডিট প্রোফাইল',
    icon: Icons.person_rounded,
    color: Color(0xFF64748B),
    kind: _PromoOptionKind.profile,
  ),
  _PromoOptionData(
    label: 'লোকেশন সেট',
    subtitle: 'উত্তরা, ঢাকা',
    icon: Icons.location_on_rounded,
    color: _areaGreen,
    kind: _PromoOptionKind.soon,
  ),
  _PromoOptionData(
    label: 'সারা দেশ থেকে পোস্ট করুন',
    subtitle: 'শুধুমাত্র আমার এলাকা হোমপেজে দেখাবে',
    icon: Icons.public_rounded,
    color: Color(0xFF2E90FA),
    kind: _PromoOptionKind.post,
  ),
];

const _promoPosts = [
  _PromoPostData(
    author: 'রফিকুল ইসলাম',
    initial: 'র',
    avatarColor: Color(0xFF0F766E),
    time: '১০ মিনিট আগে',
    type: 'ওয়ার্ড ভিত্তিক',
    body: 'আমাদের ওয়ার্ডের রাস্তার কাজ শুরু হয়েছে। সবাইকে ধন্যবাদ।',
    likes: '১২৬',
    comments: '২০',
    colors: [
      [Color(0xFF78350F), Color(0xFFF59E0B)],
      [Color(0xFF0F766E), Color(0xFF94A3B8)],
    ],
  ),
  _PromoPostData(
    author: 'মাসুমা আক্তার',
    initial: 'ম',
    avatarColor: Color(0xFF9C27B0),
    time: '৩০ মিনিট আগে',
    type: 'ঘোষণা',
    body: 'আগামীকাল সকাল ১০টায় ওয়ার্ড পরিচ্ছন্নতা কর্মসূচি হবে।',
    likes: '৮৮',
    comments: '১২',
    colors: [
      [Color(0xFF14532D), Color(0xFF22C55E)],
    ],
  ),
  _PromoPostData(
    author: 'ইমরান হোসেন',
    initial: 'ই',
    avatarColor: Color(0xFF2563EB),
    time: '১ ঘন্টা আগে',
    type: 'ইভেন্ট',
    body: 'শুক্রবার বিকেলে এলাকার মাঠে শিশুদের ফুটবল ম্যাচ।',
    likes: '৬৪',
    comments: '৯',
    colors: [
      [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
    ],
  ),
];

class _AreaHubHeader extends StatelessWidget {
  const _AreaHubHeader({
    required this.notificationCount,
    required this.onBack,
    required this.onNotify,
  });

  final int notificationCount;
  final VoidCallback onBack;
  final VoidCallback onNotify;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AreaRoundIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(bn: 'আমার এলাকা', en: 'Amar eLaka'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  height: 1.16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  bn: 'আপনার ওয়ার্ডের মানুষের সাথে যুক্ত থাকুন',
                  en: 'Stay connected with people in your ward',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _NotificationBell(count: notificationCount, onTap: onNotify),
      ],
    );
  }
}

class _ActiveWardCard extends StatelessWidget {
  const _ActiveWardCard({required this.ward, required this.onTap});

  final _AreaWardData ward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AreaSurfaceCard(
      color: _areaSoftGreen,
      borderColor: _areaGreen,
      borderWidth: 1.3,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: const BoxDecoration(
              color: _areaGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc(ward.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ward.area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        context.loc(ward.memberLabel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (ward.verified) const _VerifiedWardChip(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedWardChip extends StatelessWidget {
  const _VerifiedWardChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF8E7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFA7E9BE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 14, color: _areaGreen),
          const SizedBox(width: 4),
          Text(
            context.tr(bn: 'Verified Ward', en: 'Verified Ward'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _areaDarkGreen,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WardRulesTile extends StatelessWidget {
  const _WardRulesTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AreaSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textPrimary, width: 1.4),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(bn: 'ওয়ার্ডের নিয়মাবলী', en: 'Ward guidelines'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _AreaSocialDashboardCard extends StatefulWidget {
  const _AreaSocialDashboardCard({
    required this.activeWard,
    required this.onOpenFeatures,
    required this.onOpenChat,
    required this.onGoLive,
    required this.onAudioCall,
    required this.onVideoCall,
    required this.onOpenProfile,
  });

  final _AreaWardData activeWard;
  final VoidCallback onOpenFeatures;
  final VoidCallback onOpenChat;
  final VoidCallback onGoLive;
  final VoidCallback onAudioCall;
  final VoidCallback onVideoCall;
  final VoidCallback onOpenProfile;

  @override
  State<_AreaSocialDashboardCard> createState() =>
      _AreaSocialDashboardCardState();
}

class _AreaSocialDashboardCardState extends State<_AreaSocialDashboardCard> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final surface = _darkMode ? const Color(0xFF111827) : Colors.white;
    final textColor = _darkMode ? Colors.white : AppColors.textPrimary;
    final mutedColor = _darkMode
        ? const Color(0xFFCBD5E1)
        : AppColors.textMuted;

    return _AreaSurfaceCard(
      color: surface,
      borderColor: _darkMode ? const Color(0xFF334155) : _areaBorder,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Area social hub',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _darkMode ? Icons.dark_mode_rounded : Icons.light_mode,
                    color: mutedColor,
                    size: 18,
                  ),
                  Switch(
                    value: _darkMode,
                    activeColor: _areaGreen,
                    onChanged: (value) => setState(() => _darkMode = value),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _PresenceDot(active: true),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${widget.activeWard.titleEn} group is active now',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const Icon(Icons.verified_rounded, color: _areaGreen, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AreaHubActionButton(
                  icon: Icons.group_add_rounded,
                  label: 'Friends',
                  onTap: widget.onOpenFeatures,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AreaHubActionButton(
                  icon: Icons.forum_rounded,
                  label: 'Ward chat',
                  onTap: widget.onOpenChat,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AreaHubActionButton(
                  icon: Icons.live_tv_rounded,
                  label: 'Live',
                  onTap: widget.onGoLive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _AreaHubActionButton(
                  icon: Icons.call_rounded,
                  label: 'Audio call',
                  onTap: widget.onAudioCall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AreaHubActionButton(
                  icon: Icons.videocam_rounded,
                  label: 'Video call',
                  onTap: widget.onVideoCall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AreaHubActionButton(
                  icon: Icons.manage_accounts_rounded,
                  label: 'Profile',
                  onTap: widget.onOpenProfile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AreaHubActionButton extends StatelessWidget {
  const _AreaHubActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AreaSurfaceCard(
      padding: EdgeInsets.zero,
      radius: 12,
      boxShadow: const [],
      onTap: onTap,
      child: SizedBox(
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _areaGreen, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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
      height: 9,
      width: 9,
      decoration: BoxDecoration(
        color: active ? _areaGreen : AppColors.textMuted,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}

class _QuickPostHubCard extends StatelessWidget {
  const _QuickPostHubCard({required this.onAction});

  final ValueChanged<_AreaPostType> onAction;

  @override
  Widget build(BuildContext context) {
    return _AreaSurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(bn: 'কুইক পোস্ট করুন', en: 'Quick post'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _areaQuickActions
                .map(
                  (action) => Expanded(
                    child: _AreaQuickActionButton(
                      action: action,
                      onTap: () => onAction(action.type),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AreaQuickActionButton extends StatelessWidget {
  const _AreaQuickActionButton({required this.action, required this.onTap});

  final _AreaQuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: action.color.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(action.icon, color: action.color, size: 30),
              ),
              const SizedBox(height: 7),
              Text(
                context.loc(action.label),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaUpdatesCard extends StatelessWidget {
  const _AreaUpdatesCard({
    required this.wards,
    required this.onSeeAll,
    required this.onWardTap,
  });

  final List<_AreaWardData> wards;
  final VoidCallback onSeeAll;
  final ValueChanged<_AreaWardData> onWardTap;

  @override
  Widget build(BuildContext context) {
    return _AreaSurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(bn: 'সব এলাকার আপডেট', en: 'All area updates'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  context.tr(bn: 'সব দেখুন', en: 'See all'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: wards
                  .take(5)
                  .map(
                    (ward) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _WardUpdateChip(
                        ward: ward,
                        onTap: () => onWardTap(ward),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WardUpdateChip extends StatelessWidget {
  const _WardUpdateChip({required this.ward, required this.onTap});

  final _AreaWardData ward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = ward.selected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 86,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _areaSoftGreen : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _areaGreen : _areaBorder,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                ward.titleEn,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ward.area,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyHelplineCard extends StatelessWidget {
  const _EmergencyHelplineCard({required this.helpline, required this.onCall});

  final _AreaHelplineData? helpline;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final callLabel = helpline?.phone.isNotEmpty == true
        ? helpline!.phone
        : context.tr(bn: 'কল করুন', en: 'Call');

    return _AreaSurfaceCard(
      color: const Color(0xFFF0FAF5),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(bn: 'জরুরি হেল্পলাইন', en: 'Emergency helpline'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    bn: 'জরুরি প্রয়োজনে কল করুন',
                    en: 'Call when you need urgent help',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onCall,
            style: FilledButton.styleFrom(
              backgroundColor: _areaGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(116, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            icon: const Icon(Icons.call_rounded, size: 22),
            label: Text(
              callLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _WardFeedPreviewCard extends StatelessWidget {
  const _WardFeedPreviewCard({
    required this.posts,
    required this.onOpenFeed,
    required this.onCreatePost,
  });

  final List<_AreaFeedPostData> posts;
  final VoidCallback onOpenFeed;
  final VoidCallback onCreatePost;

  @override
  Widget build(BuildContext context) {
    return _AreaSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(bn: 'ওয়ার্ড ফিড', en: 'Ward feed'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onOpenFeed,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  context.tr(bn: 'খুলুন', en: 'Open'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FeedInputBar(onTap: onCreatePost),
          const SizedBox(height: 12),
          ...posts
              .take(2)
              .map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AreaFeedPostCard(post: post, compact: true),
                ),
              ),
        ],
      ),
    );
  }
}

class _AreaWardFeedScreen extends StatefulWidget {
  const _AreaWardFeedScreen({required this.ward});

  final _AreaWardData ward;

  @override
  State<_AreaWardFeedScreen> createState() => _AreaWardFeedScreenState();
}

class _AreaWardFeedScreenState extends State<_AreaWardFeedScreen> {
  final TenantAreaApiService _areaApiService = TenantAreaApiService();

  late Future<List<_AreaFeedPostData>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _loadPosts();
  }

  @override
  void dispose() {
    _areaApiService.dispose();
    super.dispose();
  }

  Future<List<_AreaFeedPostData>> _loadPosts() async {
    final result = await _areaApiService.getPosts(
      wardId: widget.ward.id.isEmpty ? null : widget.ward.id,
    );
    return result.posts.map(_AreaFeedPostData.fromApi).toList(growable: false);
  }

  void _reloadPosts() {
    setState(() => _postsFuture = _loadPosts());
  }

  Future<void> _openComposer(BuildContext context) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _AreaPostComposerScreen(activeWard: widget.ward),
      ),
    );

    if (created == true && mounted) {
      _reloadPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _areaBackground,
      appBar: AppBar(
        backgroundColor: _areaDarkGreen,
        foregroundColor: Colors.white,
        toolbarHeight: 68,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc(widget.ward.title),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              widget.ward.area,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ward group chat',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _WardGroupChatScreen(ward: widget.ward),
              ),
            ),
            icon: const Icon(Icons.forum_rounded),
          ),
          IconButton(
            tooltip: context.tr(bn: 'সার্চ', en: 'Search'),
            onPressed: () => showComingSoonSnackBar(
              context,
              context.tr(bn: 'ওয়ার্ড সার্চ', en: 'Ward search'),
            ),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: context.tr(bn: 'আরও', en: 'More'),
            onPressed: () => showComingSoonSnackBar(
              context,
              context.tr(bn: 'ওয়ার্ড অপশন', en: 'Ward options'),
            ),
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openComposer(context),
        backgroundColor: _areaGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: FutureBuilder<List<_AreaFeedPostData>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              final posts = snapshot.data ?? _areaFeedPosts;

              return RefreshIndicator(
                onRefresh: () async {
                  _reloadPosts();
                  await _postsFuture;
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 92),
                  children: [
                    const _AreaFeedTabs(),
                    const SizedBox(height: 12),
                    _WardGroupChatBanner(
                      ward: widget.ward,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              _WardGroupChatScreen(ward: widget.ward),
                        ),
                      ),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    if (snapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _AreaApiStatusTile(
                          message: snapshot.error.toString(),
                          onRetry: _reloadPosts,
                        ),
                      ),
                    const SizedBox(height: 12),
                    _FeedInputBar(onTap: () => _openComposer(context)),
                    const SizedBox(height: 14),
                    ...posts.map(
                      (post) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _AreaFeedPostCard(post: post),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WardGroupChatBanner extends StatelessWidget {
  const _WardGroupChatBanner({required this.ward, required this.onTap});

  final _AreaWardData ward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AreaSurfaceCard(
      padding: const EdgeInsets.all(14),
      color: const Color(0xFFEFFAF3),
      borderColor: const Color(0xFFB7E4C7),
      boxShadow: const [],
      onTap: onTap,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: _areaGreen,
                child: Icon(Icons.groups_rounded, color: Colors.white),
              ),
              const Positioned(
                right: -1,
                bottom: 1,
                child: _PresenceDot(active: true),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ward.titleEn} separate group chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Typing, active status, audio, photo and video message UI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _areaGreen),
        ],
      ),
    );
  }
}

class _AreaPostComposerScreen extends StatefulWidget {
  const _AreaPostComposerScreen({
    this.initialType,
    this.activeWard,
    this.locationOptions = const <String>[],
  });

  final _AreaPostType? initialType;
  final _AreaWardData? activeWard;
  final List<String> locationOptions;

  @override
  State<_AreaPostComposerScreen> createState() =>
      _AreaPostComposerScreenState();
}

class _AreaPostComposerScreenState extends State<_AreaPostComposerScreen> {
  final TextEditingController _detailsController = TextEditingController();
  final speech.SpeechToText _speechToText = speech.SpeechToText();
  final TenantAreaApiService _areaApiService = TenantAreaApiService();

  late _AreaPostType _selectedType;
  _AreaPrivacy _privacy = _AreaPrivacy.wardOnly;
  String _selectedLocation = 'Ward 14, Mirpur-10';
  String? _attachedPhotoName;
  String? _attachedVideoName;
  double? _selectedLatitude;
  double? _selectedLongitude;
  bool _isListening = false;
  bool _isPickingPhoto = false;
  bool _isPickingVideo = false;
  bool _highQualityPost = true;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  String _textBeforeVoice = '';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? _AreaPostType.problem;
    _selectedLocation = widget.locationOptions.isNotEmpty
        ? widget.locationOptions.first
        : _formatWardLocation(widget.activeWard) ?? _selectedLocation;
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _areaApiService.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _postTypeLabel(_AreaPostType type) {
    final action = _areaQuickActions.firstWhere((item) => item.type == type);
    return context.loc(action.label);
  }

  String _postTypeApiValue(_AreaPostType type) {
    return switch (type) {
      _AreaPostType.problem => 'problem',
      _AreaPostType.home => 'home',
      _AreaPostType.service => 'service',
      _AreaPostType.announcement => 'announcement',
      _AreaPostType.help => 'help',
    };
  }

  String _privacyApiValue(_AreaPrivacy privacy) {
    return switch (privacy) {
      _AreaPrivacy.wardOnly => 'ward_only',
      _AreaPrivacy.wardAndNearby => 'ward_and_nearby',
      _AreaPrivacy.onlyAdmins => 'only_admins',
      _AreaPrivacy.nationwideHomePage => 'nationwide_homepage',
    };
  }

  String _postScopeApiValue(_AreaPrivacy privacy) {
    return privacy == _AreaPrivacy.nationwideHomePage
        ? 'amar_elaka_home_nationwide'
        : 'ward_based';
  }

  String? _formatWardLocation(_AreaWardData? ward) {
    if (ward == null) {
      return null;
    }

    final title = ward.titleEn.trim();
    final area = ward.area.trim();
    if (title.isEmpty) {
      return area.isEmpty ? null : area;
    }
    if (area.isEmpty) {
      return title;
    }

    return '$title, $area';
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) {
          return;
        }

        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (!mounted) {
          return;
        }

        setState(() => _isListening = false);
        _showMessage(
          context.tr(
            bn: 'ভয়েস ইনপুট চালু করা যায়নি।',
            en: 'Unable to start voice input.',
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (!available) {
      _showMessage(
        context.tr(
          bn: 'এই ডিভাইসে ভয়েস ইনপুট পাওয়া যায়নি।',
          en: 'Voice input is not available on this device.',
        ),
      );
      return;
    }

    _textBeforeVoice = _detailsController.text.trimRight();
    setState(() => _isListening = true);

    await _speechToText.listen(
      localeId: context.isBangla ? 'bn_BD' : 'en_US',
      listenOptions: speech.SpeechListenOptions(partialResults: true),
      onResult: (result) {
        if (!mounted) {
          return;
        }

        final recognizedText = result.recognizedWords.trim();
        if (recognizedText.isEmpty) {
          return;
        }

        final separator = _textBeforeVoice.isEmpty ? '' : '\n';
        _detailsController.text = '$_textBeforeVoice$separator$recognizedText';
        _detailsController.selection = TextSelection.fromPosition(
          TextPosition(offset: _detailsController.text.length),
        );
      },
    );
  }

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto) {
      return;
    }

    setState(() => _isPickingPhoto = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }

      setState(() => _attachedPhotoName = result.files.single.name);
      _showMessage(context.tr(bn: 'ছবি যোগ করা হয়েছে।', en: 'Photo attached.'));
    } catch (_) {
      if (mounted) {
        _showMessage(
          context.tr(bn: 'ছবি যোগ করা যায়নি।', en: 'Unable to attach photo.'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_isPickingVideo) {
      return;
    }

    setState(() => _isPickingVideo = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }

      setState(() => _attachedVideoName = result.files.single.name);
      _showMessage('Video attached.');
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to attach video.');
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingVideo = false);
      }
    }
  }

  Future<void> _loadCurrentLocation() async {
    if (_isLoadingLocation) {
      return;
    }

    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) {
        return;
      }

      if (!serviceEnabled) {
        _showMessage(
          context.tr(
            bn: 'ডিভাইস লোকেশন চালু করুন।',
            en: 'Please turn on device location.',
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) {
        return;
      }

      if (permission == LocationPermission.denied) {
        _showMessage(
          context.tr(
            bn: 'লোকেশন পারমিশন প্রয়োজন।',
            en: 'Location permission is required.',
          ),
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          context.tr(
            bn: 'অ্যাপ সেটিংস থেকে লোকেশন পারমিশন দিন।',
            en: 'Enable location permission from app settings.',
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedLocation =
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
      });

      _showMessage(
        context.tr(bn: 'GPS লোকেশন যোগ হয়েছে।', en: 'GPS location added.'),
      );
    } catch (_) {
      if (mounted) {
        _showMessage(
          context.tr(
            bn: 'GPS লোকেশন নেওয়া যায়নি।',
            en: 'Unable to load GPS location.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _showLocationPicker() async {
    final locationOptions = widget.locationOptions.isNotEmpty
        ? widget.locationOptions
        : _areaLocationOptions;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ComposerOptionSheet<String>(
        title: context.tr(bn: 'লোকেশন নির্বাচন করুন', en: 'Select location'),
        options: [
          for (final location in locationOptions)
            _ComposerOption(
              value: location,
              title: location,
              icon: Icons.location_on_rounded,
            ),
        ],
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _selectedLocation = selected;
      _selectedLatitude = null;
      _selectedLongitude = null;
    });
  }

  Future<void> _showPrivacyPicker() async {
    final selected = await showModalBottomSheet<_AreaPrivacy>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ComposerOptionSheet<_AreaPrivacy>(
        title: context.tr(bn: 'গোপনীয়তা নির্বাচন করুন', en: 'Select privacy'),
        options: [
          for (final privacy in _AreaPrivacy.values)
            _ComposerOption(
              value: privacy,
              title: privacy.label(context),
              subtitle: privacy.subtitle(context),
              icon: privacy.icon,
            ),
        ],
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() => _privacy = selected);
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final details = _detailsController.text.trim();

    if (details.isEmpty) {
      _showMessage(
        context.tr(
          bn: 'পোস্টের বিস্তারিত লিখুন।',
          en: 'Please write post details.',
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      final result = await _areaApiService.createPost(
        wardId: widget.activeWard?.id,
        postType: _postTypeApiValue(_selectedType),
        details: details,
        locationLabel: _selectedLocation,
        privacy: _privacyApiValue(_privacy),
        attachmentName: _attachedPhotoName ?? _attachedVideoName,
        attachmentMediaType: _attachedVideoName != null
            ? 'video'
            : _attachedPhotoName != null
            ? 'image'
            : null,
        highQuality: _highQualityPost,
        postScope: _postScopeApiValue(_privacy),
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
      );

      if (!mounted) {
        return;
      }

      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(result.message),
          content: Text(
            [
              '${context.tr(bn: 'ধরন', en: 'Type')}: ${_postTypeLabel(_selectedType)}',
              '${context.tr(bn: 'লোকেশন', en: 'Location')}: $_selectedLocation',
              '${context.tr(bn: 'গোপনীয়তা', en: 'Privacy')}: ${_privacy.label(context)}',
              if (_attachedPhotoName != null)
                '${context.tr(bn: 'ছবি', en: 'Photo')}: $_attachedPhotoName',
              if (_attachedVideoName != null) 'Video: $_attachedVideoName',
              'Quality: ${_highQualityPost ? 'High' : 'Standard'}',
              'Scope: ${_postScopeApiValue(_privacy)}',
            ].join('\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.tr(bn: 'ঠিক আছে', en: 'OK')),
            ),
          ],
        ),
      );

      if (shouldClose == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } on TenantAreaApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _areaDarkGreen, width: 2.2),
                boxShadow: _areaShadow,
              ),
              child: Column(
                children: [
                  _ComposerTopBar(
                    title: context.tr(bn: 'পোস্ট করুন', en: 'Post'),
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      children: [
                        Text(
                          context.tr(
                            bn: 'পোস্টের ধরন নির্বাচন করুন',
                            en: 'Select post type',
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _areaQuickActions
                              .map(
                                (action) => Expanded(
                                  child: _ComposerTypeButton(
                                    action: action,
                                    selected: action.type == _selectedType,
                                    onTap: () => setState(() {
                                      _selectedType = action.type;
                                    }),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          height: 105,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _areaBorder),
                          ),
                          child: TextField(
                            controller: _detailsController,
                            minLines: null,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: context.tr(
                                bn: 'বিস্তারিত লিখুন...',
                                en: 'Write details...',
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.fromLTRB(
                                14,
                                13,
                                14,
                                12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ComposerAttachmentButton(
                                icon: _isListening
                                    ? Icons.stop_circle_rounded
                                    : Icons.mic_rounded,
                                iconColor: _areaGreen,
                                label: _isListening
                                    ? context.tr(
                                        bn: 'শুনছি...',
                                        en: 'Listening...',
                                      )
                                    : context.tr(bn: 'ভয়েসে বলুন', en: 'Voice'),
                                onTap: _toggleVoiceInput,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ComposerAttachmentButton(
                                icon: _isPickingPhoto
                                    ? Icons.hourglass_top_rounded
                                    : Icons.camera_alt_rounded,
                                iconColor: AppColors.textMuted,
                                label: _attachedPhotoName == null
                                    ? context.tr(
                                        bn: 'ছবি যোগ করুন',
                                        en: 'Add photo',
                                      )
                                    : context.tr(
                                        bn: 'ছবি বদলান',
                                        en: 'Change photo',
                                      ),
                                onTap: _pickPhoto,
                              ),
                            ),
                          ],
                        ),
                        if (_attachedPhotoName != null) ...[
                          const SizedBox(height: 8),
                          _ComposerStatusLine(
                            icon: Icons.image_rounded,
                            text: _attachedPhotoName!,
                            onClear: () =>
                                setState(() => _attachedPhotoName = null),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _ComposerAttachmentButton(
                                icon: _isPickingVideo
                                    ? Icons.hourglass_top_rounded
                                    : Icons.video_library_rounded,
                                iconColor: AppColors.accent,
                                label: _attachedVideoName == null
                                    ? 'Add video'
                                    : 'Change video',
                                onTap: _pickVideo,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ComposerAttachmentButton(
                                icon: Icons.high_quality_rounded,
                                iconColor: _highQualityPost
                                    ? _areaGreen
                                    : AppColors.textMuted,
                                label: _highQualityPost
                                    ? 'High quality'
                                    : 'Standard',
                                onTap: () => setState(
                                  () => _highQualityPost = !_highQualityPost,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_attachedVideoName != null) ...[
                          const SizedBox(height: 8),
                          _ComposerStatusLine(
                            icon: Icons.video_file_rounded,
                            text: _attachedVideoName!,
                            onClear: () =>
                                setState(() => _attachedVideoName = null),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _ComposerInfoTile(
                          label: context.tr(bn: 'লোকেশন', en: 'Location'),
                          value: _selectedLocation,
                          icon: Icons.location_on_rounded,
                          trailing: _isLoadingLocation
                              ? Icons.hourglass_top_rounded
                              : Icons.my_location_rounded,
                          onTap: _showLocationPicker,
                          onTrailingTap: _loadCurrentLocation,
                        ),
                        const SizedBox(height: 10),
                        _ComposerInfoTile(
                          label: context.tr(bn: 'গোপনীয়তা', en: 'Privacy'),
                          value: _privacy.label(context),
                          icon: Icons.lock_rounded,
                          trailing: Icons.keyboard_arrow_down_rounded,
                          onTap: _showPrivacyPicker,
                        ),
                        const SizedBox(height: 15),
                        _ComposerSubmitButton(
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerTopBar extends StatelessWidget {
  const _ComposerTopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _areaBorder)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: IconButton(
              tooltip: context.tr(bn: 'ফিরে যান', en: 'Back'),
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
              iconSize: 23,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 54),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerSubmitButton extends StatelessWidget {
  const _ComposerSubmitButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _areaGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        isLoading
            ? context.tr(bn: 'পোস্ট হচ্ছে...', en: 'Posting...')
            : context.tr(bn: 'পোস্ট করুন', en: 'Post'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AreaFeatureCenterScreen extends StatefulWidget {
  const _AreaFeatureCenterScreen({required this.activeWard});

  final _AreaWardData activeWard;

  @override
  State<_AreaFeatureCenterScreen> createState() =>
      _AreaFeatureCenterScreenState();
}

class _AreaFeatureCenterScreenState extends State<_AreaFeatureCenterScreen> {
  bool _autoLocation = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkMode ? const Color(0xFF0F172A) : _areaBackground,
      appBar: AppBar(
        backgroundColor: _areaDarkGreen,
        foregroundColor: Colors.white,
        title: const Text('Amar Elaka tools'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _AreaFeatureSection(
                title: 'Friends',
                children: const [
                  _AreaFeatureTile(
                    icon: Icons.person_search_rounded,
                    title: 'Suggested friends',
                    subtitle: 'People from your ward and matched interests',
                  ),
                  _AreaFeatureTile(
                    icon: Icons.people_alt_rounded,
                    title: 'Friends',
                    subtitle: 'Approved area friends list',
                  ),
                  _AreaFeatureTile(
                    icon: Icons.near_me_rounded,
                    title: 'Nearby friends',
                    subtitle: 'Distance based local suggestions',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AreaFeatureSection(
                title: 'Profile and privacy',
                children: [
                  const _AreaFeatureTile(
                    icon: Icons.edit_location_alt_rounded,
                    title: 'Edit profile',
                    subtitle: 'Name, photo, verified badge and bio',
                  ),
                  SwitchListTile(
                    value: _autoLocation,
                    activeColor: _areaGreen,
                    onChanged: (value) => setState(() => _autoLocation = value),
                    title: const Text('Auto set location'),
                    subtitle: Text(widget.activeWard.area),
                    secondary: const Icon(Icons.my_location_rounded),
                  ),
                  SwitchListTile(
                    value: _darkMode,
                    activeColor: _areaGreen,
                    onChanged: (value) => setState(() => _darkMode = value),
                    title: const Text('Dark mode'),
                    subtitle: const Text('Area pages can follow dark theme'),
                    secondary: const Icon(Icons.dark_mode_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AreaFeatureSection(
                title: 'Communication',
                children: const [
                  _AreaFeatureTile(
                    icon: Icons.live_tv_rounded,
                    title: 'Live option',
                    subtitle: 'Start ward or public live updates',
                  ),
                  _AreaFeatureTile(
                    icon: Icons.call_rounded,
                    title: 'Audio call',
                    subtitle: 'Call friends or ward admins',
                  ),
                  _AreaFeatureTile(
                    icon: Icons.videocam_rounded,
                    title: 'Video call',
                    subtitle: 'One-to-one or group video call entry',
                  ),
                  _AreaFeatureTile(
                    icon: Icons.campaign_rounded,
                    title: 'Post announcement',
                    subtitle: 'Official notice and pinned announcement',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AreaFeatureSection(
                title: 'Post scope',
                children: const [
                  _AreaFeatureTile(
                    icon: Icons.location_city_rounded,
                    title: 'Ward based posts',
                    subtitle: 'Normal posts stay inside selected ward',
                  ),
                  _AreaFeatureTile(
                    icon: Icons.travel_explore_rounded,
                    title: 'Whole country option',
                    subtitle:
                        'Ward/division/country post shown on Amar Elaka home only',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaFeatureSection extends StatelessWidget {
  const _AreaFeatureSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _AreaSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _AreaFeatureTile extends StatelessWidget {
  const _AreaFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _areaGreen),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => showComingSoonSnackBar(context, title),
    );
  }
}

class _WardGroupChatScreen extends StatefulWidget {
  const _WardGroupChatScreen({required this.ward});

  final _AreaWardData ward;

  @override
  State<_WardGroupChatScreen> createState() => _WardGroupChatScreenState();
}

class _WardGroupChatScreenState extends State<_WardGroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _areaBackground,
      appBar: AppBar(
        backgroundColor: _areaDarkGreen,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.ward.titleEn} chat'),
            const Text(
              'Active now',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Audio call',
            onPressed: () => showComingSoonSnackBar(context, 'Audio call'),
            icon: const Icon(Icons.call_rounded),
          ),
          IconButton(
            tooltip: 'Video call',
            onPressed: () => showComingSoonSnackBar(context, 'Video call'),
            icon: const Icon(Icons.videocam_rounded),
          ),
          IconButton(
            tooltip: 'Block',
            onPressed: () => showComingSoonSnackBar(context, 'Block member'),
            icon: const Icon(Icons.block_rounded),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  children: const [
                    _AreaChatBubble(
                      sender: 'Ward admin',
                      text: 'Announcement: water line repair starts at 9 PM.',
                      mine: false,
                      verified: true,
                    ),
                    _AreaChatBubble(
                      sender: 'You',
                      text: 'Thanks. Please pin the update.',
                      mine: true,
                    ),
                    _AreaChatBubble(
                      sender: 'Nearby member',
                      text: 'I can share a photo from the road.',
                      mine: false,
                    ),
                  ],
                ),
              ),
              if (_isTyping)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('Someone is typing...'),
                ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            showComingSoonSnackBar(context, 'Audio message'),
                        icon: const Icon(Icons.mic_rounded),
                      ),
                      IconButton(
                        onPressed: () =>
                            showComingSoonSnackBar(context, 'Photo or video'),
                        icon: const Icon(Icons.attach_file_rounded),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onChanged: (value) =>
                              setState(() => _isTyping = value.isNotEmpty),
                          decoration: InputDecoration(
                            hintText: 'Message ${widget.ward.titleEn}',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _messageController.clear();
                          setState(() => _isTyping = false);
                        },
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaChatBubble extends StatelessWidget {
  const _AreaChatBubble({
    required this.sender,
    required this.text,
    required this.mine,
    this.verified = false,
  });

  final String sender;
  final String text;
  final bool mine;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: mine ? _areaGreen : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: mine ? _areaGreen : _areaBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sender,
                  style: TextStyle(
                    color: mine ? Colors.white : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (verified) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified_rounded,
                    color: _areaGreen,
                    size: 14,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: mine ? Colors.white : AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllWardsScreen extends StatefulWidget {
  const _AllWardsScreen();

  @override
  State<_AllWardsScreen> createState() => _AllWardsScreenState();
}

class _AllWardsScreenState extends State<_AllWardsScreen> {
  final TenantAreaApiService _areaApiService = TenantAreaApiService();

  late Future<List<_AreaWardData>> _wardsFuture;

  @override
  void initState() {
    super.initState();
    _wardsFuture = _loadWards();
  }

  @override
  void dispose() {
    _areaApiService.dispose();
    super.dispose();
  }

  Future<List<_AreaWardData>> _loadWards() async {
    final wards = await _areaApiService.getWards();
    return wards.map(_AreaWardData.fromApi).toList(growable: false);
  }

  void _reloadWards() {
    setState(() => _wardsFuture = _loadWards());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _areaBackground,
      appBar: AppBar(
        backgroundColor: _areaDarkGreen,
        foregroundColor: Colors.white,
        title: Text(
          context.tr(bn: 'সব ওয়ার্ড', en: 'All wards'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _AreaSearchField(
                hint: context.tr(bn: 'ওয়ার্ড খুঁজুন...', en: 'Search ward...'),
              ),
              const SizedBox(height: 12),
              const _CitySegmentedSelector(),
              const SizedBox(height: 12),
              FutureBuilder<List<_AreaWardData>>(
                future: _wardsFuture,
                builder: (context, snapshot) {
                  final wards = snapshot.data ?? _areaWards;

                  return Column(
                    children: [
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      if (snapshot.hasError)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AreaApiStatusTile(
                            message: snapshot.error.toString(),
                            onRetry: _reloadWards,
                          ),
                        ),
                      _AreaSurfaceCard(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: wards
                              .map((ward) => _AllWardListTile(ward: ward))
                              .toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => showComingSoonSnackBar(
                  context,
                  context.tr(bn: 'সব ওয়ার্ড', en: 'All wards'),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _areaGreen,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: _areaBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  context.tr(bn: 'সব ওয়ার্ড দেখুন', en: 'View all wards'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaSearchField extends StatelessWidget {
  const _AreaSearchField({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: const Color(0xFFF2F5F7),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _areaBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _areaBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _areaGreen, width: 1.3),
        ),
      ),
    );
  }
}

class _CitySegmentedSelector extends StatelessWidget {
  const _CitySegmentedSelector();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CitySegmentButton(
            selected: true,
            label: context.tr(bn: 'উত্তর সিটি (DNCC)', en: 'North City'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CitySegmentButton(
            label: context.tr(bn: 'দক্ষিণ সিটি (DSCC)', en: 'South City'),
          ),
        ),
      ],
    );
  }
}

class _CitySegmentButton extends StatelessWidget {
  const _CitySegmentButton({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? _areaGreen : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? _areaGreen : _areaBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _AllWardListTile extends StatelessWidget {
  const _AllWardListTile({required this.ward});

  final _AreaWardData ward;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ward.selected ? const Color(0xFFE9F7EF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        minLeadingWidth: 28,
        leading: Icon(
          Icons.location_on_rounded,
          color: ward.selected ? _areaGreen : AppColors.textMuted,
          size: 25,
        ),
        title: Text(
          context.loc(ward.title),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          ward.area,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
        trailing: Text(
          context.loc(ward.memberLabel),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _AreaFeedTabs extends StatelessWidget {
  const _AreaFeedTabs();

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.tr(bn: 'ফিড', en: 'Feed'),
      context.tr(bn: 'সমস্যা', en: 'Problem'),
      context.tr(bn: 'সার্ভিস', en: 'Service'),
      context.tr(bn: 'বাসা', en: 'Home'),
      context.tr(bn: 'ঘোষণা', en: 'Notice'),
    ];

    return _AreaSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      radius: 0,
      boxShadow: const [],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < labels.length; index++)
              _AreaTabButton(label: labels[index], selected: index == 0),
          ],
        ),
      ),
    );
  }
}

class _AreaTabButton extends StatelessWidget {
  const _AreaTabButton({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
          color: selected ? _areaGreen : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _FeedInputBar extends StatelessWidget {
  const _FeedInputBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _areaBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(
                    bn: 'কি সমস্যা লিখুন বা বলুন...',
                    en: 'Write or speak your issue...',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.mic_rounded, color: _areaGreen),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaFeedPostCard extends StatelessWidget {
  const _AreaFeedPostCard({required this.post, this.compact = false});

  final _AreaFeedPostData post;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _AreaSurfaceCard(
      padding: const EdgeInsets.all(12),
      boxShadow: compact ? const [] : _areaShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: post.color.withValues(alpha: 0.16),
                child: Icon(Icons.person_rounded, size: 20, color: post.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.loc(post.author),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        _PostCategoryPill(post: post),
                      ],
                    ),
                    Text(
                      context.loc(post.meta),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: _areaGreen,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        const _PresenceDot(active: true),
                        const SizedBox(width: 5),
                        Text(
                          'Verified - Active',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.loc(post.body),
            maxLines: compact ? 2 : 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontSize: 13.2,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          _AreaPostArtwork(style: post.artworkStyle, compact: compact),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: _areaGreen,
                size: 18,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  post.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _areaDarkGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.8,
                  ),
                ),
              ),
              _PostStat(icon: Icons.thumb_up_alt_outlined, value: post.likes),
              const SizedBox(width: 14),
              _PostStat(
                icon: Icons.chat_bubble_outline_rounded,
                value: post.comments,
              ),
              if (!compact) ...[
                const SizedBox(width: 14),
                Icon(
                  Icons.share_outlined,
                  color: AppColors.textMuted.withValues(alpha: 0.75),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  context.tr(bn: 'শেয়ার', en: 'Share'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 11.5),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => showComingSoonSnackBar(context, 'Block user'),
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.block_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCategoryPill extends StatelessWidget {
  const _PostCategoryPill({required this.post});

  final _AreaFeedPostData post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: post.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.loc(post.category),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: post.color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PostStat extends StatelessWidget {
  const _PostStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

class _AreaPostArtwork extends StatelessWidget {
  const _AreaPostArtwork({required this.style, required this.compact});

  final _AreaArtworkStyle style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 96.0 : 164.0;
    final dark = style == _AreaArtworkStyle.streetNight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? const [Color(0xFF111827), Color(0xFF0F766E)]
                : const [Color(0xFFFFF7ED), Color(0xFFE0F2FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(children: dark ? _streetNightScene() : _roomScene()),
      ),
    );
  }

  List<Widget> _streetNightScene() {
    return [
      Positioned(
        left: 26,
        top: 20,
        child: Container(
          width: 8,
          height: 58,
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      Positioned(
        left: 18,
        top: 14,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.45),
                blurRadius: 28,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        right: 20,
        top: 24,
        child: Container(
          width: 120,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
        ),
      ),
    ];
  }

  List<Widget> _roomScene() {
    return [
      Positioned(
        left: 18,
        bottom: 14,
        child: Container(
          width: 116,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFB7791F).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      Positioned(
        right: 24,
        bottom: 18,
        child: Container(
          width: 104,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF92400E).withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      Positioned(
        left: 28,
        top: 20,
        child: Container(
          width: 86,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white),
          ),
          child: Row(
            children: List.generate(
              3,
              (_) => Expanded(
                child: Container(
                  margin: const EdgeInsets.all(3),
                  color: const Color(0xFFBAE6FD),
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        right: 28,
        top: 18,
        child: Container(
          width: 52,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    ];
  }
}

class _ComposerTypeButton extends StatelessWidget {
  const _ComposerTypeButton({
    required this.action,
    required this.selected,
    required this.onTap,
  });

  final _AreaQuickAction action;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: selected ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: selected
                        ? action.color.withValues(alpha: 0.28)
                        : action.color.withValues(alpha: 0.08),
                  ),
                ),
                child: Icon(action.icon, color: action.color, size: 27),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 15,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.loc(action.label),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 10.8,
                      height: 1,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerAttachmentButton extends StatelessWidget {
  const _ComposerAttachmentButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AreaSurfaceCard(
      padding: EdgeInsets.zero,
      radius: 10,
      boxShadow: const [],
      borderColor: const Color(0xFFE8EDF3),
      onTap: onTap,
      child: SizedBox(
        height: 42,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 21),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerStatusLine extends StatelessWidget {
  const _ComposerStatusLine({
    required this.icon,
    required this.text,
    required this.onClear,
  });

  final IconData icon;
  final String text;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAEFF5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _areaGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            tooltip: context.tr(bn: 'মুছে ফেলুন', en: 'Remove'),
            onPressed: onClear,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ComposerInfoTile extends StatelessWidget {
  const _ComposerInfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.trailing,
    this.onTap,
    this.onTrailingTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final IconData trailing;
  final VoidCallback? onTap;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textMuted,
            fontSize: 12.2,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEAEFF5)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 11),
                  Icon(icon, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onTrailingTap ?? onTap,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(10),
                    ),
                    child: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Color(0xFFEAEFF5)),
                        ),
                      ),
                      child: Icon(
                        trailing,
                        color: AppColors.textMuted,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ComposerOption<T> {
  const _ComposerOption({
    required this.value,
    required this.title,
    required this.icon,
    this.subtitle,
  });

  final T value;
  final String title;
  final String? subtitle;
  final IconData icon;
}

class _ComposerOptionSheet<T> extends StatelessWidget {
  const _ComposerOptionSheet({required this.title, required this.options});

  final String title;
  final List<_ComposerOption<T>> options;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: _areaShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];

                  return ListTile(
                    leading: Icon(option.icon, color: _areaGreen),
                    title: Text(
                      option.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: option.subtitle == null
                        ? null
                        : Text(
                            option.subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onTap: () => Navigator.of(context).pop(option.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WardRulesSheet extends StatelessWidget {
  const _WardRulesSheet({required this.rules});

  final List<LocalizedText> rules;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _areaShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(bn: 'ওয়ার্ডের নিয়মাবলী', en: 'Ward guidelines'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...rules.map((rule) => _RuleLine(text: context.loc(rule))),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr(bn: 'ঠিক আছে', en: 'OK')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: _areaGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _AreaRoundIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: onTap,
        ),
        if (count > 0)
          Positioned(
            right: -1,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AreaRoundIconButton extends StatelessWidget {
  const _AreaRoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          height: 42,
          width: 42,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: _areaShadow,
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 23),
        ),
      ),
    );
  }
}

class _AreaSurfaceCard extends StatelessWidget {
  const _AreaSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.borderColor = _areaBorder,
    this.borderWidth = 1,
    this.radius = 20,
    this.boxShadow = _areaShadow,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double radius;
  final List<BoxShadow> boxShadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final decoration = BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: boxShadow,
    );

    if (onTap == null) {
      return Container(padding: padding, decoration: decoration, child: child);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(padding: padding, decoration: decoration, child: child),
      ),
    );
  }
}

class _AreaApiStatusTile extends StatelessWidget {
  const _AreaApiStatusTile({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFC2410C),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF9A3412),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: _areaDarkGreen,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(context.tr(bn: 'আবার চেষ্টা', en: 'Retry')),
          ),
        ],
      ),
    );
  }
}

enum _AreaPostType { problem, home, service, announcement, help }

enum _AreaPrivacy { wardOnly, wardAndNearby, onlyAdmins, nationwideHomePage }

enum _AreaArtworkStyle { streetNight, room }

extension _AreaPrivacyLabel on _AreaPrivacy {
  IconData get icon {
    return switch (this) {
      _AreaPrivacy.wardOnly => Icons.groups_rounded,
      _AreaPrivacy.wardAndNearby => Icons.public_rounded,
      _AreaPrivacy.onlyAdmins => Icons.admin_panel_settings_rounded,
      _AreaPrivacy.nationwideHomePage => Icons.travel_explore_rounded,
    };
  }

  String label(BuildContext context) {
    return switch (this) {
      _AreaPrivacy.wardOnly => context.tr(
        bn: 'শুধু আমাদের ওয়ার্ডের সবাই',
        en: 'Only everyone in our ward',
      ),
      _AreaPrivacy.wardAndNearby => context.tr(
        bn: 'ওয়ার্ড ও আশেপাশের সবাই',
        en: 'Ward and nearby areas',
      ),
      _AreaPrivacy.onlyAdmins => context.tr(
        bn: 'শুধু ওয়ার্ড অ্যাডমিন',
        en: 'Ward admins only',
      ),
      _AreaPrivacy.nationwideHomePage => 'Whole country, Amar Elaka home only',
    };
  }

  String subtitle(BuildContext context) {
    return switch (this) {
      _AreaPrivacy.wardOnly => context.tr(
        bn: 'আপনার ওয়ার্ডের সদস্যরা পোস্টটি দেখতে পাবে।',
        en: 'Members of your ward can see the post.',
      ),
      _AreaPrivacy.wardAndNearby => context.tr(
        bn: 'কাছের ওয়ার্ডের মানুষও পোস্টটি দেখতে পাবে।',
        en: 'People from nearby wards can also see it.',
      ),
      _AreaPrivacy.onlyAdmins => context.tr(
        bn: 'শুধু মডারেটর বা অ্যাডমিনদের কাছে যাবে।',
        en: 'Only moderators or admins will receive it.',
      ),
      _AreaPrivacy.nationwideHomePage =>
        'Anyone from any ward or division can post; it appears on Amar Elaka home.',
    };
  }
}

class _AreaQuickAction {
  const _AreaQuickAction({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
  });

  final _AreaPostType type;
  final LocalizedText label;
  final IconData icon;
  final Color color;
}

class _AreaWardData {
  const _AreaWardData({
    this.id = '',
    required this.title,
    required this.titleEn,
    required this.area,
    required this.memberLabel,
    this.city = 'dncc',
    this.memberCount = 0,
    this.selected = false,
    this.verified = true,
  });

  final String id;
  final LocalizedText title;
  final String titleEn;
  final String area;
  final LocalizedText memberLabel;
  final String city;
  final int memberCount;
  final bool selected;
  final bool verified;

  factory _AreaWardData.fromApi(TenantAreaWard ward) {
    return _AreaWardData(
      id: ward.id,
      title: ward.title,
      titleEn: ward.titleEn,
      area: ward.area,
      memberLabel: ward.memberLabel,
      city: ward.city,
      memberCount: ward.memberCount,
      selected: ward.selected,
      verified: ward.verified,
    );
  }
}

class _AreaFeedPostData {
  const _AreaFeedPostData({
    this.id = '',
    this.postType = 'problem',
    required this.author,
    required this.meta,
    required this.category,
    required this.body,
    required this.location,
    required this.likes,
    required this.comments,
    required this.color,
    required this.artworkStyle,
  });

  final String id;
  final String postType;
  final LocalizedText author;
  final LocalizedText meta;
  final LocalizedText category;
  final LocalizedText body;
  final String location;
  final String likes;
  final String comments;
  final Color color;
  final _AreaArtworkStyle artworkStyle;

  factory _AreaFeedPostData.fromApi(TenantAreaPost post) {
    return _AreaFeedPostData(
      id: post.id,
      postType: post.postType,
      author: post.author,
      meta: post.meta,
      category: post.category,
      body: post.body,
      location: post.location,
      likes: post.likeCount.toString(),
      comments: post.commentCount.toString(),
      color: _areaPostTypeColor(post.postType),
      artworkStyle: _areaArtworkStyleFromApi(post.artworkStyle, post.postType),
    );
  }
}

class _AreaHelplineData {
  const _AreaHelplineData({required this.label, required this.phone});

  final String label;
  final String phone;

  factory _AreaHelplineData.fromApi(TenantAreaHelpline helpline) {
    return _AreaHelplineData(label: helpline.label, phone: helpline.phone);
  }
}

class _AreaHomeUiData {
  const _AreaHomeUiData({
    required this.activeWard,
    required this.wards,
    required this.feedPosts,
    required this.wardRules,
    required this.locationOptions,
    required this.notificationUnreadCount,
    this.emergencyHelpline,
  });

  final _AreaWardData activeWard;
  final List<_AreaWardData> wards;
  final List<_AreaFeedPostData> feedPosts;
  final List<LocalizedText> wardRules;
  final List<String> locationOptions;
  final int notificationUnreadCount;
  final _AreaHelplineData? emergencyHelpline;

  factory _AreaHomeUiData.fromApi(TenantAreaHomeData home) {
    final wards = home.wards.map(_AreaWardData.fromApi).toList(growable: false);
    final activeWard = home.activeWard == null
        ? _fallbackAreaHomeUiData.activeWard
        : _AreaWardData.fromApi(home.activeWard!);
    final normalizedWards = wards.isEmpty
        ? _fallbackAreaHomeUiData.wards
        : wards;
    final posts = home.feedPreview
        .map(_AreaFeedPostData.fromApi)
        .toList(growable: false);

    return _AreaHomeUiData(
      activeWard: activeWard,
      wards: normalizedWards,
      feedPosts: posts.isEmpty ? _fallbackAreaHomeUiData.feedPosts : posts,
      wardRules: home.wardRules.isEmpty
          ? _fallbackAreaHomeUiData.wardRules
          : home.wardRules,
      locationOptions: home.locationOptions.isEmpty
          ? _locationOptionsFromWards(normalizedWards)
          : home.locationOptions,
      notificationUnreadCount: home.notificationUnreadCount,
      emergencyHelpline: home.emergencyHelpline == null
          ? _fallbackAreaHomeUiData.emergencyHelpline
          : _AreaHelplineData.fromApi(home.emergencyHelpline!),
    );
  }
}

Color _areaPostTypeColor(String postType) {
  return switch (postType.toLowerCase()) {
    'home' => AppColors.primary,
    'service' => _areaGreen,
    'announcement' || 'notice' => AppColors.accent,
    'help' => const Color(0xFF7C3AED),
    _ => AppColors.danger,
  };
}

_AreaArtworkStyle _areaArtworkStyleFromApi(
  String artworkStyle,
  String postType,
) {
  final normalizedStyle = artworkStyle.toLowerCase();
  if (normalizedStyle == 'room' || postType.toLowerCase() == 'home') {
    return _AreaArtworkStyle.room;
  }

  return _AreaArtworkStyle.streetNight;
}

List<String> _locationOptionsFromWards(List<_AreaWardData> wards) {
  final options = wards
      .map((ward) {
        final title = ward.titleEn.trim();
        final area = ward.area.trim();
        if (title.isEmpty) {
          return area;
        }
        if (area.isEmpty) {
          return title;
        }

        return '$title, $area';
      })
      .where((location) => location.isNotEmpty)
      .toList(growable: false);

  return options.isEmpty ? _areaLocationOptions : options;
}

final _fallbackAreaHomeUiData = _AreaHomeUiData(
  activeWard: _areaWards.firstWhere(
    (ward) => ward.titleEn == 'Ward 14',
    orElse: () => _areaWards.first,
  ),
  wards: _areaWards,
  feedPosts: _areaFeedPosts,
  wardRules: const [
    LocalizedText(
      bn: 'বাসা, সার্ভিস, কাজ ও সহায়তার পোস্ট পরিষ্কারভাবে লিখুন।',
      en: 'Keep home, service, job and help posts clear.',
    ),
    LocalizedText(
      bn: 'সমস্যা পোস্টে বিস্তারিত লিখলে দ্রুত সমাধান পাওয়া যায়।',
      en: 'Write clear details in issue posts for faster help.',
    ),
    LocalizedText(
      bn: 'ভুল তথ্য, স্প্যাম বা ব্যক্তিগত আক্রমণ করা যাবে না।',
      en: 'Do not post false information, spam or personal attacks.',
    ),
  ],
  locationOptions: _areaLocationOptions,
  emergencyHelpline: const _AreaHelplineData(label: 'Emergency', phone: '999'),
  notificationUnreadCount: 12,
);

const _areaQuickActions = <_AreaQuickAction>[
  _AreaQuickAction(
    type: _AreaPostType.problem,
    label: LocalizedText(bn: 'সমস্যা', en: 'Problem'),
    icon: Icons.error_rounded,
    color: AppColors.danger,
  ),
  _AreaQuickAction(
    type: _AreaPostType.home,
    label: LocalizedText(bn: 'বাসা', en: 'Home'),
    icon: Icons.home_rounded,
    color: AppColors.primary,
  ),
  _AreaQuickAction(
    type: _AreaPostType.service,
    label: LocalizedText(bn: 'সার্ভিস', en: 'Service'),
    icon: Icons.engineering_rounded,
    color: _areaGreen,
  ),
  _AreaQuickAction(
    type: _AreaPostType.announcement,
    label: LocalizedText(bn: 'ঘোষণা', en: 'Notice'),
    icon: Icons.campaign_rounded,
    color: AppColors.accent,
  ),
  _AreaQuickAction(
    type: _AreaPostType.help,
    label: LocalizedText(bn: 'সাহায্য', en: 'Help'),
    icon: Icons.volunteer_activism_rounded,
    color: Color(0xFF7C3AED),
  ),
];

const _areaLocationOptions = <String>[
  'Ward 14, Mirpur-10',
  'Mirpur-14',
  'Ward 10, Mirpur',
  'Uttara Sector 11',
  'Gulshan 2',
  'Mohakhali',
  'Mohammadpur',
];

const _areaWards = <_AreaWardData>[
  _AreaWardData(
    title: LocalizedText(bn: 'ওয়ার্ড ০১ - উত্তরা', en: 'Ward 01 - Uttara'),
    titleEn: 'Ward 01',
    area: 'Uttara',
    memberLabel: LocalizedText(bn: '২.১k সদস্য', en: '2.1k members'),
  ),
  _AreaWardData(
    title: LocalizedText(bn: 'ওয়ার্ড ১০ - মিরপুর', en: 'Ward 10 - Mirpur'),
    titleEn: 'Ward 10',
    area: 'Mirpur',
    memberLabel: LocalizedText(bn: '২.৮k সদস্য', en: '2.8k members'),
    selected: true,
  ),
  _AreaWardData(
    title: LocalizedText(bn: 'ওয়ার্ড ১৪ - মিরপুর', en: 'Ward 14 - Mirpur'),
    titleEn: 'Ward 14',
    area: 'Mirpur',
    memberLabel: LocalizedText(bn: '২.৩k সদস্য', en: '2.3k members'),
  ),
  _AreaWardData(
    title: LocalizedText(bn: 'ওয়ার্ড ২৩ - গুলশান', en: 'Ward 23 - Gulshan'),
    titleEn: 'Ward 23',
    area: 'Gulshan',
    memberLabel: LocalizedText(bn: '১.৯k সদস্য', en: '1.9k members'),
  ),
  _AreaWardData(
    title: LocalizedText(bn: 'ওয়ার্ড ৩০ - তেজগাঁও', en: 'Ward 30 - Tejgaon'),
    titleEn: 'Ward 30',
    area: 'Tejgaon',
    memberLabel: LocalizedText(bn: '২.০k সদস্য', en: '2.0k members'),
  ),
  _AreaWardData(
    title: LocalizedText(bn: 'ওয়ার্ড ৩৬ - মহাখালী', en: 'Ward 36 - Mohakhali'),
    titleEn: 'Ward 36',
    area: 'Mohakhali',
    memberLabel: LocalizedText(bn: '১.৭k সদস্য', en: '1.7k members'),
  ),
  _AreaWardData(
    title: LocalizedText(
      bn: 'ওয়ার্ড ৪৫ - মোহাম্মদপুর',
      en: 'Ward 45 - Mohammadpur',
    ),
    titleEn: 'Ward 45',
    area: 'Mohammadpur',
    memberLabel: LocalizedText(bn: '২.৪k সদস্য', en: '2.4k members'),
  ),
];

const _areaFeedPosts = <_AreaFeedPostData>[
  _AreaFeedPostData(
    author: LocalizedText(bn: 'আহিদুল ইসলাম', en: 'Ahidul Islam'),
    meta: LocalizedText(bn: 'Ward 14 · ১ ঘণ্টা আগে', en: 'Ward 14 · 1h ago'),
    category: LocalizedText(bn: 'সমস্যা', en: 'Problem'),
    body: LocalizedText(
      bn: 'আমাদের রাস্তায় লাইট নেই, রাতে চলাচলে সমস্যা হয়। দ্রুত ব্যবস্থা নেওয়া দরকার।',
      en: 'There is no street light on our road. It is difficult to move at night.',
    ),
    location: 'Mirpur-14',
    likes: '25',
    comments: '10',
    color: AppColors.danger,
    artworkStyle: _AreaArtworkStyle.streetNight,
  ),
  _AreaFeedPostData(
    author: LocalizedText(bn: 'রোকসানা আক্তার', en: 'Roksana Akter'),
    meta: LocalizedText(bn: 'Ward 14 · ২ ঘণ্টা আগে', en: 'Ward 14 · 2h ago'),
    category: LocalizedText(bn: 'বাসা', en: 'Home'),
    body: LocalizedText(
      bn: 'ছোট পরিবারের জন্য ১ রুম ভাড়া হবে। ভাড়া: ৫০০০ টাকা (বিদ্যুৎ বিল আলাদা)।',
      en: 'One room is available for a small family. Rent: Tk 5000, electricity separate.',
    ),
    location: 'Ward 14, Mirpur-10',
    likes: '18',
    comments: '7',
    color: AppColors.primary,
    artworkStyle: _AreaArtworkStyle.room,
  ),
];
