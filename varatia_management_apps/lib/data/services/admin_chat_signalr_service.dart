import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../core/config/api_config.dart';
import '../../core/models/admin_chat_models.dart';

class AdminChatSignalRService {
  HubConnection? _hubConnection;

  final VoidCallback onConnected;
  final VoidCallback onDisconnected;
  final Function(AdminChatMessage) onMessageReceived;
  final Function(Map<String, dynamic>) onNotificationReceived;
  final Function(int, String, String, String) onIncomingCall;
  final Function(int, String) onCallAnswered;
  final Function(int) onCallEnded;
  final Function(int, String) onIceCandidate;

  AdminChatSignalRService({
    required this.onConnected,
    required this.onDisconnected,
    required this.onMessageReceived,
    required this.onNotificationReceived,
    required this.onIncomingCall,
    required this.onCallAnswered,
    required this.onCallEnded,
    required this.onIceCandidate,
  });

  Future<void> connect(String userId) async {
    final url = '${ApiConfig.baseUrl}/hubs/admin-chat?userId=$userId';

    _hubConnection = HubConnectionBuilder()
        .withUrl(url)
        .withAutomaticReconnect()
        .build();

    _hubConnection?.onclose(({Exception? error}) {
      debugPrint('SignalR disconnected: $error');
      onDisconnected();
    });

    _hubConnection?.on('ReceiveMessage', (List<Object?>? parameters) {
      if (parameters != null && parameters.isNotEmpty) {
        final messageData = parameters[0] as Map<String, dynamic>;
        final message = AdminChatMessage.fromJson(messageData);
        onMessageReceived(message);
      }
    });

    _hubConnection?.on('ReceiveNotification', (List<Object?>? parameters) {
      if (parameters != null && parameters.isNotEmpty) {
        final data = parameters[0] as Map<String, dynamic>;
        onNotificationReceived(data);
      }
    });

    _hubConnection?.on('IncomingCall', (List<Object?>? parameters) {
      if (parameters != null && parameters.isNotEmpty) {
        final data = parameters[0] as Map<String, dynamic>;
        onIncomingCall(
          data['conversationId'],
          data['type'],
          data['offer'],
          data['callerUserId'],
        );
      }
    });

    _hubConnection?.on('CallAnswered', (List<Object?>? parameters) {
      if (parameters != null && parameters.isNotEmpty) {
        final data = parameters[0] as Map<String, dynamic>;
        onCallAnswered(data['conversationId'], data['answer']);
      }
    });

    _hubConnection?.on('CallEnded', (List<Object?>? parameters) {
      if (parameters != null && parameters.isNotEmpty) {
        final data = parameters[0] as Map<String, dynamic>;
        onCallEnded(data['conversationId']);
      }
    });

    _hubConnection?.on('IceCandidateReceived', (List<Object?>? parameters) {
      if (parameters != null && parameters.isNotEmpty) {
        final data = parameters[0] as Map<String, dynamic>;
        onIceCandidate(data['conversationId'], data['candidate']);
      }
    });

    try {
      await _hubConnection?.start();
      onConnected();
      debugPrint('SignalR connected to admin-chat');
    } catch (e) {
      debugPrint('Error starting SignalR connection: $e');
    }
  }

  Future<void> joinConversation(int conversationId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke('JoinConversation', args: [conversationId]);
    }
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _hubConnection = null;
  }
}
