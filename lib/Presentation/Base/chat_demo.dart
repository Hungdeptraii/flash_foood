import 'package:flutter/material.dart';
import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/font_size.dart';
import 'package:flash_food/Core/response_conf.dart';
import 'package:flash_food/Core/text_styles.dart';
import 'package:gap/gap.dart';
import 'chat_bubble.dart';

class ChatDemo extends StatefulWidget {
  const ChatDemo({Key? key}) : super(key: key);

  @override
  State<ChatDemo> createState() => _ChatDemoState();
}

class _ChatDemoState extends State<ChatDemo> {
  bool _showChatDialog = false;

  void _showChat() {
    setState(() {
      _showChatDialog = true;
    });
  }

  void _hideChat() {
    setState(() {
      _showChatDialog = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat AI Demo',
          style: TextStyles.bodyLargeSemiBold.copyWith(
            color: Colors.white,
            fontSize: getFontSize(FontSizes.large),
          ),
        ),
        backgroundColor: Pallete.orangePrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Pallete.orangePrimary.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.smart_toy_rounded,
                  size: getSize(80),
                  color: Pallete.orangePrimary,
                ),
                Gap(getHeight(20)),
                Text(
                  'Flash Food AI Assistant',
                  style: TextStyles.bodyLargeSemiBold.copyWith(
                    color: Pallete.neutral100,
                    fontSize: getFontSize(FontSizes.h2),
                  ),
                ),
                Gap(getHeight(10)),
                Text(
                  'Nhấn vào bong bóng chat để trò chuyện với AI',
                  style: TextStyles.bodyMediumRegular.copyWith(
                    color: Pallete.neutral60,
                    fontSize: getFontSize(FontSizes.medium),
                  ),
                  textAlign: TextAlign.center,
                ),
                Gap(getHeight(40)),
                Container(
                  padding: EdgeInsets.all(getWidth(20)),
                  margin: EdgeInsets.symmetric(horizontal: getWidth(24)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(getSize(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Tính năng AI Assistant:',
                        style: TextStyles.bodyLargeSemiBold.copyWith(
                          color: Pallete.neutral100,
                          fontSize: getFontSize(FontSizes.large),
                        ),
                      ),
                      Gap(getHeight(16)),
                      _buildFeatureItem('🍕 Tư vấn món ăn'),
                      _buildFeatureItem('📦 Hướng dẫn đặt hàng'),
                      _buildFeatureItem('💰 Thông tin giá cả'),
                      _buildFeatureItem('🚚 Dịch vụ giao hàng'),
                      _buildFeatureItem('❓ Trả lời thắc mắc'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Chat bubble
          if (!_showChatDialog)
            ChatBubble(
              onTap: _showChat,
            ),
          // Chat dialog overlay
          if (_showChatDialog)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: ChatDialog(
                onClose: _hideChat,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: getHeight(8)),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Pallete.orangePrimary,
            size: getSize(20),
          ),
          Gap(getWidth(12)),
          Expanded(
            child: Text(
              text,
              style: TextStyles.bodyMediumRegular.copyWith(
                color: Pallete.neutral100,
                fontSize: getFontSize(FontSizes.medium),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 