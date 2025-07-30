const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticateToken } = require('../middleware/auth');

// Lấy giỏ hàng hiện tại của user
router.get('/', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  try {
    // Tìm cart của user
    const [carts] = await db.query('SELECT * FROM carts WHERE user_id = ?', [userId]);
    if (carts.length === 0) return res.json({ items: [] });

    const cartId = carts[0].id;
    const [items] = await db.query(
      `SELECT ci.id, ci.food_id, ci.quantity, f.name, f.price, f.images
       FROM cart_items ci
       JOIN foods f ON ci.food_id = f.id
       WHERE ci.cart_id = ?`, [cartId]
    );
    res.json({ items });
  } catch (err) {
    console.error('Lỗi lấy giỏ hàng:', err);
    res.status(500).json({ error: err.message });
  }
});

// Thêm/cập nhật món vào giỏ
router.post('/add', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { food_id, quantity } = req.body;
  try {
    // Tìm hoặc tạo cart cho user
    let [carts] = await db.query('SELECT * FROM carts WHERE user_id = ?', [userId]);
    let cartId;
    if (carts.length === 0) {
      const [result] = await db.query('INSERT INTO carts (user_id) VALUES (?)', [userId]);
      cartId = result.insertId;
    } else {
      cartId = carts[0].id;
    }

    // Kiểm tra món đã có trong giỏ chưa
    let [items] = await db.query('SELECT * FROM cart_items WHERE cart_id = ? AND food_id = ?', [cartId, food_id]);
    if (items.length === 0) {
      // Nếu chưa có, thêm mới
      await db.query('INSERT INTO cart_items (cart_id, food_id, quantity) VALUES (?, ?, ?)', [cartId, food_id, quantity]);
    } else {
      // Nếu đã có, cộng dồn số lượng
      const newQuantity = items[0].quantity + quantity;
      await db.query('UPDATE cart_items SET quantity = ? WHERE id = ?', [newQuantity, items[0].id]);
    }
    res.json({ success: true });
  } catch (err) {
    console.error('Lỗi thêm/cập nhật món vào giỏ:', err);
    res.status(500).json({ error: err.message });
  }
});

// Xóa món khỏi giỏ
router.post('/remove', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { food_id } = req.body;
  try {
    const [carts] = await db.query('SELECT * FROM carts WHERE user_id = ?', [userId]);
    if (carts.length === 0) return res.json({ success: true });
    const cartId = carts[0].id;
    await db.query('DELETE FROM cart_items WHERE cart_id = ? AND food_id = ?', [cartId, food_id]);
    res.json({ success: true });
  } catch (err) {
    console.error('Lỗi xóa món khỏi giỏ:', err);
    res.status(500).json({ error: err.message });
  }
});

// Xóa toàn bộ giỏ hàng
router.post('/clear', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  try {
    const [carts] = await db.query('SELECT * FROM carts WHERE user_id = ?', [userId]);
    if (carts.length === 0) return res.json({ success: true });
    const cartId = carts[0].id;
    await db.query('DELETE FROM cart_items WHERE cart_id = ?', [cartId]);
    res.json({ success: true });
  } catch (err) {
    console.error('Lỗi xóa toàn bộ giỏ hàng:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router; 