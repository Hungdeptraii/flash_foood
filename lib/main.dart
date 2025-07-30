import 'package:flash_food/Core/Routes/routes.dart';
import 'package:flash_food/Core/Routes/routes_name.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Presentation/Auth/provider/auth_provider.dart';
import 'Presentation/Auth/views/login_view.dart';
import 'Presentation/Main/main_view.dart';
import 'Presentation/Admin/admin_view.dart';
import 'Presentation/Base/provider/food_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'Presentation/Base/provider/cart_provider.dart';
import 'Presentation/Base/services/cart_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.notification?.title}');
  _showNotification(message);
}

void _showNotification(RemoteMessage message) async {
  print('Showing notification: ${message.notification?.title} - ${message.notification?.body}');
  try {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'order_channel',
      'Order Notifications',
      channelDescription: 'Thông báo trạng thái đơn hàng',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'Thông báo',
      message.notification?.body ?? '',
      platformChannelSpecifics,
    );
    print('Notification displayed successfully');
  } catch (e) {
    print('Error showing notification: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Khởi tạo local notification
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Tạo notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'order_channel',
    'Order Notifications',
    description: 'Thông báo trạng thái đơn hàng',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  print('Notification channel created');

  // Đăng ký background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  String? fcmToken = await FirebaseMessaging.instance.getToken();
  print('FCM Token: ' + (fcmToken ?? 'null'));

  // Lắng nghe notification khi app đang foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');
    _showNotification(message);
  });

  // Lắng nghe khi user tap vào notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification opened: ${message.notification?.title}');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FoodProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, CartProvider>(
      builder: (context, authProvider, cartProvider, _) {
        if (authProvider.isLoggedIn && (cartProvider.cartService == null)) {
          final token = authProvider.token!;
          final baseUrl = 'http://192.168.10.1:3000'; // Đổi thành backend của bạn
          cartProvider.setCartService(CartService(baseUrl: baseUrl, token: token));
          cartProvider.fetchCart();
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: authProvider.isLoggedIn 
            ? ((authProvider.role == 'admin' || authProvider.role == 'staff') ? const AdminView() : const MainView())
            : const LoginView(),
          onGenerateRoute: Routes.onGenerateRoute,
          theme: ThemeData(canvasColor: Colors.white),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('vi'),
            Locale('en'),
          ],
          locale: const Locale('vi'),
        );
      },
    );
  }
}
