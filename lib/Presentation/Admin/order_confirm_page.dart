import 'package:flutter/material.dart';
import '../Base/services/order_service.dart';
import '../Base/models/order_model.dart';
import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/text_styles.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../Auth/provider/auth_provider.dart';

class OrderConfirmPage extends StatefulWidget {
  final OrderService orderService;
  const OrderConfirmPage({Key? key, required this.orderService}) : super(key: key);

  @override
  State<OrderConfirmPage> createState() => _OrderConfirmPageState();
}

class _OrderConfirmPageState extends State<OrderConfirmPage> {
  late Future<List<OrderModel>> _ordersFuture;
  // Thêm biến loading cho xác nhận đơn hàng
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _ordersFuture = widget.orderService.fetchPendingOrders();
  }

  Future<void> _confirmOrder(int orderId) async {
    await widget.orderService.confirmOrder(orderId);
    setState(() {
      _ordersFuture = widget.orderService.fetchPendingOrders();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xác nhận đơn hàng!')),
    );
  }

  Future<void> _cancelOrder(int orderId, String reason) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final baseUrl = 'http://192.168.10.1:3000';
      final res = await http.post(
        Uri.parse('$baseUrl/api/orders/$orderId/cancel'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason}),
      );
      if (res.statusCode == 200) {
        setState(() {
          _ordersFuture = widget.orderService.fetchPendingOrders();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã từ chối đơn hàng!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi từ chối đơn hàng: ${res.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi từ chối đơn hàng: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String formatDate(String isoString) {
    final date = DateTime.parse(isoString).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String getPaymentMethodText(String? method) {
    if (method?.toLowerCase() == 'qr') return 'Đã thanh toán chuyển khoản (QR)';
    if (method?.toLowerCase() == 'cod') return 'Thanh toán khi nhận hàng (COD)';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.role == 'admin';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Xem đơn hàng' : 'Xác nhận đơn hàng'),
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: \\${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(child: Text(isAdmin ? 'Không có đơn hàng nào' : 'Không có đơn hàng chờ xác nhận'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Đơn #${order.id} - ${order.total} VND'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trạng thái: ${order.status}'),
                      Row(
                        children: [
                          Icon(
                            order.paymentMethod == 'qr' ? Icons.payment : Icons.money_off,
                            color: order.paymentMethod == 'qr' ? Colors.green : Colors.orange,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            getPaymentMethodText(order.paymentMethod),
                            style: TextStyles.bodySmallRegular.copyWith(
                              color: order.paymentMethod == 'qr' ? Colors.green.shade700 : Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Ngày đặt: ', style: TextStyles.bodySmallRegular.copyWith(color: Pallete.neutral60)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text('Giờ đặt: ', style: TextStyles.bodySmallRegular.copyWith(color: Pallete.neutral60)),
                              Text(DateFormat('HH:mm').format(DateTime.parse(order.createdAt).toLocal()), style: TextStyles.bodySmallRegular.copyWith(color: Pallete.neutral100)),
                              SizedBox(width: 16),
                              Text('Giờ xác nhận: ', style: TextStyles.bodySmallRegular.copyWith(color: Pallete.neutral60)),
                              Text(order.confirmedAt != null && order.confirmedAt!.isNotEmpty ? DateFormat('HH:mm').format(DateTime.parse(order.confirmedAt!).toLocal()) : 'Chưa xác nhận',
                                style: TextStyles.bodySmallRegular.copyWith(color: Pallete.neutral100)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        backgroundColor: Pallete.neutral10,
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.receipt_long, color: Pallete.orangePrimary, size: 40),
                                      SizedBox(width: 16),
                                      Text('Chi tiết đơn #${order.id}', style: TextStyles.headingH4Bold.copyWith(fontSize: 22)),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  // Nhóm thông tin khách hàng
                                  Container(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('Khách: ', style: TextStyles.bodyLargeBold.copyWith(fontSize: 18)),
                                            Expanded(child: Text(order.fullName != null && order.fullName!.isNotEmpty ? order.fullName! : order.customerName, style: TextStyles.bodyLargeRegular.copyWith(fontSize: 18))),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        if (order.phone != null && order.phone!.isNotEmpty)
                                          Row(
                                            children: [
                                              Text('SĐT: ', style: TextStyles.bodyLargeBold.copyWith(fontSize: 16)),
                                              Expanded(child: Text(order.phone!, style: TextStyles.bodyLargeRegular.copyWith(fontSize: 16))),
                                            ],
                                          ),
                                        if (order.phone != null && order.phone!.isNotEmpty) SizedBox(height: 4),
                                        if (order.address != null && order.address!.isNotEmpty)
                                          Row(
                                            children: [
                                              Text('Địa chỉ giao hàng: ', style: TextStyles.bodyLargeBold.copyWith(fontSize: 16)),
                                              Expanded(child: Text(order.address!, style: TextStyles.bodyLargeRegular.copyWith(fontSize: 16))),
                                            ],
                                          ),
                                        if (order.address != null && order.address!.isNotEmpty) SizedBox(height: 4),
                                        if (order.note != null && order.note!.isNotEmpty)
                                          Row(
                                            children: [
                                              Text('Ghi chú: ', style: TextStyles.bodyLargeBold.copyWith(fontSize: 16)),
                                              Expanded(child: Text(order.note!, style: TextStyles.bodyLargeRegular.copyWith(fontSize: 16, color: Pallete.neutral100))),
                                            ],
                                          ),
                                        if (order.note != null && order.note!.isNotEmpty) SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text('Phương thức: ', style: TextStyles.bodyLargeBold.copyWith(fontSize: 16)),
                                            Expanded(
                                              child: Text(
                                                getPaymentMethodText(order.paymentMethod),
                                                style: TextStyles.bodyLargeRegular.copyWith(fontSize: 16, color: Pallete.neutral100),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Divider(),
                                  SizedBox(height: 8),
                                  Text('Món đã đặt:', style: TextStyles.bodyLargeSemiBold.copyWith(fontSize: 18)),
                                  ...order.items.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.fastfood, color: Pallete.orangePrimary, size: 24),
                                        SizedBox(width: 8),
                                        Expanded(child: Text('${item.foodName}', style: TextStyles.bodyLargeRegular.copyWith(fontSize: 18))),
                                        Text('x${item.quantity}', style: TextStyles.bodyLargeSemiBold.copyWith(fontSize: 18)),
                                        SizedBox(width: 12),
                                        Text('(${item.price} VND)', style: TextStyles.bodyMediumRegular.copyWith(color: Pallete.neutral60, fontSize: 16)),
                                      ],
                                    ),
                                  )),
                                  SizedBox(height: 16),
                                  Text('Tổng: ${order.total} VND', style: TextStyles.bodyLargeBold.copyWith(color: Pallete.orangePrimary, fontSize: 20)),
                                  SizedBox(height: 12),
                                  Text('Ngày đặt: ' + DateFormat('dd/MM/yyyy').format(DateTime.parse(order.createdAt).toLocal()),
                                    style: TextStyles.bodyLargeRegular.copyWith(color: Pallete.neutral60, fontSize: 18)),
                                  SizedBox(height: 4),
                                  Text('Giờ đặt: ' + DateFormat('HH:mm').format(DateTime.parse(order.createdAt).toLocal()),
                                    style: TextStyles.bodyLargeRegular.copyWith(color: Pallete.neutral100, fontSize: 18)),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('Giờ xác nhận: ', style: TextStyles.bodyLargeRegular.copyWith(color: Pallete.neutral60, fontSize: 18)),
                                      Text(order.confirmedAt != null && order.confirmedAt!.isNotEmpty ? DateFormat('HH:mm').format(DateTime.parse(order.confirmedAt!).toLocal()) : 'Chưa xác nhận',
                                        style: TextStyles.bodyLargeRegular.copyWith(color: Pallete.neutral100, fontSize: 18)),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: order.paymentMethod == 'qr' ? Colors.green.shade50 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: order.paymentMethod == 'qr' ? Colors.green.shade200 : Colors.orange.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          order.paymentMethod == 'qr' ? Icons.payment : Icons.money_off,
                                          color: order.paymentMethod == 'qr' ? Colors.green : Colors.orange,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                order.paymentMethod == 'qr' ? 'Đã thanh toán chuyển khoản' : 'Thanh toán khi nhận hàng',
                                                style: TextStyles.bodyLargeSemiBold.copyWith(
                                                  color: order.paymentMethod == 'qr' ? Colors.green.shade700 : Colors.orange.shade700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (order.paymentMethod == 'qr')
                                                Text(
                                                  'Khách hàng đã thanh toán qua QR code',
                                                  style: TextStyles.bodyMediumRegular.copyWith(
                                                    color: Colors.green.shade600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  // Chỉ hiển thị nút xác nhận/từ chối cho staff, không cho admin
                                  if (Provider.of<AuthProvider>(context, listen: false).role == 'staff') ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              String cancelReason = '';
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: Text('Lý do từ chối đơn hàng'),
                                                  content: TextField(
                                                    autofocus: true,
                                                    onChanged: (value) => cancelReason = value,
                                                    decoration: InputDecoration(hintText: 'Nhập lý do từ chối...'),
                                                    maxLines: 3,
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: Text('Hủy'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        if (cancelReason.trim().isEmpty) return;
                                                        Navigator.pop(context);
                                                        Navigator.pop(context);
                                                        await _cancelOrder(order.id, cancelReason);
                                                      },
                                                      child: Text('Xác nhận'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Pallete.pureError,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              padding: EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            child: Text('Từ chối', style: TextStyles.bodyLargeSemiBold.copyWith(color: Colors.white, fontSize: 15)),
                                          ),
                                        ),
                                        if (order.status == 'pending') ...[
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                await _confirmOrder(order.id);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Pallete.orangePrimary,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                padding: EdgeInsets.symmetric(vertical: 10),
                                              ),
                                              child: Text('Xác nhận', style: TextStyles.bodyLargeSemiBold.copyWith(color: Colors.white, fontSize: 15)),
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ] else if (Provider.of<AuthProvider>(context, listen: false).role == 'admin') ...[
                                    // Admin chỉ có nút đóng
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Pallete.orangePrimary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          padding: EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        child: Text('Đóng', style: TextStyles.bodyLargeSemiBold.copyWith(color: Colors.white, fontSize: 15)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: Icon(Icons.close, color: Pallete.orangePrimary, size: 22),
                                onPressed: () => Navigator.pop(context),
                                tooltip: 'Đóng',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 