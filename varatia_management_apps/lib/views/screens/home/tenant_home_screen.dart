import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import '../../../core/models/user_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/app_context.dart';
import '../../../core/utils/local_lang.dart';
import '../../../data/models/app_models.dart';
import '../../../viewmodels/role_dashboard_view_models.dart';
import '../../widgets/app_widgets.dart';
import 'tenant_home_landing_sections.dart';

import '../tenant_reference_pages.dart';
import '../role_dashboards.dart';
import 'monthly_service_charge_gate.dart';
import 'amar_elaka/amar_elaka_welcome_page.dart';
import 'tenant_pickup_service_screen.dart';
import 'tenant_marketplace_welcome_page.dart';
import 'secure_deal/tenant_secure_deal_screen.dart';
import 'smart_bazar/smart_bazar_welcome_page.dart';
import 'tenant_tutor_welcome_page.dart';
import 'tenant_pickup_service_welcome_page.dart';
import 'tenant_amar_elaka_screen.dart';
import '../../../data/services/auth_session_service.dart';
import '../../../data/services/chat_api_service.dart';
import '../entry/entry_routes.dart';
import '../emergency_sos/emergency_sos_screen.dart';
import '../phone_verification/phone_verification_info_screen.dart';

const _tenantSurfaceShadow = <BoxShadow>[
  BoxShadow(color: Color(0x120F172A), blurRadius: 18, offset: Offset(0, 8)),
  BoxShadow(color: Color(0x0A0F172A), blurRadius: 6, offset: Offset(0, 2)),
];

const _tenantPremiumShadow = <BoxShadow>[
  BoxShadow(color: Color(0x1A2563EB), blurRadius: 28, offset: Offset(0, 14)),
  BoxShadow(color: Color(0x0D0F172A), blurRadius: 10, offset: Offset(0, 4)),
];

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  bool _hasRefreshedTenantSession = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasRefreshedTenantSession) {
      return;
    }

    _hasRefreshedTenantSession = true;
    unawaited(context.read<TenantExperienceViewModel>().refreshAuthSession());
  }

  MediaQueryData _bottomBarMediaQuery(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return mediaQuery.copyWith(
      textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shellViewModel = context.watch<RoleShellViewModel>();
    final pages = <Widget>[
      const _TenantReferenceHomePage(),
      const TenantMarketplaceSearchPage(),
      const TenantSavedListingsPage(),
      const _TenantChatHubPage(),
      const TenantProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      endDrawer: shellViewModel.selectedRole == EntryUserRole.owner
          ? const _OwnerAccountNavigationDrawer()
          : const _TenantAccountNavigationDrawer(),
      body: SafeArea(bottom: false, child: pages[shellViewModel.currentIndex]),
      bottomNavigationBar: MediaQuery(
        data: _bottomBarMediaQuery(context),
        child: _TenantBottomNavigationBar(
          selectedIndex: shellViewModel.currentIndex,
          onSelected: shellViewModel.selectTab,
        ),
      ),
    );
  }
}

class _TenantReferenceHomePage extends StatefulWidget {
  const _TenantReferenceHomePage();

  @override
  State<_TenantReferenceHomePage> createState() =>
      _TenantReferenceHomePageState();
}

class _TenantReferenceHomePageState extends State<_TenantReferenceHomePage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final query = context
        .read<TenantExperienceViewModel>()
        .marketplaceSearchQuery;
    if (_searchController.text.isEmpty && query.isNotEmpty) {
      _searchController.text = query;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearchTab() {
    context.read<TenantExperienceViewModel>().updateMarketplaceSearchQuery(
      _searchController.text.trim(),
    );
    context.read<RoleShellViewModel>().selectTab(1);
  }

  void _openMarketplaceWelcome() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TenantMarketplaceWelcomePage(),
      ),
    );
  }

  void _openCategory(MarketplaceCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TenantMarketplaceCategoryPage(category: category),
      ),
    );
  }

  void _openPostComposer() async {
    final session = await AuthSessionService().readSession();
    if (!mounted) return;

    if (session != null && session.role == EntryUserRole.owner) {
      Navigator.of(context).pushNamed(AppRoutes.postComposer);
    } else {
      Navigator.of(context).pushNamed(AppRoutes.tenantAuthBridge);
    }
  }

  void _openRentalServiceLandingPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RentalServiceLandingPage(
          onSearch: _openMarketplaceWelcome,
          onPostAdvertisement: _openPostComposer,
        ),
      ),
    );
  }

  void _openTutorTeachLearnPage() async {
    final session = await AuthSessionService().readSession();
    if (!mounted) return;

    if (session == null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const TenantTutorWelcomePage()),
      );
      return;
    }

    final canOpen = await ensureMonthlyServiceChargePaid(
      context,
      userId: session.userId,
      serviceName: context.tr(bn: 'শিক্ষক সার্ভিস', en: 'Tutor Service'),
    );
    if (!mounted || !canOpen) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TenantTutorTeachLearnPage(),
      ),
    );
  }

  void _openAmarElakaPage() async {
    final session = await AuthSessionService().readSession();
    if (!mounted) return;

    if (session == null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AmarElakaWelcomePage()),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TenantAmarElakaScreen()),
    );
  }

  void _openSecureDealPage() async {
    final session = await AuthSessionService().readSession();
    if (!mounted) return;

    if (session == null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SecureDealWelcomePage()),
      );
      return;
    }

    final canOpen = await ensureMonthlyServiceChargePaid(
      context,
      userId: session.userId,
      serviceName: context.tr(bn: 'সিকিউর ডিল', en: 'Secure Deal'),
    );
    if (!mounted || !canOpen) return;

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SecureDealHomePage()));
  }

  void _openPickupServicePage() async {
    final session = await AuthSessionService().readSession();
    if (!mounted) return;

    if (session == null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const TenantPickupServiceWelcomePage(),
        ),
      );
      return;
    }

    final canOpen = await ensureMonthlyServiceChargePaid(
      context,
      userId: session.userId,
      serviceName: context.tr(bn: 'পিকআপ সার্ভিস', en: 'Pickup Service'),
    );
    if (!mounted || !canOpen) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TenantPickupServiceScreen(),
      ),
    );
  }

  void _openSmartBazarPage() async {
    final session = await AuthSessionService().readSession();
    if (!mounted) return;

    if (session == null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SmartBazarWelcomePage()),
      );
      return;
    }

    final canOpen = await ensureMonthlyServiceChargePaid(
      context,
      userId: session.userId,
      serviceName: context.tr(bn: 'স্মার্ট বাজার', en: 'Smart Bazar'),
    );
    if (!mounted || !canOpen) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SmartBazarWelcomePage()),
    );
  }

  void _handleQuickAction(_TenantQuickActionType type) {
    switch (type) {
      case _TenantQuickActionType.rentalService:
        _openRentalServiceLandingPage();
        return;
      case _TenantQuickActionType.rent:
        _openCategory(MarketplaceCategory.rent);
        return;
      case _TenantQuickActionType.sale:
        _openCategory(MarketplaceCategory.sale);
        return;
      case _TenantQuickActionType.search:
        _openSearchTab();
        return;
      case _TenantQuickActionType.teacher:
        _openTutorTeachLearnPage();
        return;
      case _TenantQuickActionType.pickup:
        _openPickupServicePage();
        return;
      case _TenantQuickActionType.secureDeal:
        _openSecureDealPage();
        return;
      case _TenantQuickActionType.amarElaka:
        _openAmarElakaPage();
        return;
      case _TenantQuickActionType.smartBazar:
        _openSmartBazarPage();
        return;
      case _TenantQuickActionType.sos:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EmergencySosScreen()),
        );
        return;
      case _TenantQuickActionType.phoneVerification:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PhoneVerificationInfoScreen(),
          ),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantViewModel = context.watch<TenantExperienceViewModel>();
    final announcements = tenantViewModel.announcements;
    final bulletinMessage = announcements.isNotEmpty
        ? announcements.first.message
        : context.tr(
            bn: 'বুলেটিন: ফ্ল্যাট ভাড়া, বিক্রি, বাসা খোঁজা ও শিক্ষক দিচ্ছি / নিচ্ছি পোস্ট করুন',
            en: 'Bulletin: Post flat rent, sale, home search and tutor teach / learn notices',
          );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFEAF4FF),
            Color(0xFFFFFFFF),
            Color(0xFFF5F8FC),
            Color(0xFFEFFDF8),
          ],
          stops: [0, 0.34, 0.72, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
        physics: const BouncingScrollPhysics(),
        children: [
          _HomeFadeSlide(
            child: _LandingInspiredTenantHero(
              controller: _searchController,
              onSubmitted: (_) => _openSearchTab(),
              onSearchTap: _openSearchTab,
              onRequestTap: _openMarketplaceWelcome,
              onRentTap: () => _openCategory(MarketplaceCategory.rent),
              onSaleTap: () => _openCategory(MarketplaceCategory.sale),
              onTutorTap: _openTutorTeachLearnPage,
              onPickupTap: _openPickupServicePage,
            ),
          ),
          const SizedBox(height: 12),
          _HomeFadeSlide(
            delay: 80,
            child: _TenantBulletinTicker(message: bulletinMessage),
          ),
          const SizedBox(height: 18),
          _HomeSectionTitle(
            title: context.tr(bn: 'দ্রুত সার্ভিস', en: 'Quick Services'),
            subtitle: context.tr(
              bn: 'আপনার প্রয়োজনের সব সার্ভিস',
              en: 'Everything you need in one place',
            ),
          ),
          const SizedBox(height: 12),
          _HomeFadeSlide(
            delay: 120,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 430 ? 3 : 2;

                return GridView.builder(
                  itemCount: _tenantQuickActions.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 136,
                  ),
                  itemBuilder: (context, index) {
                    final item = _tenantQuickActions[index];

                    return _QuickActionCard(
                      item: item,
                      onTap: () => _handleQuickAction(item.type),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const _HomeFadeSlide(
            delay: 140,
            child: _TenantServiceExplainerBanner(),
          ),
          const SizedBox(height: 24),
          const _HomeFadeSlide(
            delay: 160,
            child: _GlossySectionWrapper(
              colors: [
                Color(0xFF0F766E),
                Color(0xFF064E3B),
                Color(0xFF047857),
                Color(0xFF34D399),
              ],
              shadowColor: Color(0xFF047857),
              child: TenantLandingStatsSection(),
            ),
          ),
          const _HomeFadeSlide(
            delay: 200,
            child: _GlossySectionWrapper(
              colors: [
                Color(0xFF4338CA),
                Color(0xFF3730A3),
                Color(0xFF4F46E5),
                Color(0xFF818CF8),
              ],
              shadowColor: Color(0xFF4338CA),
              child: TenantLandingServicesSection(),
            ),
          ),
          const _HomeFadeSlide(
            delay: 240,
            child: _GlossySectionWrapper(
              colors: [
                Color(0xFF0369A1),
                Color(0xFF0C4A6E),
                Color(0xFF0284C7),
                Color(0xFF38BDF8),
              ],
              shadowColor: Color(0xFF0284C7),
              child: TenantLandingGrocerySection(),
            ),
          ),
          const _HomeFadeSlide(
            delay: 280,
            child: _GlossySectionWrapper(
              colors: [
                Color(0xFFBE185D),
                Color(0xFF831843),
                Color(0xFFDB2777),
                Color(0xFFF472B6),
              ],
              shadowColor: Color(0xFFDB2777),
              child: TenantLandingHowItWorksSection(),
            ),
          ),
          const _HomeFadeSlide(
            delay: 320,
            child: _GlossySectionWrapper(
              colors: [
                Color(0xFFB45309),
                Color(0xFF78350F),
                Color(0xFFD97706),
                Color(0xFFFBBF24),
              ],
              shadowColor: Color(0xFFD97706),
              child: TenantLandingAudienceSection(),
            ),
          ),
          const _HomeFadeSlide(
            delay: 360,
            child: _GlossySectionWrapper(
              colors: [
                Color(0xFF6D28D9),
                Color(0xFF4C1D95),
                Color(0xFF7C3AED),
                Color(0xFFA78BFA),
              ],
              shadowColor: Color(0xFF7C3AED),
              child: TenantLandingFaqSection(),
            ),
          ),
          const _HomeFadeSlide(
            delay: 400,
            child: _GlossySectionWrapper(
              colors: [
                Color(0xFF0F766E),
                Color(0xFF134E4A),
                Color(0xFF14B8A6),
                Color(0xFF5EEAD4),
              ],
              shadowColor: Color(0xFF14B8A6),
              child: TenantLandingContactSection(),
            ),
          ),
          const _HomeFadeSlide(
            delay: 440,
            child: _GlossySectionWrapper(
              colors: [
                Color(0xFF334155),
                Color(0xFF0F172A),
                Color(0xFF475569),
                Color(0xFF94A3B8),
              ],
              shadowColor: Color(0xFF475569),
              child: TenantLandingFooterSection(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlossySectionWrapper extends StatefulWidget {
  const _GlossySectionWrapper({
    required this.child,
    required this.colors,
    required this.shadowColor,
  });
  final Widget child;
  final List<Color> colors;
  final Color shadowColor;

  @override
  State<_GlossySectionWrapper> createState() => _GlossySectionWrapperState();
}

class _GlossySectionWrapperState extends State<_GlossySectionWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + (value * 2), -1.0 + (value * 1)),
              end: Alignment(1.5 - (value * 2), 1.0 - (value * 1)),
              colors: [
                widget.colors[0].withValues(alpha: 0.4),
                widget.colors[1].withValues(alpha: 0.3),
                widget.colors[2].withValues(alpha: 0.3),
                widget.colors[3].withValues(alpha: 0.4),
              ],
              stops: const [0.0, 0.35, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withValues(
                  alpha: 0.08 + (value * 0.05),
                ),
                blurRadius: 32,
                spreadRadius: 4 + (value * 6),
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: widget.child,
        );
      },
    );
  }
}

class RentalServiceLandingPage extends StatelessWidget {
  const RentalServiceLandingPage({
    super.key,
    required this.onSearch,
    required this.onPostAdvertisement,
  });

  final VoidCallback onSearch;
  final VoidCallback onPostAdvertisement;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(context.tr(bn: 'বাসা / ফ্ল্যাট', en: 'Home / Flat')),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFEFF), Color(0xFFF7F8FC), Color(0xFFFDFCF9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _RentalServiceOptionCard(
              icon: Icons.travel_explore_rounded,
              iconColor: const Color(0xFF2563EB),
              title: context.tr(
                bn: 'বাসা / ফ্ল্যাট ভাড়া খুঁজুন',
                en: 'Search Home / Flat Rent',
              ),
              description: context.tr(
                bn: 'লোকেশন, বাজেট, রুম সংখ্যা, ফ্ল্যাট টাইপ এবং অন্যান্য তথ্য দিয়ে সহজে আপনার পছন্দের ভাড়ার বাসা বা ফ্ল্যাট খুঁজুন।',
                en: 'Find your preferred rental home or flat by location, budget, room count, flat type, and other details.',
              ),
              buttonLabel: context.tr(bn: 'এখনই খুঁজুন', en: 'Search Now'),
              onPressed: () {
                Navigator.of(context).pop();
                onSearch();
              },
            ),
            const SizedBox(height: 14),
            _RentalServiceOptionCard(
              icon: Icons.add_home_work_rounded,
              iconColor: const Color(0xFFF97316),
              title: context.tr(
                bn: 'বাসা / ফ্ল্যাট ভাড়ার বিজ্ঞাপন দিন',
                en: 'Post Home / Flat Rent Advertisement',
              ),
              description: context.tr(
                bn: 'ছবি, ভাড়া, লোকেশন, বাসার সুবিধা এবং অন্যান্য বিস্তারিত তথ্য দিয়ে সহজে আপনার বাসা বা ফ্ল্যাটের ভাড়ার বিজ্ঞাপন প্রকাশ করুন।',
                en: 'Publish your home or flat rental advertisement with photos, rent, location, amenities, and other details.',
              ),
              buttonLabel: context.tr(bn: 'বিজ্ঞাপন দিন', en: 'Post Ad'),
              onPressed: () {
                Navigator.of(context).pop();
                onPostAdvertisement();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RentalServiceOptionCard extends StatelessWidget {
  const _RentalServiceOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.72)),
        boxShadow: _tenantSurfaceShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 27),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ),
        ],
      ),
    );
  }
}

class _TenantChatHubPage extends StatelessWidget {
  const _TenantChatHubPage();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();
    final chats = viewModel.chatConversations;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        ScreenHeader(
          title: context.tr(bn: 'চ্যাট', en: 'Chat'),
          subtitle: context.tr(
            bn: 'মালিক, এজেন্ট এবং সাপোর্টের সাথে কথোপকথন এখানে দেখুন।',
            en: 'View conversations with owners, agents, and support here.',
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ChatFilterChip(
              label: context.tr(bn: 'সকল', en: 'All'),
              isSelected: true,
            ),
            _ChatFilterChip(
              label: context.tr(bn: 'মালিক', en: 'Owner'),
              isSelected: false,
            ),
            _ChatFilterChip(
              label: context.tr(bn: 'এজেন্ট', en: 'Agent'),
              isSelected: false,
            ),
            _ChatFilterChip(
              label: context.tr(bn: 'সাপোর্ট', en: 'Support'),
              isSelected: false,
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (viewModel.isLoadingChats)
          const Center(child: CircularProgressIndicator())
        else if (chats.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                context.tr(
                  bn: 'আপনার কোনো কথোপকথন নেই।',
                  en: 'You have no conversations.',
                ),
                style: const TextStyle(color: Color(0xFF6E7683)),
              ),
            ),
          )
        else
          ...chats.map((conversation) {
            final previewData = _TenantChatPreviewData(
              name: conversation.ownerName ?? 'Owner',
              message: LocalizedText(
                bn: conversation.lastMessage ?? '',
                en: conversation.lastMessage ?? '',
              ),
              time: LocalizedText(
                bn: '',
                en: '',
              ), // To be implemented with intl
              color: AppColors.primary,
              unreadCount: 0,
              conversation: conversation,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChatPreviewCard(chat: previewData),
            );
          }),
      ],
    );
  }
}

class _TenantBottomNavigationBar extends StatelessWidget {
  const _TenantBottomNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF8FBFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 1.4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1C1E40AF),
                blurRadius: 26,
                offset: Offset(0, 14),
              ),
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                Expanded(
                  child: _BottomNavItem(
                    index: 0,
                    selectedIndex: selectedIndex,
                    onSelected: onSelected,
                    icon: Icons.home_rounded,
                    selectedIcon: Icons.home_rounded,
                    label: context.loc(AppLocalLang.home),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    index: 1,
                    selectedIndex: selectedIndex,
                    onSelected: onSelected,
                    icon: Icons.search_rounded,
                    selectedIcon: Icons.search_rounded,
                    label: context.loc(AppLocalLang.search),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    index: 2,
                    selectedIndex: selectedIndex,
                    onSelected: onSelected,
                    icon: Icons.favorite_border_rounded,
                    selectedIcon: Icons.favorite_rounded,
                    label: context.tr(bn: 'সেভ করা', en: 'Saved'),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    index: 3,
                    selectedIndex: selectedIndex,
                    onSelected: onSelected,
                    icon: Icons.chat_bubble_outline_rounded,
                    selectedIcon: Icons.chat_bubble_rounded,
                    label: context.tr(bn: 'চ্যাট', en: 'Chat'),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    index: 4,
                    selectedIndex: selectedIndex,
                    onSelected: onSelected,
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: context.loc(AppLocalLang.profile),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.index,
    required this.selectedIndex,
    required this.onSelected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final int index;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;

    return InkWell(
      onTap: () => onSelected(index),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 34,
              width: isSelected ? 46 : 34,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF06B6D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : const Color(0xFFF3F7FB),
                borderRadius: BorderRadius.circular(18),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x332563EB),
                          blurRadius: 14,
                          offset: Offset(0, 7),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? Colors.white : AppColors.textMuted,
                size: 21,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeFadeSlide extends StatelessWidget {
  const _HomeFadeSlide({required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 460 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _LandingInspiredTenantHero extends StatelessWidget {
  const _LandingInspiredTenantHero({
    required this.controller,
    required this.onSubmitted,
    required this.onSearchTap,
    required this.onRequestTap,
    required this.onRentTap,
    required this.onSaleTap,
    required this.onTutorTap,
    required this.onPickupTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchTap;
  final VoidCallback onRequestTap;
  final VoidCallback onRentTap;
  final VoidCallback onSaleTap;
  final VoidCallback onTutorTap;
  final VoidCallback onPickupTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 18,
          right: 18,
          bottom: -12,
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332563EB),
                  blurRadius: 34,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
        ),
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0009)
            ..rotateX(-0.018)
            ..rotateY(0.012),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF06152E),
                  Color(0xFF174AB1),
                  Color(0xFF0891B2),
                  Color(0xFF0F766E),
                ],
                stops: [0, 0.42, 0.72, 1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x362563EB),
                  blurRadius: 38,
                  offset: Offset(0, 20),
                ),
                BoxShadow(
                  color: Color(0x180F172A),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.02),
                          Colors.black.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -42,
                  top: -46,
                  child: _HeroGlowCircle(
                    size: 144,
                    color: Colors.white.withValues(alpha: 0.13),
                  ),
                ),
                Positioned(
                  left: -52,
                  bottom: 86,
                  child: _HeroGlowCircle(
                    size: 118,
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.14),
                  ),
                ),
                Positioned(
                  right: 18,
                  bottom: 92,
                  child: _HeroGlowCircle(
                    size: 72,
                    color: const Color(0xFFFFD166).withValues(alpha: 0.13),
                  ),
                ),
                const Positioned(
                  right: 10,
                  top: 88,
                  child: _HeroFloatingBuilding(),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppLogoMark(size: 24),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              context.tr(
                                bn: 'আমারঠিকানা - স্মার্ট সার্ভিস প্ল্যাটফর্ম',
                                en: 'AmarThikanaa - smart service address',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: const Color(0xFFE0F2FE),
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    DefaultTextStyle(
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 29,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                          ),
                      child: Stack(
                        children: [
                          Opacity(
                            opacity: 0.0,
                            child: Text(
                              context.tr(
                                bn: 'বাসা, শিক্ষক, পিকআপ, নিরাপত্তা ও স্থানীয় সেবা এক জায়গায় খুঁজুন',
                                en: 'Find housing, tutors, pickup, safety & local services in one place',
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: AnimatedTextKit(
                              animatedTexts: [
                                TypewriterAnimatedText(
                                  context.tr(
                                    bn: 'বাসা, শিক্ষক, পিকআপ, নিরাপত্তা ও স্থানীয় সেবা এক জায়গায় খুঁজুন',
                                    en: 'Find housing, tutors, pickup, safety & local services in one place',
                                  ),
                                  speed: const Duration(milliseconds: 100),
                                ),
                              ],
                              isRepeatingAnimation: true,
                              repeatForever: true,
                              displayFullTextOnTap: true,
                              stopPauseOnTap: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr(
                        bn: 'প্রয়োজন অনুযায়ী খুঁজুন, রিকোয়েস্ট পাঠান এবং সঠিক সার্ভিসের সাথে দ্রুত কানেক্ট করুন।',
                        en: 'Search by need, send a request, and connect with the right service faster.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _HeroSearchField(
                      controller: controller,
                      onSubmitted: onSubmitted,
                      onSearchTap: onSearchTap,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroServiceChip(
                          label: context.tr(bn: 'ভাড়া', en: 'Rent'),
                          onTap: onRentTap,
                        ),
                        _HeroServiceChip(
                          label: context.tr(bn: 'বিক্রি', en: 'Sale'),
                          onTap: onSaleTap,
                        ),
                        _HeroServiceChip(
                          label: context.tr(bn: 'শিক্ষক', en: 'Tutor'),
                          onTap: onTutorTap,
                        ),
                        _HeroServiceChip(
                          label: context.tr(bn: 'পিকআপ', en: 'Pickup'),
                          onTap: onPickupTap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroActionButton(
                            label: context.tr(
                              bn: 'সার্ভিস রিকোয়েস্ট',
                              en: 'Request service',
                            ),
                            icon: Icons.add_task_rounded,
                            filled: true,
                            onTap: onRequestTap,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HeroActionButton(
                            label: context.tr(
                              bn: 'সার্ভিসগুলো দেখুন',
                              en: 'See services',
                            ),
                            icon: Icons.grid_view_rounded,
                            filled: false,
                            onTap: onSearchTap,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    Row(
                      children: const [
                        Expanded(
                          child: _HeroMetricCard(value: '6+', label: 'সার্ভিস'),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _HeroMetricCard(
                            value: '24/7',
                            label: 'রিকোয়েস্ট',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _HeroMetricCard(
                            value: '1',
                            label: 'প্ল্যাটফর্ম',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroGlowCircle extends StatelessWidget {
  const _HeroGlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _HeroFloatingBuilding extends StatelessWidget {
  const _HeroFloatingBuilding();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(-0.32)
          ..rotateX(0.12),
        child: Opacity(
          opacity: 0.34,
          child: SizedBox(
            width: 86,
            height: 112,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: Container(
                    width: 54,
                    height: 104,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.38),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 2,
                  bottom: 12,
                  child: Container(
                    width: 38,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: 18,
                  child: Container(
                    width: 28,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF67E8F9).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                ),
                for (var row = 0; row < 4; row++)
                  for (var col = 0; col < 2; col++)
                    Positioned(
                      left: 28 + (col * 17),
                      top: 18 + (row * 18),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.56),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSearchField extends StatelessWidget {
  const _HeroSearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onSearchTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.travel_explore_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration.collapsed(
                hintText: context.tr(
                  bn: 'এরিয়া, বাসা বা সার্ভিস খুঁজুন',
                  en: 'Search area, home, or service',
                ),
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSearchTap,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x332563EB),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? const Color(0xFF174AB1) : Colors.white;
    final background = filled
        ? Colors.white
        : Colors.white.withValues(alpha: 0.14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 18),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
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

class _HeroServiceChip extends StatelessWidget {
  const _HeroServiceChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFFE7F8FF),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroMetricCard extends StatelessWidget {
  const _HeroMetricCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSectionTitle extends StatelessWidget {
  const _HomeSectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          width: 5,
          margin: const EdgeInsets.only(top: 3, right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TenantBulletinTicker extends StatefulWidget {
  const _TenantBulletinTicker({required this.message});

  final String message;

  @override
  State<_TenantBulletinTicker> createState() => _TenantBulletinTickerState();
}

class _TenantBulletinTickerState extends State<_TenantBulletinTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF9F1239),
      fontSize: 12.5,
      fontWeight: FontWeight.w800,
      height: 1.2,
    );
    final painter = TextPainter(
      text: TextSpan(text: widget.message, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final textWidth = painter.width + 18;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFFF1F2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12F43F5E),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Container(
            height: 28,
            width: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFB7185), Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final offset =
                          constraints.maxWidth -
                          (constraints.maxWidth + textWidth) *
                              _controller.value;

                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                  );
                },
                child: Text(
                  widget.message,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: textStyle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _TenantAccountNavigationDrawer extends StatelessWidget {
  const _TenantAccountNavigationDrawer();

  void _openDrawerPage(BuildContext context, Widget page) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openProfileTab(BuildContext context) {
    final shellViewModel = context.read<RoleShellViewModel>();
    Navigator.of(context).pop();
    shellViewModel.selectTab(4);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();
    final tenant = viewModel.tenantProfile;
    final property = viewModel.activeTenantProperty;
    final propertyName = viewModel.activeTenant.propertyName.trim().isEmpty
        ? context.demoText('No property assigned')
        : viewModel.activeTenant.propertyName;
    final phoneLabel = tenant.phone.trim().isEmpty
        ? context.demoText('Not set')
        : tenant.phone;
    final rentLabel = property == null
        ? context.demoText('Not set')
        : context.money(property.monthlyRent);
    final dueLabel = property == null
        ? context.demoText('Not set')
        : context.money(property.dueAmount);

    return Drawer(
      backgroundColor: const Color(0xFFF7F8FC),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.demoText('Tenant Menu'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _TenantDrawerTenantCard(
              tenant: tenant,
              phoneLabel: phoneLabel,
              propertyName: propertyName,
              rentLabel: rentLabel,
              dueLabel: dueLabel,
            ),
            const SizedBox(height: 16),
            _TenantDrawerMenuItem(
              title: 'Owner Info',
              icon: Icons.person_pin_rounded,
              onTap: () =>
                  _openDrawerPage(context, const OwnerProfileDetailsPage()),
            ),
            _TenantDrawerMenuItem(
              title: 'Owner Payment Info',
              icon: Icons.receipt_long_rounded,
              onTap: () =>
                  _openDrawerPage(context, const TenantPaymentCenterPage()),
            ),
            _TenantDrawerMenuItem(
              title: 'Pay Owner',
              icon: Icons.account_balance_wallet_rounded,
              onTap: () =>
                  _openDrawerPage(context, const TenantRentPaymentPage()),
            ),
            _TenantDrawerMenuItem(
              title: 'Monthly Bills',
              icon: Icons.calendar_month_rounded,
              onTap: () =>
                  _openDrawerPage(context, const TenantMonthlyBillsPage()),
            ),
            _TenantDrawerMenuItem(
              title: 'Payment History',
              icon: Icons.history_rounded,
              onTap: () =>
                  _openDrawerPage(context, const TenantPaymentHistoryPage()),
            ),
            _TenantDrawerMenuItem(
              title: 'Maintenance Request',
              icon: Icons.build_circle_rounded,
              onTap: () => _openDrawerPage(
                context,
                const TenantMaintenanceRequestPage(),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFFE3E8F2)),
            const SizedBox(height: 8),
            _TenantDrawerMenuItem(
              title: 'My Profile',
              icon: Icons.person_outline_rounded,
              onTap: () => _openProfileTab(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerAccountNavigationDrawer extends StatelessWidget {
  const _OwnerAccountNavigationDrawer();

  void _openOwnerPage(BuildContext context, Widget page) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(backgroundColor: AppColors.background),
          body: SafeArea(top: false, child: page),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    Navigator.of(context).pop();
    showComingSoonSnackBar(context, context.demoText(label));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OwnerDashboardViewModel>();

    return Drawer(
      backgroundColor: const Color(0xFFF7F8FC),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.demoText('Owner Menu'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _OwnerDrawerSummaryCard(viewModel: viewModel),
            const SizedBox(height: 16),
            _TenantDrawerMenuItem(
              title: 'Owner Info',
              icon: Icons.person_rounded,
              onTap: () => _openOwnerPage(context, const OwnerProfilePage()),
            ),
            _TenantDrawerMenuItem(
              title: 'Tenant Info',
              icon: Icons.people_alt_rounded,
              onTap: () => _openOwnerPage(context, const OwnerTenantsPage()),
            ),
            _TenantDrawerMenuItem(
              title: 'Tenant Wise Payment Info',
              icon: Icons.account_balance_wallet_rounded,
              onTap: () => _openOwnerPage(
                context,
                const _OwnerTenantWisePaymentInfoPage(),
              ),
            ),
            _TenantDrawerMenuItem(
              title: 'Send Monthly Bill',
              icon: Icons.receipt_long_rounded,
              onTap: () =>
                  _openOwnerPage(context, const OwnerBillingGeneratorPage()),
            ),
            _TenantDrawerMenuItem(
              title: 'Property List',
              icon: Icons.home_work_rounded,
              onTap: () => _showComingSoon(context, 'Property List'),
            ),
            _TenantDrawerMenuItem(
              title: 'Reports',
              icon: Icons.analytics_rounded,
              onTap: () => _showComingSoon(context, 'Reports'),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFFE3E8F2)),
            const SizedBox(height: 8),
            _TenantDrawerMenuItem(
              title: 'Settings',
              icon: Icons.settings_rounded,
              onTap: () => _showComingSoon(context, 'Owner Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerDrawerSummaryCard extends StatelessWidget {
  const _OwnerDrawerSummaryCard({required this.viewModel});

  final OwnerDashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E8F2)),
        boxShadow: _tenantSurfaceShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.real_estate_agent_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.demoText('Shuvo Owner'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.demoText('Property Owner'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _TenantDrawerInfoRow(
            label: 'Properties',
            value: context.digitsText(viewModel.properties.length),
          ),
          _TenantDrawerInfoRow(
            label: 'Tenants',
            value: context.digitsText(viewModel.tenants.length),
          ),
          _TenantDrawerInfoRow(
            label: 'Collected',
            value: context.money(viewModel.collectedRent),
          ),
          _TenantDrawerInfoRow(
            label: 'Due Bills',
            value: context.money(viewModel.dueBills),
          ),
        ],
      ),
    );
  }
}

class _OwnerTenantWisePaymentInfoPage extends StatelessWidget {
  const _OwnerTenantWisePaymentInfoPage();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OwnerDashboardViewModel>();
    final tenants = viewModel.tenants;
    final payments = viewModel.rentPayments;

    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(
          title: context.demoText('Tenant Wise Payment Info'),
          subtitle: context.demoText(
            'Track paid and due rent amounts for every tenant.',
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.demoText('Payment Summary'),
          child: Column(
            children: [
              InfoLine(
                label: context.demoText('Collected Rent'),
                value: context.money(viewModel.collectedRent),
              ),
              InfoLine(
                label: context.demoText('Due Bills'),
                value: context.money(viewModel.dueBills),
              ),
              InfoLine(
                label: context.demoText('Active Tenants'),
                value: context.digitsText(tenants.length),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (tenants.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              context.demoText('No tenants found.'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          ...tenants.map((tenant) {
            final tenantPayments = payments
                .where(
                  (payment) =>
                      payment.tenantName == tenant.name ||
                      payment.propertyName == tenant.propertyName,
                )
                .toList(growable: false);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OwnerTenantPaymentSummaryCard(
                tenant: tenant,
                payments: tenantPayments,
              ),
            );
          }),
      ],
    );
  }
}

class _OwnerTenantPaymentSummaryCard extends StatelessWidget {
  const _OwnerTenantPaymentSummaryCard({
    required this.tenant,
    required this.payments,
  });

  final TenantProfile tenant;
  final List<RentPayment> payments;

  @override
  Widget build(BuildContext context) {
    final paidTotal = payments
        .where((payment) => payment.status == PaymentStatus.paid)
        .fold<int>(0, (sum, payment) => sum + payment.amount);
    final dueTotal = payments
        .where((payment) => payment.status == PaymentStatus.due)
        .fold<int>(0, (sum, payment) => sum + payment.amount);
    final latestPayment = payments.isEmpty ? null : payments.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF3)),
        boxShadow: _tenantSurfaceShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  tenant.name.characters.first,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tenant.propertyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(
                label: context.demoText(dueTotal > 0 ? 'Due' : 'Clear'),
                color: dueTotal > 0 ? AppColors.warning : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _TenantDrawerInfoRow(label: 'Paid', value: context.money(paidTotal)),
          _TenantDrawerInfoRow(label: 'Due', value: context.money(dueTotal)),
          _TenantDrawerInfoRow(
            label: 'Last Record',
            value: latestPayment?.monthLabel ?? context.demoText('No records'),
          ),
          if (latestPayment != null)
            _TenantDrawerInfoRow(
              label: 'Last Amount',
              value: context.money(latestPayment.amount),
            ),
        ],
      ),
    );
  }
}

class _TenantDrawerTenantCard extends StatelessWidget {
  const _TenantDrawerTenantCard({
    required this.tenant,
    required this.phoneLabel,
    required this.propertyName,
    required this.rentLabel,
    required this.dueLabel,
  });

  final PersonOverviewData tenant;
  final String phoneLabel;
  final String propertyName;
  final String rentLabel;
  final String dueLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E8F2)),
        boxShadow: _tenantSurfaceShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  tenant.name.characters.first,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.demoText(tenant.badgeLabel),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _TenantDrawerInfoRow(label: 'Tenant ID', value: tenant.identifier),
          _TenantDrawerInfoRow(label: 'Phone', value: phoneLabel),
          _TenantDrawerInfoRow(label: 'Property', value: propertyName),
          _TenantDrawerInfoRow(label: 'Monthly Rent', value: rentLabel),
          _TenantDrawerInfoRow(label: 'Due Amount', value: dueLabel),
        ],
      ),
    );
  }
}

class _TenantDrawerInfoRow extends StatelessWidget {
  const _TenantDrawerInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              context.demoText(label),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantDrawerMenuItem extends StatelessWidget {
  const _TenantDrawerMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3E8F2)),
            ),
            child: Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.demoText(title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.item, required this.onTap});

  final _TenantQuickActionData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 10,
          right: 10,
          bottom: -5,
          child: Container(
            height: 18,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(-0.035)
            ..rotateY(0.022),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Color.lerp(item.color, Colors.white, 0.92) ??
                          const Color(0xFFF8FAFC),
                      const Color(0xFFFFFFFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.18),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                    const BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -22,
                      child: Container(
                        height: 58,
                        width: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.color.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -14,
                      bottom: -16,
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                item.color,
                                Color.lerp(item.color, Colors.white, 0.28) ??
                                    item.color,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: item.color.withValues(alpha: 0.34),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(item.icon, color: Colors.white, size: 25),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.loc(item.title),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 13.4,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.loc(item.subtitle),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 10.4,
                                height: 1.08,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TenantServiceExplainerBanner extends StatelessWidget {
  const _TenantServiceExplainerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFEFFDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: _tenantPremiumShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -42,
            child: Container(
              height: 132,
              width: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -34,
            bottom: -46,
            child: Container(
              height: 118,
              width: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 58,
                      width: 58,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF047857), Color(0xFF064E3B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF047857,
                            ).withValues(alpha: 0.24),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/branding/amar_thikanaa_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              bn: 'বাসা খোঁজা, ভাড়া দেওয়া আর লেনদেন সমস্যা?',
                              en: 'Finding homes, renting out, or payment issues?',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 20,
                                  height: 1.12,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF064E3B),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(
                              bn: 'সমাধান একটাই - আমার ঠিকানা অ্যাপ',
                              en: 'One app for home search, rent posts, and safer deals',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  height: 1.25,
                                  color: const Color(0xFF475569),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 620;
                    final panels = _tenantServiceExplainerItems
                        .map((item) => _TenantServiceExplainerPanel(item: item))
                        .toList();

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < panels.length; i++) ...[
                            Expanded(child: panels[i]),
                            if (i != panels.length - 1)
                              const SizedBox(width: 10),
                          ],
                        ],
                      );
                    }

                    return Column(
                      children: [
                        for (var i = 0; i < panels.length; i++) ...[
                          panels[i],
                          if (i != panels.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF047857)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr(
                            bn: 'সহজে বাসা খুঁজুন, ভাড়া দিন, নিরাপদ লেনদেন করুন',
                            en: 'Search homes, post rent ads, and manage safer transactions',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
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

class _TenantServiceExplainerPanel extends StatelessWidget {
  const _TenantServiceExplainerPanel({required this.item});

  final _TenantServiceExplainerData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: item.color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: item.color.withValues(alpha: 0.12),
                ),
                child: Icon(item.icon, color: item.color, size: 23),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.loc(item.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 116,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  item.color.withValues(alpha: 0.12),
                  const Color(0xFFF8FAFC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 12,
                  top: 12,
                  bottom: 12,
                  child: _TenantServicePhoneMockup(color: item.color),
                ),
                Positioned(
                  right: 12,
                  top: 15,
                  child: _TenantServiceSpeechBubble(
                    text: context.loc(item.question),
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Icon(
                    item.backgroundIcon,
                    size: 42,
                    color: item.color.withValues(alpha: 0.20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final point in item.points) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, size: 17, color: item.color),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    context.loc(point),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
            if (point != item.points.last) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _TenantServicePhoneMockup extends StatelessWidget {
  const _TenantServicePhoneMockup({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0F172A),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
        child: Column(
          children: [
            Container(
              height: 5,
              width: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < 3; i++) ...[
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: i == 0
                      ? color.withValues(alpha: 0.16)
                      : const Color(0xFFEFF4F8),
                ),
              ),
              if (i != 2) const SizedBox(height: 5),
            ],
          ],
        ),
      ),
    );
  }
}

class _TenantServiceSpeechBubble extends StatelessWidget {
  const _TenantServiceSpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 102,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          height: 1.18,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }
}

class _TenantShowcaseListingCard extends StatelessWidget {
  const _TenantShowcaseListingCard({
    required this.listing,
    required this.onTap,
  });

  final TenantShowcaseListingData listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();
    final isSaved = listing.postId != null && listing.postType != null
        ? viewModel.isPostSaved(listing.postId!.toString(), listing.postType!)
        : false;

    void toggleSaved() {
      if (listing.postId != null && listing.postType != null) {
        viewModel.toggleSavedPost(
          listing.postId!.toString(),
          listing.postType!,
        );
      }
    }

    final description = context.tr(
      bn: 'ভেরিফাইড মালিকের পোস্ট। লোকেশন, বাজেট এবং প্রয়োজনীয় সুবিধা দেখে বিস্তারিত জানুন।',
      en: 'Verified owner listing with clear location, budget, and essential home details.',
    );
    final postedLabel = listing.isNew
        ? context.tr(bn: 'আজ পোস্ট করা', en: 'Posted today')
        : context.tr(bn: 'সম্প্রতি পোস্ট', en: 'Recently posted');
    final heroTag =
        'tenant-listing-${listing.postType ?? 'demo'}-${listing.postId ?? context.loc(listing.title)}';

    Widget media = ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: listing.imageUrl != null
          ? Image.network(
              listing.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  ListingArtwork(style: listing.artworkStyle),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: const Color(0xFFF0F2F5),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            )
          : ListingArtwork(style: listing.artworkStyle),
    );

    media = Hero(tag: heroTag, child: media);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: _tenantPremiumShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 210,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1, end: 1.025),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: media,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.42),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Row(
                        children: [
                          _ListingBadge(label: context.loc(listing.badge)),
                          if (listing.isNew) ...[
                            const SizedBox(width: 8),
                            _ListingBadge(
                              label: context.tr(bn: 'Featured', en: 'Featured'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: toggleSaved,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x260F172A),
                                blurRadius: 14,
                                offset: Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Icon(
                            isSaved
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isSaved
                                ? Colors.red
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Row(
                        children: [
                          Expanded(
                            child: _GlassMetaPill(
                              icon: Icons.verified_rounded,
                              label: context.tr(
                                bn: 'Owner Verified',
                                en: 'Owner Verified',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _GlassMetaPill(
                            icon: Icons.visibility_rounded,
                            label: '${listing.photoCount * 37} views',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            context.loc(listing.title),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 20,
                                  height: 1.16,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.loc(listing.price),
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF2563EB),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            context.loc(listing.location),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          postedLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ListingFeatureMeta(
                          icon: Icons.square_foot_rounded,
                          label: '${listing.areaSqft} sqft',
                        ),
                        _ListingFeatureMeta(
                          icon: Icons.bed_rounded,
                          label: '${listing.bedrooms} Bed',
                        ),
                        _ListingFeatureMeta(
                          icon: Icons.bathtub_outlined,
                          label: '${listing.bathrooms} Bath',
                        ),
                        _ListingFeatureMeta(
                          icon: Icons.layers_rounded,
                          label: context.tr(
                            bn: 'Floor ready',
                            en: 'Floor ready',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ListingActionButton(
                            icon: Icons.call_rounded,
                            label: context.tr(bn: 'Call', en: 'Call'),
                            color: const Color(0xFF16A34A),
                            onTap: () => showComingSoonSnackBar(
                              context,
                              context.tr(bn: 'Call', en: 'Call'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ListingActionButton(
                            icon: Icons.chat_rounded,
                            label: context.tr(bn: 'WhatsApp', en: 'WhatsApp'),
                            color: const Color(0xFF22C55E),
                            onTap: () => showComingSoonSnackBar(
                              context,
                              context.tr(bn: 'WhatsApp', en: 'WhatsApp'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ListingActionButton(
                            icon: Icons.article_rounded,
                            label: context.tr(bn: 'Details', en: 'Details'),
                            color: const Color(0xFF2563EB),
                            onTap: onTap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ListingIconActionButton(
                          icon: isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          onTap: toggleSaved,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassMetaPill extends StatelessWidget {
  const _GlassMetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingActionButton extends StatelessWidget {
  const _ListingActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17),
            const SizedBox(width: 4),
            Text(label, maxLines: 1),
          ],
        ),
      ),
    );
  }
}

class _ListingIconActionButton extends StatelessWidget {
  const _ListingIconActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        backgroundColor: const Color(0xFFEFF6FF),
        foregroundColor: const Color(0xFF2563EB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _ListingFeatureMeta extends StatelessWidget {
  const _ListingFeatureMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11.5,
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingBadge extends StatelessWidget {
  const _ListingBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3744).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class ListingArtwork extends StatelessWidget {
  const ListingArtwork({super.key, required this.style});

  final TenantListingArtworkStyle style;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      TenantListingArtworkStyle.livingRoom => const _LivingRoomArtwork(),
      TenantListingArtworkStyle.bedroom => const _BedroomArtwork(),
      TenantListingArtworkStyle.diningRoom => const _DiningRoomArtwork(),
      TenantListingArtworkStyle.building => const _BuildingArtwork(),
    };
  }
}

class _LivingRoomArtwork extends StatelessWidget {
  const _LivingRoomArtwork();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4E8DB), Color(0xFFE7D1BB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 12,
            child: Container(
              height: 86,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD9E5F6), width: 4),
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 20,
            child: Container(
              height: 66,
              width: 54,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9ED4FF), Color(0xFFEAF6FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 4,
                    right: 4,
                    bottom: 10,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4D8690),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 8,
                    child: Container(
                      height: 22,
                      width: 2,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  Positioned(
                    left: 26,
                    top: 8,
                    child: Container(
                      height: 22,
                      width: 2,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 18,
            child: Container(
              height: 66,
              width: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF4D7C55),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 66,
            child: Container(
              height: 32,
              width: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF7AB27F),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 24,
            child: Container(
              height: 44,
              width: 86,
              decoration: BoxDecoration(
                color: const Color(0xFFF7EEE4),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            left: 68,
            bottom: 32,
            child: Container(
              height: 26,
              width: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFC99A68),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            left: 114,
            bottom: 24,
            child: Container(
              height: 52,
              width: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF2F3136),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            left: 118,
            bottom: 18,
            child: Container(
              height: 10,
              width: 62,
              decoration: BoxDecoration(
                color: const Color(0xFF584436),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ColoredBox(
              color: Color(0xFFB68761),
              child: SizedBox(height: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _BedroomArtwork extends StatelessWidget {
  const _BedroomArtwork();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE4D4C2), Color(0xFFD8C0AB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 18,
            right: 18,
            top: 26,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFC39A74),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 34,
            right: 34,
            top: 48,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFCF8F2),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            left: 42,
            top: 54,
            child: Container(
              height: 16,
              width: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFE2DDD6),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            left: 80,
            top: 54,
            child: Container(
              height: 16,
              width: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFE0C9AF),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 28,
            child: _BedsideLamp(
              lampColor: const Color(0xFFE0C39D),
              baseColor: const Color(0xFF7C5A46),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 28,
            child: _BedsideLamp(
              lampColor: const Color(0xFFE0C39D),
              baseColor: const Color(0xFF7C5A46),
            ),
          ),
          Positioned(
            right: 18,
            top: 18,
            child: Container(
              height: 92,
              width: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF7F4EE), Color(0xFFE5D9CA)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ColoredBox(
              color: Color(0xFFB28A66),
              child: SizedBox(height: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _BedsideLamp extends StatelessWidget {
  const _BedsideLamp({required this.lampColor, required this.baseColor});

  final Color lampColor;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 54,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 22,
            child: Container(
              height: 20,
              width: 24,
              decoration: BoxDecoration(
                color: lampColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Container(height: 14, width: 3, color: baseColor),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              height: 10,
              width: 28,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiningRoomArtwork extends StatelessWidget {
  const _DiningRoomArtwork();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4ECE2), Color(0xFFE3D3C2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 10,
            child: Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFF9E5B5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF9E5B5).withValues(alpha: 0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 24,
            top: 30,
            child: ColoredBox(
              color: Color(0xFFB38B5E),
              child: SizedBox(height: 18, width: 2),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: 18,
            child: Container(
              height: 86,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF7F3ED), Color(0xFFE7DCD0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 58,
            bottom: 26,
            child: Container(
              height: 38,
              width: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFBA8D63),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            left: 40,
            bottom: 30,
            child: _ChairArtwork(direction: AxisDirection.left),
          ),
          const Positioned(
            left: 124,
            bottom: 30,
            child: _ChairArtwork(direction: AxisDirection.right),
          ),
          Positioned(
            right: 16,
            bottom: 22,
            child: Container(
              height: 66,
              width: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF4E7A4E),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 60,
            child: Container(
              height: 30,
              width: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF77AA72),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD4B28A), Color(0xFFC79D72)],
                ),
              ),
              child: SizedBox(height: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChairArtwork extends StatelessWidget {
  const _ChairArtwork({required this.direction});

  final AxisDirection direction;

  @override
  Widget build(BuildContext context) {
    final isLeft = direction == AxisDirection.left;

    return SizedBox(
      height: 36,
      width: 28,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 4,
            right: 4,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF9E7A5C),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: isLeft ? 4 : 12,
            child: Container(
              height: 22,
              width: 2,
              color: const Color(0xFF88664A),
            ),
          ),
          Positioned(
            top: 10,
            right: isLeft ? 12 : 4,
            child: Container(
              height: 22,
              width: 2,
              color: const Color(0xFF88664A),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildingArtwork extends StatelessWidget {
  const _BuildingArtwork();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8EA1DA), Color(0xFFDFA37D), Color(0xFFF5D6C5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 64,
            right: 42,
            bottom: 16,
            top: 16,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(-0.22),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D3549), Color(0xFF55617A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  child: Column(
                    children: List.generate(
                      6,
                      (rowIndex) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: rowIndex == 5 ? 0 : 6,
                          ),
                          child: Row(
                            children: List.generate(
                              3,
                              (_) => Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFFD27A,
                                    ).withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 98,
            right: 10,
            bottom: 12,
            top: 26,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3C485E), Color(0xFF6B7790)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Column(
                  children: List.generate(
                    5,
                    (rowIndex) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: rowIndex == 4 ? 0 : 6),
                        child: Row(
                          children: List.generate(
                            2,
                            (_) => Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFD89E,
                                  ).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6E7B65), Color(0xFF4B5C44)],
                ),
              ),
              child: SizedBox(height: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatFilterChip extends StatelessWidget {
  const _ChatFilterChip({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFE3E8F2),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChatPreviewCard extends StatelessWidget {
  const _ChatPreviewCard({required this.chat});

  final _TenantChatPreviewData chat;

  @override
  Widget build(BuildContext context) {
    final chatWindowLabel = context.tr(bn: 'চ্যাট উইন্ডো', en: 'Chat window');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (chat.conversation != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _TenantChatConversationScreen(
                  conversation: chat.conversation!,
                ),
              ),
            );
          } else {
            showComingSoonSnackBar(context, chatWindowLabel);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8ECF3)),
            boxShadow: _tenantSurfaceShadow,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: chat.color.withValues(alpha: 0.12),
                child: Text(
                  chat.name.characters.first,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: chat.color),
                ),
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
                            chat.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          context.loc(chat.time),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.loc(chat.message),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (chat.unreadCount > 0) ...[
                const SizedBox(width: 12),
                Container(
                  height: 24,
                  width: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    context.digitsText(chat.unreadCount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _TenantQuickActionType {
  rentalService,
  rent,
  sale,
  search,
  teacher,
  pickup,
  secureDeal,
  amarElaka,
  smartBazar,
  sos,
  phoneVerification,
}

enum TenantListingArtworkStyle { livingRoom, bedroom, diningRoom, building }

class _TenantQuickActionData {
  const _TenantQuickActionData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final _TenantQuickActionType type;
  final LocalizedText title;
  final LocalizedText subtitle;
  final IconData icon;
  final Color color;
}

class _TenantServiceExplainerData {
  const _TenantServiceExplainerData({
    required this.title,
    required this.question,
    required this.points,
    required this.icon,
    required this.backgroundIcon,
    required this.color,
  });

  final LocalizedText title;
  final LocalizedText question;
  final List<LocalizedText> points;
  final IconData icon;
  final IconData backgroundIcon;
  final Color color;
}

class TenantShowcaseListingData {
  const TenantShowcaseListingData({
    required this.category,
    required this.badge,
    required this.title,
    required this.location,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqft,
    required this.photoCount,
    required this.artworkStyle,
    this.imageUrl,
    this.isNew = false,
    this.rawPost,
    this.postId,
    this.postType,
  });

  final MarketplaceCategory category;
  final LocalizedText badge;
  final LocalizedText title;
  final LocalizedText location;
  final LocalizedText price;
  final int bedrooms;
  final int bathrooms;
  final int areaSqft;
  final int photoCount;
  final bool isNew;
  final TenantListingArtworkStyle artworkStyle;
  final String? imageUrl;
  final dynamic rawPost;
  final int? postId;
  final String? postType;

  LatLng get mapPosition {
    return switch (title.en) {
      'Mirpur DOHS, 2 Bed Flat' => const LatLng(23.8067, 90.3686),
      'Gulshan 2, 3 Bed Flat' => const LatLng(23.7946, 90.4143),
      'Uttara Sector 7, 3 Bed Flat' => const LatLng(23.8759, 90.3795),
      'Banani Premium 4 Bed Flat' => const LatLng(23.7937, 90.4043),
      _ => const LatLng(23.8103, 90.4125),
    };
  }
}

class _TenantChatPreviewData {
  const _TenantChatPreviewData({
    required this.name,
    required this.message,
    required this.time,
    required this.color,
    this.unreadCount = 0,
    this.conversation,
  });

  final String name;
  final LocalizedText message;
  final LocalizedText time;
  final Color color;
  final int unreadCount;
  final TenantChatConversationDto? conversation;
}

const _tenantQuickActions = <_TenantQuickActionData>[
  _TenantQuickActionData(
    type: _TenantQuickActionType.rentalService,
    title: LocalizedText(bn: 'বাসা / ফ্ল্যাট', en: 'Home / Flat'),
    subtitle: LocalizedText(
      bn: 'ভাড়া খুঁজুন / বিজ্ঞাপন দিন',
      en: 'Search rent / Post ad',
    ),
    icon: Icons.apartment_rounded,
    color: Color(0xFF2563EB),
  ),
  _TenantQuickActionData(
    type: _TenantQuickActionType.teacher,
    title: LocalizedText(bn: 'শিক্ষক', en: 'Tutor'),
    subtitle: LocalizedText(bn: 'দিচ্ছি / নিচ্ছি', en: 'Teach / Learn'),
    icon: Icons.school_rounded,
    color: Color(0xFF14B8A6),
  ),
  _TenantQuickActionData(
    type: _TenantQuickActionType.pickup,
    title: LocalizedText(bn: 'পিকআপ সার্ভিস', en: 'Pickup Service'),
    subtitle: LocalizedText(bn: 'সার্ভিস বুক করুন', en: 'Book service'),
    icon: Icons.airport_shuttle_rounded,
    color: Color(0xFFF97316),
  ),
  _TenantQuickActionData(
    type: _TenantQuickActionType.secureDeal,
    title: LocalizedText(bn: 'সিকিউর ডিল', en: 'Secure Deal'),
    subtitle: LocalizedText(bn: 'এসক্রো পেমেন্ট', en: 'Escrow payment'),
    icon: Icons.verified_user_rounded,
    color: Color(0xFF4338CA),
  ),
  _TenantQuickActionData(
    type: _TenantQuickActionType.amarElaka,
    title: LocalizedText(bn: 'আমার এলাকা', en: 'Amar eLaka'),
    subtitle: LocalizedText(bn: 'এলাকার তথ্য দেখুন', en: 'Explore your area'),
    icon: Icons.location_city_rounded,
    color: Color(0xFF0EA5E9),
  ),
  _TenantQuickActionData(
    type: _TenantQuickActionType.smartBazar,
    title: LocalizedText(bn: 'স্মার্ট বাজার', en: 'Smart Bazar'),
    subtitle: LocalizedText(bn: 'অনলাইন কেনাকাটা', en: 'Shop online'),
    icon: Icons.storefront_rounded,
    color: Color(0xFFEC4899),
  ),
  _TenantQuickActionData(
    type: _TenantQuickActionType.sos,
    title: LocalizedText(bn: 'SOS', en: 'SOS'),
    subtitle: LocalizedText(bn: 'জরুরি সাহায্য', en: 'Emergency'),
    icon: Icons.sos_rounded,
    color: Color(0xFFEF4444), // Red color for SOS
  ),
  _TenantQuickActionData(
    type: _TenantQuickActionType.phoneVerification,
    title: LocalizedText(bn: 'ফোন ভেরিফাই', en: 'Phone Verify'),
    subtitle: LocalizedText(bn: 'নিরাপদ ফোন চেক', en: 'Safe phone check'),
    icon: Icons.verified_user_rounded,
    color: Color(0xFF0F6AA8),
  ),
];

const _tenantServiceExplainerItems = <_TenantServiceExplainerData>[
  _TenantServiceExplainerData(
    title: LocalizedText(bn: 'বাসা খোঁজা', en: 'Find Home'),
    question: LocalizedText(
      bn: 'ভালো লোকেশন, বাজেট আর সুবিধা কোথায় পাবো?',
      en: 'Where do I find the right budget and location?',
    ),
    points: [
      LocalizedText(
        bn: 'লোকেশন, বাজেট ও সুবিধা দিয়ে ফিল্টার',
        en: 'Filter by location, budget, and facilities',
      ),
      LocalizedText(
        bn: 'ছবি, বিবরণ ও মালিকের তথ্য দেখুন',
        en: 'View photos, details, and owner info',
      ),
    ],
    icon: Icons.search_rounded,
    backgroundIcon: Icons.apartment_rounded,
    color: Color(0xFFDC2626),
  ),
  _TenantServiceExplainerData(
    title: LocalizedText(bn: 'ভাড়া দেওয়া', en: 'Post Rent'),
    question: LocalizedText(
      bn: 'বিশ্বস্ত ভাড়াটে পাবো তো?',
      en: 'Will I find a reliable tenant?',
    ),
    points: [
      LocalizedText(
        bn: 'সহজে প্রপার্টি লিস্ট করুন',
        en: 'List your property easily',
      ),
      LocalizedText(
        bn: 'চুক্তি ও ভাড়া ব্যবস্থাপনা করুন',
        en: 'Manage agreements and rent',
      ),
    ],
    icon: Icons.real_estate_agent_rounded,
    backgroundIcon: Icons.key_rounded,
    color: Color(0xFF0F6AA8),
  ),
  _TenantServiceExplainerData(
    title: LocalizedText(bn: 'লেনদেন সমস্যা', en: 'Payment Help'),
    question: LocalizedText(
      bn: 'অগ্রিম টাকা, চুক্তি, ভাড়া নিয়ে ঝামেলা?',
      en: 'Advance, agreement, or rent payment trouble?',
    ),
    points: [
      LocalizedText(
        bn: 'ডিজিটাল চুক্তি ও নিরাপদ লেনদেন',
        en: 'Digital agreement and safer payment',
      ),
      LocalizedText(
        bn: 'সমস্যা হলে সাপোর্ট টিম পাশে আছে',
        en: 'Support team helps when issues happen',
      ),
    ],
    icon: Icons.warning_amber_rounded,
    backgroundIcon: Icons.verified_user_rounded,
    color: Color(0xFF047857),
  ),
];

const _tenantShowcaseListings = <TenantShowcaseListingData>[
  TenantShowcaseListingData(
    category: MarketplaceCategory.rent,
    badge: LocalizedText(bn: 'ভাড়া', en: 'Rent'),
    title: LocalizedText(
      bn: 'মিরপুর DOHS, ২ বেড ফ্ল্যাট',
      en: 'Mirpur DOHS, 2 Bed Flat',
    ),
    location: LocalizedText(bn: 'মিরপুর, ঢাকা', en: 'Mirpur, Dhaka'),
    price: LocalizedText(bn: '৳ 15,000 / মাস', en: '৳ 15,000 / month'),
    bedrooms: 2,
    bathrooms: 2,
    areaSqft: 1200,
    photoCount: 6,
    artworkStyle: TenantListingArtworkStyle.livingRoom,
    isNew: true,
  ),
  TenantShowcaseListingData(
    category: MarketplaceCategory.sale,
    badge: LocalizedText(bn: 'বিক্রি', en: 'Sale'),
    title: LocalizedText(
      bn: 'গুলশান ২, ৩ বেড ফ্ল্যাট (সেল)',
      en: 'Gulshan 2, 3 Bed Flat',
    ),
    location: LocalizedText(bn: 'গুলশান, ঢাকা', en: 'Gulshan, Dhaka'),
    price: LocalizedText(bn: '৳ 1,85,00,000', en: '৳ 18,500,000'),
    bedrooms: 3,
    bathrooms: 3,
    areaSqft: 1600,
    photoCount: 8,
    artworkStyle: TenantListingArtworkStyle.bedroom,
  ),
  TenantShowcaseListingData(
    category: MarketplaceCategory.rent,
    badge: LocalizedText(bn: 'ভাড়া', en: 'Rent'),
    title: LocalizedText(
      bn: 'উত্তরা সেক্টর ৭, ৩ বেড ফ্ল্যাট',
      en: 'Uttara Sector 7, 3 Bed Flat',
    ),
    location: LocalizedText(bn: 'উত্তরা, ঢাকা', en: 'Uttara, Dhaka'),
    price: LocalizedText(bn: '৳ 22,000 / মাস', en: '৳ 22,000 / month'),
    bedrooms: 3,
    bathrooms: 3,
    areaSqft: 1500,
    photoCount: 5,
    artworkStyle: TenantListingArtworkStyle.diningRoom,
  ),
  TenantShowcaseListingData(
    category: MarketplaceCategory.sale,
    badge: LocalizedText(bn: 'বিক্রি', en: 'Sale'),
    title: LocalizedText(
      bn: 'বনানী, প্রিমিয়াম ৪ বেড ফ্ল্যাট',
      en: 'Banani Premium 4 Bed Flat',
    ),
    location: LocalizedText(bn: 'বনানী, ঢাকা', en: 'Banani, Dhaka'),
    price: LocalizedText(bn: '৳ 3,25,00,000', en: '৳ 32,500,000'),
    bedrooms: 4,
    bathrooms: 4,
    areaSqft: 2200,
    photoCount: 7,
    artworkStyle: TenantListingArtworkStyle.building,
  ),
  TenantShowcaseListingData(
    category: MarketplaceCategory.rent,
    badge: LocalizedText(bn: 'ভাড়া', en: 'Rent'),
    title: LocalizedText(
      bn: 'মোহাম্মদপুর, ফ্যামিলি ২ বেড ফ্ল্যাট',
      en: 'Mohammadpur Family 2 Bed Flat',
    ),
    location: LocalizedText(bn: 'মোহাম্মদপুর, ঢাকা', en: 'Mohammadpur, Dhaka'),
    price: LocalizedText(bn: '৳ 18,500 / মাস', en: '৳ 18,500 / month'),
    bedrooms: 2,
    bathrooms: 2,
    areaSqft: 1100,
    photoCount: 9,
    artworkStyle: TenantListingArtworkStyle.livingRoom,
    isNew: true,
  ),
  TenantShowcaseListingData(
    category: MarketplaceCategory.rent,
    badge: LocalizedText(bn: 'ব্যাচেলর', en: 'Bachelor'),
    title: LocalizedText(
      bn: 'বাড্ডা, ব্যাচেলর সিট ভাড়া',
      en: 'Badda Bachelor Seat Rent',
    ),
    location: LocalizedText(bn: 'মেরুল বাড্ডা, ঢাকা', en: 'Merul Badda, Dhaka'),
    price: LocalizedText(bn: '৳ 6,500 / মাস', en: '৳ 6,500 / month'),
    bedrooms: 1,
    bathrooms: 1,
    areaSqft: 450,
    photoCount: 4,
    artworkStyle: TenantListingArtworkStyle.bedroom,
  ),
  TenantShowcaseListingData(
    category: MarketplaceCategory.sale,
    badge: LocalizedText(bn: 'বিক্রি', en: 'Sale'),
    title: LocalizedText(
      bn: 'বসুন্ধরা আবাসিক, ৩ বেড ফ্ল্যাট',
      en: 'Bashundhara Residential 3 Bed Flat',
    ),
    location: LocalizedText(
      bn: 'বসুন্ধরা আবাসিক, ঢাকা',
      en: 'Bashundhara Residential, Dhaka',
    ),
    price: LocalizedText(bn: '৳ 1,45,00,000', en: '৳ 14,500,000'),
    bedrooms: 3,
    bathrooms: 3,
    areaSqft: 1450,
    photoCount: 12,
    artworkStyle: TenantListingArtworkStyle.diningRoom,
    isNew: true,
  ),
];

TenantShowcaseListingData _mapGeneralPostToShowcase(GeneralPostItem post) {
  var artworkStyle = TenantListingArtworkStyle.livingRoom;
  var photoCount = 5;
  var areaSqft = 1000;
  var isNew = false;
  String? imageUrl;

  if (post.mediaInfo != null && post.mediaInfo!.isNotEmpty) {
    try {
      if (post.mediaInfo!.trim().startsWith('{')) {
        final decoded = jsonDecode(post.mediaInfo!) as Map<String, dynamic>;
        if (decoded.containsKey('artworkStyle')) {
          final styleStr = decoded['artworkStyle'] as String;
          artworkStyle = TenantListingArtworkStyle.values.firstWhere(
            (e) => e.name == styleStr,
            orElse: () => TenantListingArtworkStyle.livingRoom,
          );
        }
        if (decoded.containsKey('photoCount')) {
          photoCount = (decoded['photoCount'] as num).toInt();
        }
        if (decoded.containsKey('areaSqft')) {
          areaSqft = (decoded['areaSqft'] as num).toInt();
        }
        if (decoded.containsKey('isNew')) {
          isNew = decoded['isNew'] as bool;
        }
        if (decoded.containsKey('imageUrl')) {
          imageUrl = decoded['imageUrl'] as String;
        }
      } else {
        final parts = post.mediaInfo!.split(',');
        photoCount = parts.length;
        isNew = DateTime.now().difference(post.createdOn).inHours < 24;

        for (var part in parts) {
          final trimmed = part.trim();
          final lower = trimmed.toLowerCase();
          if (lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.png') ||
              lower.endsWith('.webp') ||
              lower.endsWith('.gif')) {
            final normalizedPath = trimmed.startsWith('/')
                ? trimmed
                : '/$trimmed';
            imageUrl = '${ApiConfig.baseUrl}$normalizedPath';
            break;
          }
        }
      }
    } catch (_) {
      final parts = post.mediaInfo!.split(',');
      photoCount = parts.length;
      isNew = DateTime.now().difference(post.createdOn).inHours < 24;
    }
  } else {
    artworkStyle = TenantListingArtworkStyle
        .values[post.id % TenantListingArtworkStyle.values.length];
    isNew = DateTime.now().difference(post.createdOn).inHours < 24;
  }

  final category = post.category == 'sale'
      ? MarketplaceCategory.sale
      : MarketplaceCategory.rent;

  final badge = category == MarketplaceCategory.sale
      ? const LocalizedText(bn: 'বিক্রি', en: 'Sale')
      : (post.tenantType == 'bachelor_male' ||
                post.tenantType == 'bachelor_female'
            ? const LocalizedText(bn: 'ব্যাচেলর', en: 'Bachelor')
            : const LocalizedText(bn: 'ভাড়া', en: 'Rent'));

  final title = LocalizedText(bn: post.title, en: post.title);

  final location = LocalizedText(
    bn: '${post.areaNameBn.isNotEmpty ? post.areaNameBn : post.areaId}, ঢাকা',
    en: '${post.areaNameBn.isNotEmpty ? post.areaNameBn : post.areaId}, Dhaka',
  );

  final formattedPrice = post.price
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
  final price = category == MarketplaceCategory.rent
      ? LocalizedText(
          bn: '৳ $formattedPrice / মাস',
          en: '৳ $formattedPrice / month',
        )
      : LocalizedText(bn: '৳ $formattedPrice', en: '৳ $formattedPrice');

  return TenantShowcaseListingData(
    category: category,
    badge: badge,
    title: title,
    location: location,
    price: price,
    bedrooms: post.bedrooms,
    bathrooms: post.bathrooms,
    areaSqft: areaSqft,
    photoCount: photoCount,
    artworkStyle: artworkStyle,
    imageUrl: imageUrl,
    isNew: isNew,
    rawPost: post,
    postId: post.id,
    postType: 'general',
  );
}

Widget buildTenantShowcaseListingCard({
  required TenantShowcaseListingData listing,
  required VoidCallback onTap,
}) {
  return _TenantShowcaseListingCard(listing: listing, onTap: onTap);
}

TenantShowcaseListingData mapGeneralPostToShowcase(GeneralPostItem post) {
  return _mapGeneralPostToShowcase(post);
}

List<TenantShowcaseListingData> get publicTenantShowcaseListings =>
    _tenantShowcaseListings;

class _TenantChatConversationScreen extends StatefulWidget {
  const _TenantChatConversationScreen({required this.conversation});

  final TenantChatConversationDto conversation;

  @override
  State<_TenantChatConversationScreen> createState() =>
      _TenantChatConversationScreenState();
}

class _TenantChatConversationScreenState
    extends State<_TenantChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;
  bool _isLoading = true;
  List<TenantChatMessageDto> _messages = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final viewModel = context.read<TenantExperienceViewModel>();
    try {
      final messages = await viewModel.getChatMessages(widget.conversation.id);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load messages';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isTyping = false;
      _messageController.clear();
      // Optimistic update
      _messages.insert(
        0,
        TenantChatMessageDto(
          id: 0,
          senderUserId: 'me', // Optimistic mine
          messageText: text,
          sentAt: DateTime.now(),
        ),
      );
    });

    final viewModel = context.read<TenantExperienceViewModel>();
    try {
      await viewModel.sendChatMessage(
        conversationId: widget.conversation.id,
        ownerUserId: widget.conversation.ownerUserId,
        messageText: text,
      );
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnerName = widget.conversation.ownerName ?? 'Owner';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(title: Text(partnerName)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!))
                    : _messages.isEmpty
                    ? Center(
                        child: Text(
                          context.tr(
                            bn: 'কোনো মেসেজ নেই। নিচে টাইপ করে কথা শুরু করুন।',
                            en: 'No messages yet. Say hello!',
                          ),
                          style: const TextStyle(color: Color(0xFF6E7683)),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final sortedMessages =
                              List<TenantChatMessageDto>.from(_messages)
                                ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
                          final message = sortedMessages[index];
                          final isMine =
                              message.senderUserId !=
                              widget.conversation.ownerUserId;

                          return _TenantChatBubble(
                            sender: isMine
                                ? context.tr(bn: 'আপনি', en: 'You')
                                : partnerName,
                            text: message.messageText,
                            mine: isMine,
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onChanged: (value) =>
                              setState(() => _isTyping = value.isNotEmpty),
                          decoration: InputDecoration(
                            hintText: context.tr(
                              bn: 'মেসেজ লিখুন...',
                              en: 'Type a message...',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        height: 48,
                        width: _isTyping ? 48 : 0,
                        margin: EdgeInsets.only(left: _isTyping ? 0 : 8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isTyping ? _sendMessage : null,
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
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

class _TenantChatBubble extends StatelessWidget {
  const _TenantChatBubble({
    required this.sender,
    required this.text,
    required this.mine,
  });

  final String sender;
  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF3F4F6),
              child: Text(
                sender.isNotEmpty ? sender[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: mine ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: mine ? Radius.zero : const Radius.circular(16),
                  bottomLeft: !mine ? Radius.zero : const Radius.circular(16),
                ),
                border: mine
                    ? null
                    : Border.all(color: const Color(0xFFE8ECF3)),
                boxShadow: _tenantSurfaceShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: mine ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (mine) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
