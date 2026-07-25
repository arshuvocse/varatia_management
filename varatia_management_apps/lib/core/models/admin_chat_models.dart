class AdminChatConversation {
  final int id;
  final String requesterUserId;
  final String requesterName;
  final String adminUserId;
  final String adminName;
  final String lastMessage;
  final DateTime? lastMessageOn;
  final int unreadCount;

  AdminChatConversation({
    required this.id,
    required this.requesterUserId,
    required this.requesterName,
    required this.adminUserId,
    required this.adminName,
    required this.lastMessage,
    this.lastMessageOn,
    required this.unreadCount,
  });

  factory AdminChatConversation.fromJson(Map<String, dynamic> json) {
    return AdminChatConversation(
      id: json['id'] as int,
      requesterUserId: json['requesterUserId'] as String,
      requesterName: json['requesterName'] as String,
      adminUserId: json['adminUserId'] as String,
      adminName: json['adminName'] as String,
      lastMessage: json['lastMessage'] as String,
      lastMessageOn: json['lastMessageOn'] != null
          ? DateTime.parse(json['lastMessageOn'] as String).toLocal()
          : null,
      unreadCount: json['unreadCount'] as int,
    );
  }
}

class AdminChatMessage {
  final int id;
  final int conversationId;
  final String senderUserId;
  final String senderName;
  final String messageText;
  final DateTime sentOn;

  AdminChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.senderName,
    required this.messageText,
    required this.sentOn,
  });

  factory AdminChatMessage.fromJson(Map<String, dynamic> json) {
    return AdminChatMessage(
      id: json['id'] as int,
      conversationId: json['conversationId'] as int,
      senderUserId: json['senderUserId'] as String,
      senderName: json['senderName'] as String,
      messageText: json['messageText'] as String,
      sentOn: DateTime.parse(json['sentOn'] as String).toLocal(),
    );
  }
}
