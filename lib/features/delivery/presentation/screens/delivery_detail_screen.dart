import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/like_button.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../../core/widgets/report_button.dart';
import '../../data/models/delivery_model.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final DeliveryModel delivery;

  const DeliveryDetailScreen({super.key, required this.delivery});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  static const Color _brandColor = Color(0xFF0E7787);
  static const Color _brandColorDark = Color(0xFF0B6572);

  late DeliveryModel _delivery;

  @override
  void initState() {
    super.initState();
    _delivery = widget.delivery;
  }

  Future<void> _reloadDelivery() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(_delivery.id)
          .get();

      if (!doc.exists || !mounted) return;

      setState(() {
        _delivery = DeliveryModel.fromMap({'id': doc.id, ...doc.data()!});
      });
    } catch (_) {
      // Silent refresh fail is acceptable.
    }
  }

  Future<void> _callPhone(String phone) async {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: trimmed);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إجراء المكالمة حالياً')),
      );
    }
  }

  String _formatWhatsAppNumber(String phoneNumber) {
    String value = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (value.startsWith('+')) {
      value = value.substring(1);
    }
    if (value.startsWith('00')) {
      value = value.substring(2);
    }
    if (value.startsWith('0')) {
      value = '20${value.substring(1)}';
    }
    if (!value.startsWith('20')) {
      value = '20$value';
    }
    return value;
  }

  Future<void> _openWhatsApp() async {
    if (_delivery.deliveryWhatsApp.trim().isEmpty) return;

    final number = _formatWhatsAppNumber(_delivery.deliveryWhatsApp);
    final uri = Uri.parse('https://wa.me/$number');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن فتح واتساب حالياً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationText =
        '${_delivery.center.isEmpty ? _delivery.city : _delivery.center} - ${_delivery.governorate}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'تفاصيل الدليفري',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _brandColor,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [_brandColor, _brandColorDark],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _delivery.deliveryName.trim().isEmpty
                                ? 'د'
                                : _delivery.deliveryName
                                      .trim()
                                      .characters
                                      .first,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _delivery.deliveryName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 15,
                                  color: _brandColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    locationText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _delivery.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: Color(0xFFE11D48),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_delivery.likesCount}',
                        style: const TextStyle(
                          color: Color(0xFFBE123C),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 9,
                      //     vertical: 5,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: _delivery.availableNow
                      //         ? const Color(0xFFDCFCE7)
                      //         : const Color(0xFFFEE2E2),
                      //     borderRadius: BorderRadius.circular(10),
                      //   ),
                      //   child: Text(
                      //     _delivery.availableNow ? 'متاح الآن' : 'غير متاح',
                      //     style: TextStyle(
                      //       fontSize: 11,
                      //       fontWeight: FontWeight.w700,
                      //       color: _delivery.availableNow
                      //           ? const Color(0xFF15803D)
                      //           : const Color(0xFFB91C1C),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'التواصل',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._delivery.deliveryPhones.map(
                    (phone) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _callPhone(phone),
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: Text(
                            phone,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_delivery.deliveryWhatsApp.trim().isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openWhatsApp,
                        icon: Icon(FontAwesomeIcons.whatsapp, size: 18),
                        label: const Text(
                          'واتساب',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF16A34A),
                          side: const BorderSide(color: Color(0xFF86EFAC)),
                          backgroundColor: const Color(0xFFF0FDF4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: RatingWidget(
                      serviceId: _delivery.id,
                      serviceType: 'delivery',
                      averageRating: _delivery.averageRating,
                      totalRatings: _delivery.totalRatings,
                      starSize: 20,
                      onRatingAdded: _reloadDelivery,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: const Color(0xFFE5E7EB),
                  ),
                  LikeButton(
                    serviceId: _delivery.id,
                    serviceType: 'delivery',
                    initialLikesCount: _delivery.likesCount,
                    iconSize: 24,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: const Color(0xFFE5E7EB),
                  ),
                  ReportButton(
                    serviceId: _delivery.id,
                    serviceType: 'delivery',
                    serviceName: _delivery.deliveryName,
                    iconSize: 24,
                    showLabel: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
