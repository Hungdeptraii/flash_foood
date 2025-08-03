import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? categories;
  final Function(String)? onCategoryTap;
  final String? status;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.categories,
    this.onCategoryTap,
    this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status == 'loading')
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              )
            else
              _buildFormattedText(message, isUser),
            const SizedBox(height: 8),
            if (categories != null && categories!.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: categories!.map((category) => ActionChip(
                  label: Text(category),
                  onPressed: () {
                    if (onCategoryTap != null) {
                      onCategoryTap!(category);
                    }
                  },
                )).toList(),
              ),
            const SizedBox(height: 4),
            Text(
              '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isUser) {
    // Tách text thành các phần để xử lý bold và emoji
    List<Widget> widgets = [];
    List<String> parts = text.split('**');
    
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        if (i % 2 == 1) {
          // Bold text
          widgets.add(
            Text(
              parts[i],
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        } else {
          // Normal text
          widgets.add(
            Text(
              parts[i],
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
              ),
            ),
          );
        }
      }
    }
    
    return RichText(
      text: TextSpan(
        children: widgets.map((widget) {
          if (widget is Text) {
            return TextSpan(
              text: widget.data,
              style: widget.style,
            );
          }
          return TextSpan(text: '');
        }).toList(),
      ),
    );
  }
}