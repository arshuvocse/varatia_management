import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

const _chatGreen = Color(0xFF079455);
const _chatBackground = Color(0xFFF6F8FB);
const _chatBorder = Color(0xFFE5EAF2);

class AmarElakaWardChatPage extends StatefulWidget {
  const AmarElakaWardChatPage({super.key, required this.wardName});

  final String wardName;

  @override
  State<AmarElakaWardChatPage> createState() => _AmarElakaWardChatPageState();
}

class _AmarElakaWardChatPageState extends State<AmarElakaWardChatPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final chats = _visibleChats;

    return Scaffold(
      backgroundColor: Colors.white,
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
          'চ্যাট',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'সার্চ',
            onPressed: () => _showMessage('চ্যাট সার্চ'),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'নতুন চ্যাট',
            onPressed: () => _showMessage('নতুন চ্যাট'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.of(context).maybePop();
          } else if (index != 1) {
            _showMessage(_bottomLabels[index]);
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
        top: false,
        child: Column(
          children: [
            _ChatTabs(
              selectedIndex: _tabIndex,
              onChanged: (index) => setState(() => _tabIndex = index),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                itemCount: chats.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 64, color: _chatBorder),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return _ChatListTile(
                    chat: chat,
                    onTap: () => _openConversation(chat),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_AreaChatData> get _visibleChats {
    return switch (_tabIndex) {
      1 => _chatItems.where((chat) => chat.group).toList(),
      2 => _chatItems.where((chat) => !chat.group).toList(),
      _ => _chatItems,
    };
  }

  void _openConversation(_AreaChatData chat) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AreaConversationPage(
          title: chat.title,
          subtitle: chat.group ? widget.wardName : 'Active now',
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$message চালু হচ্ছে')));
  }
}

class _ChatTabs extends StatelessWidget {
  const _ChatTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _chatBorder)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < _chatTabs.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selectedIndex == index
                            ? _chatGreen
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _chatTabs[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selectedIndex == index
                          ? _chatGreen
                          : AppColors.textPrimary,
                      fontWeight: selectedIndex == index
                          ? FontWeight.w900
                          : FontWeight.w700,
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

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({required this.chat, required this.onTap});

  final _AreaChatData chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _ChatAvatar(chat: chat),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    chat.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat.time,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (chat.unread > 0)
                  Container(
                    height: 22,
                    constraints: const BoxConstraints(minWidth: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: chat.badgeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      chat.unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.chat});

  final _AreaChatData chat;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: chat.color,
      child: chat.group
          ? Icon(chat.icon, color: Colors.white, size: 28)
          : Text(
              chat.initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _AreaConversationPage extends StatefulWidget {
  const _AreaConversationPage({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<_AreaConversationPage> createState() => _AreaConversationPageState();
}

class _AreaConversationPageState extends State<_AreaConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _typing = true;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _chatBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.call_rounded)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.videocam_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _ChatBubble(
                  author: 'রফিক',
                  text: 'কালকের মিটিং সকাল ১০টায়।',
                  mine: false,
                  active: true,
                  verified: true,
                ),
                const _ChatBubble(
                  author: 'You',
                  text: 'ঠিক আছে, সবাইকে জানিয়ে দিচ্ছি।',
                  mine: true,
                  active: true,
                ),
                if (_typing)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'সায়মা typing...',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Photo',
                    onPressed: () => _showMessage('Photo message selected.'),
                    icon: const Icon(Icons.image_rounded),
                  ),
                  IconButton(
                    tooltip: 'Audio',
                    onPressed: () => _showMessage('Audio message selected.'),
                    icon: const Icon(Icons.mic_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: (value) =>
                          setState(() => _typing = value.isEmpty),
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send',
                    onPressed: () {
                      _messageController.clear();
                      setState(() => _typing = true);
                      _showMessage('Message sent.');
                    },
                    icon: const Icon(Icons.send_rounded, color: _chatGreen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.author,
    required this.text,
    required this.mine,
    required this.active,
    this.verified = false,
  });

  final String author;
  final String text;
  final bool mine;
  final bool active;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine ? _chatGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _chatBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 8,
                  width: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF12B76A)
                        : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  author,
                  style: TextStyle(
                    color: mine ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (verified) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified_rounded,
                    color: _chatGreen,
                    size: 15,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 5),
            Text(
              text,
              style: TextStyle(
                color: mine ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaChatData {
  const _AreaChatData({
    required this.title,
    required this.preview,
    required this.time,
    required this.color,
    required this.badgeColor,
    this.unread = 0,
    this.group = true,
    this.initial = '',
    this.icon = Icons.groups_rounded,
  });

  final String title;
  final String preview;
  final String time;
  final Color color;
  final Color badgeColor;
  final int unread;
  final bool group;
  final String initial;
  final IconData icon;
}

const _chatTabs = ['সব চ্যাট', 'ওয়ার্ড গ্রুপ', 'ব্যক্তিগত'];
const _bottomLabels = ['হোম', 'চ্যাট', 'লাইভ', 'ফ্রেন্ড'];

const _chatItems = [
  _AreaChatData(
    title: 'ওয়ার্ড-০৭ গ্রুপ',
    preview: 'রফিক: কালকের মিটিং সকাল ১০টা',
    time: '9:30 AM',
    color: Color(0xFF5CB85C),
    badgeColor: Color(0xFFF04438),
    unread: 12,
  ),
  _AreaChatData(
    title: 'ওয়ার্ড-০৮ গ্রুপ',
    preview: 'সায়মা: ধন্যবাদ সবাইকে',
    time: '8:45 AM',
    color: Color(0xFF55A7F7),
    badgeColor: Color(0xFFF04438),
    unread: 5,
  ),
  _AreaChatData(
    title: 'সেক্টর-০১ গ্রুপ',
    preview: 'তানভীর: ছুটির পাঠান',
    time: 'Yesterday',
    color: Color(0xFF9C27B0),
    badgeColor: Color(0xFF12B76A),
    unread: 3,
  ),
  _AreaChatData(
    title: 'ব্লক-A গ্রুপ',
    preview: 'ইমরান: ঠিক আছে',
    time: 'Yesterday',
    color: Color(0xFFF79009),
    badgeColor: Color(0xFF12B76A),
  ),
  _AreaChatData(
    title: 'রিয়াজ উদ্দিন',
    preview: 'Okay 👍',
    time: 'Yesterday',
    color: Color(0xFF0F766E),
    badgeColor: Color(0xFF12B76A),
    group: false,
    initial: 'র',
    icon: Icons.person_rounded,
  ),
];
