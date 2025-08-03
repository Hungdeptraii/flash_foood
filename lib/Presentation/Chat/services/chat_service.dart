import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/chat_message_model.dart';

class ChatService {
  final String baseUrl;
  final String token;

  ChatService({
    required this.baseUrl,
    required this.token,
  });

  // Lấy lịch sử chat của user
  Future<List<ChatMessageModel>> getChatHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/history/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messagesData = data['messages'] ?? [];
        
        return messagesData.map((message) {
          return ChatMessageModel.fromJson(message);
        }).toList();
      } else {
        print('Error loading chat history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error loading chat history: $e');
      return [];
    }
  }

  // Lưu tin nhắn mới
  Future<String?> saveMessage(ChatMessageModel message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/save'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(message.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['messageId'];
      } else {
        print('Error saving message: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error saving message: $e');
      return null;
    }
  }

  // Xóa lịch sử chat của user
  Future<bool> clearChatHistory(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/chat/history/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error clearing chat history: $e');
      return false;
    }
  }

  // Gửi tin nhắn đến AI và lưu vào history
  Future<String?> sendMessageToAI(String message, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/ask'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'question': message,
          'userId': userId,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'Không có phản hồi từ AI';
      } else {
        print('Error sending message to AI: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error sending message to AI: $e');
      return null;
    }
  }
} 