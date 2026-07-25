import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_context.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/secure_deal_view_model.dart';
import '../tenant_auth_bridge_screen.dart';
import '../../../../core/models/user_role.dart';

part 'secure_deal_welcome_page.dart';
part 'secure_deal_home_page.dart';
part 'secure_deal_profile_page.dart';
part 'secure_deal_create_deal_page.dart';
part 'secure_deal_confirm_deal_page.dart';
part 'secure_deal_payment_page.dart';
part 'secure_deal_payment_success_page.dart';
part 'secure_deal_details_page.dart';
part 'secure_deal_chat_page.dart';
part 'secure_deal_delivery_upload_page.dart';
part 'secure_deal_review_approve_page.dart';
part 'secure_deal_payment_released_page.dart';
part 'secure_deal_dispute_center_page.dart';
part 'secure_deal_wallet_page.dart';
part 'secure_deal_connect_page.dart';
part 'secure_deal_posts_page.dart';
part 'secure_deal_notifications_page.dart';
part 'secure_deal_vip_signup_page.dart';

const _dealPrimary = Color(0xFF4338CA);
const _dealPrimarySoft = Color(0xFFF1F0FF);
const _dealBorder = Color(0xFFE7EAF2);
const _dealShadow = <BoxShadow>[
  BoxShadow(color: Color(0x100F172A), blurRadius: 22, offset: Offset(0, 12)),
  BoxShadow(color: Color(0x080F172A), blurRadius: 8, offset: Offset(0, 3)),
];

class TenantSecureDealScreen extends StatelessWidget {
  const TenantSecureDealScreen({super.key});

  @override
  Widget build(BuildContext context) => const SecureDealWelcomePage();
}

class _SecureDealPageScaffold extends StatelessWidget {
  const _SecureDealPageScaffold({
    required this.title,
    required this.body,
    this.bottomAction,
  });

  final String title;
  final Widget body;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: bottomAction,
    );
  }
}

class _SecureDealBottomAction extends StatelessWidget {
  const _SecureDealBottomAction({
    required this.label,
    required this.onPressed,
    this.color = _dealPrimary,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _SecureDealWelcomeStep extends StatelessWidget {
  const _SecureDealWelcomeStep({required this.onLogin, required this.onSignUp});

  final VoidCallback onLogin;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      children: [
        const SizedBox(height: 18),
        const Center(child: _SecureDealShieldMark()),
        const SizedBox(height: 18),
        Text(
          'SecureDeal',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _dealPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Safe Deal, Trusted Payment',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 34),
        const _HandshakeArtwork(),
        const SizedBox(height: 28),
        Text(
          'A trusted escrow platform\nwhere deals get done safely.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 15,
            height: 1.45,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: onLogin,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: _dealPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Login'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onSignUp,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: _dealPrimary,
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Sign Up'),
        ),
        const SizedBox(height: 26),
        Text(
          'Trusted by thousands of users',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MiniUserAvatar(color: Color(0xFFFFCC80), label: 'R'),
            _MiniUserAvatar(color: Color(0xFFBFDBFE), label: 'A'),
            _MiniUserAvatar(color: Color(0xFFFBCFE8), label: 'J'),
            _MiniUserAvatar(color: Color(0xFFBBF7D0), label: 'M'),
            SizedBox(width: 8),
            Text(
              '10K+',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecureDealShieldMark extends StatelessWidget {
  const _SecureDealShieldMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      width: 106,
      child: CustomPaint(painter: _ShieldPainter()),
    );
  }
}

class _HandshakeArtwork extends StatelessWidget {
  const _HandshakeArtwork();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 146,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 92,
            width: 92,
            decoration: BoxDecoration(
              color: _dealPrimarySoft,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: _dealPrimary,
              size: 34,
            ),
          ),
          Positioned(
            left: 8,
            bottom: 0,
            child: _PersonIllustration(
              jacketColor: const Color(0xFF2563EB),
              faceRight: true,
            ),
          ),
          Positioned(
            right: 8,
            bottom: 0,
            child: _PersonIllustration(
              jacketColor: const Color(0xFF10B981),
              faceRight: false,
            ),
          ),
          Positioned(
            bottom: 30,
            child: Container(
              height: 18,
              width: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF4B183),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE09A6A), width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonIllustration extends StatelessWidget {
  const _PersonIllustration({
    required this.jacketColor,
    required this.faceRight,
  });

  final Color jacketColor;
  final bool faceRight;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(faceRight ? 1.0 : -1.0, 1.0),
      child: SizedBox(
        height: 96,
        width: 82,
        child: Stack(
          children: [
            Positioned(
              left: 30,
              top: 6,
              child: Container(
                height: 30,
                width: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4B183),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Positioned(
              left: 36,
              top: 0,
              child: Container(
                height: 14,
                width: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 36,
              child: Container(
                height: 58,
                width: 54,
                decoration: BoxDecoration(
                  color: jacketColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(18),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 2,
              top: 54,
              child: Container(
                height: 12,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4B183),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniUserAvatar extends StatelessWidget {
  const _MiniUserAvatar({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 2),
      height: 26,
      width: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shieldPaint = Paint()
      ..color = _dealPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.08)
      ..lineTo(size.width * 0.84, size.height * 0.22)
      ..lineTo(size.width * 0.78, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.8,
        size.width * 0.5,
        size.height * 0.92,
      )
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.8,
        size.width * 0.22,
        size.height * 0.58,
      )
      ..lineTo(size.width * 0.16, size.height * 0.22)
      ..close();
    canvas.drawPath(path, shieldPaint);

    final handPaint = Paint()
      ..color = _dealPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.52),
      Offset(size.width * 0.47, size.height * 0.64),
      handPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.52),
      Offset(size.width * 0.53, size.height * 0.64),
      handPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.62),
      Offset(size.width * 0.55, size.height * 0.62),
      handPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SecureDealHomeStep extends StatelessWidget {
  const _SecureDealHomeStep({
    required this.onCreateDeal,
    required this.onOpenDeal,
    required this.onOpenChat,
    required this.onOpenWallet,
    required this.onOpenConnect,
    required this.onOpenPosts,
    required this.onOpenNotifications,
    required this.onOpenVip,
    required this.onOpenAdmin,
  });

  final VoidCallback onCreateDeal;
  final VoidCallback onOpenDeal;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenWallet;
  final VoidCallback onOpenConnect;
  final VoidCallback onOpenPosts;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenVip;
  final VoidCallback onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, Rahat',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Good Morning!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onOpenNotifications,
              icon: const Icon(Icons.notifications_none_rounded),
              color: AppColors.textPrimary,
            ),
            IconButton(
              onPressed: onOpenAdmin,
              icon: const Icon(Icons.admin_panel_settings_outlined),
              color: AppColors.textPrimary,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF2E1BC9)],
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
                    onPressed: onOpenWallet,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.visibility_outlined,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '৳ 24,560.00',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onOpenWallet,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    backgroundColor: Colors.white,
                    foregroundColor: _dealPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Money'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _DealHomeAction(
                icon: Icons.edit_note_rounded,
                label: 'Create Deal',
                onTap: onCreateDeal,
              ),
            ),
            Expanded(
              child: _DealHomeAction(
                icon: Icons.work_outline_rounded,
                label: 'My Deals',
                onTap: onOpenDeal,
              ),
            ),
            Expanded(
              child: _DealHomeAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Messages',
                badge: true,
                onTap: onOpenChat,
              ),
            ),
            Expanded(
              child: _DealHomeAction(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Wallet',
                onTap: onOpenWallet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DealHomeAction(
                icon: Icons.workspace_premium_outlined,
                label: 'VIP',
                onTap: onOpenVip,
              ),
            ),
            Expanded(
              child: _DealHomeAction(
                icon: Icons.connect_without_contact_rounded,
                label: 'Connect',
                onTap: onOpenConnect,
              ),
            ),
            Expanded(
              child: _DealHomeAction(
                icon: Icons.post_add_rounded,
                label: 'Posts',
                onTap: onOpenPosts,
              ),
            ),
            Expanded(
              child: _DealHomeAction(
                icon: Icons.verified_rounded,
                label: 'Verified',
                onTap: onOpenVip,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _DealCompletionOverview(),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Ongoing Deals',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(onPressed: onOpenDeal, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 8),
        _DealSummaryCard(
          title: 'Logo Design for Business',
          seller: 'with Jannatul Islam',
          amount: '৳ 5,000',
          progress: 0.6,
          status: 'In Progress',
          statusColor: _dealPrimary,
          barColor: _dealPrimary,
          onTap: onOpenDeal,
        ),
        const SizedBox(height: 12),
        _DealSummaryCard(
          title: 'Facebook Cover Design',
          seller: 'with Ahmed Khan',
          amount: '৳ 3,500',
          progress: 0.34,
          status: 'Pending Approval',
          statusColor: AppColors.warning,
          barColor: AppColors.accent,
          onTap: onOpenDeal,
        ),
      ],
    );
  }
}

class _SecureDealHomeNavBar extends StatelessWidget {
  const _SecureDealHomeNavBar();

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _dealBorder)),
        boxShadow: _dealShadow,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            children: [
              const Expanded(
                child: _SecureDealNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: true,
                ),
              ),
              Expanded(
                child: _SecureDealNavItem(
                  icon: Icons.work_outline_rounded,
                  label: 'Deals',
                  onTap: () =>
                      _openPage(context, const SecureDealDetailsPage()),
                ),
              ),
              const _SecureDealNavCreateButton(),
              Expanded(
                child: _SecureDealNavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  showBadge: true,
                  onTap: () => _openPage(context, const SecureDealChatPage()),
                ),
              ),
              Expanded(
                child: _SecureDealNavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: () =>
                      _openPage(context, const SecureDealProfilePage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecureDealNavItem extends StatelessWidget {
  const _SecureDealNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.showBadge = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool showBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _dealPrimary : AppColors.textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 23),
              if (showBadge)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    height: 9,
                    width: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecureDealNavCreateButton extends StatelessWidget {
  const _SecureDealNavCreateButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      child: Center(
        child: Material(
          color: _dealPrimary,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SecureDealCreateDealPage(),
                ),
              );
            },
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x334338CA),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DealHomeAction extends StatelessWidget {
  const _DealHomeAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: _dealPrimarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: _dealPrimary),
                  ),
                  if (badge)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        height: 17,
                        width: 17,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
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

class _DealCompletionOverview extends StatelessWidget {
  const _DealCompletionOverview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _dealBorder),
        boxShadow: _dealShadow,
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.task_alt_rounded, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completed deals',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '18 deals completed successfully',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const _StatusChip(
            label: '4.9 rating',
            backgroundColor: Color(0xFFFFF7ED),
            textColor: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _DealSummaryCard extends StatelessWidget {
  const _DealSummaryCard({
    required this.title,
    required this.seller,
    required this.amount,
    required this.progress,
    required this.status,
    required this.statusColor,
    required this.barColor,
    required this.onTap,
  });

  final String title;
  final String seller;
  final String amount;
  final double progress;
  final String status;
  final Color statusColor;
  final Color barColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _dealBorder),
            boxShadow: _dealShadow,
          ),
          child: Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: Color(0xFFD99A2B),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
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
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Text(
                          amount,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(seller, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: progress,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${(progress * 100).round()}% Completed',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(fontSize: 11),
                        ),
                        const Spacer(),
                        _StatusChip(
                          label: status,
                          backgroundColor: statusColor.withValues(alpha: 0.1),
                          textColor: statusColor,
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

class _CreateDealStep extends StatelessWidget {
  const _CreateDealStep({
    required this.projectTitleController,
    required this.descriptionController,
    required this.budgetController,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.deliveryTimes,
    required this.selectedDeliveryTime,
    required this.onDeliveryTimeChanged,
  });

  final TextEditingController projectTitleController;
  final TextEditingController descriptionController;
  final TextEditingController budgetController;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final List<String> deliveryTimes;
  final String? selectedDeliveryTime;
  final ValueChanged<String?> onDeliveryTimeChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
      children: [
        _DealFieldLabel(
          text: context.tr(bn: 'প্রজেক্ট টাইটেল', en: 'Project Title'),
        ),
        TextField(
          controller: projectTitleController,
          textInputAction: TextInputAction.next,
          decoration: _dealInputDecoration(
            context,
            context.tr(
              bn: 'যেমন: বাসা ভাড়ার অ্যাডভান্স',
              en: 'e.g. Logo design for my Business',
            ),
          ),
        ),
        const SizedBox(height: 16),
        _DealFieldLabel(
          text: context.tr(bn: 'ক্যাটাগরি', en: 'Category'),
        ),
        DropdownButtonFormField<String>(
          value: selectedCategory,
          hint: Text(
            context.tr(bn: 'ক্যাটাগরি নির্বাচন করুন', en: 'Select Category'),
          ),
          items: categories
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(growable: false),
          onChanged: onCategoryChanged,
          decoration: _dealInputDecoration(
            context,
            context.tr(bn: 'ক্যাটাগরি নির্বাচন করুন', en: 'Select Category'),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        const SizedBox(height: 16),
        _DealFieldLabel(
          text: context.tr(bn: 'বিবরণ', en: 'Description'),
        ),
        TextField(
          controller: descriptionController,
          maxLines: 4,
          maxLength: 1000,
          decoration: _dealInputDecoration(
            context,
            context.tr(
              bn: 'ডিলের বিস্তারিত লিখুন...',
              en: 'Describe your project in detail...',
            ),
          ),
        ),
        const SizedBox(height: 10),
        _DealFieldLabel(
          text: context.tr(bn: 'বাজেট', en: 'Budget (৳)'),
        ),
        TextField(
          controller: budgetController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: _dealInputDecoration(
            context,
            context.tr(bn: 'পরিমাণ লিখুন', en: 'Enter amount'),
          ),
        ),
        const SizedBox(height: 16),
        _DealFieldLabel(
          text: context.tr(bn: 'ডেলিভারি সময়', en: 'Delivery Time'),
        ),
        DropdownButtonFormField<String>(
          value: selectedDeliveryTime,
          hint: Text(
            context.tr(
              bn: 'ডেলিভারি সময় নির্বাচন করুন',
              en: 'Select delivery time',
            ),
          ),
          items: deliveryTimes
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(growable: false),
          onChanged: onDeliveryTimeChanged,
          decoration: _dealInputDecoration(
            context,
            context.tr(
              bn: 'ডেলিভারি সময় নির্বাচন করুন',
              en: 'Select delivery time',
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        const SizedBox(height: 18),
        _DealFieldLabel(
          text: context.tr(
            bn: 'অ্যাটাচমেন্ট যোগ করুন (ঐচ্ছিক)',
            en: 'Add Attachment (Optional)',
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr(
                      bn: 'ফাইল অ্যাটাচমেন্ট এখন ডেমো হিসেবে দেখানো হচ্ছে।',
                      en: 'File attachment is shown as a demo action for now.',
                    ),
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: _dealBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(118, 52),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(context.tr(bn: 'ফাইল যোগ করুন', en: 'Add File')),
          ),
        ),
      ],
    );
  }
}

class _ConfirmDealStep extends StatelessWidget {
  const _ConfirmDealStep({
    required this.projectTitle,
    required this.category,
    required this.description,
    required this.deliveryTime,
    required this.budget,
    required this.serviceFee,
    required this.totalPayable,
  });

  final String projectTitle;
  final String category;
  final String description;
  final String deliveryTime;
  final int budget;
  final int serviceFee;
  final int totalPayable;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
      children: [
        _DealReadOnlyBlock(
          label: context.tr(bn: 'প্রজেক্ট টাইটেল', en: 'Project Title'),
          value: projectTitle,
        ),
        _DealReadOnlyBlock(
          label: context.tr(bn: 'ক্যাটাগরি', en: 'Category'),
          value: category,
        ),
        _DealReadOnlyBlock(
          label: context.tr(bn: 'বিবরণ', en: 'Description'),
          value: description,
        ),
        _DealReadOnlyBlock(
          label: context.tr(bn: 'বাজেট', en: 'Budget'),
          value: context.money(budget),
        ),
        _DealReadOnlyBlock(
          label: context.tr(bn: 'ডেলিভারি সময়', en: 'Delivery Time'),
          value: deliveryTime,
        ),
        const SizedBox(height: 4),
        const Divider(height: 1, color: _dealBorder),
        const SizedBox(height: 18),
        _AmountRow(
          label: context.tr(bn: 'সার্ভিস ফি (৫%)', en: 'Service Fee (5%)'),
          amount: context.money(serviceFee),
        ),
        const SizedBox(height: 14),
        _AmountRow(
          label: context.tr(bn: 'মোট পেমেন্ট', en: 'Total Payable'),
          amount: context.money(totalPayable),
          isTotal: true,
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr(
                    bn: 'টাকা এসক্রোতে নিরাপদ থাকবে এবং ডেলিভারি অনুমোদনের পর রিলিজ হবে।',
                    en: 'Amount will be held in escrow and released when you approve the delivery.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentStep extends StatelessWidget {
  const _PaymentStep({
    required this.totalPayable,
    required this.paymentMethods,
    required this.selectedPaymentIndex,
    required this.onPaymentSelected,
  });

  final int totalPayable;
  final List<_PaymentMethodData> paymentMethods;
  final int selectedPaymentIndex;
  final ValueChanged<int> onPaymentSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _dealBorder),
            boxShadow: _dealShadow,
          ),
          child: Column(
            children: [
              Text(
                context.tr(bn: 'মোট পেমেন্ট', en: 'Total Payable'),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                context.money(totalPayable),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 34,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.tr(
            bn: 'পেমেন্ট পদ্ধতি নির্বাচন করুন',
            en: 'Choose Payment Method',
          ),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        ...paymentMethods.indexed.map((entry) {
          final index = entry.$1;
          final method = entry.$2;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PaymentMethodTile(
              method: method,
              isSelected: index == selectedPaymentIndex,
              onTap: () => onPaymentSelected(index),
            ),
          );
        }),
      ],
    );
  }
}

class _PaymentSuccessStep extends StatelessWidget {
  const _PaymentSuccessStep({
    required this.onViewDetails,
    required this.onGoHome,
  });

  final VoidCallback onViewDetails;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 42, 18, 24),
      children: [
        const _SuccessBadge(),
        const SizedBox(height: 28),
        Text(
          context.tr(bn: 'পেমেন্ট সফল!', en: 'Payment Successful!'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr(
            bn: 'আপনার পেমেন্ট এসক্রোতে নিরাপদে রাখা হয়েছে।',
            en: 'Your payment has been held securely in escrow.',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 58),
        Container(
          padding: const EdgeInsets.all(18),
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
                context.tr(bn: 'ডিল আইডি', en: 'Deal ID'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '#DEAL-2024-0001',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: onViewDetails,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: _dealPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            context.tr(bn: 'ডিল ডিটেইলস দেখুন', en: 'View Deal Details'),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onGoHome,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: _dealPrimary,
            side: const BorderSide(color: Color(0xFFC7D2FE)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(context.tr(bn: 'হোমে যান', en: 'Go to Home')),
        ),
      ],
    );
  }
}

class _DealDetailsStep extends StatelessWidget {
  const _DealDetailsStep({required this.projectTitle, required this.budget});

  final String projectTitle;
  final int budget;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Container(
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
                  _StatusChip(
                    label: context.tr(bn: 'চলমান', en: 'In Progress'),
                    backgroundColor: _dealPrimarySoft,
                    textColor: _dealPrimary,
                  ),
                  const Spacer(),
                  _StatusChip(
                    label: context.tr(bn: '৬০%', en: '60%'),
                    backgroundColor: _dealPrimarySoft,
                    textColor: _dealPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                projectTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.money(budget),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: _dealBorder),
              const SizedBox(height: 16),
              const _DealInfoPillRow(
                icon: Icons.timer_outlined,
                label: 'Delivery time',
                value: '3 days left',
              ),
              const SizedBox(height: 10),
              const _DealInfoPillRow(
                icon: Icons.payments_outlined,
                label: 'Cash out',
                value: 'Both parties after approval',
              ),
              const SizedBox(height: 16),
              const _DealPersonRow(
                role: 'Buyer',
                name: 'Rahat Hossain',
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(height: 14),
              const _DealPersonRow(
                role: 'Seller',
                name: 'Jannatul Islam',
                color: Color(0xFF0EA5E9),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    context.tr(bn: 'প্রগ্রেস', en: 'Progress'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    context.tr(bn: '৬০%', en: '60%'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(
                  minHeight: 7,
                  value: 0.6,
                  backgroundColor: Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(_dealPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _dealBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _DealMenuTile(
                icon: Icons.timeline_rounded,
                label: context.tr(bn: 'ডিল টাইমলাইন', en: 'Deal Timeline'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr(
                          bn: 'ডিল টাইমলাইন এখন ডেমো হিসেবে দেখানো হচ্ছে।',
                          en: 'Deal timeline is shown as a demo action for now.',
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: _dealBorder),
              _DealMenuTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: context.tr(bn: 'চ্যাট', en: 'Chat'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SecureDealChatPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: _dealBorder),
              _DealMenuTile(
                icon: Icons.insert_drive_file_outlined,
                label: context.tr(
                  bn: 'ফাইল ও ডেলিভারি',
                  en: 'Files & Delivery',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SecureDealDeliveryUploadPage(
                        projectTitle: projectTitle,
                        budget: budget,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: _dealBorder),
              _DealMenuTile(
                icon: Icons.gpp_maybe_outlined,
                label: context.tr(bn: 'ডিসপিউট', en: 'Dispute'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SecureDealDisputeCenterPage(
                        projectTitle: projectTitle,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: _dealBorder),
              _DealMenuTile(
                icon: Icons.payments_outlined,
                label: 'Cash Out Options',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SecureDealWalletPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: _dealBorder),
              _DealMenuTile(
                icon: Icons.cancel_outlined,
                label: context.tr(bn: 'ডিল বাতিল করুন', en: 'Cancel Deal'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr(
                          bn: 'ডিল বাতিল করার অপশন এখন ডেমো হিসেবে দেখানো হচ্ছে।',
                          en: 'Cancel deal is shown as a demo action for now.',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DealChatPage extends StatelessWidget {
  const _DealChatPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        toolbarHeight: 68,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Ahmed Khan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 7,
                  width: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  context.tr(bn: 'অনলাইন', en: 'Online'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 10,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                children: [
                  _ChatBubble(
                    message: context.tr(
                      bn: 'হাই, আমি আপনার প্রজেক্টে কাজ শুরু করব।',
                      en: 'Hi, I will start working on your project.',
                    ),
                    time: '10:30 AM',
                  ),
                  const SizedBox(height: 12),
                  _ChatBubble(
                    message: context.tr(
                      bn: 'ঠিক আছে, ধন্যবাদ!',
                      en: 'Okay, thank you!',
                    ),
                    time: '10:31 AM',
                    isMine: true,
                  ),
                  const SizedBox(height: 18),
                  _ChatBubble(
                    message: context.tr(
                      bn: 'এখানে প্রথম কনসেপ্ট দিলাম।',
                      en: 'Here is the first concept.',
                    ),
                    time: '10:45 AM',
                    attachment: const _ChatAttachmentCard(),
                  ),
                  const SizedBox(height: 12),
                  _ChatBubble(
                    message: context.tr(
                      bn: 'ভালো লাগছে! চালিয়ে যান।',
                      en: 'Looks great! Please continue.',
                    ),
                    time: '10:46 AM',
                    isMine: true,
                  ),
                ],
              ),
            ),
            const SafeArea(top: false, child: _ChatComposer()),
          ],
        ),
      ),
    );
  }
}

class _DeliveryUploadPage extends StatelessWidget {
  const _DeliveryUploadPage({
    this.dealId,
    required this.projectTitle,
    required this.budget,
  });

  final String? dealId;
  final String projectTitle;
  final int budget;

  @override
  Widget build(BuildContext context) {
    return _DealSubPageScaffold(
      title: context.tr(bn: 'ডেলিভারি আপলোড', en: 'Delivery Upload'),
      bottomAction: FilledButton(
        onPressed: () async {
          if (dealId != null) {
            final vm = context.read<SecureDealViewModel>();
            // Note: proofUrl and note would typically come from user input fields.
            final success = await vm.deliverDeal(
              dealId!,
              'https://example.com/proof.pdf',
              'Work finished.',
            );
            if (success && context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SecureDealReviewApprovePage(
                    dealId: dealId,
                    projectTitle: projectTitle,
                    budget: budget,
                  ),
                ),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to submit delivery.')),
              );
            }
          }
        },
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: _dealPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          context.tr(bn: 'ডেলিভারি সাবমিট করুন', en: 'Submit Delivery'),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        children: [
          const _UploadDropZone(),
          const SizedBox(height: 24),
          Text(
            context.tr(bn: 'ফাইল (১)', en: 'Files (1)'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const _UploadedFileTile(),
          const SizedBox(height: 22),
          _DealFieldLabel(
            text: context.tr(
              bn: 'মেসেজ যোগ করুন (ঐচ্ছিক)',
              en: 'Add Message (Optional)',
            ),
          ),
          TextField(
            maxLines: 3,
            decoration: _dealInputDecoration(
              context,
              context.tr(bn: 'একটি মেসেজ লিখুন...', en: 'Write a message...'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewApprovePage extends StatelessWidget {
  const _ReviewApprovePage({
    this.dealId,
    required this.projectTitle,
    required this.budget,
  });

  final String? dealId;
  final String projectTitle;
  final int budget;

  @override
  Widget build(BuildContext context) {
    return _DealSubPageScaffold(
      title: context.tr(bn: 'রিভিউ ও অ্যাপ্রুভ', en: 'Review & Approve'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Text(
            context.tr(bn: 'ডেলিভারড কাজ', en: 'Delivered Work'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const _DeliveredWorkPreview(),
          const SizedBox(height: 20),
          Text(
            context.tr(bn: 'সেলারের মেসেজ', en: 'Message from Seller'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              bn: 'ফাইনাল লোগোটি দেখুন। আশা করি ভালো লাগবে।',
              en: 'Please check the final logo. Hope you like it.',
            ),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SecureDealPaymentReleasedPage(amount: budget),
                ),
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              context.tr(
                bn: 'অ্যাপ্রুভ ও পেমেন্ট রিলিজ',
                en: 'Approve & Release Payment',
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr(
                      bn: 'রিভিশন রিকোয়েস্ট পাঠানো হয়েছে।',
                      en: 'Revision request has been sent.',
                    ),
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: Color(0xFFFED7AA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.tr(bn: 'রিভিশন চাইুন', en: 'Request Revision')),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      SecureDealDisputeCenterPage(projectTitle: projectTitle),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: Color(0xFFFECACA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              context.tr(bn: 'ডেলিভারি রিজেক্ট', en: 'Reject Delivery'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentReleasedPage extends StatelessWidget {
  const _PaymentReleasedPage({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 58, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ReleaseSuccessBadge(),
              const SizedBox(height: 30),
              Text(
                context.tr(bn: 'পেমেন্ট রিলিজ হয়েছে!', en: 'Payment Released!'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr(
                  bn: '${context.money(amount)} জান্নাতুল ইসলামের কাছে রিলিজ হয়েছে।',
                  en: '${context.money(amount)} has been released to Jannatul Islam.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 56),
              Text(
                context.tr(
                  bn: 'Secure Deal ব্যবহার করার জন্য ধন্যবাদ!',
                  en: 'Thank you for using Secure Deal!',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr(
                          bn: 'রেটিং ফিচার এখন ডেমো হিসেবে দেখানো হচ্ছে।',
                          en: 'Rating is shown as a demo action for now.',
                        ),
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: _dealPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.tr(
                    bn: 'অভিজ্ঞতা রেট করুন',
                    en: 'Rate Your Experience',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const TenantSecureDealScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: _dealPrimary,
                  side: const BorderSide(color: Color(0xFFC7D2FE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(context.tr(bn: 'হোমে যান', en: 'Go to Home')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisputeCenterPage extends StatelessWidget {
  const _DisputeCenterPage({this.dealId, required this.projectTitle});

  final String? dealId;
  final String projectTitle;

  @override
  Widget build(BuildContext context) {
    return _DealSubPageScaffold(
      title: context.tr(bn: 'ডিসপিউট সেন্টার', en: 'Dispute Center'),
      bottomAction: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: _dealBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(context.tr(bn: 'ডিলে ফিরে যান', en: 'Back to Deals')),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        children: [
          _DisputeInfoRow(
            label: context.tr(bn: 'ডিল আইডি', en: 'Deal ID'),
            value: '#DEAL-2024-0001',
          ),
          _DisputeInfoRow(
            label: context.tr(bn: 'প্রজেক্ট', en: 'Project'),
            value: projectTitle,
          ),
          _DisputeInfoRow(
            label: context.tr(bn: 'স্ট্যাটাস', en: 'Status'),
            valueWidget: _StatusChip(
              label: context.tr(bn: 'ডিসপিউটেড', en: 'DISPUTED'),
              backgroundColor: const Color(0xFFFFE4E6),
              textColor: AppColors.danger,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr(bn: 'কারণ', en: 'Reason'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              bn: 'কাজটি প্রত্যাশা অনুযায়ী হয়নি।',
              en: 'The work is not as expected.',
            ),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            context.tr(bn: 'প্রমাণ', en: 'Evidence'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _EvidenceThumb(icon: Icons.apartment_rounded),
              SizedBox(width: 8),
              _EvidenceThumb(icon: Icons.person_rounded),
              SizedBox(width: 8),
              _MoreEvidenceThumb(),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            context.tr(bn: 'মেসেজ', en: 'Messages'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _ConversationTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SecureDealChatPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            context.tr(bn: 'আমাদের সিদ্ধান্ত', en: 'Our Decision'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              bn: 'আমরা কেসটি রিভিউ করছি। আপনাকে দ্রুত জানানো হবে।',
              en: 'We are reviewing the case. You will be notified soon.',
            ),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecureDealAdminDashboardPage extends StatelessWidget {
  const _SecureDealAdminDashboardPage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return const _SecureDealAdminDesktopDashboard();
        }

        return const _SecureDealAdminMobileDashboard();
      },
    );
  }
}

class _SecureDealAdminMobileDashboard extends StatelessWidget {
  const _SecureDealAdminMobileDashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        surfaceTintColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('SecureDeal Admin'),
        actions: const [_AdminAvatar()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: const [
          _AdminMetricsWrap(),
          SizedBox(height: 16),
          _AdminDealsOverviewPanel(),
          SizedBox(height: 16),
          _AdminDealsStatusPanel(),
          SizedBox(height: 16),
          _AdminRecentDealsPanel(),
          SizedBox(height: 16),
          _AdminRecentDisputesPanel(),
        ],
      ),
    );
  }
}

class _SecureDealAdminDesktopDashboard extends StatelessWidget {
  const _SecureDealAdminDesktopDashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1224),
      body: SafeArea(
        child: Row(
          children: [
            const _AdminSideNav(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                children: [
                  const _AdminTopBar(),
                  const SizedBox(height: 18),
                  const _AdminMetricsGrid(),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(flex: 2, child: _AdminDealsOverviewPanel()),
                      SizedBox(width: 18),
                      Expanded(child: _AdminDealsStatusPanel()),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(flex: 2, child: _AdminRecentDealsPanel()),
                      SizedBox(width: 18),
                      Expanded(child: _AdminRecentDisputesPanel()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 14),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Color(0xFFFFE0B2),
        child: Text('A'),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.white,
          tooltip: 'Back',
        ),
        const SizedBox(width: 6),
        Text(
          'SecureDeal',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 14),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu_rounded),
          color: Colors.white,
        ),
        const Spacer(),
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFFFE0B2),
          child: Text('A'),
        ),
        const SizedBox(width: 10),
        Text(
          'Admin',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
      ],
    );
  }
}

class _AdminSideNav extends StatelessWidget {
  const _AdminSideNav();

  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String, bool)>[
      (Icons.dashboard_rounded, 'Dashboard', true),
      (Icons.group_outlined, 'Users', false),
      (Icons.handshake_outlined, 'Deals', false),
      (Icons.gpp_maybe_outlined, 'Disputes', false),
      (Icons.receipt_long_outlined, 'Transactions', false),
      (Icons.reviews_outlined, 'Reviews', false),
      (Icons.bar_chart_rounded, 'Reports', false),
      (Icons.settings_outlined, 'Settings', false),
      (Icons.support_agent_rounded, 'Support', false),
      (Icons.logout_rounded, 'Logout', false),
    ];

    return Container(
      width: 176,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'SecureDeal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...items.map(
            (item) =>
                _AdminNavItem(icon: item.$1, label: item.$2, selected: item.$3),
          ),
        ],
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: selected ? _dealPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMetricsWrap extends StatelessWidget {
  const _AdminMetricsWrap();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: const [
        _AdminMetricCard(
          title: 'Total Users',
          value: '12,549',
          trend: '+12.5%',
        ),
        _AdminMetricCard(title: 'Total Deals', value: '3,245', trend: '+8.2%'),
        _AdminMetricCard(
          title: 'Total Amount',
          value: '৳ 25,430.00',
          trend: '+15.3%',
        ),
        _AdminMetricCard(
          title: 'Total Revenue',
          value: '৳ 1,271,500',
          trend: '+10.5%',
        ),
      ],
    );
  }
}

class _AdminMetricsGrid extends StatelessWidget {
  const _AdminMetricsGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _AdminMetricCard(
            title: 'Total Users',
            value: '12,549',
            trend: '+12.5%',
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _AdminMetricCard(
            title: 'Total Deals',
            value: '3,245',
            trend: '+8.2%',
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _AdminMetricCard(
            title: 'Total Amount',
            value: '৳ 25,430.00',
            trend: '+15.3%',
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _AdminMetricCard(
            title: 'Total Revenue',
            value: '৳ 1,271,500',
            trend: '+10.5%',
          ),
        ),
      ],
    );
  }
}

class _AdminDealsOverviewPanel extends StatelessWidget {
  const _AdminDealsOverviewPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _adminPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deals Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 188,
            child: CustomPaint(
              painter: _AdminLineChartPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDealsStatusPanel extends StatelessWidget {
  const _AdminDealsStatusPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _adminPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deals by Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                height: 136,
                width: 136,
                child: CustomPaint(
                  painter: _AdminDonutPainter(),
                  child: const Center(
                    child: Text(
                      '100%',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  children: [
                    _AdminLegend(
                      color: Color(0xFF2563EB),
                      text: '60% Completed',
                    ),
                    _AdminLegend(color: Color(0xFF10B981), text: '20% Ongoing'),
                    _AdminLegend(
                      color: Color(0xFFF59E0B),
                      text: '10% Disputed',
                    ),
                    _AdminLegend(
                      color: Color(0xFFEF4444),
                      text: '10% Cancelled',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminRecentDealsPanel extends StatelessWidget {
  const _AdminRecentDealsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _adminPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _AdminPanelTitle('Recent Deals'),
          SizedBox(height: 10),
          _AdminDealRow(
            id: '#DEAL-0001',
            project: 'Logo Design',
            amount: '৳ 5,000',
            status: 'Completed',
          ),
          _AdminDealRow(
            id: '#DEAL-0002',
            project: 'Website Design',
            amount: '৳ 8,000',
            status: 'Ongoing',
          ),
          _AdminDealRow(
            id: '#DEAL-0003',
            project: 'SEO Service',
            amount: '৳ 12,000',
            status: 'Disputed',
          ),
          _AdminDealRow(
            id: '#DEAL-0004',
            project: 'Mobile App Design',
            amount: '৳ 15,000',
            status: 'Completed',
          ),
        ],
      ),
    );
  }
}

class _AdminRecentDisputesPanel extends StatelessWidget {
  const _AdminRecentDisputesPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _adminPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _AdminPanelTitle('Recent Disputes'),
          SizedBox(height: 12),
          _AdminDisputeTile(id: '#DISC-0001', issue: 'Logo not as described'),
          _AdminDisputeTile(id: '#DISC-0002', issue: 'Delivery delay'),
          _AdminDisputeTile(id: '#DISC-0003', issue: 'Work not delivered'),
        ],
      ),
    );
  }
}

class _AdminPanelTitle extends StatelessWidget {
  const _AdminPanelTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _AdminDisputeTile extends StatelessWidget {
  const _AdminDisputeTile({required this.id, required this.issue});

  final String id;
  final String issue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _dealBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _dealPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  issue,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _dealPrimary,
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              minimumSize: const Size(58, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.title,
    required this.value,
    required this.trend,
  });

  final String title;
  final String value;
  final String trend;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 158),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _adminPanelDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              trend,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminLegend extends StatelessWidget {
  const _AdminLegend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            height: 9,
            width: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

class _AdminDealRow extends StatelessWidget {
  const _AdminDealRow({
    required this.id,
    required this.project,
    required this.amount,
    required this.status,
  });

  final String id;
  final String project;
  final String amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'Disputed'
        ? AppColors.danger
        : status == 'Ongoing'
        ? _dealPrimary
        : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _dealBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              id,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _dealPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              project,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(amount, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 10),
          _StatusChip(
            label: status,
            backgroundColor: color.withValues(alpha: 0.1),
            textColor: color,
          ),
        ],
      ),
    );
  }
}

class _AdminLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    void drawLine(List<double> values, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final x = size.width * i / (values.length - 1);
        final y = size.height - (size.height * values[i]);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    drawLine(const [0.25, 0.48, 0.42, 0.61, 0.53, 0.66, 0.78], _dealPrimary);
    drawLine(const [
      0.18,
      0.31,
      0.29,
      0.45,
      0.38,
      0.52,
      0.58,
    ], AppColors.success);
    drawLine(const [
      0.12,
      0.21,
      0.18,
      0.28,
      0.25,
      0.34,
      0.39,
    ], AppColors.danger);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AdminDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.18;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    var start = -1.57;
    final segments = <(double, Color)>[
      (0.6, const Color(0xFF2563EB)),
      (0.2, const Color(0xFF10B981)),
      (0.1, const Color(0xFFF59E0B)),
      (0.1, const Color(0xFFEF4444)),
    ];

    for (final segment in segments) {
      paint.color = segment.$2;
      final sweep = segment.$1 * 6.28318;
      canvas.drawArc(rect.deflate(strokeWidth / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

BoxDecoration _adminPanelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: const [
      BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
    ],
  );
}

class _DealSubPageScaffold extends StatelessWidget {
  const _DealSubPageScaffold({
    required this.title,
    required this.child,
    this.bottomAction,
  });

  final String title;
  final Widget child;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        centerTitle: true,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: bottomAction == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: bottomAction,
              ),
            ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.time,
    this.isMine = false,
    this.attachment,
  });

  final String message;
  final String time;
  final bool isMine;
  final Widget? attachment;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? _dealPrimary : const Color(0xFFF2F4F8);
    final textColor = isMine ? Colors.white : AppColors.textPrimary;
    final hasAttachment = attachment != null;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(14, 12, 14, hasAttachment ? 10 : 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMine ? 14 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  if (hasAttachment) ...[
                    const SizedBox(height: 10),
                    attachment!,
                  ],
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              time,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 10,
                color: const Color(0xFF98A2B3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAttachmentCard extends StatelessWidget {
  const _ChatAttachmentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(child: _SmallLogoMark()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'concept_1.jpg',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '2.5 MB',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: TextField(
                decoration: InputDecoration(
                  hintText: context.tr(
                    bn: 'মেসেজ লিখুন...',
                    en: 'Type a message...',
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _dealBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _dealBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _dealPrimary),
                  ),
                  suffixIcon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 46,
            width: 46,
            child: IconButton.filled(
              onPressed: () {},
              style: IconButton.styleFrom(
                backgroundColor: _dealPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadDropZone extends StatelessWidget {
  const _UploadDropZone();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        height: 178,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              color: _dealPrimary,
              size: 42,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(
                bn: 'ফাইল ড্র্যাগ ও ড্রপ করুন\nঅথবা আপলোড করতে ট্যাপ করুন',
                en: 'Drag & Drop files here\nor tap to upload',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadedFileTile extends StatelessWidget {
  const _UploadedFileTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dealBorder),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: _SmallLogoMark()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'logo_final_v1.png',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text('2.4 MB', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _DeliveredWorkPreview extends StatelessWidget {
  const _DeliveredWorkPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _dealShadow,
      ),
      child: const Center(
        child: Text(
          'A',
          style: TextStyle(
            color: Color(0xFFD99A2B),
            fontSize: 92,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _DisputeInfoRow extends StatelessWidget {
  const _DisputeInfoRow({required this.label, this.value, this.valueWidget});

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _dealBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  valueWidget ??
                  Text(
                    value ?? '',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceThumb extends StatelessWidget {
  const _EvidenceThumb({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: 62,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF64748B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}

class _MoreEvidenceThumb extends StatelessWidget {
  const _MoreEvidenceThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '+3',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _dealBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: _dealPrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr(bn: 'কনভারসেশন দেখুন', en: 'View Conversation'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _dealPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallLogoMark extends StatelessWidget {
  const _SmallLogoMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'A',
      style: TextStyle(
        color: Color(0xFFD99A2B),
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8DEE9)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const dashWidth = 7.0;
    const dashSpace = 5.0;
    const radius = 14.0;

    void drawHorizontal(double y) {
      var x = radius;
      while (x < size.width - radius) {
        canvas.drawLine(
          Offset(x, y),
          Offset((x + dashWidth).clamp(0, size.width - radius), y),
          paint,
        );
        x += dashWidth + dashSpace;
      }
    }

    void drawVertical(double x) {
      var y = radius;
      while (y < size.height - radius) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, (y + dashWidth).clamp(0, size.height - radius)),
          paint,
        );
        y += dashWidth + dashSpace;
      }
    }

    drawHorizontal(0);
    drawHorizontal(size.height);
    drawVertical(0);
    drawVertical(size.width);

    canvas.drawArc(
      const Rect.fromLTWH(0, 0, radius * 2, radius * 2),
      3.14,
      1.57,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - radius * 2, 0, radius * 2, radius * 2),
      4.71,
      1.57,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(0, size.height - radius * 2, radius * 2, radius * 2),
      1.57,
      1.57,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width - radius * 2,
        size.height - radius * 2,
        radius * 2,
        radius * 2,
      ),
      0,
      1.57,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DealFieldLabel extends StatelessWidget {
  const _DealFieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DealReadOnlyBlock extends StatelessWidget {
  const _DealReadOnlyBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  final String label;
  final String amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
        Text(
          amount,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final _PaymentMethodData method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? _dealPrimarySoft : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFC7D2FE) : _dealBorder,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: method.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(method.icon, color: method.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  method.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? _dealPrimary : const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReleaseSuccessBadge extends StatelessWidget {
  const _ReleaseSuccessBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 98,
        width: 98,
        decoration: const BoxDecoration(
          color: Color(0xFF059669),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x2A059669),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 58),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 6,
            left: 86,
            child: _ConfettiDot(color: Color(0xFF2563EB)),
          ),
          const Positioned(
            top: 24,
            right: 72,
            child: _ConfettiDot(color: Color(0xFFF97316)),
          ),
          const Positioned(
            bottom: 24,
            left: 70,
            child: _ConfettiDot(color: Color(0xFF16A34A)),
          ),
          const Positioned(
            bottom: 18,
            right: 92,
            child: _ConfettiDot(color: Color(0xFFE11D48)),
          ),
          Container(
            height: 98,
            width: 98,
            decoration: const BoxDecoration(
              color: Color(0xFF059669),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x2A059669),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 58,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiDot extends StatelessWidget {
  const _ConfettiDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.58,
      child: Container(
        height: 8,
        width: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DealPersonRow extends StatelessWidget {
  const _DealPersonRow({
    required this.role,
    required this.name,
    required this.color,
  });

  final String role;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.16),
          child: Text(
            name.characters.first,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
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
                context.demoText(role),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          color: _dealPrimary,
        ),
      ],
    );
  }
}

class _DealInfoPillRow extends StatelessWidget {
  const _DealInfoPillRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dealBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: _dealPrimary, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DealMenuTile extends StatelessWidget {
  const _DealMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textMuted, size: 21),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _dealInputDecoration(BuildContext context, String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF94A3B8)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _dealBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _dealPrimary, width: 1.4),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _dealBorder),
    ),
  );
}

class _PaymentMethodData {
  const _PaymentMethodData({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
