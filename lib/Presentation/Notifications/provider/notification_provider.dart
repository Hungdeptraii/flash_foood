import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Core/services/notification_service.dart';
import '../Models/notification_model.dart';
import '../../Auth/provider/auth_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isInitialized = false; // Thêm flag để tránh spam
  String? _userId;
  String _baseUrl = 'http://192.168.10.1:3000';
  
  // Thêm AuthProvider để lấy thông tin user
  AuthProvider? _authProvider;
  
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }
  
  // Reset provider khi user đăng nhập
  void reset() {
    _isInitialized = false;
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _userId = null;
  }

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Khởi tạo provider
  Future<void> initialize() async {
    await _loadUserId();
    await _loadNotifications();
    await _loadUnreadCount();
    _isInitialized = true;
  }

  // Lấy userId từ AuthProvider hoặc SharedPreferences
  Future<void> _loadUserId() async {
    // Ưu tiên lấy từ AuthProvider trước
    if (_authProvider != null && _authProvider!.userId != null) {
      _userId = _authProvider!.userId;
    } else {
      // Fallback: lấy từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString('userId');
      final userIdInt = prefs.getInt('userId');
      
      // Ưu tiên string, nếu không có thì dùng int và convert sang string
      _userId = userIdString ?? userIdInt?.toString();
    }
  }

  // Lấy danh sách thông báo từ backend
  Future<void> _loadNotifications() async {
    if (_userId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authToken = await _getAuthToken();
      
      if (authToken == null) {
        return;
      }

      final url = '$_baseUrl/api/notifications';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notificationsData = data['notifications'] ?? [];
        
        _notifications = notificationsData.map((notification) {
          return NotificationModel.fromJson(notification);
        }).toList();
      }
    } catch (e) {
      print('❌ Error loading notifications: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Lấy số thông báo chưa đọc
  Future<void> _loadUnreadCount() async {
    if (_userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/notifications/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _unreadCount = data['count'] ?? 0;
        notifyListeners();
      } else {
        print('Error loading unread count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  // Lấy auth token từ AuthProvider hoặc SharedPreferences
  Future<String?> _getAuthToken() async {
    // Ưu tiên lấy từ AuthProvider trước
    if (_authProvider != null && _authProvider!.token != null) {
      return _authProvider!.token;
    }
    
    // Fallback: lấy từ SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Sửa từ 'authToken' thành 'token'
  }

  // Đánh dấu thông báo đã đọc
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await _loadUnreadCount();
      } else {
        print('Error marking notification as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await _loadNotifications();
        await _loadUnreadCount();
      } else {
        print('Error deleting notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Refresh thông báo
  Future<void> refreshNotifications() async {
    await _loadNotifications();
    await _loadUnreadCount();
  }

  // Thêm thông báo mới (được gọi khi nhận thông báo từ Firebase)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }

  // Cập nhật số thông báo chưa đọc
  void updateUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
} 