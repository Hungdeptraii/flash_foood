import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Khởi tạo service
  Future<void> initialize() async {
    // Cấu hình local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    // Cấu hình Android channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Xử lý thông báo khi app đang mở
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Xử lý khi user tap vào thông báo
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }

  // Lưu thông báo vào Firebase Database
  Future<void> saveNotificationToDatabase({
    required String title,
    required String body,
    required String userId,
    required String type,
    String? orderId,
    String? status,
  }) async {
    try {
      final notificationData = {
        'title': title,
        'body': body,
        'userId': userId,
        'type': type,
        'orderId': orderId,
        'status': status,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final DocumentReference docRef = await _firestore.collection('notifications').add(notificationData);
      print('Notification saved to Firebase Database: ${docRef.id}');
    } catch (e) {
      print('Error saving notification to Firebase Database: $e');
    }
  }

  // Xử lý thông báo khi app đang mở
  void _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      
      // Hiển thị local notification
      await _showLocalNotification(message);
      
      // Lưu vào Firebase Database
      await saveNotificationToDatabase(
        title: message.notification?.title ?? 'Thông báo',
        body: message.notification?.body ?? '',
        userId: message.data['userId'] ?? '',
        type: message.data['type'] ?? 'general',
        orderId: message.data['orderId'],
        status: message.data['status'],
      );
    }
  }

  // Xử lý khi user tap vào thông báo
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    // Có thể thêm logic điều hướng dựa trên loại thông báo
    if (message.data['type'] == 'order_created') {
      // Điều hướng đến trang đơn hàng
    } else if (message.data['type'] == 'order_confirmed') {
      // Điều hướng đến trang đơn hàng
    }
  }

  // Hiển thị local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Lấy danh sách thông báo của user
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> notifications = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data != null) {
          notifications.add({
            'id': doc.id,
            ...Map<String, dynamic>.from(data as Map<String, dynamic>),
          });
        }
      }

      return notifications;
    } catch (e) {
      print('Error getting user notifications: $e');
      return [];
    }
  }

  // Đánh dấu thông báo đã đọc
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Lấy số thông báo chưa đọc
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }
} 