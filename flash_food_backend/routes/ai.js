const express = require('express');
const router = express.Router();
const { askGeminiAboutFoods, getFoodCategoriesFromDB } = require('../utils/ai');

router.post('/ask', async (req, res) => {
  const { question, prompt, userId } = req.body;
  const userQuestion = question || prompt;

  if (!userQuestion || typeof userQuestion !== 'string' || userQuestion.trim() === '') {
    return res.status(400).json({ error: 'Missing or invalid question/prompt' });
  }

  try {
    const answer = await askGeminiAboutFoods(userQuestion);
    
    // Lưu tin nhắn vào chat history nếu có userId
    if (userId) {
      const ChatService = require('../services/chatService');
      
      // Lưu tin nhắn user
      await ChatService.saveMessage({
        message: userQuestion,
        isUser: true,
        timestamp: new Date().toISOString(),
        userId: userId.toString(),
      });
      
      // Lưu phản hồi AI
      await ChatService.saveMessage({
        message: answer,
        isUser: false,
        timestamp: new Date().toISOString(),
        userId: userId.toString(),
      });
    }
    
    res.json({ answer });
  } catch (err) {
    console.error('AI error:', err);
    res.status(500).json({ error: 'Lỗi khi xử lý với Gemini' });
  }
});

router.get('/categories', async (req, res) => {
  try {
    // Assume you have a function to get categories from your database
    const categories = await getFoodCategoriesFromDB();
    res.json({ categories });
  } catch (err) {
    console.error('Category error:', err);
    res.status(500).json({ error: 'Lỗi khi lấy danh sách danh mục' });
  }
});


module.exports = router;
