class UserModel {
  final String uid; // Firebase User ID
  final String email;
  final String displayName;
  final String photoUrl;
  final String role; // 'user', 'pharmacy', 'admin'
  final String? pharmacyId; // إذا كان صاحب صيدلية
  final String? medicalSupplyId; // إذا كان صاحب مستلزمات طبية
  final String? phoneNumber; // رقم الهاتف
  final String? whatsappNumber; // رقم الواتساب
  final String? address; // العنوان

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.role = 'user', // default: مستخدم عادي
    this.pharmacyId,
    this.medicalSupplyId,
    this.phoneNumber,
    this.whatsappNumber,
    this.address,
  });

  // Convert from Firestore document
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final resolvedRole = _asString(json['role'], fallback: 'user');

    return UserModel(
      uid: _asString(json['uid']),
      email: _asString(json['email']),
      displayName: _asString(json['displayName']),
      photoUrl: _asString(json['photoUrl']),
      role: resolvedRole.isEmpty ? 'user' : resolvedRole,
      pharmacyId: _asNullableString(json['pharmacyId']),
      medicalSupplyId: _asNullableString(json['medicalSupplyId']),
      phoneNumber: _asNullableString(json['phoneNumber']),
      whatsappNumber: _asNullableString(json['whatsappNumber']),
      address: _asNullableString(json['address']),
    );
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  // Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'pharmacyId': pharmacyId,
      'medicalSupplyId': medicalSupplyId,
      'phoneNumber': phoneNumber,
      'whatsappNumber': whatsappNumber,
      'address': address,
    };
  }

  // Copy with method
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? role,
    String? pharmacyId,
    String? medicalSupplyId,
    String? phoneNumber,
    String? whatsappNumber,
    String? address,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      medicalSupplyId: medicalSupplyId ?? this.medicalSupplyId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      address: address ?? this.address,
    );
  }

  // Check if user is pharmacy owner
  bool get isPharmacyOwner => role == 'pharmacy';

  // Check if user is clinic owner
  bool get isClinicOwner => role == 'clinic_owner';

  // Check if user is laboratory owner
  bool get isLaboratoryOwner => role == 'laboratory';

  // Check if user is radiology owner
  bool get isRadiologyOwner => role == 'radiology';

  // Check if user is gym owner
  bool get isGymOwner => role == 'gym';

  // Check if user is rehabilitation center owner
  bool get isRehabilitationOwner => role == 'rehabilitation_center';

  // Check if user is medical supply owner
  bool get isMedicalSupplyOwner => role == 'medical_supply_owner';

  // Check if user is admin
  bool get isAdmin => role == 'admin';

  // Check if user is regular user
  bool get isRegularUser => role == 'user';
}
