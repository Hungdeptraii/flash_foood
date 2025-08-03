import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotificationModel {
  final String? id;
  final String notificationTitle;
  final String notificationContent;
  final bool isRead;
  final DateTime? createdAt;
  final String? type;
  final String? orderId;
  final String? status;
  final String? reason;
  final String? orderTotal;
  final List<dynamic>? orderItems;
  final String? message;

  NotificationModel({
    this.id,
    required this.notificationContent,
    required this.notificationTitle,
    this.isRead = false,
    this.createdAt,
    this.type,
    this.orderId,
    this.status,
    this.reason,
    this.orderTotal,
    this.orderItems,
    this.message,
  });

  // Factory constructor để tạo từ JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseCreatedAt(dynamic createdAt) {
      if (createdAt == null) return null;
      
      try {
        // Nếu là Firebase timestamp object
        if (createdAt is Map<String, dynamic> && 
            createdAt.containsKey('_seconds') && 
            createdAt.containsKey('_nanoseconds')) {
          final seconds = createdAt['_seconds'] as int;
          final nanoseconds = createdAt['_nanoseconds'] as int;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
        
        // Nếu là string ISO format
        if (createdAt is String) {
          return DateTime.parse(createdAt);
        }
        
        // Nếu là timestamp number
        if (createdAt is int) {
          return DateTime.fromMillisecondsSinceEpoch(createdAt);
        }
        
        return null;
      } catch (e) {
        return null;
      }
    }

    return NotificationModel(
      id: json['id'],
      notificationTitle: json['title'] ?? '',
      notificationContent: json['body'] ?? '',
      isRead: json['read'] ?? false,
      createdAt: parseCreatedAt(json['createdAt']),
      type: json['type'],
      orderId: json['orderId'],
      status: json['status'],
      reason: json['reason'],
      orderTotal: json['orderTotal'],
      orderItems: json['orderItems'],
      message: json['message'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': notificationTitle,
      'body': notificationContent,
      'read': isRead,
      'createdAt': createdAt?.toIso8601String(),
      'type': type,
      'orderId': orderId,
      'status': status,
      'reason': reason,
      'orderTotal': orderTotal,
      'orderItems': orderItems,
      'message': message,
    };
  }

  // Kiểm tra có phải thông báo đặt hàng không
  bool get isOrderNotification => 
      type == 'order_success' || 
      type == 'order_status' || 
      type == 'order_created' || 
      type == 'order_confirmed' || 
      type == 'order_cancelled';
  
  // Kiểm tra có phải thông báo đặt hàng thành công không
  bool get isOrderSuccess => 
      type == 'order_success' || 
      type == 'order_created';
  
  // Kiểm tra có phải thông báo trạng thái đơn hàng không
  bool get isOrderStatus => 
      type == 'order_status' || 
      type == 'order_confirmed' || 
      type == 'order_cancelled';
}

