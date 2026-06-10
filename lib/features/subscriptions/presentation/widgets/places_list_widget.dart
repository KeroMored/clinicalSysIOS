import 'package:flutter/material.dart';
import '../../data/models/subscribed_place_model.dart';
import '../widgets/place_subscription_card.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

class PlacesListWidget extends StatelessWidget {
  final List<SubscribedPlaceModel> places;
  final bool hasMoreData;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final PlaceType? selectedType;
  final Function(PlaceType?) onTypeSelected;
  final Function(SubscribedPlaceModel) onPlaceTap;
  final Function(SubscribedPlaceModel) onPaymentTap;
  final VoidCallback onSyncPlaces;

  const PlacesListWidget({
    super.key,
    required this.places,
    required this.hasMoreData,
    required this.scrollController,
    required this.searchController,
    required this.selectedType,
    required this.onTypeSelected,
    required this.onPlaceTap,
    required this.onPaymentTap,
    required this.onSyncPlaces,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن مكان...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            // Trigger reload
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    FilterChipWidget(
                      label: 'الكل',
                      isSelected: selectedType == null,
                      onTap: () => onTypeSelected(null),
                    ),
                    ...PlaceType.values.map(
                      (type) => FilterChipWidget(
                        label: type.arabicName,
                        isSelected: selectedType == type,
                        onTap: () => onTypeSelected(type),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: places.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد أماكن مسجلة',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: onSyncPlaces,
                        icon: const Icon(Icons.sync),
                        label: const Text('مزامنة الأماكن'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  itemCount: places.length + (hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == places.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: AppLoadingIndicator()),
                      );
                    }

                    final place = places[index];
                    return PlaceSubscriptionCard(
                      place: place,
                      onTap: () => onPlaceTap(place),
                      onPaymentTap: () => onPaymentTap(place),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF00BCD4).withValues(alpha: 0.2),
        checkmarkColor: const Color(0xFF00BCD4),
      ),
    );
  }
}
