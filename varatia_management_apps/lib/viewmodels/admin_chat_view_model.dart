import 'package:flutter/foundation.dart';
import '../../data/services/admin_chat_api_service.dart';
import '../../data/services/admin_chat_signalr_service.dart';
import '../../core/models/admin_chat_models.dart';

class AdminChatViewModel extends ChangeNotifier {
  final AdminChatApiService _apiService;
  AdminChatSignalRService? _signalRService;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  bool _isConnected = false;

  List<AdminChatConversation> _inbox = [];
  List<AdminChatConversation> get inbox => _inbox;

  int? _activeConversationId;
  List<AdminChatMessage> _messages = [];
  List<AdminChatMessage> get messages => _messages;

  bool _isLoadingInbox = false;
  bool get isLoadingInbox => _isLoadingInbox;

  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  // Call state
  int? _incomingCallConversationId;
  String? _incomingCallCallerId;
  int? get incomingCallConversationId => _incomingCallConversationId;
  String? get incomingCallCallerId => _incomingCallCallerId;

  AdminChatViewModel(this._apiService);

  Future<AdminContact> getDefaultAdmin() {
    return _apiService.getDefaultAdmin();
  }

  void init(String userId) {
    if (_currentUserId == userId && _isConnected) return;

    _currentUserId = userId;

    _signalRService?.disconnect();
    _signalRService = AdminChatSignalRService(
      onConnected: () {
        _isConnected = true;
        notifyListeners();
      },
      onDisconnected: () {
        _isConnected = false;
        notifyListeners();
      },
      onMessageReceived: _handleNewMessage,
      onNotificationReceived: _handleNotification,
      onIncomingCall: _handleIncomingCall,
      onCallAnswered: _handleCallAnswered,
      onCallEnded: _handleCallEnded,
      onIceCandidate: _handleIceCandidate,
    );

    _signalRService?.connect(userId);
    fetchInbox();
  }

  Future<void> fetchInbox() async {
    if (_currentUserId == null) return;

    _isLoadingInbox = true;
    notifyListeners();

    try {
      _inbox = await _apiService.getInbox(_currentUserId!);
    } catch (e) {
      debugPrint('Error fetching inbox: $e');
    } finally {
      _isLoadingInbox = false;
      notifyListeners();
    }
  }

  Future<void> openConversation(int conversationId) async {
    if (_currentUserId == null) return;

    _activeConversationId = conversationId;
    _messages = [];
    _isLoadingMessages = true;
    notifyListeners();

    try {
      // In a real app we'd fetch message history via a paginated API endpoint.
      // But for this mockup, the GetConversation endpoint doesn't return full history,
      // so we just join the SignalR group to get new messages.
      await _apiService.getConversation(conversationId, _currentUserId!);
      await _signalRService?.joinConversation(conversationId);
    } catch (e) {
      debugPrint('Error opening conversation: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<int?> startChatWithAdmin(String adminUserId) async {
    if (_currentUserId == null) return null;

    try {
      final conv = await _apiService.openChat(_currentUserId!, adminUserId);
      return conv.id;
    } catch (e) {
      debugPrint('Error starting chat: $e');
      return null;
    }
  }

  Future<void> sendMessage(String text) async {
    if (_currentUserId == null ||
        _activeConversationId == null ||
        text.trim().isEmpty) {
      return;
    }

    try {
      await _apiService.sendMessage(
        _activeConversationId!,
        _currentUserId!,
        text,
      );
      // We don't manually add to _messages because we'll receive it back via SignalR
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  void _handleNewMessage(AdminChatMessage message) {
    if (_activeConversationId == message.conversationId) {
      _messages.add(message);
      notifyListeners();
    } else {
      // It's for another conversation, refresh inbox to update LastMessage
      fetchInbox();
    }
  }

  void _handleNotification(Map<String, dynamic> data) {
    // If not in the active chat, refresh inbox
    if (_activeConversationId != data['conversationId']) {
      fetchInbox();
    }
  }

  void _handleIncomingCall(
    int conversationId,
    String type,
    String offer,
    String callerId,
  ) {
    _incomingCallConversationId = conversationId;
    _incomingCallCallerId = callerId;
    notifyListeners();
  }

  void _handleCallAnswered(int conversationId, String answer) {
    // WebRTC logic to process answer
  }

  void _handleCallEnded(int conversationId) {
    if (_incomingCallConversationId == conversationId) {
      _incomingCallConversationId = null;
      _incomingCallCallerId = null;
      notifyListeners();
    }
  }

  void _handleIceCandidate(int conversationId, String candidate) {
    // WebRTC logic to add candidate
  }

  void dismissIncomingCall() {
    _incomingCallConversationId = null;
    _incomingCallCallerId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _signalRService?.disconnect();
    super.dispose();
  }
}
