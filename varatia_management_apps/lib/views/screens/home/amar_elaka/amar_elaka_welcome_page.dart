import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_context.dart';
import 'amar_elaka_auth_page.dart';

const _amarElakaWelcomeShadow = <BoxShadow>[
  BoxShadow(color: Color(0x120F172A), blurRadius: 18, offset: Offset(0, 8)),
  BoxShadow(color: Color(0x080F172A), blurRadius: 6, offset: Offset(0, 2)),
];

class AmarElakaWelcomePage extends StatelessWidget {
  const AmarElakaWelcomePage({super.key});

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const AmarElakaAuthPage(initialMode: AmarElakaAuthMode.login),
      ),
    );
  }

  void _openSignUp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const AmarElakaAuthPage(initialMode: AmarElakaAuthMode.register),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        surfaceTintColor: const Color(0xFFF7F8FC),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              children: [
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    height: 74,
                    width: 74,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_city_rounded,
                      color: Color(0xFF0EA5E9),
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  context.tr(bn: 'আমার এলাকা', en: 'Amar eLaka'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr(
                    bn: 'এলাকার তথ্য, পোস্ট এবং জরুরি আপডেট দেখতে লগইন বা সাইন আপ করুন।',
                    en: 'Login or sign up to view area info, posts, and urgent updates.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 34),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8ECF3)),
                    boxShadow: _amarElakaWelcomeShadow,
                  ),
                  child: Column(
                    children: [
                      _AmarElakaWelcomeFeature(
                        icon: Icons.maps_home_work_rounded,
                        title: context.tr(
                          bn: 'লোকাল আপডেট',
                          en: 'Local updates',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AmarElakaWelcomeFeature(
                        icon: Icons.forum_rounded,
                        title: context.tr(bn: 'এলাকার পোস্ট', en: 'Area posts'),
                      ),
                      const SizedBox(height: 12),
                      _AmarElakaWelcomeFeature(
                        icon: Icons.support_agent_rounded,
                        title: context.tr(
                          bn: 'জরুরি সহায়তা',
                          en: 'Emergency support',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => _openLogin(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(context.tr(bn: 'লগইন', en: 'Login')),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _openSignUp(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(context.tr(bn: 'সাইন আপ', en: 'Sign Up')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmarElakaWelcomeFeature extends StatelessWidget {
  const _AmarElakaWelcomeFeature({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0EA5E9), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
