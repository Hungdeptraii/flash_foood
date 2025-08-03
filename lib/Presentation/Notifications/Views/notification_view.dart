import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/font_size.dart';
import 'package:flash_food/Core/response_conf.dart';
import 'package:flash_food/Core/text_styles.dart';
import 'package:flash_food/Presentation/Base/base.dart';
import 'package:flash_food/Presentation/Notifications/Models/notification_model.dart';
import 'package:flash_food/Presentation/Notifications/provider/notification_provider.dart';
import 'package:flash_food/Presentation/Notifications/screens/notification_item.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({Key? key}) : super(key: key);

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  @override
  void initState() {
    super.initState();
    // Khởi tạo provider khi widget được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      provider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    MathUtils.init(context);

    return Scaffold(
      appBar: buildAppBar(buildContext: context, screenTitle: "Thông báo"),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (notificationProvider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const Gap(16),
                  Text(
                    'Không có thông báo nào',
                    style: TextStyles.bodyMediumRegular.copyWith(
                      color: Colors.grey[600],
                      fontSize: getFontSize(FontSizes.medium),
                    ),
                  ),
                ],
              ),
            );
          }

          
          
          // Phân loại thông báo theo ngày
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
                      final todayNotifications = notificationProvider.notifications
                .where((notification) {
              if (notification.createdAt == null) {
                return false;
              }
              final notificationDate = DateTime(
                notification.createdAt!.year,
                notification.createdAt!.month,
                notification.createdAt!.day,
              );
              final isToday = notificationDate.isAtSameMomentAs(today);
              return isToday;
            })
                .toList();

          final yesterdayNotifications = notificationProvider.notifications
              .where((notification) {
                if (notification.createdAt == null) return false;
                final notificationDate = DateTime(
                  notification.createdAt!.year,
                  notification.createdAt!.month,
                  notification.createdAt!.day,
                );
                final yesterday = today.subtract(const Duration(days: 1));
                return notificationDate.isAtSameMomentAs(yesterday);
              })
              .toList();

          final olderNotifications = notificationProvider.notifications
              .where((notification) {
                if (notification.createdAt == null) return false;
                final notificationDate = DateTime(
                  notification.createdAt!.year,
                  notification.createdAt!.month,
                  notification.createdAt!.day,
                );
                final yesterday = today.subtract(const Duration(days: 1));
                return notificationDate.isBefore(yesterday);
              })
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              await notificationProvider.refreshNotifications();
            },
            child: ListView(
              children: [
                const Gap(24),
                
                // Hiển thị tất cả thông báo (tạm thời bỏ qua filter theo ngày)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: getWidth(24)),
                  child: Container(
                    padding: EdgeInsets.only(bottom: getHeight(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tất cả thông báo",
                          style: TextStyles.bodyMediumSemiBold.copyWith(
                            color: Pallete.neutral60,
                            fontSize: getFontSize(FontSizes.medium),
                          ),
                        ),
                        const Gap(16),
                        Column(
                          children: notificationProvider.notifications
                              .asMap()
                              .map((key, value) => MapEntry(
                                key,
                                NotificationTile(
                                  notificationModel: value,
                                  isEspecialNotification: !value.isRead,
                                  onTap: () {
                                    if (value.id != null) {
                                      notificationProvider.markNotificationAsRead(value.id!);
                                    }
                                  },
                                  onDelete: () {
                                    if (value.id != null) {
                                      notificationProvider.deleteNotification(value.id!);
                                    }
                                  },
                                ),
                              ))
                              .values
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Thông báo hôm qua
                if (yesterdayNotifications.isNotEmpty) ...[
                  Container(
                    width: 375,
                    height: 4,
                    decoration: const BoxDecoration(color: Color(0xFFEDEDED)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: getWidth(24)),
                    child: Container(
                      padding: EdgeInsets.only(top: getHeight(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hôm qua",
                            style: TextStyles.bodyMediumSemiBold.copyWith(
                              color: Pallete.neutral60,
                              fontSize: getFontSize(FontSizes.medium),
                            ),
                          ),
                          const Gap(16),
                          Column(
                            children: yesterdayNotifications
                                .asMap()
                                .map((key, value) => MapEntry(
                                  key,
                                  NotificationTile(
                                    notificationModel: value,
                                    isEspecialNotification: !value.isRead,
                                    onTap: () {
                                      if (value.id != null) {
                                        notificationProvider.markNotificationAsRead(value.id!);
                                      }
                                    },
                                    onDelete: () {
                                      if (value.id != null) {
                                        notificationProvider.deleteNotification(value.id!);
                                      }
                                    },
                                  ),
                                ))
                                .values
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Thông báo cũ hơn
                if (olderNotifications.isNotEmpty) ...[
                  Container(
                    width: 375,
                    height: 4,
                    decoration: const BoxDecoration(color: Color(0xFFEDEDED)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: getWidth(24)),
                    child: Container(
                      padding: EdgeInsets.only(top: getHeight(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Trước đó",
                            style: TextStyles.bodyMediumSemiBold.copyWith(
                              color: Pallete.neutral60,
                              fontSize: getFontSize(FontSizes.medium),
                            ),
                          ),
                          const Gap(16),
                          Column(
                            children: olderNotifications
                                .asMap()
                                .map((key, value) => MapEntry(
                                  key,
                                  NotificationTile(
                                    notificationModel: value,
                                    isEspecialNotification: !value.isRead,
                                    onTap: () {
                                      if (value.id != null) {
                                        notificationProvider.markNotificationAsRead(value.id!);
                                      }
                                    },
                                  ),
                                ))
                                .values
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
