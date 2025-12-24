import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'offer_card.dart';

class AllOffersScreen extends StatelessWidget {
  const AllOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern SliverAppBar
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: Color(0xFF00BCD4),
              foregroundColor: const Color(0xFF1E3A5F),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00BCD4),
                       Color(0xFF4DD0E1),
                       Color(0xFF4DD0E1),
                       ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.1,
                          child: Image.asset(
                            'assets/images/pattern.png',
                            repeat: ImageRepeat.repeat,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.local_offer_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // const Text(
                            //   'العروض والخصومات ',
                            //   style: TextStyle(
                            //     color: Colors.white,
                            //     fontSize: 28,
                            //     fontWeight: FontWeight.bold,
                            //     // shadows: [
                            //     //   Shadow(
                            //     //     color: Colors.black26,
                            //     //     offset: Offset(0, 2),
                            //     //     blurRadius: 4,
                            //     //   ),
                            //     // ],
                            //   ),
                            // ),
                            // const SizedBox(height: 8),
                            // Text(
                            //   'اكتشف أفضل العروض الحصرية',
                            //   style: TextStyle(
                            //     color: Colors.white.withOpacity(0.95),
                            //     fontSize: 15,
                            //     fontWeight: FontWeight.w500,
                            //   ),
                            // ),
                        
                        
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                title: const Text(
                  'العروض والخصومات ',
                  style: TextStyle(
                    color:Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
              ),
            ),
            
            // Content
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('offers')
                  .where('isActive', isEqualTo: true)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                size: 64,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'حدث خطأ أثناء التحميل',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A5F),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'يرجى المحاولة مرة أخرى',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final offers = snapshot.data?.docs ?? [];

                if (offers.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_offer_outlined,
                                size: 72,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'لا توجد عروض متاحة حالياً',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A5F),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'تابع الصيدليات لمعرفة العروض الجديدة',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final offerDoc = offers[index];
                        final offerData = offerDoc.data() as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OfferCard(
                            offerId: offerDoc.id,
                            pharmacyId: offerData['pharmacyId'] ?? '',
                            pharmacyName: offerData['pharmacyName'] ?? 'صيدلية',
                            title: offerData['title'] ?? '',
                            description: offerData['description'] ?? '',
                            notes: offerData['notes'] ?? '',
                            images: List<String>.from(offerData['images'] ?? []),
                            createdAt: (offerData['createdAt'] as Timestamp?)?.toDate(),
                            isOwnerView: false,
                            isActive: offerData['isActive'] ?? true,
                          ),
                        );
                      },
                      childCount: offers.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
