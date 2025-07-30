import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/assets_constantes.dart';
import 'package:flash_food/Core/font_size.dart';
import 'package:flash_food/Core/response_conf.dart';
import 'package:flash_food/Core/text_styles.dart';
import 'package:flash_food/Presentation/Auth/screens/default_button.dart';
import 'package:flash_food/Presentation/Base/base.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../Base/provider/cart_provider.dart';
import '../../Base/services/order_service.dart';
import '../../Auth/provider/auth_provider.dart';
import 'package:flash_food/Presentation/Models/category_model.dart';
// import 'package:qr_flutter/qr_flutter.dart'; // Tạm thời comment để tránh lỗi

class PaymentView extends StatefulWidget {
  final List cartItems;
  final int total;
  const PaymentView({Key? key, required this.cartItems, required this.total}) : super(key: key);

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedPaymentMethod;

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Xác nhận đơn hàng')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Danh sách món đã chọn:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...widget.cartItems.map<Widget>((item) => ListTile(
              leading: Image.asset(
                categories.firstWhere(
                  (c) => c.designation.toLowerCase() == item.food.category.toLowerCase(),
                  orElse: () => categories[0],
                ).link,
                width: 40,
                height: 40,
              ),
              title: Text(item.food.name),
              subtitle: Text('${item.food.price.toInt()} VND x${item.quantity}'),
              trailing: Text('${(item.food.price * item.quantity).toInt()} VND'),
            )),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng tiền:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${widget.total} VND', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
            SizedBox(height: 24),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Địa chỉ giao hàng *',
                labelStyle: TextStyle(color: Colors.red),
                border: OutlineInputBorder(),
                hintText: 'Nhập địa chỉ giao hàng của bạn',
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
                hintText: 'Nhập ghi chú',
              ),
            ),
            SizedBox(height: 12),
            Text('Phương thức thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<String>(
              value: 'cod',
              groupValue: _selectedPaymentMethod,
              onChanged: (v) => setState(() => _selectedPaymentMethod = v),
              title: Text('Thanh toán khi nhận hàng'),
            ),
            RadioListTile<String>(
              value: 'qr',
              groupValue: _selectedPaymentMethod,
              onChanged: (v) => setState(() => _selectedPaymentMethod = v),
              title: Text('Mã QR'),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // Kiểm tra địa chỉ giao hàng
                if (_addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng nhập địa chỉ giao hàng!'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                if (_selectedPaymentMethod == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng chọn phương thức thanh toán!'), backgroundColor: Colors.red),
                  );
                  return;
                }
                final cartProvider = Provider.of<CartProvider>(context, listen: false);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final baseUrl = 'http://192.168.10.1:3000'; // Hoặc lấy từ config
                final orderService = OrderService(baseUrl: baseUrl, token: authProvider.token!);
                if (_selectedPaymentMethod == 'qr') {
                  // Hiển thị QR code và giả lập thanh toán
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      Future.delayed(Duration(seconds: 10), () {
                        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                      });
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('Quét mã QR để thanh toán'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/images/1753883986846.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      color: Colors.grey.shade100,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.qr_code, size: 80, color: Colors.grey.shade400),
                                          SizedBox(height: 8),
                                          Text(
                                            'VIETQR\nBUI DUC TRUNG\n104****036\nVietcombank',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Vui lòng quét mã QR bằng app ngân hàng để thanh toán.\n(Quét giả lập, tự động xác nhận sau 10 giây)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Đang xử lý thanh toán...', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ).then((_) async {
                    // Sau khi đóng dialog (sau 10s), tiến hành tạo đơn hàng
                    try {
                      await orderService.createOrder(
                        List.from(widget.cartItems),
                        address: _addressController.text,
                        note: _noteController.text,
                        paymentMethod: _selectedPaymentMethod!,
                      );
                      await cartProvider.clearCart();
                      if (mounted) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Thanh toán thành công! Đơn hàng đã được đặt và chờ xác nhận.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi khi đặt hàng: $e'), backgroundColor: Colors.red),
                      );
                    }
                  });
                } else {
                  // Thanh toán khi nhận hàng
                  try {
                    await orderService.createOrder(
                      List.from(widget.cartItems),
                      address: _addressController.text,
                      note: _noteController.text,
                      paymentMethod: _selectedPaymentMethod!,
                    );
                    await cartProvider.clearCart();
                    if (mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đặt hàng thành công! Xem đơn hàng tại mục Hồ sơ.')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi đặt hàng: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text('Xác nhận đặt hàng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
