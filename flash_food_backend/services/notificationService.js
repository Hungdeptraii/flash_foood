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

  // Tạo thông báo đặt hàng thành công
  static async createOrderSuccessNotification({
    userId,
    orderId,
    orderTotal,
    orderItems = []
  }) {
    try {
      const title = 'Đặt hàng thành công! 🎉';
      const body = `Đơn hàng #${orderId} của bạn đã được đặt thành công với tổng tiền ${orderTotal} VND. Chúng tôi sẽ xử lý đơn hàng của bạn sớm nhất!`;
      
      const notificationData = {
        title: title,
        body: body,
        userId: userId,
        type: 'order_success',
        orderId: orderId,
        status: 'pending',
        orderTotal: orderTotal,
        orderItems: orderItems,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      const docRef = await db.collection('notifications').add(notificationData);
      console.log('Order success notification saved with ID:', docRef.id);
      return docRef.id;
    } catch (error) {
      console.error('Error creating order success notification:', error);
      throw error;
    }
  }

  // Tạo thông báo trạng thái đơn hàng
  static async createOrderStatusNotification({
    userId,
    orderId,
    status,
    message
  }) {
    try {
      let title = '';
      let body = '';
      
      switch (status) {
        case 'confirmed':
          title = 'Đơn hàng đã được xác nhận! ✅';
          body = `Đơn hàng #${orderId} đã được xác nhận và đang được chuẩn bị.`;
          break;
        case 'preparing':
          title = 'Đơn hàng đang được chuẩn bị! 👨‍🍳';
          body = `Đơn hàng #${orderId} đang được chuẩn bị. Sẽ sẵn sàng sớm!`;
          break;
        case 'ready':
          title = 'Đơn hàng đã sẵn sàng! 🚚';
          body = `Đơn hàng #${orderId} đã sẵn sàng và đang được giao đến bạn.`;
          break;
        case 'delivered':
          title = 'Đơn hàng đã được giao! 🎉';
          body = `Đơn hàng #${orderId} đã được giao thành công. Cảm ơn bạn đã sử dụng dịch vụ của chúng tôi!`;
          break;
        case 'cancelled':
          title = 'Đơn hàng đã bị hủy! ❌';
          body = `Đơn hàng #${orderId} đã bị hủy. ${message || 'Vui lòng liên hệ với chúng tôi nếu có thắc mắc.'}`;
          break;
        default:
          title = 'Cập nhật đơn hàng';
          body = message || `Đơn hàng #${orderId} có cập nhật mới.`;
      }

      const notificationData = {
        title: title,
        body: body,
        userId: userId,
        type: 'order_status',
        orderId: orderId,
        status: status,
        message: message,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      const docRef = await db.collection('notifications').add(notificationData);
      console.log('Order status notification saved with ID:', docRef.id);
      return docRef.id;
    } catch (error) {
      console.error('Error creating order status notification:', error);
      throw error;
    }
  }

  // Lấy danh sách thông báo của user
  static async getUserNotifications(userId) {
    try {
      // Chỉ filter theo userId, không orderBy để tránh cần index phức tạp
      const snapshot = await db.collection('notifications')
        .where('userId', '==', userId)
        .get();

      const notifications = [];
      snapshot.forEach((doc) => {
        notifications.push({
          id: doc.id,
          ...doc.data()
        });
      });

      // Sort trong JavaScript thay vì trong query
      notifications.sort((a, b) => {
        const dateA = a.createdAt ? new Date(a.createdAt.toDate()) : new Date(0);
        const dateB = b.createdAt ? new Date(b.createdAt.toDate()) : new Date(0);
        return dateB - dateA; // Descending order
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