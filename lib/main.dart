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
import 'Presentation/Notifications/provider/notification_provider.dart';
import 'Presentation/Chat/provider/chat_provider.dart';
import 'Presentation/Chat/services/chat_service.dart';
import 'Core/services/notification_service.dart';
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

  // Khởi tạo notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

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
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer4<AuthProvider, CartProvider, NotificationProvider, ChatProvider>(
      builder: (context, authProvider, cartProvider, notificationProvider, chatProvider, _) {
        // Sử dụng Future.microtask để tránh gọi setState trong build
        if (authProvider.isLoggedIn && (cartProvider.cartService == null)) {
          Future.microtask(() {
            final token = authProvider.token!;
            final baseUrl = 'http://192.168.10.1:3000'; // Đổi thành backend của bạn
            cartProvider.setCartService(CartService(baseUrl: baseUrl, token: token));
            cartProvider.fetchCart();
          });
        }

        // Khởi tạo notification provider khi user đã đăng nhập
        if (authProvider.isLoggedIn && !notificationProvider.isInitialized) {
          Future.microtask(() {
            notificationProvider.setAuthProvider(authProvider);
            notificationProvider.initialize();
          });
        } else if (!authProvider.isLoggedIn && notificationProvider.isInitialized) {
          // Reset provider khi user chưa đăng nhập
          Future.microtask(() {
            notificationProvider.reset();
          });
        }

        // Khởi tạo chat provider khi user đã đăng nhập
        if (authProvider.isLoggedIn && !chatProvider.isInitialized) {
          Future.microtask(() {
            chatProvider.setAuthProvider(authProvider);
            final token = authProvider.token!;
            final baseUrl = 'http://192.168.10.1:3000';
            chatProvider.setChatService(ChatService(baseUrl: baseUrl, token: token));
            chatProvider.initialize();
          });
        } else if (!authProvider.isLoggedIn && chatProvider.isInitialized) {
          // Reset provider khi user chưa đăng nhập
          Future.microtask(() {
            chatProvider.reset();
          });
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
