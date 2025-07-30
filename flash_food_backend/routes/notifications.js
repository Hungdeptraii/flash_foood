const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const NotificationService = require('../services/notificationService');

// Lấy danh sách thông báo của user
router.get('/', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const notifications = await NotificationService.getUserNotifications(userId);
    res.json({ notifications });
  } catch (error) {
    console.error('Error getting notifications:', error);
    res.status(500).json({ error: 'Lỗi khi lấy danh sách thông báo' });
  }
});

// Đánh dấu thông báo đã đọc
router.put('/:id/read', authenticateToken, async (req, res) => {
  try {
    const notificationId = req.params.id;
    await NotificationService.markNotificationAsRead(notificationId);
    res.json({ message: 'Đã đánh dấu thông báo đã đọc' });
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ error: 'Lỗi khi đánh dấu thông báo đã đọc' });
  }
});

// Xóa thông báo
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const notificationId = req.params.id;
    await NotificationService.deleteNotification(notificationId);
    res.json({ message: 'Đã xóa thông báo' });
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ error: 'Lỗi khi xóa thông báo' });
  }
});

// Lấy số thông báo chưa đọc
router.get('/unread-count', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const count = await NotificationService.getUnreadNotificationCount(userId);
    res.json({ count });
  } catch (error) {
    console.error('Error getting unread notification count:', error);
    res.status(500).json({ error: 'Lỗi khi lấy số thông báo chưa đọc' });
  }
});

module.exports = router; 