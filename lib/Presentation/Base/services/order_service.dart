import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';

class OrderService {
  final String baseUrl;
  final String token;

  OrderService({required this.baseUrl, required this.token});

  Future<List<OrderModel>> fetchPendingOrders() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/orders?status=pending'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        print('orders response:  {res.body}');
        final data = jsonDecode(res.body);
        return (data['orders'] as List)
            .map((e) => OrderModel.fromJson(e))
            .toList();
      } else {
        print('Error fetching orders:  {res.statusCode} -  {res.body}');
        throw Exception('Failed to fetch orders:  {res.statusCode}');
      }
    } catch (e) {
      print('Exception in fetchPendingOrders:  {e}');
      throw Exception('Failed to fetch orders:  {e}');
    }
  }

  Future<void> confirmOrder(int orderId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/orders/$orderId/confirm'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) {
        print('Error confirming order: ${res.statusCode} - ${res.body}');
        throw Exception('Failed to confirm order: ${res.statusCode}');
      }
    } catch (e) {
      print('Exception in confirmOrder: $e');
      throw Exception('Failed to confirm order: $e');
    }
  }

  Future<void> createOrder(List<CartItem> items, {String? address, String? note, String? paymentMethod}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/orders/create'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'items': items.map((e) => {
            'food_id': e.food.id,
            'quantity': e.quantity,
          }).toList(),
          'address': address ?? '',
          'note': note ?? '',
          if (paymentMethod != null) 'payment_method': paymentMethod,
        }),
      );
      if (res.statusCode != 200) {
        print('Error creating order: ${res.statusCode} - ${res.body}');
        throw Exception('Failed to create order: ${res.statusCode}');
      }
    } catch (e) {
      print('Exception in createOrder: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  Future<List<OrderModel>> fetchAllOrders() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/orders?my=1'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        print('orders response:  {res.body}');
        final data = jsonDecode(res.body);
        return (data['orders'] as List)
            .map((e) => OrderModel.fromJson(e))
            .toList();
      } else {
        print('Error fetching orders: \\u0000{res.statusCode} - \\u0000{res.body}');
        throw Exception('Failed to fetch orders: \\u0000{res.statusCode}');
      }
    } catch (e) {
      print('Exception in fetchAllOrders:  {e}');
      throw Exception('Failed to fetch orders:  {e}');
    }
  }

  Future<void> deleteOrder(int orderId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/api/orders/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) {
        print('Error deleting order: ${res.statusCode} - ${res.body}');
        throw Exception('Failed to delete order: ${res.statusCode}');
      }
    } catch (e) {
      print('Exception in deleteOrder: $e');
      throw Exception('Failed to delete order: $e');
    }
  }
} 