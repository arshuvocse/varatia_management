import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:varatia_management_apps/core/theme/app_theme.dart';

import 'package:varatia_management_apps/viewmodels/admin_chat_view_model.dart';

class AdminChatPage extends StatefulWidget {
  const AdminChatPage({
    super.key,
    required this.conversationId,
    required this.tenantName,
  });

  final int conversationId;
  final String tenantName;

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminChatViewModel>().openConversation(
        widget.conversationId,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.tenantName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Online',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Consumer<AdminChatViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoadingMessages) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.messages.length,
                  itemBuilder: (context, index) {
                    final message = viewModel.messages[index];
                    final isMe =
                        message.senderUserId == viewModel.currentUserId;
                    return _buildMessageBubble(
                      context,
                      message: message.messageText,
                      isMe: isMe,
                      time:
                          '${message.sentOn.hour}:${message.sentOn.minute.toString().padLeft(2, '0')}',
                    );
                  },
                ),
              ),
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_messageController.text.trim().isNotEmpty) {
                            viewModel.sendMessage(_messageController.text);
                            _messageController.clear();
                          }
                        },
                        icon: const Icon(Icons.send, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context, {
    required String message,
    required bool isMe,
    required String time,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(0),
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(16),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
