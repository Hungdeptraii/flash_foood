import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isVerifying = false;
  String message = '';

  // Kiểm tra xác minh email từ backend
  Future<void> checkEmailVerified() async {
    setState(() {
      isVerifying = true;
      message = 'Đang kiểm tra...';
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.10.1:3000/auth/check-verified?email=${Uri.encodeComponent(widget.email)}'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['emailVerified'] == true) {
        setState(() {
          message = 'Xác minh thành công! Đang chuyển...';
        });

        // TODO: Navigate đến trang chính của app
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          message = 'Email chưa được xác minh.';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Lỗi khi kiểm tra: $e';
      });
    } finally {
      setState(() {
        isVerifying = false;
      });
    }
  }

  // Gửi lại email xác minh
  Future<void> resendVerificationEmail() async {
    setState(() {
      message = 'Đang gửi lại email xác minh...';
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.10.1:3000/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'password': 'MậtKhẩuNgườiDùng', // <-- Bạn cần truyền mật khẩu thật nếu có.
        }),
      );

      final data = jsonDecode(response.body);

      setState(() {
        message = data['message'] ?? 'Đã gửi lại email.';
      });
    } catch (e) {
      setState(() {
        message = 'Lỗi khi gửi lại: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác minh Email'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'Một email xác minh đã được gửi tới:\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isVerifying ? null : checkEmailVerified,
              child: const Text('Tôi đã xác minh'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: resendVerificationEmail,
              child: const Text('Gửi lại email xác minh'),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}
