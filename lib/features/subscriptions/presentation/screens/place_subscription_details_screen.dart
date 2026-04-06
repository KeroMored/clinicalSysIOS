import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../data/repositories/subscription_repository.dart';
import '../cubit/subscription_cubit.dart';
import '../cubit/subscription_state.dart';
import '../widgets/subscription_detail_widgets.dart';
import '../widgets/add_payment_dialog.dart';
import 'edit_place_details_screen.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class PlaceSubscriptionDetailsScreen extends StatelessWidget {
  final String placeId;

  const PlaceSubscriptionDetailsScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SubscriptionCubit(SubscriptionRepository())
            ..loadPlaceDetails(placeId),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocConsumer<SubscriptionCubit, SubscriptionState>(
          listener: (context, state) {
            if (state is PaymentRecorded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is PaymentDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.orange,
                ),
              );
            } else if (state is NotesUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is PlaceDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.pop(context);
            } else if (state is SubscriptionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is PaymentsLoading) {
              return Scaffold(
                appBar: const GradientAppBar(
                  title: 'تفاصيل الاشتراك',
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
                body: const Center(child: AppLoadingIndicator()),
              );
            }

            if (state is PlaceDetailsLoaded) {
              return Scaffold(
                appBar: GradientAppBar(
                  title: state.place.placeName,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                      onPressed: () => _showDeleteConfirmation(context),
                      tooltip: 'حذف',
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton.extended(
                  onPressed: () => _showAddPaymentDialog(context, state),
                  backgroundColor: Colors.green,
                  icon: const Icon(Icons.add),
                  label: const Text('تسجيل دفعة'),
                ),
                body: RefreshIndicator(
                  onRefresh: () async {
                    context.read<SubscriptionCubit>().loadPlaceDetails(placeId);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PlaceInfoCardWidget(
                          place: state.place,
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditPlaceDetailsScreen(place: state.place),
                              ),
                            ).then((updated) {
                              if (updated == true) {
                                context
                                    .read<SubscriptionCubit>()
                                    .loadPlaceDetails(placeId);
                              }
                            });
                          },
                        ),

                        SubscriptionStatusCardWidget(place: state.place),

                        NotesSectionWidget(
                          notes: state.place.notes,
                          onEdit: () =>
                              _showEditNotesDialog(context, state.place.notes),
                        ),

                        PaymentHistorySectionWidget(
                          payments: state.payments,
                          onDeletePayment: (payment) {
                            context
                                .read<SubscriptionCubit>()
                                .deletePaymentRecord(
                                  payment.id,
                                  placeId,
                                  payment.amount,
                                );
                          },
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Scaffold(
              appBar: const GradientAppBar(
                title: 'تفاصيل الاشتراك',
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
              ),
              body: const Center(child: Text('خطأ في تحميل البيانات')),
            );
          },
        ),
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, PlaceDetailsLoaded state) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<SubscriptionCubit>(),
        child: AddPaymentDialog(
          settings: state.settings,
          placeName: state.place.placeName,
          onSubmit: (amount, type, date, notes) {
            context.read<SubscriptionCubit>().recordPayment(
              subscribedPlaceId: placeId,
              amount: amount,
              paymentType: type,
              paymentDate: date,
              notes: notes,
            );
          },
        ),
      ),
    );
  }

  void _showEditNotesDialog(BuildContext context, String currentNotes) {
    final controller = TextEditingController(text: currentNotes);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل الملاحظات'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'أضف ملاحظات...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SubscriptionCubit>().updatePlaceNotes(
                placeId,
                controller.text,
              );
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المكان'),
        content: const Text(
          'هل أنت متأكد من حذف هذا المكان من سجل الاشتراكات؟\nسيتم حذف جميع سجلات الدفع المرتبطة به.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SubscriptionCubit>().deletePlace(placeId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
