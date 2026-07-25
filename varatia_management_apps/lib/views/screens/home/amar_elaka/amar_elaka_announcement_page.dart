import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AmarElakaAnnouncementPage extends StatefulWidget {
  const AmarElakaAnnouncementPage({super.key, required this.wardName});

  final String wardName;

  @override
  State<AmarElakaAnnouncementPage> createState() =>
      _AmarElakaAnnouncementPageState();
}

class _AmarElakaAnnouncementPageState extends State<AmarElakaAnnouncementPage> {
  final TextEditingController _controller = TextEditingController();
  bool _pinToTop = true;
  bool _notifyWard = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(title: const Text('Post announcement')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5EAF2)),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.wardName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  minLines: 5,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Announcement details',
                    hintText: 'Write a clear local announcement...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _pinToTop,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pin to top'),
                  onChanged: (value) => setState(() => _pinToTop = value),
                ),
                SwitchListTile(
                  value: _notifyWard,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notify ward members'),
                  onChanged: (value) => setState(() => _notifyWard = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Announcement posted.')),
              );
              Navigator.of(context).maybePop();
            },
            icon: const Icon(Icons.campaign_rounded),
            label: const Text('Publish announcement'),
          ),
        ],
      ),
    );
  }
}
