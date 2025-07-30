const admin = require('firebase-admin');
const db = require('../db');

/**
 * Send FCM notification with proper error handling
 * @param {string} token - FCM token
 * @param {Object} notification - Notification object
 * @param {Object} data - Data payload
 * @param {number} userId - User ID for logging and token cleanup
 * @returns {Promise<boolean>} - Returns true if sent successfully, false if failed
 */
async function sendFCMNotification(token, notification, data, userId) {
  try {
    await admin.messaging().send({
      token: token,
      notification: notification,
      data: data
    });
    console.log(`FCM notification sent successfully to user ${userId}`);
    return true;
  } catch (fcmError) {
    // Handle FCM errors - token might be invalid
    if (fcmError.code === 'messaging/registration-token-not-registered' || 
        fcmError.code === 'messaging/invalid-registration-token' ||
        fcmError.code === 'messaging/registration-token-not-registered') {
      console.log(`Invalid FCM token for user ${userId}, removing from database`);
      // Remove invalid token from database
      await db.query('UPDATE users SET fcm_token = NULL WHERE id = ?', [userId]);
    } else {
      console.log('FCM notification error:', fcmError);
    }
    return false;
  }
}

/**
 * Send FCM notification if user has valid token
 * @param {number} userId - User ID
 * @param {Object} notification - Notification object
 * @param {Object} data - Data payload
 * @returns {Promise<boolean>} - Returns true if sent successfully, false if failed or no token
 */
async function sendFCMNotificationToUser(userId, notification, data) {
  try {
    const [[userInfo]] = await db.query('SELECT fcm_token FROM users WHERE id = ?', [userId]);
    if (userInfo && userInfo.fcm_token) {
      return await sendFCMNotification(userInfo.fcm_token, notification, data, userId);
    }
    return false;
  } catch (error) {
    console.error('Error getting user FCM token:', error);
    return false;
  }
}

module.exports = {
  sendFCMNotification,
  sendFCMNotificationToUser
}; 