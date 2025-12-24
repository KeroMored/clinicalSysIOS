import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for reports/complaints against any service
class ReportModel {
  final String id;
  final String serviceId; // ID of clinic, pharmacy, lab, etc.
  final String serviceType; // 'clinic', 'pharmacy', 'laboratory', etc.
  final String serviceName; // Name of the reported service
  final String reportedBy; // User ID who reported
  final String reporterEmail;
  final String reporterName;
  final String complaint; // The complaint text
  final String status; // 'pending', 'reviewed', 'resolved'
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? adminNotes;

  ReportModel({
    required this.id,
    required this.serviceId,
    required this.serviceType,
    required this.serviceName,
    required this.reportedBy,
    required this.reporterEmail,
    required this.reporterName,
    required this.complaint,
    this.status = 'pending',
    required this.createdAt,
    this.reviewedAt,
    this.adminNotes,
  });

  // Convert from Firestore
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      serviceId: data['serviceId'] ?? '',
      serviceType: data['serviceType'] ?? '',
      serviceName: data['serviceName'] ?? '',
      reportedBy: data['reportedBy'] ?? '',
      reporterEmail: data['reporterEmail'] ?? '',
      reporterName: data['reporterName'] ?? '',
      complaint: data['complaint'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null 
          ? (data['reviewedAt'] as Timestamp).toDate() 
          : null,
      adminNotes: data['adminNotes'],
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'serviceType': serviceType,
      'serviceName': serviceName,
      'reportedBy': reportedBy,
      'reporterEmail': reporterEmail,
      'reporterName': reporterName,
      'complaint': complaint,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'adminNotes': adminNotes,
    };
  }

  // Copy with
  ReportModel copyWith({
    String? id,
    String? serviceId,
    String? serviceType,
    String? serviceName,
    String? reportedBy,
    String? reporterEmail,
    String? reporterName,
    String? complaint,
    String? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? adminNotes,
  }) {
    return ReportModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceType: serviceType ?? this.serviceType,
      serviceName: serviceName ?? this.serviceName,
      reportedBy: reportedBy ?? this.reportedBy,
      reporterEmail: reporterEmail ?? this.reporterEmail,
      reporterName: reporterName ?? this.reporterName,
      complaint: complaint ?? this.complaint,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}
