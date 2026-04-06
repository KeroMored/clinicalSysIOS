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

      // Get first medicine from array for notification body
      const firstMedicine = requestData.medicines && requestData.medicines.length > 0 
        ? requestData.medicines[0] 
        : null;
      const medicineNames = requestData.medicines && requestData.medicines.length > 0
        ? requestData.medicines.map(m => m.medicineName || m.medicine_name || 'دواء').join(', ')
        : 'أدوية';
      const totalMedicines = requestData.medicines ? requestData.medicines.length : 0;

      // Prepare notification payload
      const message = {
        notification: {
          title: 'طلب دواء جديد 💊',
          body: totalMedicines > 1 
            ? `${requestData.userName} يطلب ${totalMedicines} أدوية`
            : `${requestData.userName} يطلب ${medicineNames}`,
        },
        data: {
          type: 'new_medicine_request',
          requestId: requestId,
          medicineNames: medicineNames,
          totalMedicines: totalMedicines.toString(),
          userName: requestData.userName || '',
          phoneNumber: requestData.phoneNumber || '',
          whatsappNumber: requestData.whatsappNumber || '',
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

      // Format appointment date and time
      const appointmentDate = bookingData.appointmentDate ? bookingData.appointmentDate.toDate() : new Date();
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const bookingDay = new Date(appointmentDate.getFullYear(), appointmentDate.getMonth(), appointmentDate.getDate());
      
      const dateStr = bookingDay.getTime() === today.getTime() 
        ? 'اليوم' 
        : `${appointmentDate.getDate()}/${appointmentDate.getMonth() + 1}/${appointmentDate.getFullYear()}`;
      
      const timeStr = `${appointmentDate.getHours().toString().padStart(2, '0')}:${appointmentDate.getMinutes().toString().padStart(2, '0')}`;
      
      const visitTypeArabic = bookingData.visitType === 'followUp' ? 'إعادة' : 'كشف';

      // Prepare notification payload
      const doctorName = clinicData.doctorName || '';
      const clinicTitle = doctorName ? `حجز جديد - عيادة د. ${doctorName} 📅` : 'حجز جديد أونلاين 📅';
      const notificationBody = `${bookingData.patientName} حجز موعد\n${visitTypeArabic} - ${dateStr} الساعة ${timeStr}`;
      
      const message = {
        notification: {
          title: clinicTitle,
          body: notificationBody,
        },
        data: {
          type: 'new_booking',
          bookingId: bookingId,
          clinicId: clinicId,
          patientName: bookingData.patientName || '',
          patientPhone: bookingData.patientPhone || '',
          bookingNumber: (bookingData.bookingNumber || 0).toString(),
          doctorName: bookingData.doctorName || doctorName,
          notes: bookingData.notes || '',
          visitType: visitTypeArabic,
          appointmentDate: dateStr,
          appointmentTime: timeStr,
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'clinic_bookings',
            icon: 'ic_launcher_foreground',
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
 * Send notification to doctor when secretary adds or deletes booking
 * Triggers on: clinic_notifications collection onCreate
 * Sends to doctors via clinic topic
 */
exports.notifyDoctorOnSecretaryAction = onDocumentCreated(
  'clinic_notifications/{notificationId}',
  async (event) => {
    try {
      const notificationData = event.data.data();
      const clinicId = notificationData.clinicId;

      if (!clinicId) {
        console.log('No clinicId in notification, skipping');
        return null;
      }

      // Get clinic data
      const clinicDoc = await admin.firestore().collection('clinics').doc(clinicId).get();
      
      if (!clinicDoc.exists) {
        console.log('Clinic not found:', clinicId);
        return null;
      }

      const clinicData = clinicDoc.data();
      const doctorEmails = clinicData.doctorEmails || [];
      
      if (doctorEmails.length === 0) {
        console.log('No doctor emails found for clinic:', clinicId);
        return null;
      }

      // Prepare notification payload
      const message = {
        notification: {
          title: notificationData.title || 'إشعار من العيادة',
          body: notificationData.message || '',
        },
        data: {
          type: notificationData.type || 'clinic_notification',
          clinicId: clinicId,
          patientName: notificationData.patientName || '',
          visitType: notificationData.visitType || '',
          appointmentDate: notificationData.appointmentDate || '',
          appointmentTime: notificationData.appointmentTime || '',
          bookingNumber: (notificationData.bookingNumber || 0).toString(),
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

      // Send to clinic-specific topic (doctors subscribed)
      const clinicTopic = `clinic_${clinicId}`;
      const topicMessage = {...message, topic: clinicTopic};
      
      const topicResponse = await admin.messaging().send(topicMessage);
      console.log('Secretary action notification sent to doctors:', clinicTopic, topicResponse);

      return {
        success: true, 
        topicResponse: topicResponse,
        message: 'Notification sent to doctors successfully',
      };
    } catch (error) {
      console.error('Error sending secretary action notification:', error);
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
/**
 * Send notification to all pharmacies when a near expire item is added
 * Triggers on: near_expire_items collection onCreate
 * Sends to pharmacy_requests topic (all pharmacies)
 */
exports.notifyPharmaciesOnNearExpireItem = onDocumentCreated(
  'near_expire_items/{itemId}',
  async (event) => {
    try {
      const itemData = event.data.data();
      const itemId = event.params.itemId;

      // Prepare notification payload
      const message = {
        notification: {
          title: '💊 دواء قارب على الانتهاء',
          body: `${itemData.pharmacyName} عرضت ${itemData.medicineName} قارب على الانتهاء`,
        },
        data: {
          type: 'near_expire_item',
          itemId: itemId,
          pharmacyId: itemData.pharmacyId || '',
          pharmacyName: itemData.pharmacyName || '',
          medicineName: itemData.medicineName || '',
          medicineType: itemData.medicineType || '',
          quantity: (itemData.quantity || 0).toString(),
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'pharmacy_requests',
            icon: 'ic_notification',
            color: '#FF6B00',
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

      // Send to pharmacy_requests topic (all pharmacies)
      const topicMessage = {...message, topic: 'pharmacy_requests'};
      const topicResponse = await admin.messaging().send(topicMessage);
      console.log('Near expire item notification sent to pharmacy topic:', topicResponse);

      // Update item with notification sent status
      await event.data.ref.update({
        notificationSent: true,
        notificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        topicResponse: topicResponse,
        message: 'Near expire notification sent to pharmacies successfully',
      };
    } catch (error) {
      console.error('Error sending near expire notification:', error);
      return {success: false, error: error.message};
    }
  }
);

/**
 * Send notification to laboratory when a new online booking is created
 * Triggers on: lab_bookings collection onCreate
 * Sends to lab-specific topic (lab_LABID)
 */
exports.notifyLabOnNewBooking = onDocumentCreated(
  'lab_bookings/{bookingId}',
  async (event) => {
    try {
      const bookingData = event.data.data();
      const bookingId = event.params.bookingId;
      const laboratoryId = bookingData.laboratoryId;

      if (!laboratoryId) {
        console.log('No laboratoryId in booking, skipping notification');
        return null;
      }

      // Only send notification for online bookings
      if (bookingData.isOnlineBooking !== true) {
        console.log('Booking is not online, skipping notification');
        return null;
      }

      // Get laboratory data
      const labDoc = await admin.firestore().collection('laboratories').doc(laboratoryId).get();
      
      if (!labDoc.exists) {
        console.log('Laboratory not found:', laboratoryId);
        return null;
      }

      const labData = labDoc.data();
      const authEmails = labData.authEmails || [];
      
      if (authEmails.length === 0) {
        console.log('No authEmails found for laboratory:', laboratoryId);
        return null;
      }

      const bookingTests = Array.isArray(bookingData.testTypes)
        ? bookingData.testTypes.filter((test) => typeof test === 'string' && test.trim() !== '')
        : [];
      const fallbackTest = typeof bookingData.testType === 'string' ? bookingData.testType.trim() : '';
      if (bookingTests.length === 0 && fallbackTest) {
        bookingTests.push(fallbackTest);
      }
      const testsSummary = bookingTests.length > 0 ? bookingTests.join('، ') : '';

      // Prepare notification payload
      const message = {
        notification: {
          title: 'حجز تحليل جديد أونلاين 🔬',
          body: testsSummary
            ? `${bookingData.patientName} حجز ${testsSummary} - رقم الحجز: ${bookingData.bookingNumber}`
            : `${bookingData.patientName} حجز موعد - رقم الحجز: ${bookingData.bookingNumber}`,
        },
        data: {
          type: 'new_lab_booking',
          bookingId: bookingId,
          laboratoryId: laboratoryId,
          patientName: bookingData.patientName || '',
          patientPhone: bookingData.patientPhone || '',
          bookingNumber: (bookingData.bookingNumber || 0).toString(),
          testType: bookingTests.length > 0 ? bookingTests[0] : '',
          testTypes: JSON.stringify(bookingTests),
          testsSummary: testsSummary,
          serviceType: bookingData.serviceType || '',
          notes: bookingData.notes || '',
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'lab_bookings',
            icon: 'ic_notification',
            color: '#00BCD4',
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

      // Send to lab-specific topic
      const labTopic = `lab_${laboratoryId}`;
      const topicMessage = {...message, topic: labTopic};
      
      const topicResponse = await admin.messaging().send(topicMessage);
      console.log('Lab booking notification sent to lab topic:', labTopic, topicResponse);

      // Update booking with notification sent status
      await event.data.ref.update({
        notificationSent: true,
        notificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true, 
        topicResponse: topicResponse,
        message: 'Notification sent to laboratory topic successfully',
      };
    } catch (error) {
      console.error('Error sending lab booking notification:', error);
      return {success: false, error: error.message};
    }
  }
);

/**
 * Send notification from laboratory to all users
 * Triggers on: lab_notifications collection onCreate
 * Sends to all_users topic
 */
exports.sendLabNotificationToUsers = onDocumentCreated(
  'lab_notifications/{notificationId}',
  async (event) => {
    try {
      const notificationData = event.data.data();
      const notificationId = event.params.notificationId;

      if (notificationData.sent) {
        console.log('Notification already sent');
        return null;
      }

      // Get laboratory data
      const labDoc = await admin.firestore()
        .collection('laboratories')
        .doc(notificationData.laboratoryId)
        .get();

      if (!labDoc.exists) {
        console.log('Laboratory not found:', notificationData.laboratoryId);
        return null;
      }

      const labData = labDoc.data();

      // Prepare full notification text
      const fullText = `${notificationData.title}\n${notificationData.message}`;

      // Prepare notification payload
      const message = {
        notification: {
          title: labData.name,
          body: fullText,
        },
        data: {
          type: 'laboratory_announcement',
          notificationId: notificationId,
          laboratoryId: notificationData.laboratoryId,
          laboratoryName: labData.name,
          title: notificationData.title,
          message: notificationData.message,
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'high_importance_channel',
            icon: 'ic_launcher_foreground',
            color: '#00BCD4',
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

      // Send to all_users topic
      const topicMessage = {...message, topic: 'all_users'};
      const topicResponse = await admin.messaging().send(topicMessage);
      console.log('Laboratory notification sent to all users:', topicResponse);

      // Update notification with sent status
      await event.data.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: topicResponse,
      });

      return {
        success: true,
        topicResponse: topicResponse,
        message: 'Laboratory notification sent to all users successfully',
      };
    } catch (error) {
      console.error('Error sending laboratory notification:', error);
      
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
 * Send notification from clinic to all users
 * Triggers on: clinic_notifications_broadcast collection onCreate
 * Sends to all_users topic
 */
exports.sendClinicNotificationToUsers = onDocumentCreated(
  'clinic_notifications_broadcast/{notificationId}',
  async (event) => {
    try {
      const notificationData = event.data.data();
      const notificationId = event.params.notificationId;

      if (notificationData.sent) {
        console.log('Notification already sent');
        return null;
      }

      // Get clinic data
      const clinicDoc = await admin.firestore()
        .collection('clinics')
        .doc(notificationData.clinicId)
        .get();

      if (!clinicDoc.exists) {
        console.log('Clinic not found:', notificationData.clinicId);
        return null;
      }

      const clinicData = clinicDoc.data();

      // Prepare full notification text
      const fullText = `${notificationData.title}\n${notificationData.message}`;

      // Prepare notification payload
      const message = {
        notification: {
          title: `عيادة د. ${clinicData.doctorName}`,
          body: fullText,
        },
        data: {
          type: 'clinic_announcement',
          notificationId: notificationId,
          clinicId: notificationData.clinicId,
          clinicName: clinicData.doctorName,
          title: notificationData.title,
          message: notificationData.message,
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'high_importance_channel',
            icon: 'ic_launcher_foreground',
            color: '#0891B2',
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

      // Send to all_users topic
      const topicMessage = {...message, topic: 'all_users'};
      const topicResponse = await admin.messaging().send(topicMessage);
      console.log('Clinic notification sent to all users:', topicResponse);

      // Update notification with sent status
      await event.data.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: topicResponse,
      });

      return {
        success: true,
        topicResponse: topicResponse,
        message: 'Clinic notification sent to all users successfully',
      };
    } catch (error) {
      console.error('Error sending clinic notification:', error);

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
 * Send notification from gym to all users
 * Triggers on: gym_notifications collection onCreate
 * Sends to all_users topic
 */
exports.sendGymNotificationToUsers = onDocumentCreated(
  'gym_notifications/{notificationId}',
  async (event) => {
    try {
      const notificationData = event.data.data();
      const notificationId = event.params.notificationId;

      if (notificationData.sent) {
        console.log('Notification already sent');
        return null;
      }

      // Get gym data
      const gymDoc = await admin.firestore()
        .collection('gyms')
        .doc(notificationData.gymId)
        .get();

      if (!gymDoc.exists) {
        console.log('Gym not found:', notificationData.gymId);
        return null;
      }

      const gymData = gymDoc.data();

      // Prepare full notification text
      const fullText = `${notificationData.title}\n${notificationData.message}`;

      // Prepare notification payload
      const message = {
        notification: {
          title: gymData.name,
          body: fullText,
        },
        data: {
          type: 'gym_announcement',
          notificationId: notificationId,
          gymId: notificationData.gymId,
          gymName: gymData.name,
          title: notificationData.title,
          message: notificationData.message,
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'high_importance_channel',
            icon: 'ic_launcher_foreground',
            color: '#FF6B6B',
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

      // Send to all_users topic
      const topicMessage = {...message, topic: 'all_users'};
      const topicResponse = await admin.messaging().send(topicMessage);
      console.log('Gym notification sent to all users:', topicResponse);

      // Update notification with sent status
      await event.data.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: topicResponse,
      });

      return {
        success: true,
        topicResponse: topicResponse,
        message: 'Gym notification sent to all users successfully',
      };
    } catch (error) {
      console.error('Error sending gym notification:', error);

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
 * Send notification from admin to all users
 * Triggers on: admin_notifications_broadcast collection onCreate
 * Sends to all_users topic with optional store URL action
 */
exports.sendAdminNotificationToUsers = onDocumentCreated(
  'admin_notifications_broadcast/{notificationId}',
  async (event) => {
    try {
      const notificationData = event.data.data();
      const notificationId = event.params.notificationId;

      if (notificationData.sent) {
        console.log('Admin notification already sent');
        return null;
      }

      const message = {
        notification: {
          title: 'Mallawy Care',
          body: notificationData.message || 'لديك إشعار جديد من التطبيق',
        },
        data: {
          type: 'admin_announcement',
          notificationId: notificationId,
          title: notificationData.title || 'Mallawy Care',
          message: notificationData.message || '',
          openUrl: notificationData.openUrl || '',
          actionType: notificationData.openStoreOnTap ? 'open_store' : 'none',
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'high_importance_channel',
            icon: 'ic_launcher_foreground',
            color: '#00BCD4',
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

      const topicMessage = {...message, topic: 'all_users'};
      const topicResponse = await admin.messaging().send(topicMessage);
      console.log('Admin notification sent to all users:', topicResponse);

      await event.data.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: topicResponse,
      });

      return {
        success: true,
        topicResponse: topicResponse,
        message: 'Admin notification sent to all users successfully',
      };
    } catch (error) {
      console.error('Error sending admin notification:', error);

      await event.data.ref.update({
        error: error.message,
        errorAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {success: false, error: error.message};
    }
  }
);