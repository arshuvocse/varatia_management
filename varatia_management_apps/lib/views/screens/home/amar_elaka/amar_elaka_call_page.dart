import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

enum AmarElakaCallType { audio, video }

class AmarElakaCallPage extends StatelessWidget {
  const AmarElakaCallPage({
    super.key,
    required this.wardName,
    required this.callType,
  });

  final String wardName;
  final AmarElakaCallType callType;

  @override
  Widget build(BuildContext context) {
    final isVideo = callType == AmarElakaCallType.video;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(title: Text(isVideo ? 'Video call' : 'Audio call')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5EAF2)),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFFEFFAF3),
                  child: Icon(
                    isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                    color: const Color(0xFF079455),
                    size: 46,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$wardName support group',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  isVideo
                      ? 'Start a ward video call with local members.'
                      : 'Start a quick audio call with local members.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundCallButton(
                      icon: Icons.mic_off_rounded,
                      color: const Color(0xFF475467),
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _RoundCallButton(
                      icon: isVideo
                          ? Icons.videocam_off_rounded
                          : Icons.volume_up_rounded,
                      color: const Color(0xFF155EEF),
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _RoundCallButton(
                      icon: Icons.call_end_rounded,
                      color: AppColors.danger,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _CallStatusTile(
            title: 'Active members',
            subtitle: '12 people are active now',
            icon: Icons.people_alt_rounded,
          ),
          const _CallStatusTile(
            title: 'Typing indicator',
            subtitle: 'Typing status stays visible in ward chat.',
            icon: Icons.keyboard_rounded,
          ),
        ],
      ),
    );
  }
}

class _RoundCallButton extends StatelessWidget {
  const _RoundCallButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Ink(
        height: 58,
        width: 58,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _CallStatusTile extends StatelessWidget {
  const _CallStatusTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF079455)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
