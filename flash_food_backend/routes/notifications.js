const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const NotificationService = require('../services/notificationService');

// Lấy danh sách thông báo của user
router.get('/', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    // Convert userId sang string để đảm bảo khớp với Firebase
    const userIdString = userId.toString();

    const notifications = await NotificationService.getUserNotifications(userIdString);

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

    // Convert userId sang string để đảm bảo khớp với Firebase
    const userIdString = userId.toString();

    const count = await NotificationService.getUnreadNotificationCount(userIdString);

    res.json({ count });
  } catch (error) {
    console.error('Error getting unread notification count:', error);
    res.status(500).json({ error: 'Lỗi khi lấy số thông báo chưa đọc' });
  }
});

// Gửi thông báo mới
router.post('/send', authenticateToken, async (req, res) => {
  try {
    const { title, body, userId, type, orderId, status } = req.body;
    
    if (!title || !body || !userId) {
      return res.status(400).json({ error: 'Thiếu thông tin bắt buộc' });
    }

    const notificationId = await NotificationService.saveNotification({
      title,
      body,
      userId,
      type: type || 'general',
      orderId,
      status,
    });

    res.json({ 
      message: 'Thông báo đã được gửi thành công',
      notificationId 
    });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ error: 'Lỗi khi gửi thông báo' });
  }
});

// Tạo thông báo đặt hàng thành công
router.post('/order-success', authenticateToken, async (req, res) => {
  try {
    const { userId, orderId, orderTotal, orderItems } = req.body;
    
    if (!userId || !orderId || !orderTotal) {
      return res.status(400).json({ error: 'Thiếu thông tin bắt buộc' });
    }

    const notificationId = await NotificationService.createOrderSuccessNotification({
      userId,
      orderId,
      orderTotal,
      orderItems: orderItems || [],
    });

    res.json({ 
      message: 'Thông báo đặt hàng thành công đã được tạo',
      notificationId 
    });
  } catch (error) {
    console.error('Error creating order success notification:', error);
    res.status(500).json({ error: 'Lỗi khi tạo thông báo đặt hàng thành công' });
  }
});

// Tạo thông báo cập nhật trạng thái đơn hàng
router.post('/order-status', authenticateToken, async (req, res) => {
  try {
    const { userId, orderId, status, message } = req.body;
    
    if (!userId || !orderId || !status) {
      return res.status(400).json({ error: 'Thiếu thông tin bắt buộc' });
    }

    const notificationId = await NotificationService.createOrderStatusNotification({
      userId,
      orderId,
      status,
      message,
    });

    res.json({ 
      message: 'Thông báo cập nhật trạng thái đơn hàng đã được tạo',
      notificationId 
    });
  } catch (error) {
    console.error('Error creating order status notification:', error);
    res.status(500).json({ error: 'Lỗi khi tạo thông báo cập nhật trạng thái đơn hàng' });
  }
});

// Gửi thông báo cho nhiều user
router.post('/send-multiple', authenticateToken, async (req, res) => {
  try {
    const { title, body, userIds, type, orderId, status } = req.body;
    
    if (!title || !body || !userIds || !Array.isArray(userIds)) {
      return res.status(400).json({ error: 'Thiếu thông tin bắt buộc' });
    }

    const results = [];
    for (const userId of userIds) {
      try {
        const notificationId = await NotificationService.saveNotification({
          title,
          body,
          userId,
          type: type || 'general',
          orderId,
          status,
        });
        results.push({ userId, notificationId, success: true });
      } catch (error) {
        results.push({ userId, error: error.message, success: false });
      }
    }

    res.json({ 
      message: 'Thông báo đã được gửi',
      results 
    });
  } catch (error) {
    console.error('Error sending multiple notifications:', error);
    res.status(500).json({ error: 'Lỗi khi gửi thông báo' });
  }
});

module.exports = router; 