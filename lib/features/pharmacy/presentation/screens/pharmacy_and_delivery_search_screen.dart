import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../delivery/data/models/delivery_model.dart';
import '../../../delivery/presentation/screens/delivery_detail_screen.dart';
import '../../data/models/pharmacy_model.dart';
import '../../data/repositories/pharmacy_repository.dart';
import '../cubit/pharmacy_cubit.dart';
import 'pharmacy_details_screen.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class PharmacyAndDeliverySearchScreen extends StatefulWidget {
  final String initialQuery;

  const PharmacyAndDeliverySearchScreen({super.key, this.initialQuery = ''});

  @override
  State<PharmacyAndDeliverySearchScreen> createState() =>
      _PharmacyAndDeliverySearchScreenState();
}

class _PharmacyAndDeliverySearchScreenState
    extends State<PharmacyAndDeliverySearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<PharmacyModel> _filteredPharmacies = [];
  List<DeliveryModel> _filteredDeliveries = [];

  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;

    if (widget.initialQuery.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch([String? customQuery]) async {
    final queryText = (customQuery ?? _searchController.text).trim();

    if (queryText.isEmpty) {
      if (!mounted) return;
      setState(() {
        _hasSearched = false;
        _errorMessage = null;
        _filteredPharmacies = [];
        _filteredDeliveries = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _searchPharmacies(queryText),
        _searchDeliveries(queryText),
      ]);

      if (mounted) {
        setState(() {
          _filteredPharmacies = results[0] as List<PharmacyModel>;
          _filteredDeliveries = results[1] as List<DeliveryModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل تحميل نتائج البحث: $e';
        });
      }
    }
  }

  Future<List<PharmacyModel>> _searchPharmacies(String queryText) async {
    final pharmaciesById = <String, PharmacyModel>{};

    final nameQuery = await FirebaseFirestore.instance
        .collection('pharmacies')
        .orderBy('name')
        .startAt([queryText])
        .endAt(['$queryText\uf8ff'])
        .limit(20)
        .get();

    for (final doc in nameQuery.docs) {
      final data = doc.data();
      if (data['status'] == 'approved') {
        pharmaciesById[doc.id] = PharmacyModel.fromFirestore(doc);
      }
    }

    final addressQuery = await FirebaseFirestore.instance
        .collection('pharmacies')
        .orderBy('address')
        .startAt([queryText])
        .endAt(['$queryText\uf8ff'])
        .limit(20)
        .get();

    for (final doc in addressQuery.docs) {
      final data = doc.data();
      if (data['status'] == 'approved') {
        pharmaciesById[doc.id] = PharmacyModel.fromFirestore(doc);
      }
    }

    return pharmaciesById.values.toList();
  }

  Future<List<DeliveryModel>> _searchDeliveries(String queryText) async {
    final deliveriesById = <String, DeliveryModel>{};

    final nameQuery = await FirebaseFirestore.instance
        .collection('deliveries')
        .orderBy('deliveryName')
        .startAt([queryText])
        .endAt(['$queryText\uf8ff'])
        .limit(20)
        .get();

    for (final doc in nameQuery.docs) {
      final data = doc.data();
      if (data['status'] == 'approved' && data['isActive'] == true) {
        deliveriesById[doc.id] = DeliveryModel.fromMap({'id': doc.id, ...data});
      }
    }

    final cityQuery = await FirebaseFirestore.instance
        .collection('deliveries')
        .orderBy('city')
        .startAt([queryText])
        .endAt(['$queryText\uf8ff'])
        .limit(20)
        .get();

    for (final doc in cityQuery.docs) {
      final data = doc.data();
      if (data['status'] == 'approved' && data['isActive'] == true) {
        deliveriesById[doc.id] = DeliveryModel.fromMap({'id': doc.id, ...data});
      }
    }

    return deliveriesById.values.toList();
  }

  void _onSearchChanged(String value) {
    if (!_hasSearched && _errorMessage == null) return;

    if (!mounted) return;

    setState(() {
      _hasSearched = false;
      _errorMessage = null;
      _filteredPharmacies = [];
      _filteredDeliveries = [];
    });
  }

  void _openPharmacy(PharmacyModel pharmacy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => PharmacyCubit(PharmacyRepository()),
          child: PharmacyDetailsScreen(pharmacyId: pharmacy.id),
        ),
      ),
    );
  }

  void _openDelivery(DeliveryModel delivery) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryDetailScreen(delivery: delivery),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppTheme.secondaryColor,
        title: const Text(
          'بحث الصيدليات والدليفري',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'اكتب وابحث من الكيبورد...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: _isLoading ? null : _performSearch,
                  icon: const Icon(Icons.search_rounded),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: AppLoadingIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Text(
          'اكتب الاسم ثم اضغط بحث من الكيبورد',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (_filteredPharmacies.isEmpty && _filteredDeliveries.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد نتائج مطابقة في الصيدليات أو الدليفري',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      children: [
        if (_filteredPharmacies.isNotEmpty) ...[
          const _ResultsHeader(
            title: 'الصيدليات',
            icon: Icons.local_pharmacy_rounded,
          ),
          const SizedBox(height: 8),
          ..._filteredPharmacies.map(_buildPharmacyTile),
          const SizedBox(height: 14),
        ],
        if (_filteredDeliveries.isNotEmpty) ...[
          const _ResultsHeader(
            title: 'الدليفري',
            icon: Icons.delivery_dining_rounded,
          ),
          const SizedBox(height: 8),
          ..._filteredDeliveries.map(_buildDeliveryTile),
        ],
      ],
    );
  }

  Widget _buildPharmacyTile(PharmacyModel pharmacy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: () => _openPharmacy(pharmacy),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFDFF5F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.local_pharmacy_rounded,
            color: Color(0xFF0B8293),
            size: 20,
          ),
        ),
        title: Text(
          pharmacy.name,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          pharmacy.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildDeliveryTile(DeliveryModel delivery) {
    final isAvailable = delivery.availableNow;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: () => _openDelivery(delivery),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE7FBEF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.delivery_dining_rounded,
            color: Color(0xFF16A34A),
            size: 20,
          ),
        ),
        title: Text(
          delivery.deliveryName,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${delivery.governorate} - ${delivery.city}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isAvailable
                ? const Color(0xFFDDF7EC)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            isAvailable ? 'متاح' : 'غير متاح',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isAvailable
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ResultsHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0B8293)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
