import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a report/complaint for a service
  Future<String> submitReport({
    required String serviceId,
    required String serviceType,
    required String serviceName,
    required String userId,
    required String userEmail,
    required String userName,
    required String complaint,
  }) async {
    try {
      final report = ReportModel(
        id: '',
        serviceId: serviceId,
        serviceType: serviceType,
        serviceName: serviceName,
        reportedBy: userId,
        reporterEmail: userEmail,
        reporterName: userName,
        complaint: complaint,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('reports').add(report.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Get all reports for a specific service
  Future<List<ReportModel>> getServiceReports(String serviceId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('serviceId', isEqualTo: serviceId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get reports by status (for admin)
  Future<List<ReportModel>> getReportsByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all reports (for admin)
  Future<List<ReportModel>> getAllReports() async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .limit(100) // limit to avoid too much data
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get reports submitted by a user
  Future<List<ReportModel>> getUserReports(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('reportedBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update report status (admin only)
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final updateData = {
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      };

      if (adminNotes != null && adminNotes.isNotEmpty) {
        updateData['adminNotes'] = adminNotes;
      }

      await _firestore.collection('reports').doc(reportId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  /// Add admin notes to a report
  Future<void> addAdminNotes(String reportId, String notes) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'adminNotes': notes,
      });
    } catch (e) {
      throw Exception('Failed to add admin notes: $e');
    }
  }

  /// Delete a report (admin only)
  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  /// Stream reports for real-time updates (admin)
  Stream<List<ReportModel>> streamReports({String? status}) {
    try {
      Query query = _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true);

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      return query.limit(100).snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => ReportModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Get pending reports count (for admin badge)
  Future<int> getPendingReportsCount() async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
