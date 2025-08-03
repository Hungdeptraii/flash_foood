require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');
const mysql = require('mysql2/promise');

// Khởi tạo Gemini AI
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Khởi tạo pool MySQL
const db = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
});

/**
 * Hàm lấy danh mục món ăn từ database
 * @returns {Promise<Array>} - Danh sách các danh mục
 */
async function getFoodCategoriesFromDB() {
  try {
    const [rows] = await db.query('SELECT DISTINCT category FROM foods WHERE category IS NOT NULL AND category != "" ORDER BY category');
    return rows.map(row => row.category);
  } catch (error) {
    console.error('Database error when getting categories:', error);
    // Trả về danh sách mặc định nếu có lỗi
    return ['Burger', 'Pizza', 'Taco', 'Cơm', 'Phở', 'Bún', 'Mì', 'Gỏi', 'Bánh Mì', 'Súp'];
  }
}

/**
 * Hàm xử lý yêu cầu AI
 * @param {string} prompt - Câu lệnh prompt từ client
 * @returns {Promise<string>} - Kết quả trả về từ Gemini
 */
async function askGeminiAboutFoods(prompt) {
  if (!prompt) throw new Error('Missing prompt');

  try {
    // Kiểm tra API key
    if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY === 'your_gemini_api_key_here') {
      throw new Error('Gemini API key chưa được cấu hình. Vui lòng thêm GEMINI_API_KEY vào file .env');
    }

    // Lấy danh sách món ăn từ database
    let foodList = '';
    try {
      const [rows] = await db.query('SELECT name, description, price FROM foods LIMIT 20');
      foodList = rows.map(food =>
        `- ${food.name}: ${food.description || 'Không có mô tả'} (Giá: ${food.price}đ)`
      ).join('\n');
    } catch (dbError) {
      console.error('Database error:', dbError);
      foodList = 'Không thể lấy danh sách món ăn từ database.';
    }

    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const systemPrompt = `Bạn là một trợ lý AI chuyên về ẩm thực và nhà hàng. 
    Hãy trả lời câu hỏi của khách hàng một cách thân thiện và hữu ích.
    Nếu có danh sách món ăn, hãy sử dụng thông tin đó để đưa ra gợi ý phù hợp.
    
    **Hướng dẫn format trả lời:**
    - Sử dụng emoji để tạo cảm giác thân thiện
    - Format giá tiền rõ ràng với đơn vị VNĐ
    - Sử dụng bullet points (•) thay vì dấu gạch đầu dòng
    - Tạo khoảng cách giữa các phần để dễ đọc
    - Sử dụng bold (**) cho tên món ăn và giá
    - Thêm mô tả ngắn gọn cho mỗi món
    
    Danh sách món ăn hiện có:
    ${foodList}
    
    Câu hỏi của khách hàng: ${prompt}
    
    **Lưu ý:** Hãy trả lời bằng tiếng Việt và format đẹp, dễ đọc.`;

    const result = await model.generateContent(systemPrompt);
    const response = await result.response;
    return response.text();
  } catch (error) {
    console.error('AI processing error:', error);
    if (error.message.includes('API key')) {
      throw new Error('Lỗi cấu hình: ' + error.message);
    } else if (error.message.includes('quota')) {
      throw new Error('Đã hết quota API. Vui lòng kiểm tra tài khoản Gemini.');
    } else {
      throw new Error('Lỗi xử lý AI: ' + error.message);
    }
  }
}

module.exports = { askGeminiAboutFoods, getFoodCategoriesFromDB };
