import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:varatia_management_apps/core/theme/app_theme.dart';
import 'package:varatia_management_apps/core/utils/app_context.dart';
import 'package:varatia_management_apps/data/services/auth_session_service.dart';
import 'package:varatia_management_apps/viewmodels/admin_chat_view_model.dart';
import 'admin_chat_page.dart';

class AdminInboxPage extends StatefulWidget {
  const AdminInboxPage({super.key});

  @override
  State<AdminInboxPage> createState() => _AdminInboxPageState();
}

class _AdminInboxPageState extends State<AdminInboxPage> {
  final AuthSessionService _authSessionService = AuthSessionService();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeInbox());
  }

  Future<void> _initializeInbox() async {
    try {
      final session = await _authSessionService.readSession();
      final userId = session?.userId.trim();
      if (userId == null || userId.isEmpty) {
        throw Exception('Please login again to load inbox.');
      }

      if (!mounted) return;
      context.read<AdminChatViewModel>().init(userId);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr(bn: 'ইনবক্স', en: 'Inbox')),
        centerTitle: true,
      ),
      body: Consumer<AdminChatViewModel>(
        builder: (context, viewModel, child) {
          if (_errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            );
          }

          if (viewModel.isLoadingInbox) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.inbox.isEmpty) {
            return Center(
              child: Text(
                context.tr(bn: 'কোনো মেসেজ নেই', en: 'No messages yet'),
                style: const TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.inbox.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final conversation = viewModel.inbox[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminChatPage(
                        conversationId: conversation.id,
                        tenantName: conversation.requesterName,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.surfaceSoft,
                        child: Text(
                          conversation.requesterName.isNotEmpty
                              ? conversation.requesterName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conversation.requesterName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              conversation.lastMessage,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (conversation.lastMessageOn != null)
                            Text(
                              '${conversation.lastMessageOn!.hour}:${conversation.lastMessageOn!.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          const SizedBox(height: 6),
                          if (conversation.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${conversation.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
