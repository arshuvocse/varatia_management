import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/models/admin_chat_models.dart';

class AdminChatApiService {
  AdminChatApiService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<AdminContact> getDefaultAdmin() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/admin-chat/default-admin'),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AdminContact.fromJson(json['admin'] as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load admin contact: ${response.body}');
    }
  }

  Future<AdminChatConversation> openChat(
    String requesterUserId,
    String adminUserId,
  ) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/admin-chat/open'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requesterUserId': requesterUserId,
        'adminUserId': adminUserId,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      return AdminChatConversation.fromJson(json['conversation']);
    } else {
      throw Exception('Failed to open chat: ${response.body}');
    }
  }

  Future<List<AdminChatConversation>> getInbox(String userId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/admin-chat/inbox?userId=$userId'),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      final List<dynamic> conversations = json['conversations'];
      return conversations
          .map((c) => AdminChatConversation.fromJson(c))
          .toList();
    } else {
      throw Exception('Failed to load inbox: ${response.body}');
    }
  }

  Future<AdminChatConversation> getConversation(
    int conversationId,
    String userId,
  ) async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin-chat/conversations/$conversationId?userId=$userId',
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      return AdminChatConversation.fromJson(json['conversation']);
    } else {
      throw Exception('Failed to get conversation: ${response.body}');
    }
  }

  Future<AdminChatMessage> sendMessage(
    int conversationId,
    String senderUserId,
    String messageText,
  ) async {
    final response = await _client.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin-chat/conversations/$conversationId/messages',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'senderUserId': senderUserId,
        'messageText': messageText,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      return AdminChatMessage.fromJson(json['message']);
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }
}

class AdminContact {
  const AdminContact({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
  });

  final String userId;
  final String fullName;
  final String phoneNumber;

  factory AdminContact.fromJson(Map<String, dynamic> json) {
    return AdminContact(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Admin',
      phoneNumber: json['phoneNumber'] as String? ?? '',
    );
  }
}
