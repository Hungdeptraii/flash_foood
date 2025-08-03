const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const ChatService = require('../services/chatService');

// Lấy lịch sử chat của user
router.get('/history/:userId', authenticateToken, async (req, res) => {
  try {
    const userId = req.params.userId;
    
    // Kiểm tra quyền truy cập
    if (req.user.id.toString() !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Không có quyền truy cập' });
    }

    const messages = await ChatService.getChatHistory(userId);
    res.json({ messages });
  } catch (error) {
    console.error('Error getting chat history:', error);
    res.status(500).json({ error: 'Lỗi khi lấy lịch sử chat' });
  }
});

// Lưu tin nhắn mới
router.post('/save', authenticateToken, async (req, res) => {
  try {
    const { message, isUser, timestamp, userId, categories, orderId, status } = req.body;
    
    if (!message || isUser === undefined || !timestamp || !userId) {
      return res.status(400).json({ error: 'Thiếu thông tin bắt buộc' });
    }

    // Kiểm tra quyền truy cập
    if (req.user.id.toString() !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Không có quyền truy cập' });
    }

    const messageId = await ChatService.saveMessage({
      message,
      isUser,
      timestamp,
      userId,
      categories,
      orderId,
      status,
    });

    res.json({ 
      message: 'Tin nhắn đã được lưu thành công',
      messageId 
    });
  } catch (error) {
    console.error('Error saving message:', error);
    res.status(500).json({ error: 'Lỗi khi lưu tin nhắn' });
  }
});

// Xóa lịch sử chat của user
router.delete('/history/:userId', authenticateToken, async (req, res) => {
  try {
    const userId = req.params.userId;
    
    // Kiểm tra quyền truy cập
    if (req.user.id.toString() !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Không có quyền truy cập' });
    }

    await ChatService.clearChatHistory(userId);
    res.json({ message: 'Đã xóa lịch sử chat' });
  } catch (error) {
    console.error('Error clearing chat history:', error);
    res.status(500).json({ error: 'Lỗi khi xóa lịch sử chat' });
  }
});

module.exports = router; 