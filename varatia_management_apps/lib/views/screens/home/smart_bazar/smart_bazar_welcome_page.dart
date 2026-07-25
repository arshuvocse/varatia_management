import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_context.dart';
import 'smart_bazar_login_page.dart';
import 'smart_bazar_registration_page.dart';

class SmartBazarWelcomePage extends StatelessWidget {
  const SmartBazarWelcomePage({super.key});

  void _openAuth(BuildContext context, int initialTabIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => initialTabIndex == 0
            ? const SmartBazarLoginPage()
            : const SmartBazarRegistrationPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Beautiful Custom Storefront Artwork
                const Center(child: _SmartBazarStorefrontArtwork()),
                const SizedBox(height: 36),
                // App Name / Title
                Text(
                  context.tr(
                    bn: 'স্মার্ট বাজারে স্বাগতম',
                    en: 'Welcome to Smart Bazar',
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  context.tr(
                    bn: 'আপনার নিত্যপ্রয়োজনীয় পণ্য কেনাকাটা করুন সহজে ও সাশ্রয়ী মূল্যে। সেরা মানের পণ্য সরাসরি আপনার দরজায়!',
                    en: 'Shop your daily essentials easily and at affordable prices. High quality products delivered directly to your doorstep!',
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Login Button
                FilledButton(
                  onPressed: () => _openAuth(context, 0),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFEC4899,
                    ), // Smart Bazar theme color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    context.tr(bn: 'লগইন করুন', en: 'Log In'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Registration Button
                OutlinedButton(
                  onPressed: () => _openAuth(context, 1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEC4899),
                    side: const BorderSide(color: Color(0xFFEC4899), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.tr(
                      bn: 'নতুন অ্যাকাউন্ট তৈরি করুন',
                      en: 'Create New Account',
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // --- BENEFITS SECTION ---
                _buildBenefitsHeader(context),
                const SizedBox(height: 16),
                _buildBenefitsList(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            context.tr(
              bn: 'স্মার্টবাজারের সুবিধাসমূহ',
              en: 'Benefits of Smart Bazar',
            ),
            style: const TextStyle(
              color: Color(0xFF065F46),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const Expanded(child: Divider(indent: 10, color: Color(0xFFE2E8F0))),
      ],
    );
  }

  Widget _buildBenefitsList(BuildContext context) {
    final benefits = [
      _BenefitItemData(
        icon: Icons.monetization_on_outlined,
        label: context.tr(bn: 'ইনস্ট্যান্ট ক্যাশব্যাক', en: 'Instant Cashback'),
      ),
      _BenefitItemData(
        icon: Icons.verified_outlined,
        label: context.tr(
          bn: 'স্বচ্ছ ও নির্ভরযোগ্য লেনদেন',
          en: 'Safe Transactions',
        ),
      ),
      _BenefitItemData(
        icon: Icons.trending_up_rounded,
        label: context.tr(
          bn: 'দোকানের বিক্রি বৃদ্ধিতে সহায়তা',
          en: 'Boost Shop Sales',
        ),
      ),
      _BenefitItemData(
        icon: Icons.favorite_outline_rounded,
        label: context.tr(
          bn: 'কাস্টমার লয়্যালটি বাড়ায়',
          en: 'Customer Loyalty',
        ),
      ),
      _BenefitItemData(
        icon: Icons.article_outlined,
        label: context.tr(bn: 'সহজ হিসাব ও রিপোর্ট', en: 'Easy Reports'),
      ),
      _BenefitItemData(
        icon: Icons.security_rounded,
        label: context.tr(
          bn: 'সর্বোচ্চ নিরাপত্তা ও তথ্য সুরক্ষা',
          en: 'Secure Data',
        ),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: benefits.map((item) {
          return Container(
            width: 140,
            height: 100,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: const Color(0xFF10B981),
                  ),
                ),
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BenefitItemData {
  final IconData icon;
  final String label;
  _BenefitItemData({required this.icon, required this.label});
}

class _SmartBazarStorefrontArtwork extends StatelessWidget {
  const _SmartBazarStorefrontArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 180,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background Glow/Circle
          Positioned(
            top: 10,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE7F3), // Light pink glow
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFCE7F3).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          // Store Main building body
          Positioned(
            bottom: 25,
            child: Container(
              width: 150,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: Border.all(color: const Color(0xFFF5D0E3), width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          // Door
          Positioned(
            bottom: 25,
            child: Container(
              width: 44,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F8),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                border: Border.all(color: const Color(0xFFEC4899), width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    right: 6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEC4899),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Window Left
          Positioned(
            bottom: 45,
            left: 50,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF0EA5E9), width: 1.5),
              ),
            ),
          ),
          // Window Right
          Positioned(
            bottom: 45,
            right: 50,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF0EA5E9), width: 1.5),
              ),
            ),
          ),
          // Awning (Store Roof stripes)
          Positioned(
            bottom: 105,
            child: Container(
              width: 170,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: List.generate(
                    7,
                    (index) => Expanded(
                      child: Container(
                        color: index % 2 == 0
                            ? const Color(0xFFEC4899)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Hanging Sign
          Positioned(
            bottom: 85,
            left: 36,
            child: RotationTransition(
              turns: const AlwaysStoppedAnimation(-5 / 360),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'OPEN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Ground Floor Line
          Positioned(
            bottom: 15,
            child: Container(
              width: 190,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          // Decorative Shopping Bag left
          Positioned(
            bottom: 25,
            left: 20,
            child: Container(
              width: 18,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
          // Decorative Shopping Bag right
          Positioned(
            bottom: 25,
            right: 20,
            child: Container(
              width: 20,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
