const admin = require('firebase-admin');
const db = admin.firestore();

class ChatService {
  // Lấy lịch sử chat của user
  static async getChatHistory(userId) {
    try {
      const snapshot = await db
        .collection('chat_messages')
        .where('userId', '==', userId)
        .orderBy('timestamp', 'asc')
        .get();

      const messages = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        messages.push({
          id: doc.id,
          ...data,
          timestamp: data.timestamp.toDate().toISOString(),
        });
      });

      return messages;
    } catch (error) {
      console.error('Error getting chat history:', error);
      throw error;
    }
  }

  // Lưu tin nhắn mới
  static async saveMessage(messageData) {
    try {
      const { message, isUser, timestamp, userId, categories, orderId, status } = messageData;

      const messageDoc = {
        message,
        isUser,
        timestamp: admin.firestore.Timestamp.fromDate(new Date(timestamp)),
        userId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Thêm các trường tùy chọn nếu có
      if (categories) messageDoc.categories = categories;
      if (orderId) messageDoc.orderId = orderId;
      if (status) messageDoc.status = status;

      const docRef = await db.collection('chat_messages').add(messageDoc);
      return docRef.id;
    } catch (error) {
      console.error('Error saving message:', error);
      throw error;
    }
  }

  // Xóa lịch sử chat của user
  static async clearChatHistory(userId) {
    try {
      const snapshot = await db
        .collection('chat_messages')
        .where('userId', '==', userId)
        .get();

      const batch = db.batch();
      snapshot.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      return true;
    } catch (error) {
      console.error('Error clearing chat history:', error);
      throw error;
    }
  }

  // Lấy tin nhắn gần đây nhất của user
  static async getRecentMessages(userId, limit = 10) {
    try {
      const snapshot = await db
        .collection('chat_messages')
        .where('userId', '==', userId)
        .orderBy('timestamp', 'desc')
        .limit(limit)
        .get();

      const messages = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        messages.push({
          id: doc.id,
          ...data,
          timestamp: data.timestamp.toDate().toISOString(),
        });
      });

      return messages.reverse(); // Đảo ngược để có thứ tự thời gian tăng dần
    } catch (error) {
      console.error('Error getting recent messages:', error);
      throw error;
    }
  }

  // Đếm số tin nhắn của user
  static async getMessageCount(userId) {
    try {
      const snapshot = await db
        .collection('chat_messages')
        .where('userId', '==', userId)
        .count()
        .get();

      return snapshot.data().count;
    } catch (error) {
      console.error('Error getting message count:', error);
      throw error;
    }
  }
}

module.exports = ChatService; 