import 'package:flutter/material.dart';
import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/font_size.dart';
import 'package:flash_food/Core/response_conf.dart';
import 'package:flash_food/Core/text_styles.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime? timestamp;

  const ChatBubble({
    Key? key, 
    required this.message, 
    required this.isUser,
    this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: getHeight(4), horizontal: getWidth(8)),
        padding: EdgeInsets.all(getWidth(12)),
        decoration: BoxDecoration(
          color: isUser ? Pallete.orangePrimary : Colors.grey[100],
          borderRadius: BorderRadius.circular(getSize(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyles.bodyMediumRegular.copyWith(
                color: isUser ? Colors.white : Pallete.neutral100,
                fontSize: getFontSize(FontSizes.medium),
              ),
            ),
            if (timestamp != null)
              Padding(
                padding: EdgeInsets.only(top: getHeight(4)),
                child: Text(
                  '${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isUser ? Colors.white70 : Colors.grey[600],
                    fontSize: getFontSize(FontSizes.small),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 