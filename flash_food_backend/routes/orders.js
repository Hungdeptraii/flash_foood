const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticateToken, requireAdmin, requireStaff } = require('../middleware/auth');
const axios = require('axios');
const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');
const NotificationService = require('../services/notificationService');
const { sendFCMNotificationToUser } = require('../utils/fcmUtils');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

// Tạo đơn hàng mới
router.post('/create', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { items, address, note, payment_method } = req.body; // Thêm payment_method
  console.log('Order request:', req.body); // Thêm log debug
  try {
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'No items in order' });
    }
    // Kiểm tra payment_method hợp lệ
    if (!payment_method || !['cod', 'qr'].includes(payment_method)) {
      return res.status(400).json({ error: 'Vui lòng chọn phương thức thanh toán hợp lệ (cod hoặc qr)!' });
    }
    // Tính tổng tiền
    let total = 0;
    for (const item of items) {
      const [foods] = await db.query('SELECT price FROM foods WHERE id = ?', [item.food_id]);
      if (foods.length === 0) return res.status(400).json({ error: 'Food not found' });
      total += foods[0].price * item.quantity;
    }
    // Tạo đơn hàng
    const [orderResult] = await db.query(
      'INSERT INTO orders (user_id, total, status, address, note, payment_method) VALUES (?, ?, ?, ?, ?, ?)',
      [userId, total, 'pending', address || '', note || '', payment_method]
    );
    const orderId = orderResult.insertId;
    // Thêm từng món vào order_items
    for (const item of items) {
      const [foods] = await db.query('SELECT price FROM foods WHERE id = ?', [item.food_id]);
      await db.query(
        'INSERT INTO order_items (order_id, food_id, quantity, price) VALUES (?, ?, ?, ?)',
        [orderId, item.food_id, item.quantity, foods[0].price]
      );
    }
    // Gửi FCM notification cho user
    await sendFCMNotificationToUser(userId, {
      title: 'Đặt hàng thành công',
      body: 'Đơn hàng của bạn đã được đặt thành công!'
    }, {
      type: 'order_created',
      orderId: orderId.toString(),
      userId: userId.toString(),
      status: 'pending'
    });

    // Lưu thông báo vào Firebase Database
    await NotificationService.saveNotification({
      title: 'Đặt hàng thành công',
      body: 'Đơn hàng của bạn đã được đặt thành công!',
      userId: userId,
      type: 'order_created',
      orderId: orderId,
      status: 'pending'
    });
    res.json({ success: true, order_id: orderId });
  } catch (err) {
    console.log('Order error:', err); // Thêm log debug
    res.status(500).json({ error: err.message });
  }
});

// Lấy danh sách đơn hàng (có thể lọc theo status)
router.get('/', authenticateToken, async (req, res) => {
  try {
    const status = req.query.status;
    const user = req.user; // lấy từ middleware authenticateToken
    const onlyMyOrders = req.query.my === '1';
    let query = `SELECT o.id, o.user_id, o.total, o.status, o.created_at, o.confirmed_at, o.cancel_reason, o.address, o.note, o.payment_method, u.username as customer_name, u.full_name, u.phone
                 FROM orders o
                 JOIN users u ON o.user_id = u.id`;
    let params = [];

    // Nếu là user thường, chỉ cho xem đơn của chính mình
    if (user.role === 'user' || onlyMyOrders) {
      query += ' WHERE o.user_id = ?';
      params.push(user.id);
      if (status) {
        query += ' AND o.status = ?';
        params.push(status);
      }
    } else {
      // admin/staff có thể lọc theo status
      if (status) {
        query += ' WHERE o.status = ?';
        params.push(status);
      }
    }

    const [orders] = await db.query(query, params);

    // Lấy items cho từng order
    for (let order of orders) {
      const [items] = await db.query(
        `SELECT oi.quantity, oi.price, f.name as food_name
         FROM order_items oi
         JOIN foods f ON oi.food_id = f.id
         WHERE oi.order_id = ?`,
        [order.id]
      );
      order.items = items;
    }

    res.json({ orders });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Xác nhận đơn hàng (staff)
router.post('/:id/confirm', authenticateToken, requireStaff, async (req, res) => {
  const orderId = req.params.id;
  try {
    // Cập nhật trạng thái và giờ xác nhận
    await db.query('UPDATE orders SET status = ?, confirmed_at = NOW() WHERE id = ?', ['confirmed', orderId]);
    // Lấy user_id của đơn hàng
    const [[orderInfo]] = await db.query('SELECT user_id FROM orders WHERE id = ?', [orderId]);
    if (orderInfo) {
      // Gửi FCM notification cho user
      await sendFCMNotificationToUser(orderInfo.user_id, {
        title: 'Đơn hàng đã được xác nhận',
        body: 'Đơn hàng của bạn đã được xác nhận và đang được xử lý.'
      }, {
        type: 'order_confirmed',
        orderId: orderId.toString(),
        userId: orderInfo.user_id.toString(),
        status: 'confirmed'
      });

      // Lưu thông báo vào Firebase Database
      await NotificationService.saveNotification({
        title: 'Đơn hàng đã được xác nhận',
        body: 'Đơn hàng của bạn đã được xác nhận và đang được xử lý.',
        userId: orderInfo.user_id,
        type: 'order_confirmed',
        orderId: orderId,
        status: 'confirmed'
      });
    }
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Từ chối/hủy đơn hàng (staff)
router.post('/:id/cancel', authenticateToken, requireStaff, async (req, res) => {
  const orderId = req.params.id;
  const { reason } = req.body;
  try {
    // Lấy user_id của đơn hàng
    const [[orderInfo]] = await db.query('SELECT user_id FROM orders WHERE id = ?', [orderId]);
    if (!orderInfo) return res.status(404).json({ error: 'Order not found' });
    // Hủy đơn hàng
    await db.query('UPDATE orders SET status = ?, cancel_reason = ? WHERE id = ?', ['cancelled', reason, orderId]);
    // Gửi FCM notification cho user
    await sendFCMNotificationToUser(orderInfo.user_id, {
      title: 'Đơn hàng bị từ chối',
      body: reason ? `Lý do: ${reason}` : 'Đơn hàng của bạn đã bị từ chối.'
    }, {
      type: 'order_cancelled',
      orderId: orderId.toString(),
      userId: orderInfo.user_id.toString(),
      status: 'cancelled',
      reason: reason || 'Không có lý do'
    });

    // Lưu thông báo vào Firebase Database
    await NotificationService.saveNotification({
      title: 'Đơn hàng bị từ chối',
      body: reason ? `Lý do: ${reason}` : 'Đơn hàng của bạn đã bị từ chối.',
      userId: orderInfo.user_id,
      type: 'order_cancelled',
      orderId: orderId,
      status: 'cancelled',
      reason: reason || 'Không có lý do'
    });
    res.json({ success: true, message: 'Đơn hàng đã bị admin từ chối.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Endpoint để khách hàng hủy đơn hàng (chuyển sang trạng thái cancelled)
router.post('/:id/cancel-by-user', authenticateToken, async (req, res) => {
  const orderId = req.params.id;
  const userId = req.user.id;
  
  try {
    // Kiểm tra đơn hàng có tồn tại không
    const [orders] = await db.query('SELECT status, user_id FROM orders WHERE id = ?', [orderId]);
    if (!orders.length) return res.status(404).json({ message: 'Order not found' });
    
    const order = orders[0];
    const status = order.status;
    
    // Chỉ cho phép khách hàng hủy đơn của chính mình khi trạng thái là 'pending'
    if (order.user_id !== userId) {
      return res.status(403).json({ message: 'Không có quyền hủy đơn hàng này' });
    }
    if (status !== 'pending') {
      return res.status(400).json({ message: 'Chỉ được hủy đơn hàng khi trạng thái là pending' });
    }
    
    // Cập nhật trạng thái thành cancelled
    await db.query('UPDATE orders SET status = ?, cancel_reason = ? WHERE id = ?', ['cancelled', 'Khách hàng hủy đơn', orderId]);
    
    res.json({ message: 'Đã hủy đơn hàng thành công' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err });
  }
});

// Thêm endpoint xóa đơn hàng
router.delete('/:id', authenticateToken, async (req, res) => {
  const orderId = req.params.id;
  const userId = req.user.id;
  // const userRole = req.user.role; // Không cần phân biệt role nữa
  
  try {
    // Kiểm tra đơn hàng có tồn tại không
    const [orders] = await db.query('SELECT status, user_id FROM orders WHERE id = ?', [orderId]);
    if (!orders.length) return res.status(404).json({ message: 'Order not found' });
    
    const order = orders[0];
    const status = order.status;
    
    // Bất kỳ ai cũng chỉ được xóa đơn của chính mình khi trạng thái là 'pending' hoặc 'cancelled'
    if (order.user_id !== userId) {
      return res.status(403).json({ message: 'Không có quyền xóa đơn hàng này' });
    }
    if (status !== 'pending' && status !== 'cancelled') {
      return res.status(400).json({ message: 'Chỉ được xóa đơn hàng khi trạng thái là pending hoặc cancelled' });
    }
    // Xóa order_items trước (mặc dù có CASCADE, nhưng để đảm bảo)
    await db.query('DELETE FROM order_items WHERE order_id = ?', [orderId]);
    // Sau đó xóa order
    await db.query('DELETE FROM orders WHERE id = ?', [orderId]);
    res.json({ message: 'Đã xóa đơn hàng thành công' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err });
  }
});

// API doanh thu: chỉ admin mới được truy cập
router.get('/revenue', authenticateToken, requireAdmin, async (req, res) => {
  const { from, to } = req.query;
  try {
    let query = `SELECT SUM(total) as total_revenue, COUNT(*) as total_orders FROM orders WHERE status = 'confirmed'`;
    let params = [];
    if (from) {
      query += ' AND confirmed_at >= ?';
      params.push(from);
    }
    if (to) {
      query += ' AND confirmed_at <= ?';
      params.push(to);
    }
    const [result] = await db.query(query, params);
    res.json({
      total_revenue: result[0].total_revenue || 0,
      total_orders: result[0].total_orders || 0
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// API doanh thu theo món ăn: chỉ admin mới được truy cập
router.get('/revenue-by-food', authenticateToken, requireAdmin, async (req, res) => {
  const { from, to } = req.query;
  try {
    let query = `SELECT f.id as food_id, f.name as food_name, SUM(oi.quantity) as quantity, SUM(oi.price * oi.quantity) as revenue
                 FROM order_items oi
                 JOIN orders o ON oi.order_id = o.id
                 JOIN foods f ON oi.food_id = f.id
                 WHERE o.status = 'confirmed'`;
    let params = [];
    if (from) {
      query += ' AND o.confirmed_at >= ?';
      params.push(from);
    }
    if (to) {
      query += ' AND o.confirmed_at <= ?';
      params.push(to);
    }
    query += ' GROUP BY f.id, f.name';
    const [foods] = await db.query(query, params);
    const totalRevenue = foods.reduce((sum, item) => sum + (item.revenue || 0), 0);
    res.json({
      total_revenue: totalRevenue,
      foods
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router; 