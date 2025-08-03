import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'screens/chat_bubble.dart';
import 'provider/chat_provider.dart';
import 'Models/chat_message_model.dart';

class ChatView extends StatefulWidget {
  const ChatView({Key? key}) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showPrompts = false;

  final List<String> _suggestedPrompts = [
    "Tìm món ăn theo danh mục",
    "Tìm món ăn theo khoảng giá",
    "Hướng dẫn đặt đồ ăn",
  ];



  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      // Chỉ thêm tin nhắn chào mừng nếu chưa có tin nhắn nào sau khi đã khởi tạo
      if (chatProvider.messages.isEmpty && chatProvider.isInitialized) {
        final welcomeMessage = ChatMessageModel(
          message: 'Xin chào! Tôi là AI trợ lý, có thể giúp gì cho bạn?',
          isUser: false,
          timestamp: DateTime.now(),
        );
        chatProvider.addMessage(welcomeMessage);
      }
    });
  }



  void _handlePromptTap(String prompt) {
    if (prompt == "Tìm món ăn theo danh mục") {
      _fetchCategoriesAndShowButtons();
    } else if (prompt == "Tìm món ăn theo khoảng giá") {
      _showPriceRangeDialog();
    } else {
      _controller.text = prompt;
      sendMessage();
    }
  }

  Future<void> _fetchCategoriesAndShowButtons() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.10.1:3000/api/ai/categories'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categories = List<String>.from(data['categories']);
        _showCategoryButtons(categories);
      } else {
        _showError('Không thể lấy danh mục: Lỗi server ${response.statusCode}');
      }
    } catch (e) {
      _showError('Lỗi kết nối: $e');
    }
  }

  void _showCategoryButtons(List<String> categories) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final categoryMessage = ChatMessageModel(
      message: 'Vui lòng chọn một danh mục:',
      isUser: false,
      timestamp: DateTime.now(),
      categories: categories,
    );
    chatProvider.addMessage(categoryMessage);
  }

  void _showError(String message) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final errorMessage = ChatMessageModel(
      message: message,
      isUser: false,
      timestamp: DateTime.now(),
    );
    chatProvider.addMessage(errorMessage);
  }

  void _showPriceRangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn khoảng giá'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Dưới 50.000đ'),
                onTap: () {
                  Navigator.of(context).pop();
                  _controller.text = "Tìm món ăn dưới 50.000đ";
                  sendMessage();
                },
              ),
              ListTile(
                title: const Text('50.000đ - 100.000đ'),
                onTap: () {
                  Navigator.of(context).pop();
                  _controller.text = "Tìm món ăn từ 50.000đ đến 100.000đ";
                  sendMessage();
                },
              ),
              ListTile(
                title: const Text('100.000đ - 200.000đ'),
                onTap: () {
                  Navigator.of(context).pop();
                  _controller.text = "Tìm món ăn từ 100.000đ đến 200.000đ";
                  sendMessage();
                },
              ),
              ListTile(
                title: const Text('Trên 200.000đ'),
                onTap: () {
                  Navigator.of(context).pop();
                  _controller.text = "Tìm món ăn trên 200.000đ";
                  sendMessage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendMessage(text);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
             appBar: AppBar(
         title: const Text('Chat AI'),
         actions: [
           IconButton(
             icon: const Icon(Icons.clear_all),
             onPressed: () {
               final chatProvider = Provider.of<ChatProvider>(context, listen: false);
               chatProvider.clearHistory();
             },
             tooltip: 'Xóa lịch sử',
           ),
         ],
       ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
                     return Column(
             children: [
               Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatProvider.messages[index];
                                         return ChatBubble(
                       message: msg.message,
                       isUser: msg.isUser,
                       timestamp: msg.timestamp,
                       categories: msg.categories,
                       status: msg.status,
                       onCategoryTap: (category) {
                         _controller.text = "Tìm món ăn trong danh mục $category";
                         sendMessage();
                       },
                     );
                  },
                ),
                             ),
               Column(
                 children: [
                   // Mũi tên để hiện/ẩn prompts
                   InkWell(
                     onTap: () {
                       setState(() {
                         _showPrompts = !_showPrompts;
                       });
                     },
                     child: Container(
                       padding: const EdgeInsets.all(8.0),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(
                             _showPrompts ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                             color: Colors.grey[600],
                             size: 20,
                           ),
                           const SizedBox(width: 8),
                           Text(
                             _showPrompts ? 'Ẩn gợi ý' : 'Hiện gợi ý',
                             style: TextStyle(
                               color: Colors.grey[600],
                               fontSize: 12,
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                   // Container prompts (chỉ hiện khi _showPrompts = true)
                   if (_showPrompts)
                     Container(
                       padding: const EdgeInsets.all(16.0),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             'Bạn có thể hỏi tôi:',
                             style: TextStyle(
                               fontWeight: FontWeight.bold,
                               fontSize: 16,
                               color: Colors.grey[700],
                             ),
                           ),
                           const SizedBox(height: 12),
                           ..._suggestedPrompts.map((prompt) => Padding(
                             padding: const EdgeInsets.only(bottom: 8.0),
                             child: InkWell(
                               onTap: () => _handlePromptTap(prompt),
                               child: Container(
                                 width: double.infinity,
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                   color: Colors.grey[50],
                                   borderRadius: BorderRadius.circular(8),
                                   border: Border.all(color: Colors.grey[300]!),
                                 ),
                                 child: Text(
                                   prompt,
                                   style: TextStyle(
                                     color: Colors.grey[700],
                                     fontSize: 14,
                                   ),
                                 ),
                               ),
                             ),
                           )).toList(),
                         ],
                       ),
                     ),
                 ],
                                               ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !chatProvider.isLoading,
                        decoration: InputDecoration(
                          hintText: chatProvider.isLoading ? 'Đang xử lý...' : 'Nhập tin nhắn...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onSubmitted: chatProvider.isLoading ? null : (_) => sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: chatProvider.isLoading ? null : sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}