import 'package:flutter/material.dart';
import '../../data/models/medical_supply_model.dart';

// TODO: Implement full offers screen - placeholder for now
class MedicalSupplyOffersScreen extends StatelessWidget {
  final MedicalSupplyModel supply;

  const MedicalSupplyOffersScreen({super.key, required this.supply});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عروض المكان'),
        ),
        body: const Center(
          child: Text('صفحة العروض - قيد التطوير'),
        ),
      ),
    );
  }
}
