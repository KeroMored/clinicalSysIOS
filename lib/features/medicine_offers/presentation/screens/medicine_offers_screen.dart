import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/medicine_offer_cubit.dart';
import '../widgets/medicine_offer_card.dart';

class MedicineOffersScreen extends StatefulWidget {
  const MedicineOffersScreen({super.key});

  @override
  State<MedicineOffersScreen> createState() => _MedicineOffersScreenState();
}

class _MedicineOffersScreenState extends State<MedicineOffersScreen> {
  @override
  void initState() {
    super.initState();
    // جلب كل العروض النشطة
    context.read<MedicineOfferCubit>().loadAllActiveOffers();
  }

  Future<void> _refreshOffers() async {
    await context.read<MedicineOfferCubit>().loadAllActiveOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'عروض الأدوية',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1A5F7A),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        body: BlocConsumer<MedicineOfferCubit, MedicineOfferState>(
          listener: (context, state) {
            if (state is MedicineOfferError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is MedicineOfferLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1A5F7A),
                ),
              );
            }

            if (state is MedicineOfferLoaded) {
              if (state.offers.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refreshOffers,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 100,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد عروض متاحة حالياً',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'اسحب للأسفل للتحديث',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshOffers,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: state.offers.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final offer = state.offers[index];
                    return MedicineOfferCard(offer: offer);
                  },
                ),
              );
            }

            // حالة افتراضية
            return RefreshIndicator(
              onRefresh: _refreshOffers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'اسحب للأسفل لتحميل العروض',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
