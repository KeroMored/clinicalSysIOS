/**
 * Cloud Functions for sending FCM notifications
 * Using 2nd Gen Functions for better performance and reliability
 * 
 * Setup Instructions:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Login: firebase login
 * 3. Initialize functions: firebase init functions
 * 4. Deploy: firebase deploy --only functions
 */

const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {onRequest} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
const {setGlobalOptions} = require('firebase-functions/v2');

admin.initializeApp();

// Set global options for all functions
setGlobalOptions({
  region: 'us-central1',
  maxInstances: 10,
});

/**
 * Send notification to all pharmacies when a new medicine request is created
 * Triggers on: medicine_requests collection onCreate
 * Sends to ALL users with emails in ANY pharmacy's authEmails array
 */
exports.notifyPharmaciesOnNewRequest = onDocumentCreated(
  'medicine_requests/{requestId}',
  async (event) => {
    try {
      const requestData = event.data.data();
      const requestId = event.params.requestId;

      // Get all approved pharmacies
      const pharmaciesSnapshot = await admin.firestore()
        .collection('pharmacies')
        .where('status', '==', 'approved')
        .get();

      if (pharmaciesSnapshot.empty) {
        console.log('No approved pharmacies found');
        return null;
      }

      // Collect all unique authEmails from all pharmacies
      const allAuthEmails = new Set();
      pharmaciesSnapshot.forEach((doc) => {
        const pharmacyData = doc.data();
        const authEmails = pharmacyData.authEmails || [];
        authEmails.forEach(email => allAuthEmails.add(email));
      });

      const authEmailsArray = Array.from(allAuthEmails);
      
      if (authEmailsArray.length === 0) {
        console.log('No authEmails found in pharmacies');
        return null;
      }

      // Prepare notification payload
      const message = {
        notification: {
          title: 'طلب دواء جديد 💊',
          body: `${requestData.userName} يطلب ${requestData.medicineName} - الكمية: ${requestData.quantity} علبة`,
        },
        data: {
          type: 'new_medicine_request',
          requestId: requestId,
          medicineName: requestData.medicineName,
          quantity: requestData.quantity.toString(),
          userName: requestData.userName,
          phoneNumber: requestData.phoneNumber,
          whatsappNumber: requestData.whatsappNumber || '',
          imageUrl: requestData.imageUrl || '',
          notes: requestData.notes || '',
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'medicine_requests',
            icon: 'ic_notification',
            color: '#9C27B0',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // Send to topic (for backwards compatibility)
      const topicMessage = {...message, topic: 'pharmacy_requests'};
      const topicResponse = await admin.messaging().send(topicMessage);
      console.log('Notification sent to pharmacy topic:', topicResponse);

      // Send to ALL users whose emails are in authEmails
      // We need to batch this if there are many emails (Firestore 'in' query limit is 30)
      const sendPromises = [];
      const batchSize = 30;
      
      for (let i = 0; i < authEmailsArray.length; i += batchSize) {
        const emailBatch = authEmailsArray.slice(i, i + batchSize);
        
        const usersSnapshot = await admin.firestore()
          .collection('users')
          .where('email', 'in', emailBatch)
          .get();

        usersSnapshot.forEach((userDoc) => {
          const userData = userDoc.data();
          if (userData.fcmToken) {
            const tokenMessage = {...message};
            delete tokenMessage.topic;
            tokenMessage.token = userData.fcmToken;
            
            sendPromises.push(
              admin.messaging().send(tokenMessage)
                .then(() => {
                  console.log(`Notification sent to pharmacy user: ${userData.email}`);
                  return {success: true, email: userData.email};
                })
                .catch((error) => {
                  console.log(`Failed to send to ${userData.email}:`, error.message);
                  return {success: false, email: userData.email, error: error.message};
                })
            );
          } else {
            console.log(`No FCM token for pharmacy user: ${userData.email}`);
          }
        });
      }

      const results = await Promise.all(sendPromises);
      console.log(`Sent notifications to ${results.filter(r => r.success).length}/${authEmailsArray.length} pharmacy users`);

      // Update request with notification sent status
      await event.data.ref.update({
        notificationSent: true,
        notificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
        notificationSentToEmails: authEmailsArray,
      });

      return {
        success: true, 
        topicResponse: topicResponse,
        userResults: results,
        totalEmails: authEmailsArray.length,
        successCount: results.filter(r => r.success).length,
      };
    } catch (error) {
      console.error('Error sending notification:', error);
      return {success: false, error: error.message};
    }
  }
);

/**
 * Alternative: Process notifications from pending_notifications collection
 * This is useful if you want to queue notifications
 */
exports.processPendingNotifications = onDocumentCreated(
  'pending_notifications/{notificationId}',
  async (event) => {
    try {
      const notificationData = event.data.data();
      const snap = event.data;

      if (notificationData.sent) {
        console.log('Notification already sent');
        return null;
      }

      const message = {
        notification: {
          title: notificationData.title,
          body: notificationData.body,
        },
        data: notificationData.data || {},
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
          },
        },
        topic: notificationData.topic,
      };

      // Send to topic
      const response = await admin.messaging().send(message);

      // Mark as sent
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response,
      });

      console.log('Pending notification sent:', response);
      return {success: true};
    } catch (error) {
      console.error('Error processing pending notification:', error);

      // Log error in document
      await event.data.ref.update({
        error: error.message,
        errorAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {success: false, error: error.message};
    }
  }
);

/**
 * Test function to send a test notification
 * Call via HTTP: https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/sendTestNotification
 */
exports.sendTestNotification = onRequest(async (req, res) => {
  try {
    const message = {
      notification: {
        title: 'اختبار الإشعارات 🔔',
        body: 'هذا إشعار تجريبي للصيدليات',
      },
      data: {
        type: 'test',
        timestamp: Date.now().toString(),
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
        },
      },
      topic: 'pharmacy_requests',
    };

    const response = await admin.messaging().send(message);

    res.json({
      success: true,
      messageId: response,
      message: 'Test notification sent successfully',
    });
  } catch (error) {
    console.error('Error sending test notification:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Clean up old completed/cancelled requests (optional)
 * Runs daily at midnight Cairo time
 */
exports.cleanupOldRequests = onSchedule(
  {
    schedule: '0 0 * * *',
    timeZone: 'Africa/Cairo',
  },
  async (event) => {
    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const snapshot = await admin
        .firestore()
        .collection('medicine_requests')
        .where('status', 'in', ['completed', 'cancelled'])
        .where('createdAt', '<', thirtyDaysAgo)
        .get();

      const batch = admin.firestore().batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Cleaned up ${snapshot.size} old requests`);

      return {success: true, deletedCount: snapshot.size};
    } catch (error) {
      console.error('Error cleaning up old requests:', error);
      return {success: false, error: error.message};
    }
  }
);

/**
 * Send notification to clinic when a new online booking is created
 * Triggers on: bookings collection onCreate
 * Sends to ALL users with emails in clinic's authEmails array
 */
exports.notifyClinicOnNewBooking = onDocumentCreated(
  'bookings/{bookingId}',
  async (event) => {
    try {
      const bookingData = event.data.data();
      const bookingId = event.params.bookingId;
      const clinicId = bookingData.clinicId;

      if (!clinicId) {
        console.log('No clinicId in booking, skipping notification');
        return null;
      }

      // تحقق: إرسال notification فقط للحجوزات الأونلاين
      if (bookingData.isOnlineBooking !== true) {
        console.log('Booking is not online, skipping notification');
        return null;
      }

      // Get clinic data to find authEmails
      const clinicDoc = await admin.firestore().collection('clinics').doc(clinicId).get();
      
      if (!clinicDoc.exists) {
        console.log('Clinic not found:', clinicId);
        return null;
      }

      const clinicData = clinicDoc.data();
      const authEmails = clinicData.authEmails || [];
      
      if (authEmails.length === 0) {
        console.log('No authEmails found for clinic:', clinicId);
        return null;
      }

      // Prepare notification payload
      const message = {
        notification: {
          title: 'حجز جديد أونلاين 📅',
          body: `${bookingData.patientName} حجز موعد - رقم الحجز: ${bookingData.bookingNumber}`,
        },
        data: {
          type: 'new_booking',
          bookingId: bookingId,
          clinicId: clinicId,
          patientName: bookingData.patientName || '',
          patientPhone: bookingData.patientPhone || '',
          bookingNumber: (bookingData.bookingNumber || 0).toString(),
          doctorName: bookingData.doctorName || '',
          notes: bookingData.notes || '',
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'clinic_bookings',
            icon: 'ic_notification',
            color: '#3B82F6',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // Send to clinic-specific topic
      const clinicTopic = `clinic_${clinicId}`;
      const topicMessage = {...message, topic: clinicTopic};
      
      const topicResponse = await admin.messaging().send(topicMessage);
      console.log('Booking notification sent to clinic topic:', clinicTopic, topicResponse);

      // Send to ALL users whose emails are in authEmails array
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('email', 'in', authEmails)
        .get();

      const sendPromises = [];
      
      usersSnapshot.forEach((userDoc) => {
        const userData = userDoc.data();
        if (userData.fcmToken) {
          const tokenMessage = {...message};
          delete tokenMessage.topic;
          tokenMessage.token = userData.fcmToken;
          
          sendPromises.push(
            admin.messaging().send(tokenMessage)
              .then(() => {
                console.log(`Notification sent to user: ${userData.email}`);
                return {success: true, email: userData.email};
              })
              .catch((error) => {
                console.log(`Failed to send to ${userData.email}:`, error.message);
                return {success: false, email: userData.email, error: error.message};
              })
          );
        } else {
          console.log(`No FCM token for user: ${userData.email}`);
        }
      });

      const results = await Promise.all(sendPromises);
      console.log(`Sent notifications to ${results.filter(r => r.success).length}/${authEmails.length} users`);

      // Update booking with notification sent status
      await event.data.ref.update({
        notificationSent: true,
        notificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
        notificationSentToEmails: authEmails,
      });

      return {
        success: true, 
        topicResponse: topicResponse,
        userResults: results,
        totalEmails: authEmails.length,
        successCount: results.filter(r => r.success).length,
      };
    } catch (error) {
      console.error('Error sending booking notification:', error);
      return {success: false, error: error.message};
    }
  }
);
