import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../Presentation/Auth/provider/auth_provider.dart';

class ManageRevenuePage extends StatefulWidget {
  const ManageRevenuePage({Key? key}) : super(key: key);

  @override
  State<ManageRevenuePage> createState() => _ManageRevenuePageState();
}

class _ManageRevenuePageState extends State<ManageRevenuePage> with SingleTickerProviderStateMixin {
  DateTime? fromDate;
  DateTime? toDate;
  double totalRevenue = 0;
  int totalOrders = 0;
  bool isLoading = false;
  String? error;

  List<Map<String, dynamic>> foodRevenue = [];
  bool isLoadingFood = false;
  String? errorFood;

  late TabController _tabController;

  String get token => Provider.of<AuthProvider>(context, listen: false).token ?? '';
  final String apiBase = 'http://192.168.10.1:3000/api/orders/revenue';
  final String apiFood = 'http://192.168.10.1:3000/api/orders/revenue-by-food';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchRevenue();
    fetchRevenueByFood();
  }

  Future<void> fetchRevenue() async {
    setState(() { isLoading = true; error = null; });
    try {
      String url = apiBase;
      List<String> params = [];
      if (fromDate != null) params.add('from=${fromDate!.toIso8601String().substring(0,10)}');
      if (toDate != null) params.add('to=${toDate!.toIso8601String().substring(0,10)}');
      if (params.isNotEmpty) url += '?' + params.join('&');
      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          totalRevenue = double.tryParse(data['total_revenue'].toString()) ?? 0;
          totalOrders = int.tryParse(data['total_orders'].toString()) ?? 0;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Lỗi lấy doanh thu: ${res.body}';
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

  Future<void> fetchRevenueByFood() async {
    setState(() { isLoadingFood = true; errorFood = null; });
    try {
      String url = apiFood;
      List<String> params = [];
      if (fromDate != null) params.add('from=${fromDate!.toIso8601String().substring(0,10)}');
      if (toDate != null) params.add('to=${toDate!.toIso8601String().substring(0,10)}');
      if (params.isNotEmpty) url += '?' + params.join('&');
      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          foodRevenue = List<Map<String, dynamic>>.from(data['foods'] ?? []);
          isLoadingFood = false;
        });
      } else {
        setState(() {
          errorFood = 'Lỗi lấy doanh thu theo món: ${res.body}';
          isLoadingFood = false;
        });
      }
    } catch (e) {
      setState(() {
        errorFood = 'Lỗi kết nối: $e';
        isLoadingFood = false;
      });
    }
  }

  void reloadAll() {
    fetchRevenue();
    fetchRevenueByFood();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý doanh thu'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tổng hợp'),
            Tab(text: 'Theo món ăn'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fromDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => fromDate = picked);
                    },
                    child: Text(fromDate == null ? 'Từ ngày' : fromDate!.toString().substring(0,10)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: toDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => toDate = picked);
                    },
                    child: Text(toDate == null ? 'Đến ngày' : toDate!.toString().substring(0,10)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: reloadAll,
                  child: const Text('Xem'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Tổng hợp
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (error != null)
                    Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
                  else
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tổng doanh thu:', style: TextStyle(fontSize: 18)),
                            Text('${totalRevenue.toStringAsFixed(0)} VND', style: const TextStyle(fontSize: 28, color: Colors.purple, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            const Text('Số đơn đã xác nhận:', style: TextStyle(fontSize: 18)),
                            Text('$totalOrders', style: const TextStyle(fontSize: 28, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  // Tab 2: Theo món ăn
                  if (isLoadingFood)
                    const Center(child: CircularProgressIndicator())
                  else if (errorFood != null)
                    Center(child: Text(errorFood!, style: const TextStyle(color: Colors.red)))
                  else
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Doanh thu theo món ăn:', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 8),
                            Expanded(
                              child: foodRevenue.isEmpty
                                  ? const Center(child: Text('Không có dữ liệu.'))
                                  : ListView.separated(
                                      itemCount: foodRevenue.length,
                                      separatorBuilder: (_, __) => const Divider(),
                                      itemBuilder: (context, index) {
                                        final item = foodRevenue[index];
                                        return ListTile(
                                          leading: CircleAvatar(child: Text('${index + 1}')),
                                          title: Text(item['food_name'] ?? ''),
                                          subtitle: Text('Số lượng: ${int.tryParse(item['quantity'].toString()) ?? 0}'),
                                          trailing: Text('${double.tryParse(item['revenue'].toString())?.toStringAsFixed(0) ?? '0'} VND', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Tổng doanh thu: ${foodRevenue.fold<num>(0, (sum, item) => sum + (double.tryParse(item['revenue'].toString()) ?? 0))} VND',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 