import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../Auth/provider/auth_provider.dart';

class ManageCustomerPage extends StatefulWidget {
  final VoidCallback? onRoleChanged;
  const ManageCustomerPage({Key? key, this.onRoleChanged}) : super(key: key);

  @override
  ManageCustomerPageState createState() => ManageCustomerPageState();
}

class ManageCustomerPageState extends State<ManageCustomerPage> {
  List<Map<String, dynamic>> customers = [];
  bool isLoading = true;
  String? error;

  String get token => Provider.of<AuthProvider>(context, listen: false).token ?? '';
  final String apiBase = 'http://192.168.10.1:3000/api/user';

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() { isLoading = true; });
    try {
      final res = await http.get(
        Uri.parse('$apiBase/customers'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          customers = List<Map<String, dynamic>>.from(data['customers'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Lỗi lấy danh sách khách hàng: \n${res.body}';
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

  void deleteCustomer(String id) async {
    final confirm = await showConfirmDeleteDialog(
      context: context,
      title: 'Xác nhận xoá',
      content: 'Bạn có chắc chắn muốn xoá khách hàng này?',
    );
    if (confirm != true) return;
    setState(() { isLoading = true; });
    try {
      final res = await http.delete(
        Uri.parse('$apiBase/customers/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        await fetchCustomers();
      } else {
        setState(() {
          error = 'Lỗi xoá khách hàng: \n${res.body}';
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

  void showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final emailCtrl = TextEditingController();
        final usernameCtrl = TextEditingController();
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
                    child: Text('Thêm khách hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: usernameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordCtrl,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: Icon(Icons.lock, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      suffixIcon: IconButton(
                        icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.blue),
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
                          backgroundColor: Colors.blue,
                          shape: StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        onPressed: () async {
                          final email = emailCtrl.text.trim();
                          final username = usernameCtrl.text.trim();
                          final password = passwordCtrl.text.trim();
                          if (email.isEmpty || username.isEmpty || password.isEmpty) return;
                          Navigator.pop(context);
                          await addCustomer(email, username, password);
                        },
                        child: const Text('Thêm', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void showEditCustomerDialog(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) {
        final usernameCtrl = TextEditingController(text: customer['username'] ?? '');
        final fullNameCtrl = TextEditingController(text: customer['full_name'] ?? '');
        final phoneCtrl = TextEditingController(text: customer['phone'] ?? '');
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
                    child: Text('Sửa khách hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: usernameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: fullNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Họ tên',
                      prefixIcon: Icon(Icons.badge, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: customer['password'] ?? '',
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
                      prefixIcon: Icon(Icons.lock, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      suffixIcon: IconButton(
                        icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.blue),
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
                          backgroundColor: Colors.blue,
                          shape: StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await editCustomer(
                            customer['id'].toString(),
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

  Future<void> editCustomer(String id, String username, String fullName, String phone, String password) async {
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
        Uri.parse('$apiBase/customers/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      if (res.statusCode == 200) {
        await fetchCustomers();
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

  Future<void> addCustomer(String email, String username, String password) async {
    setState(() { isLoading = true; });
    try {
      final res = await http.post(
        Uri.parse('$apiBase/customers'),
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
        await fetchCustomers();
      } else {
        setState(() {
          error = 'Lỗi thêm khách hàng: \n${res.body}';
          isLoading = false;
        });
        await fetchCustomers(); // Luôn cập nhật lại danh sách khi lỗi
      }
    } catch (e) {
      setState(() {
        error = 'Lỗi kết nối: $e';
        isLoading = false;
      });
      await fetchCustomers(); // Luôn cập nhật lại danh sách khi lỗi
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
      body: customers.isEmpty
          ? const Center(child: Text('Chưa có khách hàng nào.'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: customers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(Icons.person, color: Colors.blue, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 4),
                              Text(customer['email'] ?? '', style: TextStyle(color: Colors.grey[700], fontSize: 15)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange, size: 28),
                          onPressed: () => showEditCustomerDialog(customer),
                          tooltip: 'Sửa',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                          onPressed: () => deleteCustomer(customer['id'].toString()),
                          tooltip: 'Xoá',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddCustomerDialog,
        child: const Icon(Icons.add),
        tooltip: 'Thêm khách hàng',
      ),
    );
  }
} 