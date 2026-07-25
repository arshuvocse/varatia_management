import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AmarElakaLivePage extends StatefulWidget {
  const AmarElakaLivePage({super.key, required this.wardName});

  final String wardName;

  @override
  State<AmarElakaLivePage> createState() => _AmarElakaLivePageState();
}

class _AmarElakaLivePageState extends State<AmarElakaLivePage> {
  bool _cameraOn = true;
  bool _microphoneOn = true;
  bool _highQuality = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(title: const Text('Live')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 260,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.wardName,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(
                  Icons.live_tv_rounded,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ward live broadcast',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'High quality stream preview for local announcements.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _LiveSwitch(
            icon: Icons.videocam_rounded,
            title: 'Camera',
            value: _cameraOn,
            onChanged: (value) => setState(() => _cameraOn = value),
          ),
          _LiveSwitch(
            icon: Icons.mic_rounded,
            title: 'Microphone',
            value: _microphoneOn,
            onChanged: (value) => setState(() => _microphoneOn = value),
          ),
          _LiveSwitch(
            icon: Icons.high_quality_rounded,
            title: 'High quality',
            value: _highQuality,
            onChanged: (value) => setState(() => _highQuality = value),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live session is ready.')),
              );
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start live'),
          ),
        ],
      ),
    );
  }
}

class _LiveSwitch extends StatelessWidget {
  const _LiveSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF079455),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
