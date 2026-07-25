import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:varatia_management_apps/core/theme/app_theme.dart';
import 'package:varatia_management_apps/core/utils/app_context.dart';
import 'package:varatia_management_apps/data/services/auth_session_service.dart';
import 'package:varatia_management_apps/viewmodels/admin_chat_view_model.dart';

class TenantGeneralPostChatPage extends StatefulWidget {
  const TenantGeneralPostChatPage({
    super.key,
    this.adminUserId,
    this.adminName,
  });

  final String? adminUserId;
  final String? adminName;

  @override
  State<TenantGeneralPostChatPage> createState() =>
      _TenantGeneralPostChatPageState();
}

class _TenantGeneralPostChatPageState extends State<TenantGeneralPostChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final AuthSessionService _authSessionService = AuthSessionService();
  bool _isInitialized = false;
  String? _currentUserId;
  String? _adminName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeChat());
  }

  Future<void> _initializeChat() async {
    final viewModel = context.read<AdminChatViewModel>();
    try {
      final session = await _authSessionService.readSession();
      final userId = session?.userId.trim();
      if (userId == null || userId.isEmpty) {
        throw Exception('Please login again to start chat.');
      }

      final admin = widget.adminUserId?.trim().isNotEmpty == true
          ? null
          : await viewModel.getDefaultAdmin();
      final adminUserId = widget.adminUserId?.trim().isNotEmpty == true
          ? widget.adminUserId!.trim()
          : admin!.userId;
      final adminName = widget.adminName?.trim().isNotEmpty == true
          ? widget.adminName!.trim()
          : admin?.fullName ?? 'Admin';

      viewModel.init(userId);
      final conversationId = await viewModel.startChatWithAdmin(adminUserId);
      if (conversationId == null) {
        throw Exception('Unable to start admin chat.');
      }

      await viewModel.openConversation(conversationId);
      if (!mounted) return;
      setState(() {
        _currentUserId = userId;
        _adminName = adminName;
        _isInitialized = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
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
              _adminName ?? context.tr(bn: 'অ্যাডমিন', en: 'Admin'),
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
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          : !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Consumer<AdminChatViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoadingMessages) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    Expanded(
                      child: viewModel.messages.isEmpty
                          ? Center(
                              child: Text(
                                context.tr(
                                  bn: 'অ্যাডমিনের সাথে আপনার কোনো চ্যাট নেই।',
                                  en: 'You have no chat history with the admin.',
                                ),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: viewModel.messages.length,
                              itemBuilder: (context, index) {
                                final message = viewModel.messages[index];
                                final isMe =
                                    message.senderUserId == _currentUserId;
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
                          border: Border(
                            top: BorderSide(color: AppColors.border),
                          ),
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
                                  viewModel.sendMessage(
                                    _messageController.text,
                                  );
                                  _messageController.clear();
                                }
                              },
                              icon: const Icon(
                                Icons.send,
                                color: AppColors.primary,
                              ),
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
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
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
