import 'package:flutter/material.dart';
import '../../data/models/medical_supply_model.dart';

// TODO: Implement full manage screen - placeholder for now
class ManageMedicalSupplyScreen extends StatelessWidget {
  final MedicalSupplyModel supply;

  const ManageMedicalSupplyScreen({super.key, required this.supply});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المكان'),
        ),
        body: const Center(
          child: Text('صفحة إدارة المكان - قيد التطوير'),
        ),
      ),
    );
  }
}
