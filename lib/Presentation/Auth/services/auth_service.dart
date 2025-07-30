import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    print('LOGIN: email=$email, password=$password');
    final response = await http.post(
      Uri.parse('http://192.168.10.1:3000/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    print('Status: [33m${response.statusCode}[0m');
    print('Body: ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Đăng nhập thất bại');
    }
  }

  static Future<Map<String, dynamic>?> register(String email, String username, String password, String phone) async {
    print('REGISTER: email=$email, username=$username, password=$password, phone=$phone');
    final response = await http.post(
      Uri.parse('http://192.168.10.1:3000/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'username': username, 'password': password, 'phone': phone}),
    );
    print('Status: \x1B[33m[33m[33m${response.statusCode}\x1B[0m');
    print('Body: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Đăng ký thất bại');
    }
  }

  static Future<Map<String, dynamic>?> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('http://192.168.10.1:3000/api/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Lấy thông tin cá nhân thất bại');
    }
  }

  static Future<bool> updateProfile({
    required String token,
    required String fullName,
    required String birthday,
    required String phone,
    String? avatar,
  }) async {
    final response = await http.put(
      Uri.parse('http://192.168.10.1:3000/api/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'full_name': fullName,
        'birthday': birthday,
        'phone': phone,
        'avatar': avatar,
      }),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Cập nhật thông tin thất bại');
    }
  }
} 