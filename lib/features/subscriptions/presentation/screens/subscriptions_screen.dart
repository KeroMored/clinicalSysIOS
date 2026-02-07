import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../data/models/subscribed_place_model.dart';
import '../../data/repositories/subscription_repository.dart';
import '../cubit/subscription_cubit.dart';
import '../cubit/subscription_state.dart';
import '../widgets/subscription_detail_widgets.dart';
import '../widgets/add_payment_dialog.dart';
import 'place_subscription_details_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  PlaceType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200 pixels from the bottom
      final cubit = context.read<SubscriptionCubit>();
      cubit.loadMorePlaces();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SubscriptionCubit(SubscriptionRepository())..loadAllPlaces(),
      child: Builder(
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: GradientAppBar(
              title: 'إدارة الاشتراكات',
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            actions: [
              BlocBuilder<SubscriptionCubit, SubscriptionState>(
                builder: (context, state) {
                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      switch (value) {
                        case 'sync':
                          context.read<SubscriptionCubit>().syncAllPlaces();
                          break;
                        case 'refresh':
                          context.read<SubscriptionCubit>().loadAllPlaces();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'sync',
                        child: Row(
                          children: [
                            Icon(Icons.sync, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('مزامنة الأماكن'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, color: Colors.green),
                            SizedBox(width: 8),
                            Text('تحديث'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Tab Bar
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black45,
                  tabs: const [
                    Tab(text: 'الكل', icon: Icon(Icons.list_alt, size: 20)),
                    Tab(text: 'الإعدادات', icon: Icon(Icons.settings, size: 20)),
                    Tab(text: 'الإحصائيات', icon: Icon(Icons.analytics, size: 20)),
                  ],
                ),
              ),
              // Body content
              Expanded(
                child: BlocConsumer<SubscriptionCubit, SubscriptionState>(
            listener: (context, state) {
              if (state is SettingsUpdated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is PaymentRecorded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is PlacesSynced) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${state.message} (${state.syncedCount} جديد)'),
                    backgroundColor: Colors.blue,
                  ),
                );
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
              if (state is SubscriptionLoading || state is SyncingPlaces || state is PlacesLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري التحميل...'),
                    ],
                  ),
                );
              }

              if (state is SubscriptionLoaded) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    PlacesListWidget(
                      places: state.places,
                      hasMoreData: state.hasMoreData,
                      scrollController: _scrollController,
                      searchController: _searchController,
                      selectedType: _selectedType,
                      onTypeSelected: (type) {
                        print('🔍 Filter selected: ${type?.arabicName ?? "الكل"}');
                        setState(() => _selectedType = type);
                        try {
                          if (type == null) {
                            context.read<SubscriptionCubit>().loadAllPlaces();
                          } else {
                            context.read<SubscriptionCubit>().loadPlacesByType(type);
                          }
                        } catch (e) {
                          print('❌ Error in filter: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('خطأ: $e')),
                          );
                        }
                      },
                      onPlaceTap: (place) => _navigateToDetails(context, place),
                      onPaymentTap: (place) => _showAddPaymentDialog(context, place, state.settings),
                      onSyncPlaces: () => context.read<SubscriptionCubit>().syncAllPlaces(),
                    ),
                    SettingsTabWidget(
                      settings: state.settings,
                      onSave: (monthly, yearly) {
                        context.read<SubscriptionCubit>().updateSettings(
                              monthlyPrice: monthly,
                              yearlyPrice: yearly,
                            );
                      },
                    ),
                    StatisticsTabWidget(
                      statistics: state.statistics,
                      onExpiredTap: () {
                        context.read<SubscriptionCubit>().loadExpiredSubscriptions();
                        _tabController.animateTo(0);
                      },
                      onExpiringSoonTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('سيتم إضافة هذه الميزة قريباً')),
                        );
                      },
                    ),
                  ],
                );
              }

              // For any other state, try to reload
              if (state is SubscriptionInitial || state is PaymentRecorded || 
                  state is SettingsUpdated || state is NotesUpdated) {
                // Trigger reload
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<SubscriptionCubit>().loadAllPlaces();
                });
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('خطأ في تحميل البيانات'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<SubscriptionCubit>().loadAllPlaces();
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            },
          ),
              ), // End of Expanded
            ], // End of Column children
          ), // End of body Column
        ), // End of Scaffold
      ), // End of Directionality
      ), // End of Builder
    ); // End of BlocProvider
  }

  void _navigateToDetails(BuildContext context, SubscribedPlaceModel place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceSubscriptionDetailsScreen(placeId: place.id),
      ),
    );
  }

  void _showAddPaymentDialog(
    BuildContext context,
    SubscribedPlaceModel place,
    settings,
  ) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<SubscriptionCubit>(),
        child: AddPaymentDialog(
          settings: settings,
          placeName: place.placeName,
          onSubmit: (amount, type, date, notes) {
            context.read<SubscriptionCubit>().recordPayment(
                  subscribedPlaceId: place.id,
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
}
