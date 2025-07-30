const { sendFCMNotificationToUser } = require('./utils/fcmUtils');

// Test function to verify FCM error handling
async function testFCMErrorHandling() {
  console.log('Testing FCM error handling...');
  
  try {
    // Test with an invalid user ID (should not crash)
    const result = await sendFCMNotificationToUser(999999, {
      title: 'Test Notification',
      body: 'This is a test notification'
    }, {
      type: 'test',
      testId: '123'
    });
    
    console.log('Test completed successfully. Result:', result);
    console.log('FCM error handling is working correctly!');
  } catch (error) {
    console.error('Test failed:', error);
  }
}

// Run the test
testFCMErrorHandling(); 