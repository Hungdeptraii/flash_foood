import 'package:flutter/material.dart';
import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/font_size.dart';
import 'package:flash_food/Core/response_conf.dart';
import 'package:flash_food/Core/text_styles.dart';
import 'package:gap/gap.dart';

class ChatBubble extends StatefulWidget {
  final VoidCallback onTap;
  
  const ChatBubble({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for breathing effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Bounce animation for tap effect
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: getHeight(100),
      right: getWidth(20),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _bounceAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value * _bounceAnimation.value,
            child: GestureDetector(
              onTap: _handleTap,
              onTapDown: (_) => setState(() => _isHovered = true),
              onTapUp: (_) => setState(() => _isHovered = false),
              onTapCancel: () => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: getSize(60),
                height: getSize(60),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isHovered
                        ? [Pallete.orangePrimary, Pallete.orangePrimary.withOpacity(0.7)]
                        : [Pallete.orangePrimary, Pallete.orangePrimary.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Pallete.orangePrimary.withOpacity(0.3),
                      blurRadius: _isHovered ? 20 : 10,
                      spreadRadius: _isHovered ? 2 : 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // AI icon
                    Center(
                      child: Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: getSize(28),
                      ),
                    ),
                    // Pulse ring effect
                    if (_isHovered)
                      Center(
                        child: Container(
                          width: getSize(70),
                          height: getSize(70),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    // Notification dot
                    Positioned(
                      top: getSize(8),
                      right: getSize(8),
                      child: Container(
                        width: getSize(12),
                        height: getSize(12),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Chat dialog widget
class ChatDialog extends StatefulWidget {
  final VoidCallback onClose;
  
  const ChatDialog({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<ChatDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _slideController.forward();
    
    // Add welcome message
    _messages.add(ChatMessage(
      text: "Xin chào! Tôi là AI assistant của Flash Food. Tôi có thể giúp bạn tìm món ăn, đặt hàng hoặc trả lời các câu hỏi về dịch vụ của chúng tôi. Bạn cần gì nào? 😊",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final userMessage = _messageController.text;
    _messageController.clear();
    
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    
    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: _generateAIResponse(userMessage),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    });
  }

  String _generateAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('món ăn') || message.contains('food') || message.contains('đồ ăn')) {
      return "Chúng tôi có rất nhiều món ăn ngon! Bạn có thể xem menu trong phần 'Tìm kiếm theo danh mục' hoặc tôi có thể gợi ý một số món phổ biến như: Pizza, Burger, Sushi, Phở, Bún chả... Bạn thích món gì? 🍕🍔🍜";
    } else if (message.contains('đặt hàng') || message.contains('order')) {
      return "Để đặt hàng, bạn chỉ cần:\n1. Chọn món ăn yêu thích\n2. Thêm vào giỏ hàng\n3. Điền thông tin giao hàng\n4. Chọn phương thức thanh toán\n5. Xác nhận đơn hàng\n\nTôi có thể hướng dẫn chi tiết hơn nếu bạn cần! 📦";
    } else if (message.contains('giá') || message.contains('price') || message.contains('cost')) {
      return "Giá cả của chúng tôi rất cạnh tranh! Mỗi món ăn có giá khác nhau, bạn có thể xem giá chi tiết khi chọn món. Chúng tôi cũng có nhiều ưu đãi và khuyến mãi thường xuyên. Bạn muốn xem món nào cụ thể không? 💰";
    } else if (message.contains('giao hàng') || message.contains('delivery')) {
      return "Chúng tôi giao hàng trong vòng 30-45 phút! Phí giao hàng từ 10k-20k tùy khoảng cách. Bạn có thể theo dõi đơn hàng real-time và nhận thông báo khi shipper đến. Có gì thắc mắc về dịch vụ giao hàng không? 🚚";
    } else if (message.contains('cảm ơn') || message.contains('thank')) {
      return "Cảm ơn bạn đã sử dụng dịch vụ của chúng tôi! Nếu cần hỗ trợ thêm, đừng ngại liên hệ tôi nhé. Chúc bạn ngon miệng! 😊🙏";
    } else {
      return "Xin lỗi, tôi chưa hiểu rõ câu hỏi của bạn. Bạn có thể hỏi về:\n• Món ăn và menu\n• Cách đặt hàng\n• Giá cả và khuyến mãi\n• Dịch vụ giao hàng\n• Hoặc bất kỳ thắc mắc nào khác! 🤔";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        margin: EdgeInsets.all(getWidth(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(getSize(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(getWidth(16)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Pallete.orangePrimary, Pallete.orangePrimary.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(getSize(20)),
                  topRight: Radius.circular(getSize(20)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: getSize(40),
                    height: getSize(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.smart_toy_rounded,
                      color: Pallete.orangePrimary,
                      size: getSize(24),
                    ),
                  ),
                  Gap(getWidth(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "AI Assistant",
                          style: TextStyles.bodyLargeSemiBold.copyWith(
                            color: Colors.white,
                            fontSize: getFontSize(FontSizes.large),
                          ),
                        ),
                        Text(
                          "Online",
                          style: TextStyles.bodyMediumRegular.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: getFontSize(FontSizes.small),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: getSize(24),
                    ),
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(getWidth(16)),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
            // Input
            Container(
              padding: EdgeInsets.all(getWidth(16)),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(getSize(20)),
                  bottomRight: Radius.circular(getSize(20)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Nhập tin nhắn...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(getSize(25)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: getWidth(16),
                          vertical: getHeight(12),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  Gap(getWidth(8)),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: getSize(40),
                      height: getSize(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Pallete.orangePrimary, Pallete.orangePrimary.withOpacity(0.7)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: getSize(20),
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

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: EdgeInsets.only(bottom: getHeight(12)),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: getSize(32),
              height: getSize(32),
              decoration: BoxDecoration(
                color: Pallete.orangePrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: getSize(18),
              ),
            ),
            Gap(getWidth(8)),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(getWidth(12)),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? Pallete.orangePrimary 
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(getSize(16)),
              ),
              child: Text(
                message.text,
                style: TextStyles.bodyMediumRegular.copyWith(
                  color: message.isUser ? Colors.white : Pallete.neutral100,
                  fontSize: getFontSize(FontSizes.medium),
                ),
              ),
            ),
          ),
          if (message.isUser) Gap(getWidth(8)),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: getHeight(12)),
      child: Row(
        children: [
          Container(
            width: getSize(32),
            height: getSize(32),
            decoration: BoxDecoration(
              color: Pallete.orangePrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: getSize(18),
            ),
          ),
          Gap(getWidth(8)),
          Container(
            padding: EdgeInsets.all(getWidth(12)),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(getSize(16)),
            ),
            child: Row(
              children: [
                _buildDot(0),
                Gap(getWidth(4)),
                _buildDot(1),
                Gap(getWidth(4)),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Container(
          width: getSize(8),
          height: getSize(8),
          decoration: BoxDecoration(
            color: Pallete.orangePrimary,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
} 