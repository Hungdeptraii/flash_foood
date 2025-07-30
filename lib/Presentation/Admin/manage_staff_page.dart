import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../Auth/provider/auth_provider.dart';

class ManageStaffPage extends StatefulWidget {
  final String? adminRole; // truyền role từ ngoài vào để kiểm tra quyền
  final VoidCallback? onRoleChanged;
  const ManageStaffPage({Key? key, this.adminRole, this.onRoleChanged}) : super(key: key);

  @override
  ManageStaffPageState createState() => ManageStaffPageState();
}

class ManageStaffPageState extends State<ManageStaffPage> {
  List<Map<String, dynamic>> staffs = [];
  bool isLoading = true;
  String? error;

  String get token => Provider.of<AuthProvider>(context, listen: false).token ?? '';
  final String apiBase = 'http://192.168.10.1:3000/api/user'; // Đổi lại IP nếu chạy thật

  @override
  void initState() {
    super.initState();
    if (widget.adminRole == 'admin') {
      fetchStaffs();
    } else {
      setState(() {
        isLoading = false;
        error = 'Bạn không có quyền truy cập trang này.';
      });
    }
  }

  Future<void> fetchStaffs() async {
    setState(() { isLoading = true; });
    try {
      final res = await http.get(
        Uri.parse('$apiBase/staffs'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          staffs = List<Map<String, dynamic>>.from(data['staffs'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Lỗi lấy danh sách nhân viên: \n${res.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Lỗi kết nối: $e';
        isLoading = false;
      });
    }
  }

  void showAddStaffDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final emailCtrl = TextEditingController();
        final usernameCtrl = TextEditingController();
        final passwordCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Thêm nhân viên'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
            ElevatedButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                final username = usernameCtrl.text.trim();
                final password = passwordCtrl.text.trim();
                if (email.isEmpty || username.isEmpty || password.isEmpty) return;
                Navigator.pop(context);
                await addStaff(email, username, password);
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> addStaff(String email, String username, String password) async {
    setState(() { isLoading = true; });
    try {
      final res = await http.post(
        Uri.parse('$apiBase/staffs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );
      if (res.statusCode == 201) {
        await fetchStaffs();
      } else {
        setState(() {
          error = 'Lỗi thêm nhân viên: \n${res.body}';
          isLoading = false;
        });
        await fetchStaffs(); // Luôn cập nhật lại danh sách khi lỗi
      }
    } catch (e) {
      setState(() {
        error = 'Lỗi kết nối: $e';
        isLoading = false;
      });
      await fetchStaffs(); // Luôn cập nhật lại danh sách khi lỗi
    }
  }

  void showEditStaffDialog(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (context) {
        final usernameCtrl = TextEditingController(text: staff['username'] ?? '');
        final fullNameCtrl = TextEditingController(text: staff['full_name'] ?? '');
        final phoneCtrl = TextEditingController(text: staff['phone'] ?? '');
        final passwordCtrl = TextEditingController();
        bool showPassword = false;
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 8,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text('Sửa nhân viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: usernameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person, color: Colors.orange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: fullNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Họ tên',
                      prefixIcon: Icon(Icons.badge, color: Colors.orange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone, color: Colors.orange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: staff['password'] ?? '',
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    enabled: false,
                    style: const TextStyle(color: Colors.grey),
                    obscureText: false,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordCtrl,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      prefixIcon: Icon(Icons.lock, color: Colors.orange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      suffixIcon: IconButton(
                        icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.orange),
                        onPressed: () => setState(() => showPassword = !showPassword),
                      ),
                    ),
                    obscureText: !showPassword,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Huỷ'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await editStaff(
                            staff['id'].toString(),
                            usernameCtrl.text.trim(),
                            fullNameCtrl.text.trim(),
                            phoneCtrl.text.trim(),
                            passwordCtrl.text.trim(),
                          );
                        },
                        child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> editStaff(String id, String username, String fullName, String phone, String password) async {
    setState(() { isLoading = true; });
    try {
      final body = {
        'username': username,
        'full_name': fullName,
        'phone': phone,
      };
      if (password.isNotEmpty) {
        body['password'] = password;
      }
      final res = await http.put(
        Uri.parse('$apiBase/staffs/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      if (res.statusCode == 200) {
        await fetchStaffs();
        widget.onRoleChanged?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cập nhật thành công!')),
          );
        }
      } else {
        setState(() {
          error = 'Lỗi cập nhật: \n${res.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Lỗi kết nối: $e';
        isLoading = false;
      });
    }
  }

  Future<bool?> showConfirmDeleteDialog({
    required BuildContext context,
    required String title,
    required String content,
    String cancelText = 'Huỷ',
    String confirmText = 'Xoá',
    Color confirmColor = Colors.red,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText, style: TextStyle(color: confirmColor)),
          ),
        ],
      ),
    );
  }

  void deleteStaff(String id) async {
    final confirm = await showConfirmDeleteDialog(
      context: context,
      title: 'Xác nhận xoá',
      content: 'Bạn có chắc chắn muốn xoá nhân viên này?',
    );
    if (confirm != true) return;
    setState(() { isLoading = true; });
    try {
      final res = await http.delete(
        Uri.parse('$apiBase/staffs/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        await fetchStaffs();
      } else {
        setState(() {
          error = 'Lỗi xoá nhân viên: \n${res.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Lỗi kết nối: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error!, style: const TextStyle(color: Colors.red)));
    }
    return Scaffold(
      // KHÔNG có appBar ở đây, vì đã có ở màn cha
      body: staffs.isEmpty
          ? const Center(child: Text('Chưa có nhân viên nào.'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: staffs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final staff = staffs[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.person, color: Colors.orange, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(staff['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 4),
                              Text(staff['email'] ?? '', style: TextStyle(color: Colors.grey[700], fontSize: 15)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange, size: 28),
                          onPressed: () => showEditStaffDialog(staff),
                          tooltip: 'Sửa',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                          onPressed: () => deleteStaff(staff['id'].toString()),
                          tooltip: 'Xoá',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddStaffDialog,
        child: const Icon(Icons.add),
        tooltip: 'Thêm nhân viên',
      ),
    );
  }
} 