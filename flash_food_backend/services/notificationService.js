const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

// Khởi tạo Firebase Admin SDK nếu chưa có
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

class NotificationService {
  // Lưu thông báo vào Firebase Database
  static async saveNotification({
    title,
    body,
    userId,
    type,
    orderId,
    status,
    reason = null
  }) {
    try {
      const notificationData = {
        title: title,
        body: body,
        userId: userId,
        type: type,
        orderId: orderId,
        status: status,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        ...(reason && { reason: reason })
      };

      const docRef = await db.collection('notifications').add(notificationData);
      console.log('Notification saved to Firebase Database with ID:', docRef.id);
      return docRef.id;
    } catch (error) {
      console.error('Error saving notification to Firebase Database:', error);
      throw error;
    }
  }

  // Lấy danh sách thông báo của user
  static async getUserNotifications(userId) {
    try {
      const snapshot = await db.collection('notifications')
        .where('userId', '==', userId)
        .orderBy('createdAt', 'desc')
        .get();

      const notifications = [];
      snapshot.forEach((doc) => {
        notifications.push({
          id: doc.id,
          ...doc.data()
        });
      });

      return notifications;
    } catch (error) {
      console.error('Error getting user notifications:', error);
      return [];
    }
  }

  // Đánh dấu thông báo đã đọc
  static async markNotificationAsRead(notificationId) {
    try {
      await db.collection('notifications').doc(notificationId).update({
        read: true
      });
      console.log('Notification marked as read:', notificationId);
    } catch (error) {
      console.error('Error marking notification as read:', error);
      throw error;
    }
  }

  // Xóa thông báo
  static async deleteNotification(notificationId) {
    try {
      await db.collection('notifications').doc(notificationId).delete();
      console.log('Notification deleted:', notificationId);
    } catch (error) {
      console.error('Error deleting notification:', error);
      throw error;
    }
  }

  // Lấy số thông báo chưa đọc
  static async getUnreadNotificationCount(userId) {
    try {
      const snapshot = await db.collection('notifications')
        .where('userId', '==', userId)
        .where('read', '==', false)
        .get();

      return snapshot.size;
    } catch (error) {
      console.error('Error getting unread notification count:', error);
      return 0;
    }
  }
}

module.exports = NotificationService; 