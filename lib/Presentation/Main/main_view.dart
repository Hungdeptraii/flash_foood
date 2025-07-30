import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/font_size.dart';
import 'package:flash_food/Core/response_conf.dart';
import 'package:flash_food/Core/text_styles.dart';
import 'package:flash_food/Presentation/Cart/cart_view.dart';
import 'package:flash_food/Presentation/Chat/chat_view.dart';
import 'package:flash_food/Presentation/Main/home_view.dart';
import 'package:flash_food/Presentation/Profil/profil_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Auth/provider/auth_provider.dart';
import '../Admin/admin_view.dart';
import '../Admin/order_confirm_page.dart';
import '../Base/services/order_service.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    MathUtils.init(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.role == 'admin' || authProvider.role == 'staff';
    final isStaff = authProvider.role == 'staff';
    
    final _pages = [
      const HomeView(),
      const CartView(),
      const ChatView(),
      const ProfilView(),
      if (isAdmin) const AdminView(),
    ];
    
    return Scaffold(
      body: _pages.elementAt(_currentIndex),
      bottomNavigationBar: Container(
        decoration: const ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          shadows: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 40,
              offset: Offset(0, 0),
              spreadRadius: 0,
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (value) {
            // Nếu là staff và ấn vào tab quản lý (index 4), chuyển thẳng vào OrderConfirmPage
            if (isStaff && value == 4) {
              final token = authProvider.token!;
              final baseUrl = 'http://192.168.10.1:3000';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderConfirmPage(
                    orderService: OrderService(baseUrl: baseUrl, token: token),
                  ),
                ),
              );
            } else {
              setState(() {
                _currentIndex = value;
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: false,
          iconSize: getSize(24),
          selectedItemColor: Pallete.orangePrimary,
          selectedLabelStyle: TextStyles.bodySmallMedium.copyWith(
              fontSize: getFontSize(FontSizes.small)
          ),
          unselectedItemColor: Pallete.neutral50,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: "Trang chủ",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: "Giỏ hàng",
            ),
            const BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chat_bubble), label: "Tin nhắn"),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Hồ sơ"),
            if (isAdmin)
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: "Quản lý",
              ),
          ],
          elevation: 0,
        ),
      ),
    );
  }
}

// Placeholder cho AdminView, sẽ thay bằng màn hình thật sau
class AdminViewPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Admin/Staff Management View (Coming soon)', style: TextStyle(fontSize: 18)));
  }
}
