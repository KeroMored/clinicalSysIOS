import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/clinic_model.dart';
import '../../data/models/clinic_department.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../../core/widgets/like_button.dart';
import '../../../../core/widgets/report_button.dart';
import '../../../../core/utils/working_hours_helper.dart';
import '../../../../core/utils/auth_helpers.dart';
import 'book_appointment_screen.dart';
import '../widgets/clinic_working_hours_content.dart';
import '../widgets/clinic_reviews_button.dart';
import '../widgets/clinic_full_screen_image.dart';

class ClinicDetailsScreen extends StatefulWidget {
  final ClinicModel clinic;
  final bool isFromBanner;

  const ClinicDetailsScreen({
    super.key,
    required this.clinic,
    this.isFromBanner = false,
  });

  @override
  _ClinicDetailsScreenState createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends State<ClinicDetailsScreen> {
  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _primaryDark = Color(0xFF115E59);
  static const Color _titleColor = Color(0xFF134E4A);
  static const String _bookingSettingsCollection = 'app_settings';
  static const String _bookingSettingsDoc = 'booking';

  late ClinicModel _clinic;
  late final Future<bool> _isBookingEnabledFuture;

  @override
  void initState() {
    super.initState();
    _clinic = widget.clinic;
    _isBookingEnabledFuture = _fetchIsBookingEnabled();
  }

  Future<void> _reloadClinic() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(_clinic.id)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _clinic = ClinicModel.fromFirestore(doc);
        });
      }
    } catch (e) {
      debugPrint('Error reloading clinic: $e');
    }
  }

  Future<bool> _fetchIsBookingEnabled() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_bookingSettingsCollection)
          .doc(_bookingSettingsDoc)
          .get();

      final data = doc.data();
      if (data == null) return true;

      final value = data['isBooking'];
      return value is bool ? value : true;
    } catch (e) {
      debugPrint('Error loading booking settings: $e');
      return true;
    }
  }

  // Check if clinic is open now
  bool _isClinicOpenNow() {
    return WorkingHoursHelper.isServiceOpen(
      workingHours: _clinic.workingHours.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      holidays: _clinic.holidays,
    );
  }

  BoxDecoration _sectionDecoration({Color color = Colors.white}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildClinicStatusBadge() {
    final isOpen = _isClinicOpenNow();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFF0F766E) : const Color(0xFFB91C1C),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            isOpen ? 'متاح الآن' : 'مغلق الآن',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clinics')
          .doc(_clinic.id)
          .snapshots(),
      builder: (context, snapshot) {
        // Update clinic data if available
        if (snapshot.hasData && snapshot.data!.exists) {
          _clinic = ClinicModel.fromFirestore(snapshot.data!);
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'د. ${_clinic.doctorName}',
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              leading: widget.isFromBanner
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: _primaryColor,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: _primaryColor,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF5FAF9), Color(0xFFEDF4F3)],
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Doctor Image with Status Badge
                    if (_clinic.doctorImageUrl != null)
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClinicFullScreenImage(
                                    imageUrl: _clinic.doctorImageUrl!,
                                    heroTag: 'clinic_${_clinic.id}',
                                  ),
                                ),
                              );
                            },
                            child: Hero(
                              tag: 'clinic_${_clinic.id}',
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(28),
                                ),
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      height: 280,
                                      width: double.infinity,
                                      child: Image.network(
                                        _clinic.doctorImageUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child: SpinKitPulsingGrid(
                                                  color: _primaryColor,
                                                  size: 48,
                                                ),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 60,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(
                                                alpha: 0.35,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Status Badge
                          Positioned(
                            bottom: 18,
                            left: 16,
                            child: _buildClinicStatusBadge(),
                          ),
                        ],
                      )
                    else
                      // عرض أيقونة افتراضية إذا لم توجد صورة
                      Stack(
                        children: [
                          Container(
                            height: 280,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _primaryColor.withValues(alpha: 0.14),
                                  _primaryDark.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(28),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.medical_services_rounded,
                                  size: 80,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                          ),
                          // Status Badge
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: _buildClinicStatusBadge(),
                          ),
                        ],
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Doctor Name & Info Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: _sectionDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: _primaryColor,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "د. ${_clinic.doctorName}",
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: _titleColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _clinic.department.arabicName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  color: const Color(0xFFE2E8F0),
                                ),
                                const SizedBox(height: 16),
                                if (_clinic.about.isNotEmpty) ...[
                                  Text(
                                    _clinic.about,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF475569),
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 1,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (_clinic.specialization.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.medical_services_rounded,
                                          color: _primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'خدمات العيادة',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _titleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ..._clinic.specialization
                                      .map(
                                        (service) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  top: 6,
                                                ),
                                                child: Icon(
                                                  Icons.circle,
                                                  size: 8,
                                                  color: _primaryColor,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  service,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF475569),
                                                    height: 1.6,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Consultation Fee
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: _sectionDecoration(),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.payments_rounded,
                                    color: _primaryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'سعر الكشف',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _clinic.consultationFee > 0
                                            ? '${_clinic.consultationFee.toInt()} جنيه'
                                            : 'غير محدد',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: _titleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Nursery availability (for pediatrics only)
                          if (_clinic.department ==
                                  ClinicDepartment.pediatrics &&
                              _clinic.hasNursery) ...[
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: _sectionDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _primaryColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.child_care_rounded,
                                      color: _primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'يوجد حضانة بالعيادة',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _titleColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Address & Location
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: _sectionDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: _primaryColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'العنوان',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _titleColor,
                                        ),
                                      ),
                                    ),
                                    if (_clinic.latitude != null &&
                                        _clinic.longitude != null)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: _primaryDark,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.location_on,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () => _openMaps(context),
                                          tooltip: 'افتح الخريطة',
                                          padding: const EdgeInsets.all(10),
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _clinic.address,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF475569),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Working Hours
                          Container(
                            decoration: _sectionDecoration(color: Colors.white),
                            child: ClinicWorkingHoursContent(
                              workingHours: _clinic.workingHours,
                              holidays: _clinic.holidays,
                              isClinicOpenNow: _isClinicOpenNow(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Book Appointment Button
                          if (_clinic.onlineBookingEnabled) ...[
                            FutureBuilder<bool>(
                              future: _isBookingEnabledFuture,
                              builder: (context, snapshot) {
                                final isBookingEnabled = snapshot.data ?? true;
                                if (!isBookingEnabled) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [_primaryColor, _primaryDark],
                                          begin: Alignment.centerRight,
                                          end: Alignment.centerLeft,
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _primaryColor.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 14,
                                            offset: const Offset(0, 7),
                                          ),
                                        ],
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final isAuthenticated =
                                                await AuthHelpers.requireAuth(
                                                  context,
                                                  message:
                                                      'يجب تسجيل الدخول لحجز موعد في العيادة',
                                                );

                                            if (!isAuthenticated || !mounted) {
                                              return;
                                            }

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    BookAppointmentScreen(
                                                      clinic: _clinic,
                                                    ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.calendar_month_rounded,
                                            size: 22,
                                          ),
                                          label: const Text(
                                            'احجز موعد الآن',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              },
                            ),
                          ],

                          // Contact Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: _sectionDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _primaryDark,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.phone_in_talk_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'تواصل معنا',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _titleColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Phone Numbers (Multiple)
                                if (_clinic.phones.isNotEmpty) ...[
                                  ...List.generate(_clinic.phones.length, (
                                    index,
                                  ) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _primaryDark.withValues(
                                              alpha: 0.2,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () => _makePhoneCall(
                                            context,
                                            _clinic.phones[index],
                                          ),
                                          icon: const Icon(
                                            Icons.phone,
                                            size: 20,
                                          ),
                                          label: Text(
                                            _clinic.phones.length > 1
                                                ? 'رقم ${index + 1}: ${_clinic.phones[index]}'
                                                : 'اتصال: ${_clinic.phones[index]}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _primaryDark,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 16,
                                            ),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],

                                // WhatsApp Button
                                if (_clinic.whatsapp != null)
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF25D366,
                                        ).withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openWhatsApp(context),
                                      icon: Icon(Icons.chat, size: 20),
                                      label: const Text(
                                        'واتساب',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0F766E,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 16,
                                        ),
                                        elevation: 0,
                                        minimumSize: const Size(
                                          double.infinity,
                                          50,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Rating & Actions
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: _sectionDecoration(),
                            child: Row(
                              children: [
                                // Rating Widget
                                Expanded(
                                  flex: 2,
                                  child: RatingWidget(
                                    serviceId: _clinic.id,
                                    serviceType: 'clinic',
                                    averageRating: _clinic.averageRating,
                                    totalRatings: _clinic.totalRatings,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 55,
                                  color: Colors.grey[200],
                                ),
                                // Like Button
                                Expanded(
                                  child: Center(
                                    child: LikeButton(
                                      serviceId: _clinic.id,
                                      serviceType: 'clinic',
                                      initialLikesCount: _clinic.totalLikes,
                                      iconSize: 26,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 55,
                                  color: Colors.grey[200],
                                ),
                                // Report Button
                                Expanded(
                                  child: Center(
                                    child: ReportButton(
                                      serviceId: _clinic.id,
                                      serviceType: 'clinic',
                                      serviceName: _clinic.doctorName,
                                      iconSize: 26,
                                      showLabel: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Reviews Button
                          ClinicReviewsButton(
                            averageRating: _clinic.averageRating,
                            totalRatings: _clinic.totalRatings,
                            onTap: () => _showReviewsDialog(context),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReviewsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 650, maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تقييمات د. ${_clinic.doctorName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_clinic.totalRatings} تقييم',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Average Rating
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _clinic.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < _clinic.averageRating.floor()
                                        ? Icons.star_rounded
                                        : (index < _clinic.averageRating
                                              ? Icons.star_half_rounded
                                              : Icons.star_outline_rounded),
                                    color: Colors.white,
                                    size: 16,
                                  );
                                }),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'من أصل 5',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Ratings List
              Expanded(
                child: RatingsListWidget(serviceId: _clinic.id, starSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatWhatsAppNumber(String input) {
    // خد الرقم زي ما هو وضيفله +20 فقط
    String n = input.trim();
    // لو بيبدأ بـ + شيله
    if (n.startsWith('+')) n = n.substring(1);
    // لو بيبدأ بـ 20 يبقى خلاص
    if (n.startsWith('20')) return n;
    // ضيف +20 قدام الرقم
    return '20$n';
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    if (_clinic.whatsapp == null) return;

    try {
      final formatted = _formatWhatsAppNumber(_clinic.whatsapp!);
      final message =
          'مرحباً 👋\nأريد الاستفسار عن موعد في عيادة د. ${_clinic.doctorName}';
      final url =
          'https://wa.me/$formatted?text=${Uri.encodeComponent(message)}';

      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح واتساب')));
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    try {
      final Uri launchUri = Uri(scheme: 'tel', path: phone);

      await launchUrl(launchUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر الاتصال')));
      }
    }
  }

  Future<void> _openMaps(BuildContext context) async {
    if (_clinic.latitude == null || _clinic.longitude == null) return;

    try {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${_clinic.latitude},${_clinic.longitude}';

      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح الخرائط')));
      }
    }
  }
}
