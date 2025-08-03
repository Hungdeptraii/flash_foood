const express = require('express');
const pool = require('../db');
const router = express.Router();

// Lấy danh sách món ăn
router.get('/', async (req, res) => {
  try {
    const [foods] = await pool.query('SELECT * FROM foods');
    res.json(foods);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Lỗi server' });
  }
});

// Thêm món ăn
router.post('/', async (req, res) => {
  try {
    const { name, description, price, images, category } = req.body;
    if (!name || !price || !category) {
      return res.status(400).json({ error: 'Thiếu tên, giá hoặc category' });
    }
    const imagesStr = Array.isArray(images) ? images.join(',') : (images || '');
    const [result] = await pool.query(
      'INSERT INTO foods (name, description, price, images, category) VALUES (?, ?, ?, ?, ?)',
      [name, description, price, imagesStr, category]
    );
    const [food] = await pool.query('SELECT * FROM foods WHERE id = ?', [result.insertId]);
    res.status(201).json(food[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Lỗi server' });
  }
});

// Xóa món ăn
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await pool.query('DELETE FROM foods WHERE id = ?', [id]);
    res.json({ message: 'Đã xóa món ăn' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Lỗi server' });
  }
});

// Sửa món ăn
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, price, images, category } = req.body;
    if (!name || !price || !category) {
      return res.status(400).json({ error: 'Thiếu tên, giá hoặc category' });
    }
    const imagesStr = Array.isArray(images) ? images.join(',') : (images || '');
    await pool.query(
      'UPDATE foods SET name = ?, description = ?, price = ?, images = ?, category = ? WHERE id = ?',
      [name, description, price, imagesStr, category, id]
    );
    const [food] = await pool.query('SELECT * FROM foods WHERE id = ?', [id]);
    res.json(food[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Lỗi server' });
  }
});

// Lấy danh sách danh mục món ăn (category)
router.get('/categories', async (req, res) => {
  try {
    const [categories] = await pool.query('SELECT DISTINCT category FROM foods');
    res.json(categories.map(c => c.category));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Lỗi server' });
  }
});

// Lấy món ăn theo danh mục
router.get('/by-category/:category', async (req, res) => {
  try {
    const { category } = req.params;
    const [foods] = await pool.query('SELECT * FROM foods WHERE category = ?', [category]);
    res.json(foods);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Lỗi server' });
  }
});

module.exports = router; 