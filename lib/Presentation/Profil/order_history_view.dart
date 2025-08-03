import 'package:flutter/material.dart';
import '../Base/models/order_model.dart';
import '../Base/services/order_service.dart';
import 'package:intl/intl.dart';
import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/text_styles.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../Auth/provider/auth_provider.dart';
import 'dart:convert';

String formatDate(String isoString) {
  final date = DateTime.parse(isoString).toLocal();
  return DateFormat('dd/MM/yyyy HH:mm').format(date);
}

String getPaymentMethodText(String? method) {
  if (method?.toLowerCase() == 'qr') return 'Mã QR';
  if (method?.toLowerCase() == 'cod') return 'Thanh toán khi nhận hàng';
  return '';
}

class OrderHistoryView extends StatefulWidget {
  final List<OrderModel> orders;
  final VoidCallback? onOrderDeleted;
  const OrderHistoryView({Key? key, required this.orders, this.onOrderDeleted}) : super(key: key);

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  late List<OrderModel> _orders;

  @override
  void initState() {
    super.initState();
    _orders = List.from(widget.orders);
    
    // Auto refresh khi mở app để đồng bộ với database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshOrders();
    });
  }

  List<OrderModel> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

  Future<void> _refreshOrders() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng đăng nhập lại!'), backgroundColor: Colors.red),
        );
        return;
      }

      // Reload dữ liệu từ server
      final orderService = OrderService(baseUrl: 'http://192.168.10.1:3000', token: token);
      final newOrders = await orderService.fetchAllOrders();
      
      setState(() {
        _orders = newOrders;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi làm mới dữ liệu: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Đơn hàng của tôi'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _refreshOrders,
              tooltip: 'Làm mới dữ liệu',
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Chờ xác nhận'),
              Tab(text: 'Đã xác nhận'),
              Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList(getOrdersByStatus('pending'), 'Chờ xác nhận'),
            _buildOrderList(getOrdersByStatus('confirmed'), 'Đã xác nhận'),
            _buildOrderList(getOrdersByStatus('cancelled'), 'Đã hủy'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, String emptyText) {
    if (orders.isEmpty) {
      return Center(child: Text('Không có đơn hàng $emptyText.'));
    }
    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 2,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            leading: Icon(Icons.receipt_long, color: Pallete.orangePrimary, size: 32),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mã đơn: ${order.id}', style: TextStyles.bodyLargeBold.copyWith(fontSize: 18)),
                Text(order.status, style: TextStyles.bodyLargeSemiBold.copyWith(
                  color: order.status == 'pending' ? Pallete.orangePrimary : order.status == 'confirmed' ? Colors.green : Colors.red,
                  fontSize: 16)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Text('Tổng: ${order.total} VND', style: TextStyles.bodyLargeBold.copyWith(color: Pallete.orangePrimary, fontSize: 17)),
                SizedBox(height: 4),
                Text('Ngày đặt: ' + DateFormat('dd/MM/yyyy').format(DateTime.parse(order.createdAt).toLocal()),
                  style: TextStyles.bodyMediumRegular.copyWith(color: Pallete.neutral60, fontSize: 15)),
                SizedBox(height: 2),
                Text('Giờ đặt: ' + DateFormat('HH:mm').format(DateTime.parse(order.createdAt).toLocal()),
                  style: TextStyles.bodyMediumRegular.copyWith(color: Pallete.neutral100, fontSize: 15)),
                SizedBox(height: 2),
                Row(
                  children: [
                    Text('Giờ xác nhận: ', style: TextStyles.bodyMediumRegular.copyWith(color: Pallete.neutral60, fontSize: 15)),
                    Text(order.confirmedAt != null && order.confirmedAt!.isNotEmpty ? DateFormat('HH:mm').format(DateTime.parse(order.confirmedAt!).toLocal()) : 'Chưa xác nhận',
                      style: TextStyles.bodyMediumRegular.copyWith(color: order.confirmedAt != null && order.confirmedAt!.isNotEmpty ? Pallete.neutral100 : Pallete.orangePrimary, fontSize: 15)),
                  ],
                ),
              ],
            ),
            trailing: Icon(Icons.chevron_right, size: 28),
            onTap: () {
              _showOrderDetailDialog(order);
            },
          ),
        );
      },
      ),
    );
  }

  void _showOrderDetailDialog(OrderModel order) {
    print('paymentMethod:  ${order.paymentMethod}');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Pallete.neutral10,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
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
                )).toList(),
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
                      style: TextStyles.bodyLargeRegular.copyWith(color: order.confirmedAt != null && order.confirmedAt!.isNotEmpty ? Pallete.neutral100 : Pallete.orangePrimary, fontSize: 18)),
                  ],
                ),
                if (order.status == 'cancelled' && order.cancelReason != null && order.cancelReason!.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Text('Lý do từ chối:', style: TextStyles.bodyMediumSemiBold.copyWith(color: Pallete.pureError)),
                  SizedBox(height: 2),
                  Text(order.cancelReason!, style: TextStyles.bodyMediumRegular.copyWith(color: Pallete.pureError)),
                ],
                SizedBox(height: 20),
                // Nếu đơn đã xác nhận thì chỉ hiện nút Đóng căn giữa
                if (order.status == 'confirmed')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.close, size: 18, color: Colors.white),
                        label: Text('Đóng'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Pallete.orangePrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  )
                // Nếu đơn đã hủy thì hiện nút xóa và đóng
                else if (order.status == 'cancelled')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.delete_forever, size: 18),
                            label: Text('Xóa đơn này'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () async {
                              try {
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                final token = authProvider.token;
                                if (token == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Vui lòng đăng nhập lại!'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }
                                
                                // Xóa đơn hàng đã bị hủy
                                final orderService = OrderService(baseUrl: 'http://192.168.10.1:3000', token: token);
                                await orderService.deleteOrder(order.id);
                                
                                Navigator.pop(context); // Đóng dialog
                                setState(() {
                                  // Xóa đơn hàng khỏi danh sách
                                  _orders.removeWhere((o) => o.id == order.id);
                                });
                                widget.onOrderDeleted?.call();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã xóa đơn hàng!')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi khi xóa đơn hàng: $e'), backgroundColor: Colors.red),
                                );
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.close, size: 18, color: Colors.white),
                            label: Text('Đóng'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Pallete.orangePrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (order.status == 'pending')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.delete, size: 18),
                          label: Text('Hủy đơn này'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Pallete.pureError,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                          ),
                          onPressed: () async {
                            try {
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final token = authProvider.token;
                              if (token == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Vui lòng đăng nhập lại!'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              
                              // Chỉ hủy đơn hàng pending
                              final res = await http.post(
                                Uri.parse('http://192.168.10.1:3000/api/orders/${order.id}/cancel-by-user'),
                                headers: {'Authorization': 'Bearer $token'},
                              );
                              
                              if (res.statusCode == 200) {
                                Navigator.pop(context); // Đóng dialog
                                setState(() {
                                  // Cập nhật trạng thái đơn hàng thành cancelled
                                  final orderIndex = _orders.indexWhere((o) => o.id == order.id);
                                  if (orderIndex != -1) {
                                    _orders[orderIndex] = _orders[orderIndex].copyWith(
                                      status: 'cancelled',
                                      cancelReason: 'Khách hàng hủy đơn',
                                    );
                                  }
                                });
                                widget.onOrderDeleted?.call();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã hủy đơn hàng!')),
                                );
                              } else if (res.statusCode == 401) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại!'), backgroundColor: Colors.red),
                                );
                              } else if (res.statusCode == 403) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Không có quyền hủy đơn hàng này!'), backgroundColor: Colors.red),
                                );
                              } else if (res.statusCode == 400) {
                                final errorData = jsonDecode(res.body);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(errorData['message'] ?? 'Chỉ hủy được đơn pending!'), backgroundColor: Colors.red),
                                );
                              } else if (res.statusCode == 404) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đơn hàng không tồn tại!'), backgroundColor: Colors.red),
                                );
                                widget.onOrderDeleted?.call();
                              } else {
                                try {
                                  final errorData = jsonDecode(res.body);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi khi hủy đơn hàng: ${errorData['message'] ?? res.body}'), backgroundColor: Colors.red),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi khi hủy đơn hàng: ${res.body}'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 24),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.close, size: 18, color: Colors.white),
                          label: Text('Đóng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Pallete.orangePrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 