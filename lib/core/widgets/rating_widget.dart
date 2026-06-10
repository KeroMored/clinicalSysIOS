import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';
import '../services/rating_service.dart';
import '../utils/auth_helpers.dart';
import '../theme/app_theme.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

class RatingWidget extends StatefulWidget {
  final String serviceId;
  final String serviceType;
  final double averageRating;
  final int totalRatings;
  final bool showRatingsCount;
  final double starSize;
  final VoidCallback? onRatingAdded;

  const RatingWidget({
    Key? key,
    required this.serviceId,
    required this.serviceType,
    required this.averageRating,
    required this.totalRatings,
    this.showRatingsCount = true,
    this.starSize = 20.0,
    this.onRatingAdded,
  }) : super(key: key);

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  final RatingService _ratingService = RatingService();

  String _getCollectionName(String serviceType) {
    switch (serviceType) {
      case 'clinic':
        return 'clinics';
      case 'pharmacy':
        return 'pharmacies';
      case 'laboratory':
        return 'laboratories';
      case 'radiology':
        return 'radiology_centers';
      case 'rehabilitation':
        return 'rehabilitation_centers';
      case 'nurse':
        return 'nurses';
      case 'gym':
        return 'gyms';
      case 'delivery':
        return 'deliveries';
      default:
        return 'clinics';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(_getCollectionName(widget.serviceType))
          .doc(widget.serviceId)
          .snapshots(),
      builder: (context, snapshot) {
        double averageRating = widget.averageRating;
        int totalRatings = widget.totalRatings;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          averageRating = (data['averageRating'] ?? 0.0).toDouble();
          totalRatings = data['totalRatings'] ?? 0;
        }

        return GestureDetector(
          onTap: () => _showRatingDialog(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star rating display
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  if (index < averageRating.floor()) {
                    // Full star
                    return Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: widget.starSize,
                    );
                  } else if (index < averageRating) {
                    // Half star
                    return Icon(
                      Icons.star_half,
                      color: Colors.amber,
                      size: widget.starSize,
                    );
                  } else {
                    // Empty star
                    return Icon(
                      Icons.star_border,
                      color: Colors.grey[400],
                      size: widget.starSize,
                    );
                  }
                }),
              ),
              if (widget.showRatingsCount) ...[
                const SizedBox(width: 6),
                Text(
                  '($totalRatings)',
                  style: TextStyle(
                    fontSize: widget.starSize * 0.7,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showRatingDialog(BuildContext context) async {
    // Check authentication first
    final isAuthenticated = await AuthHelpers.requireAuth(
      context,
      message: 'يجب تسجيل الدخول لتقييم المكان',
    );

    if (!isAuthenticated) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    int selectedRating = 0;
    String comment = '';

    // Load existing rating if any
    try {
      final existingRating = await _ratingService.getUserRating(
        widget.serviceId,
        user.uid,
      );
      if (existingRating != null) {
        selectedRating = existingRating.rating;
        comment = existingRating.comment ?? '';
      }
    } catch (e) {
      // Ignore error, will start with empty rating
    }

    if (!context.mounted) return;

    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 550),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Header
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFBBF24,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Title
                    const Text(
                      'قيّم تجربتك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'رأيك يهمنا ويساعد الآخرين',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    // Star rating selector with animation
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedRating = index + 1;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Icon(
                                index < selectedRating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: index < selectedRating
                                    ? const Color(0xFFF59E0B)
                                    : Colors.grey[400],
                                size: 34,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    if (selectedRating > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        _getRatingText(selectedRating),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Comment field
                    TextField(
                      maxLines: 3,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'شاركنا تجربتك... (اختياري)',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFF59E0B),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onChanged: (value) {
                        comment = value;
                      },
                      controller: TextEditingController(text: comment),
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: (selectedRating > 0 && !isSubmitting)
                                ? () async {
                                    setDialogState(() {
                                      isSubmitting = true;
                                    });

                                    try {
                                      // Get user name from Firestore
                                      String userName = 'مستخدم';
                                      try {
                                        final userDoc = await FirebaseFirestore
                                            .instance
                                            .collection('users')
                                            .doc(user.uid)
                                            .get();
                                        if (userDoc.exists) {
                                          userName =
                                              userDoc.data()?['displayName'] ??
                                              'مستخدم';
                                        }
                                      } catch (e) {
                                        // If Firestore fails, use Auth displayName
                                        userName = user.displayName ?? 'مستخدم';
                                      }

                                      final rating = RatingModel(
                                        id: '',
                                        serviceId: widget.serviceId,
                                        serviceType: widget.serviceType,
                                        userId: user.uid,
                                        userEmail: user.email ?? '',
                                        userName: userName,
                                        rating: selectedRating,
                                        comment: comment.isEmpty
                                            ? null
                                            : comment,
                                        createdAt: DateTime.now(),
                                      );

                                      await _ratingService.addRating(rating);

                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 12),
                                              Text('تم إضافة التقييم بنجاح'),
                                            ],
                                          ),
                                          backgroundColor: const Color(
                                            0xFF10B981,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );

                                      // Notify parent to refresh
                                      if (widget.onRatingAdded != null) {
                                        widget.onRatingAdded!();
                                      }

                                      // Refresh this widget
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    } catch (e) {
                                      setDialogState(() {
                                        isSubmitting = false;
                                      });
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('حدث خطأ: $e')),
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: AppLoadingIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'إرسال التقييم',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'سيء جداً 😞';
      case 2:
        return 'سيء 😕';
      case 3:
        return 'مقبول 😐';
      case 4:
        return 'جيد 😊';
      case 5:
        return 'ممتاز 🌟';
      default:
        return '';
    }
  }
}

// Widget to show all ratings for a service
class RatingsListWidget extends StatelessWidget {
  final String serviceId;
  final double starSize;

  const RatingsListWidget({
    Key? key,
    required this.serviceId,
    this.starSize = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RatingService ratingService = RatingService();

    return FutureBuilder<List<RatingModel>>(
      future: ratingService.getServiceRatings(serviceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoadingIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'لا توجد تقييمات بعد',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final ratings = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ratings.length,
          itemBuilder: (context, index) {
            final rating = ratings[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.1,
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rating.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < rating.rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: starSize,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDate(rating.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (rating.comment != null &&
                        rating.comment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        rating.comment!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ قليل';
    }
  }
}
