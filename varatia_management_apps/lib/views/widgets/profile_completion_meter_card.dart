import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_context.dart';
import '../../data/models/tutor_bdjobs_profile.dart';
import '../../data/services/tutor_profile_storage_service.dart';
import '../screens/tutor_profile_form_screen.dart';

class ProfileCompletionMeterCard extends StatefulWidget {
  const ProfileCompletionMeterCard({
    super.key,
    this.compact = false,
    this.onTap,
  });

  final bool compact;
  final VoidCallback? onTap;

  @override
  State<ProfileCompletionMeterCard> createState() =>
      _ProfileCompletionMeterCardState();
}

class _ProfileCompletionMeterCardState
    extends State<ProfileCompletionMeterCard> {
  final TutorProfileStorageService _storageService =
      TutorProfileStorageService();

  @override
  void initState() {
    super.initState();
    _storageService.loadProfile();
  }

  void _openForm(BuildContext context) {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TutorProfileFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TutorBdjobsProfile?>(
      valueListenable: _storageService.profileNotifier,
      builder: (context, profile, _) {
        final currentProfile = profile ?? const TutorBdjobsProfile();
        final score = currentProfile.completionScore;
        final ratio = currentProfile.progressRatio;
        final scoreColor = currentProfile.scoreColor;
        final gradientColors = currentProfile.scoreGradientColors;
        final missingItems = currentProfile.missingItems;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openForm(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF8FAFC),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: score >= 90
                      ? const Color(0xFFA7F3D0)
                      : score >= 60
                      ? const Color(0xFFBFDBFE)
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scoreColor.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  const BoxShadow(
                    color: Color(0x080F172A),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Badge & BDJobs Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          score >= 100
                              ? Icons.verified_rounded
                              : Icons.speed_rounded,
                          color: scoreColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  context.tr(
                                    bn: 'বিডিজবস স্টাইল প্রোফাইল স্কোর',
                                    en: 'BDJobs Style Profile Score',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr(bn: 'টিউশন', en: 'Tutor'),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              score >= 100
                                  ? context.tr(
                                      bn: 'অভিনন্দন! আপনার প্রোফাইল সম্পূর্ণ ভেরিফাইড',
                                      en: 'Congratulations! Profile 100% complete',
                                    )
                                  : context.tr(
                                      bn: 'দ্রুত টিউশন পেতে প্রোফাইল ১০০% সম্পন্ন করুন',
                                      en: 'Complete profile to 100% to get more offers',
                                    ),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Gauge Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: scoreColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          context.tr(
                            bn: '${context.digitsText(score)}%',
                            en: '$score%',
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Animated Progress Bar
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutCubic,
                        widthFactor: ratio.clamp(0.04, 1.0),
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: scoreColor.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Score status row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: scoreColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            context.tr(
                              bn: currentProfile.scoreLevelBn,
                              en: currentProfile.scoreLevelEn,
                            ),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: scoreColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        score >= 100
                            ? context.tr(
                                bn: 'সকল তথ্য সম্পন্ন',
                                en: 'All fields completed',
                              )
                            : context.tr(
                                bn: 'বাকি ${context.digitsText(100 - score)}%',
                                en: '${100 - score}% remaining',
                              ),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),

                  // Missing Suggestions Checklist (if not complete)
                  if (missingItems.isNotEmpty && !widget.compact) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),
                    Text(
                      context.tr(
                        bn: '💡 স্কোর বাড়ানোর পরামর্শ:',
                        en: '💡 Tips to boost your score:',
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: missingItems.take(2).map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                size: 13,
                                color: const Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                context.tr(
                                  bn: item.titleBn,
                                  en: item.titleEn,
                                ),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  context.tr(
                                    bn: '+${context.digitsText(item.weight)}%',
                                    en: '+${item.weight}%',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Action Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: score >= 100
                            ? const [Color(0xFF059669), Color(0xFF047857)]
                            : const [Color(0xFFEA580C), Color(0xFFC2410C)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (score >= 100
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFEA580C))
                              .withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          score >= 100
                              ? Icons.edit_note_rounded
                              : Icons.touch_app_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          score >= 100
                              ? context.tr(
                                  bn: 'প্রোফাইল তথ্য আপডেট করুন',
                                  en: 'Update Profile Details',
                                )
                              : context.tr(
                                  bn: 'প্রোফাইল পূরণ করুন (স্কোর বাড়ান)',
                                  en: 'Complete Profile (Boost Score)',
                                ),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
