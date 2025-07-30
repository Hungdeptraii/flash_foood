import 'package:flash_food/Core/Routes/routes_name.dart';
import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/assets_constantes.dart';
import 'package:flash_food/Core/font_size.dart';
import 'package:flash_food/Core/response_conf.dart';
import 'package:flash_food/Core/text_styles.dart';
import 'package:flash_food/Presentation/Auth/screens/default_button.dart';
import 'package:flash_food/Presentation/Base/base.dart';
import 'package:flash_food/Presentation/Profil/screens/profile_info_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:flash_food/Presentation/Auth/provider/auth_provider.dart';
import 'package:flash_food/Presentation/Auth/views/login_view.dart';
import '../Base/provider/cart_provider.dart';
import '../Base/services/order_service.dart';
import '../Base/models/order_model.dart';
import 'order_history_view.dart';
import 'package:intl/intl.dart';
import 'package:flash_food/Presentation/Auth/services/auth_service.dart';

class ProfilView extends StatefulWidget {
  const ProfilView({Key? key}) : super(key: key);

  @override
  State<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<ProfilView> {
  late Future<List<OrderModel>> _ordersFuture;
  String fullName = '';
  String email = '';

  void _refreshOrders() {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    final baseUrl = 'http://192.168.10.1:3000';
    setState(() {
      _ordersFuture = OrderService(baseUrl: baseUrl, token: token).fetchAllOrders();
    });
  }

  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    final baseUrl = 'http://192.168.10.1:3000';
    _ordersFuture = OrderService(baseUrl: baseUrl, token: token).fetchAllOrders();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    final user = await AuthService.getProfile(token);
    if (user == null) return;
    setState(() {
      fullName = user['full_name'] ?? user['username'] ?? '';
      email = user['email'] ?? '';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        buildContext: context,
        screenTitle: "Cài đặt hồ sơ",
        isBackup: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: getWidth(24)),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Gap(24),
                    Stack(
                      children: [
                        CircleAvatar(
                          backgroundImage: const AssetImage(AssetsConstants.user),
                          radius: getSize(50),
                        ),
                        Positioned(
                          left: getSize(72),
                          bottom: getSize(8),
                          child: Container(
                            width: getSize(32),
                            height: getSize(32),
                            padding: EdgeInsets.all(getSize(6)),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F5FF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.camera_fill,
                              color: Pallete.orangePrimary,
                              size: getSize(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    Text(
                      fullName.isNotEmpty ? fullName : "Nguyễn Văn A",
                      style: TextStyles.bodyLargeSemiBold.copyWith(
                        color: Pallete.neutral100,
                        fontSize: getFontSize(FontSizes.large),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      email.isNotEmpty ? email : "NguyenVanA@gmail.com",
                      style: TextStyles.bodyMediumRegular.copyWith(
                        color: const Color(0xFF878787),
                        fontSize: getFontSize(FontSizes.medium),
                      ),
                    ),
                    const Gap(28),
                    FutureBuilder<List<OrderModel>>(
                      future: _ordersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Lỗi khi tải đơn hàng: ${snapshot.error}'));
                        }
                        final orders = snapshot.data ?? [];
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Đơn hàng của tôi",
                                  style: TextStyles.bodyLargeSemiBold.copyWith(
                                    color: Pallete.neutral100,
                                    fontSize: getFontSize(FontSizes.large),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderHistoryView(
                                          orders: orders,
                                          onOrderDeleted: _refreshOrders,
                                        ),
                                      ),
                                    );
                                    // Refresh orders khi quay lại từ OrderHistoryView
                                    _refreshOrders();
                                  },
                                  child: Text("Xem tất cả", style: TextStyle(color: Pallete.orangePrimary)),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(getSize(12)),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(getSize(8)),
                              ),
                              child: Text(
                                'Tổng số đơn đã đặt: ${orders.where((o) => o.status == "pending" || o.status == "confirmed").length}',
                                style: TextStyles.bodyLargeSemiBold.copyWith(
                                  color: Pallete.orangePrimary,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const Gap(24),
                    Container(
                      width: double.infinity,
                      decoration: const ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignCenter,
                            color: Color(0xFFEDEDED),
                          ),
                        ),
                      ),
                    ),
                    const Gap(24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cài đặt",
                          style: TextStyles.bodySmallMedium.copyWith(
                            color: const Color(0xFF878787),
                            fontSize: getFontSize(FontSizes.small),
                          ),
                        ),
                        ProfileInfoTile(
                          function: () async {
                            await Navigator.pushNamed(context, RoutesName.personnalData);
                            _loadUserProfile();
                          },
                          prefixIcon: Icons.person,
                          title: "Thông tin cá nhân",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Gap(24),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: DefaultButton(
              btnContent: "Đăng xuất",
              btnIcon: Icons.login_outlined,
              contentColor: Pallete.pureError,
              iconColor: Pallete.pureError,
              bgColor: Colors.white,
              borderColor: Pallete.neutral40,
              function: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Xác nhận đăng xuất'),
                    content: Text('Bạn có chắc chắn muốn đăng xuất?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Đăng xuất', style: TextStyle(color: Pallete.pureError)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final cartProvider = Provider.of<CartProvider>(context, listen: false);
                  cartProvider.clearLocal();
                  await Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                  );
                }
                              },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatDate(String isoString) {
  final date = DateTime.parse(isoString).toLocal();
  return DateFormat('dd/MM/yyyy HH:mm').format(date);
}
