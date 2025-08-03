import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _role;
  String? _userId;
  bool get isLoggedIn => _token != null;
  String? get role => _role;
  String? get token => _token;
  String? get userId => _userId;

  AuthProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    _userId = prefs.getString('userId');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final result = await AuthService.login(email, password);
      if (result != null && result['token'] != null) {
        _token = result['token'];
        _role = result['role'];
        _userId = result['userId']?.toString();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('role', _role ?? '');
        await prefs.setString('userId', _userId ?? '');
        notifyListeners();
        // Gửi FCM token lên backend
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        print('FCM Token for backend: $fcmToken');
        if (fcmToken != null && _token != null) {
          try {
            final response = await http.post(
              Uri.parse('http://192.168.10.1:3000/api/user/save-fcm-token'),
              headers: {
                'Authorization': 'Bearer $_token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'fcm_token': fcmToken}),
            );
            print('FCM token saved to backend: ${response.statusCode}');
          } catch (e) {
            print('Error saving FCM token: $e');
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      // 1. Đăng nhập Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        debugPrint('Người dùng hủy đăng nhập Google');
        return false;
      }

      // 2. Lấy xác thực Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Đăng nhập Firebase bằng credential Google
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // 4. Lấy Firebase ID Token
      final idToken = await userCredential.user?.getIdToken();
      print('Firebase ID Token: $idToken'); // <--- DÒNG NÀY

      if (idToken == null) {
        debugPrint('Không lấy được idToken');
        return false;
      }

      // 5. Gửi token lên backend
      print('Đang gửi token lên backend...');
      final response = await http.post(
        Uri.parse('http://192.168.10.1:3000/api/auth/google-login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['token'] != null) {
          _token = data['token'];
          _role = data['role'];
          _userId = data['userId']?.toString();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          await prefs.setString('role', _role ?? '');
          await prefs.setString('userId', _userId ?? '');
          notifyListeners();
          debugPrint('Đăng nhập Google + backend thành công');
          return true;
        } else {
          debugPrint('Backend trả về dữ liệu không hợp lệ: $data');
          return false;
        }
      } else {
        debugPrint('Lỗi backend: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stack) {
      debugPrint('Lỗi đăng nhập Google/backend: $e\n$stack');
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');
    notifyListeners();
  }

  Future<bool> register(String email, String username, String password, String phone) async {
    try {
      final result = await AuthService.register(email, username, password, phone);
      if (result != null && result['message'] != null) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
} 