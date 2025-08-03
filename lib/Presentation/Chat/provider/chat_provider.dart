import 'package:flutter/material.dart';
import '../Models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../../Auth/provider/auth_provider.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _userId;
  ChatService? _chatService;
  AuthProvider? _authProvider;

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  void setChatService(ChatService chatService) {
    _chatService = chatService;
  }

  // Reset provider khi user đăng nhập
  void reset() {
    _isInitialized = false;
    _messages.clear();
    _isLoading = false;
    _userId = null;
    _chatService = null;
  }

  // Khởi tạo provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadUserId();
    await _loadChatHistory();
    _isInitialized = true;
    notifyListeners();
  }

  // Lấy userId từ AuthProvider
  Future<void> _loadUserId() async {
    if (_authProvider != null && _authProvider!.userId != null) {
      _userId = _authProvider!.userId;
    }
  }

  // Lấy lịch sử chat
  Future<void> _loadChatHistory() async {
    if (_userId == null || _chatService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final history = await _chatService!.getChatHistory(_userId!);
      _messages.clear();
      _messages.addAll(history);
    } catch (e) {
      print('Error loading chat history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Thêm tin nhắn mới
  Future<void> addMessage(ChatMessageModel message) async {
    _messages.add(message);
    notifyListeners();

    // Lưu tin nhắn vào backend
    if (_chatService != null) {
      await _chatService!.saveMessage(message);
    }
  }

  // Gửi tin nhắn đến AI
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _userId == null) return;

    // Tạo tin nhắn user
    final userMessage = ChatMessageModel(
      message: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      userId: _userId,
    );

    await addMessage(userMessage);

    // Gửi đến AI
    if (_chatService != null) {
      setState(() {
        _isLoading = true;
      });

      // Thêm tin nhắn loading vào danh sách chat
      final loadingMessage = ChatMessageModel(
        message: 'AI đang trả lời...',
        isUser: false,
        timestamp: DateTime.now(),
        userId: _userId,
        status: 'loading',
      );
      _messages.add(loadingMessage);
      notifyListeners();

      try {
        final aiResponse = await _chatService!.sendMessageToAI(text.trim(), _userId!);
        
        // Xóa tin nhắn loading
        _messages.removeWhere((msg) => msg.status == 'loading');
        
        if (aiResponse != null) {
          final aiMessage = ChatMessageModel(
            message: aiResponse,
            isUser: false,
            timestamp: DateTime.now(),
            userId: _userId,
          );
          await addMessage(aiMessage);
        }
      } catch (e) {
        // Xóa tin nhắn loading nếu có lỗi
        _messages.removeWhere((msg) => msg.status == 'loading');
        print('Error sending message to AI: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Xóa lịch sử chat
  Future<void> clearHistory() async {
    if (_userId == null || _chatService == null) return;

    try {
      final success = await _chatService!.clearChatHistory(_userId!);
      if (success) {
        _messages.clear();
        notifyListeners();
      }
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }

  // Thêm tin nhắn với categories
  Future<void> addMessageWithCategories(String text, List<String> categories) async {
    final message = ChatMessageModel(
      message: text,
      isUser: false,
      timestamp: DateTime.now(),
      userId: _userId,
      categories: categories,
    );

    await addMessage(message);
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
} 