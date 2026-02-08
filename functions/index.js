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
 * Sends to pharmacy_requests topic only (optimized for scalability)
 */
exports.notifyPharmaciesOnNewRequest = onDocumentCreated(
  'medicine_requests/{requestId}',
  async (event) => {
    try {
      const requestData = event.data.data();
      const requestId = event.params.requestId;

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

      // Send to topic only (efficient for all pharmacies)
      const topicMessage = {...message, topic: 'pharmacy_requests'};
      const topicResponse = await admin.messaging().send(topicMessage);
      console.log('Notification sent to pharmacy topic:', topicResponse);

      // Update request with notification sent status
      await event.data.ref.update({
        notificationSent: true,
        notificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true, 
        topicResponse: topicResponse,
        message: 'Notification sent to topic successfully',
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

      // Update booking with notification sent status
      await event.data.ref.update({
        notificationSent: true,
        notificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true, 
        topicResponse: topicResponse,
        message: 'Notification sent to clinic topic successfully',
      };
    } catch (error) {
      console.error('Error sending booking notification:', error);
      return {success: false, error: error.message};
    }
  }
);

/**
 * Send notification to ALL users when a new pharmacy offer is added
 * Triggers on: offers collection onCreate
 * Sends to all_users topic (using Firebase Cloud Messaging Topics - NO user reads!)
 */
exports.notifyUsersOnNewOffer = onDocumentCreated(
  'offers/{offerId}',
  async (event) => {
    try {
      const offerData = event.data.data();
      const offerId = event.params.offerId;

      // Get pharmacy info
      const pharmacyDoc = await admin.firestore()
        .collection('pharmacies')
        .doc(offerData.pharmacyId)
        .get();

      if (!pharmacyDoc.exists) {
        console.log('Pharmacy not found:', offerData.pharmacyId);
        return null;
      }

      const pharmacyData = pharmacyDoc.data();

      // Prepare notification payload for general offers (not medicine-specific)
      const message = {
        notification: {
          title: `عرض جديد من ${pharmacyData.name} 🎉`,
          body: offerData.title || offerData.description || 'عرض خاص للصيدلية',
        },
        data: {
          type: 'new_pharmacy_offer',
          offerId: offerId,
          pharmacyId: offerData.pharmacyId,
          pharmacyName: pharmacyData.name,
          title: offerData.title || '',
          description: offerData.description || '',
          notes: offerData.notes || '',
          imageUrl: (offerData.images && offerData.images.length > 0) ? offerData.images[0] : '',
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'medicine_offers',
            icon: 'ic_notification',
            color: '#FF9800',
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

      // Send to all_users topic (everyone gets pharmacy offers)
      const topicMessage = {...message, topic: 'all_users'};
      const topicResponse = await admin.messaging().send(topicMessage);
      console.log('Offer notification sent to all_users topic:', topicResponse);

      // Update offer with notification sent status
      await event.data.ref.update({
        notificationSent: true,
        notificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        topicResponse: topicResponse,
        message: 'Offer notification sent to all users successfully',
      };
    } catch (error) {
      console.error('Error sending offer notification:', error);
      return {success: false, error: error.message};
    }
  }
);
