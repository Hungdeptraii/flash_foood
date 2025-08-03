import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/font_size.dart';
import 'package:flash_food/Core/response_conf.dart';
import 'package:flash_food/Core/text_styles.dart';
import 'package:flash_food/Presentation/Notifications/Models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    Key? key, 
    required this.notificationModel, 
    required this.isEspecialNotification,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  final NotificationModel notificationModel;
  final bool isEspecialNotification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: getHeight(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            isEspecialNotification == true
                ? const Column(
                    children: [
                      Divider(
                        color: Pallete.neutral30,
                        height: 1,
                      ),
                      Gap(16),
                    ],
                  )
                : const SizedBox(),
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getNotificationColor(),
                  ),
                  child: Icon(
                    _getNotificationIcon(notificationModel.type),
                    color: notificationModel.isRead 
                        ? Pallete.neutral60 
                        : Colors.white,
                    size: 20,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notificationModel.notificationTitle,
                              style: TextStyles.bodyLargeSemiBold.copyWith(
                                color: notificationModel.isRead 
                                    ? Pallete.neutral60 
                                    : Pallete.neutral100,
                                fontSize: getFontSize(FontSizes.large),
                              ),
                            ),
                          ),
                          if (!notificationModel.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getNotificationColor(),
                              ),
                            ),
                          if (onDelete != null)
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 16,
                                color: Pallete.neutral40,
                              ),
                              onPressed: onDelete,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                            ),
                        ],
                      ),
                      const Gap(4),
                      Text(
                        notificationModel.notificationContent,
                        style: TextStyles.bodyMediumRegular.copyWith(
                          color: Pallete.neutral60,
                          fontSize: getFontSize(FontSizes.medium),
                        ),
                      ),
                      if (notificationModel.isOrderSuccess && notificationModel.orderTotal != null) ...[
                        const Gap(4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Pallete.orangePrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Tổng tiền: ${notificationModel.orderTotal} VND',
                            style: TextStyles.bodySmallRegular.copyWith(
                              color: Pallete.orangePrimary,
                              fontSize: getFontSize(FontSizes.small),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (notificationModel.createdAt != null) ...[
                        const Gap(4),
                        Text(
                          _formatDateTime(notificationModel.createdAt!),
                          style: TextStyles.bodySmallRegular.copyWith(
                            color: Pallete.neutral40,
                            fontSize: getFontSize(FontSizes.small),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'order_status':
      case 'order_confirmed':
        return Icons.local_shipping;
      case 'order_success':
      case 'order_created':
        return Icons.check_circle;
      case 'order_cancelled':
        return Icons.cancel;
      case 'promotion':
        return Icons.local_offer;
      case 'account':
        return Icons.account_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor() {
    switch (notificationModel.type) {
      case 'order_success':
      case 'order_created':
        return Colors.green;
      case 'order_status':
      case 'order_confirmed':
        return Pallete.orangePrimary;
      case 'order_cancelled':
        return Colors.red;
      case 'promotion':
        return Colors.purple;
      case 'account':
        return Pallete.bluePrimary;
      default:
        return notificationModel.isRead 
            ? Pallete.greyPrimary 
            : Pallete.bluePrimary;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      } else {
        return '${difference.inHours} giờ trước';
      }
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
