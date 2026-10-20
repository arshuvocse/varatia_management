import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class TenantChatConversationDto {
  final int id;
  final String tenantUserId;
  final String ownerUserId;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? tenantName;
  final String? ownerName;
  final String? lastMessage;

  TenantChatConversationDto({
    required this.id,
    required this.tenantUserId,
    required this.ownerUserId,
    required this.createdAt,
    required this.lastMessageAt,
    this.tenantName,
    this.ownerName,
    this.lastMessage,
  });

  factory TenantChatConversationDto.fromJson(Map<String, dynamic> json) {
    return TenantChatConversationDto(
      id: json['id'] as int,
      tenantUserId: json['tenantUserId'] as String,
      ownerUserId: json['ownerUserId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      tenantName: json['tenantName'] as String?,
      ownerName: json['ownerName'] as String?,
      lastMessage: json['lastMessage'] as String?,
    );
  }
}

class TenantChatMessageDto {
  final int id;
  final String senderUserId;
  final String messageText;
  final DateTime sentAt;
  final DateTime? readAt;

  TenantChatMessageDto({
    required this.id,
    required this.senderUserId,
    required this.messageText,
    required this.sentAt,
    this.readAt,
  });

  factory TenantChatMessageDto.fromJson(Map<String, dynamic> json) {
    return TenantChatMessageDto(
      id: json['id'] as int,
      senderUserId: json['senderUserId'] as String,
      messageText: json['messageText'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }
}

class TenantChatApiService {
  TenantChatApiService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<TenantChatConversationDto>> getConversations(
    String userId,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/TenantChat/conversations/$userId',
    );
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .map((json) => TenantChatConversationDto.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return <TenantChatConversationDto>[];
    } else {
      throw Exception('Failed to fetch chat conversations');
    }
  }

  Future<List<TenantChatMessageDto>> getMessages(int conversationId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/TenantChat/conversations/$conversationId/messages',
    );
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .map((json) => TenantChatMessageDto.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } else {
      throw Exception('Failed to fetch chat messages');
    }
  }

  Future<int> sendMessage({
    int? conversationId,
    required String tenantUserId,
    required String ownerUserId,
    required String senderUserId,
    required String messageText,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/TenantChat/messages');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (conversationId != null) 'conversationId': conversationId,
        'tenantUserId': tenantUserId,
        'ownerUserId': ownerUserId,
        'senderUserId': senderUserId,
        'messageText': messageText,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['conversationId'] as int;
    } else {
      throw Exception('Failed to send message');
    }
  }
}
