# Chat AI Bubble - Flash Food

## 🎯 Tính năng

Bong bóng chat AI được tích hợp vào màn hình home của ứng dụng Flash Food, cung cấp trải nghiệm tương tác thông minh cho người dùng.

## ✨ Đặc điểm chính

### 1. **Bong bóng Chat (ChatBubble)**
- **Vị trí**: Góc dưới bên phải màn hình
- **Animation**: 
  - Hiệu ứng thở (pulse animation)
  - Hiệu ứng bounce khi tap
  - Hiệu ứng hover với ring effect
- **Design**: 
  - Gradient màu cam (theme của app)
  - Icon AI robot
  - Dot notification đỏ
  - Shadow và glow effects

### 2. **Dialog Chat (ChatDialog)**
- **Animation**: Slide up từ dưới lên
- **UI/UX**:
  - Header với avatar AI và status "Online"
  - Chat messages với bubble design
  - Input field với send button
  - Typing indicator
  - Overlay background mờ

### 3. **AI Responses**
Hệ thống AI có thể trả lời các câu hỏi về:
- 🍕 **Món ăn**: Gợi ý menu, món phổ biến
- 📦 **Đặt hàng**: Hướng dẫn quy trình đặt hàng
- 💰 **Giá cả**: Thông tin giá và khuyến mãi
- 🚚 **Giao hàng**: Thời gian và phí giao hàng
- ❓ **Hỗ trợ**: Trả lời thắc mắc chung

## 🚀 Cách sử dụng

### 1. **Trong Home Screen**
```dart
// Import
import 'package:flash_food/Presentation/Base/chat_bubble.dart';

// Sử dụng trong Stack
Stack(
  children: [
    // Your main content
    SingleChildScrollView(...),
    
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
)
```

### 2. **Demo Screen**
Để test tính năng, chạy:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ChatDemo()),
);
```

## 🎨 Customization

### 1. **Thay đổi màu sắc**
```dart
// Trong chat_bubble.dart
colors: _isHovered
    ? [Pallete.orangePrimary, Pallete.orangeSecondary]
    : [Pallete.orangePrimary, Pallete.orangePrimary.withOpacity(0.8)],
```

### 2. **Thay đổi vị trí**
```dart
// Trong ChatBubble widget
Positioned(
  bottom: getHeight(100), // Thay đổi khoảng cách từ bottom
  right: getWidth(20),    // Thay đổi khoảng cách từ right
  child: ...
)
```

### 3. **Thêm AI responses mới**
```dart
// Trong _generateAIResponse method
String _generateAIResponse(String userMessage) {
  final message = userMessage.toLowerCase();
  
  if (message.contains('your_keyword')) {
    return "Your custom response";
  }
  // ... existing responses
}
```

## 🔧 Technical Details

### 1. **Animation Controllers**
- `_pulseController`: Tạo hiệu ứng thở
- `_bounceController`: Tạo hiệu ứng bounce khi tap
- `_slideController`: Tạo hiệu ứng slide cho dialog

### 2. **State Management**
- `_showChatDialog`: Quản lý trạng thái hiển thị dialog
- `_messages`: Lưu trữ lịch sử chat
- `_isTyping`: Hiển thị typing indicator

### 3. **Responsive Design**
- Sử dụng `getWidth()`, `getHeight()`, `getSize()` cho responsive
- Tương thích với theme colors của app

## 📱 Screenshots

### Bong bóng Chat
- Vị trí: Góc dưới phải
- Icon: Robot AI
- Màu: Gradient cam
- Animation: Pulse + Bounce

### Dialog Chat
- Header: AI Assistant + Online status
- Messages: Bubble design
- Input: Text field + Send button
- Background: Semi-transparent overlay

## 🎯 Benefits

1. **User Experience**: Tương tác thông minh và thân thiện
2. **Customer Support**: Hỗ trợ 24/7 với AI
3. **Engagement**: Tăng tương tác người dùng
4. **Modern UI**: Design hiện đại với animation mượt mà
5. **Accessibility**: Dễ sử dụng và trực quan

## 🔮 Future Enhancements

1. **Real AI Integration**: Kết nối với AI service thực
2. **Voice Chat**: Hỗ trợ chat bằng giọng nói
3. **Image Recognition**: Nhận diện hình ảnh món ăn
4. **Personalization**: Tùy chỉnh theo sở thích người dùng
5. **Multi-language**: Hỗ trợ nhiều ngôn ngữ

## 🐛 Troubleshooting

### Lỗi thường gặp:
1. **Animation không chạy**: Kiểm tra TickerProviderStateMixin
2. **Dialog không hiển thị**: Kiểm tra Stack và Positioned
3. **Responsive issues**: Kiểm tra getWidth/getHeight functions

### Debug:
```dart
// Thêm debug prints
print('Chat bubble tapped');
print('Dialog state: $_showChatDialog');
``` 