import 'package:flutter/material.dart';

class ChatMessageModel {
  final String? id;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? userId;
  final List<String>? categories;
  final String? orderId;
  final String? status;

  ChatMessageModel({
    this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.userId,
    this.categories,
    this.orderId,
    this.status,
  });

  // Factory constructor để tạo từ JSON
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      message: json['message'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      categories: json['categories'] != null 
          ? List<String>.from(json['categories'])
          : null,
      orderId: json['orderId'],
      status: json['status'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'categories': categories,
      'orderId': orderId,
      'status': status,
    };
  }

  // Tạo message mới từ data hiện tại
  ChatMessageModel copyWith({
    String? id,
    String? message,
    bool? isUser,
    DateTime? timestamp,
    String? userId,
    List<String>? categories,
    String? orderId,
    String? status,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      message: message ?? this.message,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      categories: categories ?? this.categories,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
    );
  }
} 