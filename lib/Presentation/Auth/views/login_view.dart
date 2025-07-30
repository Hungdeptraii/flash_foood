import 'package:flash_food/Core/Routes/routes_name.dart';
import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/response_conf.dart';
import 'package:flash_food/Core/text_styles.dart';
import 'package:flash_food/Presentation/Auth/screens/default_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../screens/default_field.dart';
import 'package:gap/gap.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flash_food/Core/Utils/utils.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../../Base/services/cart_service.dart';
import '../../Base/provider/cart_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle();
    if (success) {
      // Chuyển sang màn hình chính
      Navigator.pushReplacementNamed(context, RoutesName.main);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập Google thất bại!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    MathUtils.init(context);

    final List<Map<String, dynamic>> socialIcons = [
      {'icon': 'assets/icons/google.svg', 'onTap': _handleGoogleSignIn},
      {'icon': 'assets/icons/facebook.svg', 'onTap': () {}}, // Thêm nếu cần
    ];

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: getWidth(24)).copyWith(
          top: MediaQuery.of(context).viewPadding.top,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(32),
            Text(
              "Đăng nhập tài khoản của bạn.",
              style: TextStyles.headingH4SemiBold
                  .copyWith(color: Pallete.neutral100),
            ),
            const Gap(8),
            Text(
              "Hãy đăng nhập tài khoản của bạn",
              style: TextStyles.bodyMediumMedium.copyWith(
                color: Pallete.neutral60,
                fontSize: getFontSize(14),
              ),
            ),
            const Gap(32),
            DefaultField(
              hintText: "Nhập Email",
              controller: emailController,
              labelText: "Địa chỉ Email",
            ),
            const Gap(14),
            DefaultField(
              hintText: "Nhập mật khẩu",
              controller: passwordController,
              labelText: "Mật khẩu",
              isPasswordField: true,
            ),
            const Gap(24),
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: () =>
                    Navigator.pushNamed(context, RoutesName.forgetPassword),
                child: Text(
                  "Quên mật khẩu?",
                  style: TextStyles.bodyMediumMedium.copyWith(
                    color: Pallete.orangePrimary,
                    fontSize: getFontSize(14),
                  ),
                ),
              ),
            ),
            const Gap(24),
            DefaultButton(
              btnContent: "Đăng nhập",
              function: () async {
                try {
                  final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
                  final cartProvider =
                  Provider.of<CartProvider>(context, listen: false);
                  final success = await authProvider.login(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );
                  if (success) {
                    final token = authProvider.token!;
                    final baseUrl = 'http://192.168.10.1:3000'; // Đổi backend của bạn
                    cartProvider.setCartService(
                        CartService(baseUrl: baseUrl, token: token));
                    await cartProvider.fetchCart();
                    Navigator.pushReplacementNamed(context, RoutesName.main);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đăng nhập thất bại!')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
                  );
                }
              },
            ),
            const Gap(24),
            Row(
              children: [
                const Expanded(
                    child: Divider(color: Pallete.neutral60, height: 0.5)),
                const Gap(16),
                Text(
                  "Đăng nhập với",
                  style: TextStyles.bodyMediumMedium.copyWith(
                    color: Pallete.neutral60,
                    fontSize: getFontSize(14),
                  ),
                ),

                const Gap(16),
                const Expanded(
                    child: Divider(color: Pallete.neutral60, height: 0.5)),
              ],
            ),
            const Gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: socialIcons
                  .map(
                    (e) => Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: InkWell(
                    onTap: e['onTap'],
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Pallete.neutral40, width: 1),
                      ),
                      child: SvgPicture.asset(e['icon']),
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
            const Gap(32),
            Align(
              alignment: Alignment.center,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Bạn không có tài khoản?",
                      style: TextStyles.bodyMediumMedium.copyWith(
                          color: Pallete.neutral100,
                          fontSize: getFontSize(14)),
                    ),
                    TextSpan(
                        text: ' ',
                        style: TextStyles.bodyMediumSemiBold.copyWith(
                            fontSize: getFontSize(14))),
                    TextSpan(
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.pushReplacementNamed(
                            context, RoutesName.signUp),
                      text: 'Đăng ký',
                      style: TextStyles.bodyMediumSemiBold.copyWith(
                          color: Pallete.orangePrimary,
                          fontSize: getFontSize(14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
