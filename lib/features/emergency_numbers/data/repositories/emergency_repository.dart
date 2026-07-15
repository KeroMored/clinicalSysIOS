import 'package:flutter/material.dart';
import '../models/emergency_number_model.dart';

class EmergencyRepository {
  // Get all emergency numbers
  List<EmergencyNumberModel> getEmergencyNumbers() {
    return [
      const EmergencyNumberModel(
        id: '1',
        title: 'الإسعاف',
        number: '123',
        description: 'خدمة الإسعاف والطوارئ الطبية',
        icon: Icons.local_hospital,
        color: Color(0xFFEF4444),
      ),
      const EmergencyNumberModel(
        id: '2',
        title: 'الشرطة - النجدة',
        number: '122',
        description: 'خدمة الشرطة والنجدة',
        icon: Icons.local_police,
        color: Color(0xFF3B82F6),
      ),
      const EmergencyNumberModel(
        id: '3',
        title: 'المطافي',
        number: '180',
        description: 'خدمة الإطفاء والحماية المدنية',
        icon: Icons.fire_truck,
        color: Color(0xFFF97316),
      ),
      const EmergencyNumberModel(
        id: '4',
        title: 'الخط الساخن - وزارة الصحة',
        number: '105',
        description: 'الاستعلامات الطبية والإرشادات الصحية',
        icon: Icons.phone_in_talk,
        color: Color(0xFF10B981),
      ),
      const EmergencyNumberModel(
        id: '5',
        title: 'حماية المستهلك',
        number: '19588',
        description: 'الشكاوى والبلاغات الخاصة بحماية المستهلك',
        icon: Icons.security,
        color: Color(0xFF8B5CF6),
      ),
    /*   const EmergencyNumberModel(
        id: '6',
        title: 'مكافحة المخدرات',
        number: '122',
        description: 'الإبلاغ عن قضايا المخدرات',
        icon: Icons.report,
        color: Color(0xFFDC2626),
      ), */
    ];
  }
}
