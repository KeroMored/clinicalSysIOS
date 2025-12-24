class LabTest {
  final String id;
  final String name;
  final String category;
  final String? description;

  const LabTest({
    required this.id,
    required this.name,
    required this.category,
    this.description,
  });
}

class LabTestCategories {
  static const String hematology = 'تحاليل الدم';
  static const String biochemistry = 'التحاليل الكيميائية';
  static const String microbiology = 'تحاليل الميكروبيولوجي';
  static const String immunology = 'تحاليل المناعة';
  static const String hormones = 'تحاليل الهرمونات';
  static const String tumourMarkers = 'دلالات الأورام';
  static const String urine = 'تحاليل البول';
  static const String stool = 'تحاليل البراز';
  static const String serology = 'تحاليل الأمصال';
  static const String other = 'أخرى';
}

class AvailableLabTests {
  static const List<LabTest> allTests = [
    // تحاليل الدم
    LabTest(
      id: 'cbc',
      name: 'صورة دم كاملة (CBC)',
      category: LabTestCategories.hematology,
      description: 'Complete Blood Count',
    ),
    LabTest(
      id: 'esr',
      name: 'سرعة الترسيب (ESR)',
      category: LabTestCategories.hematology,
    ),
    LabTest(
      id: 'blood_group',
      name: 'فصيلة الدم',
      category: LabTestCategories.hematology,
    ),
    LabTest(
      id: 'pt_ptt',
      name: 'زمن البروثرومبين والثرومبوبلاستين',
      category: LabTestCategories.hematology,
      description: 'PT & PTT',
    ),
    
    // التحاليل الكيميائية
    LabTest(
      id: 'blood_sugar',
      name: 'سكر الدم',
      category: LabTestCategories.biochemistry,
    ),
    LabTest(
      id: 'hba1c',
      name: 'السكر التراكمي (HbA1c)',
      category: LabTestCategories.biochemistry,
    ),
    LabTest(
      id: 'lipid_profile',
      name: 'دهون الدم الكاملة',
      category: LabTestCategories.biochemistry,
      description: 'Cholesterol, Triglycerides, HDL, LDL',
    ),
    LabTest(
      id: 'liver_function',
      name: 'وظائف الكبد',
      category: LabTestCategories.biochemistry,
      description: 'ALT, AST, Albumin, Bilirubin',
    ),
    LabTest(
      id: 'kidney_function',
      name: 'وظائف الكلى',
      category: LabTestCategories.biochemistry,
      description: 'Creatinine, Urea, Uric Acid',
    ),
    LabTest(
      id: 'electrolytes',
      name: 'أملاح الدم',
      category: LabTestCategories.biochemistry,
      description: 'Na, K, Cl, Ca, Mg',
    ),
    
    // تحاليل الميكروبيولوجي
    LabTest(
      id: 'urine_culture',
      name: 'مزرعة بول',
      category: LabTestCategories.microbiology,
    ),
    LabTest(
      id: 'stool_culture',
      name: 'مزرعة براز',
      category: LabTestCategories.microbiology,
    ),
    LabTest(
      id: 'throat_culture',
      name: 'مسحة حلق',
      category: LabTestCategories.microbiology,
    ),
    LabTest(
      id: 'blood_culture',
      name: 'مزرعة دم',
      category: LabTestCategories.microbiology,
    ),
    
    // تحاليل المناعة
    LabTest(
      id: 'hiv',
      name: 'فيروس نقص المناعة (HIV)',
      category: LabTestCategories.immunology,
    ),
    LabTest(
      id: 'hepatitis_b',
      name: 'التهاب الكبد ب (HBsAg)',
      category: LabTestCategories.immunology,
    ),
    LabTest(
      id: 'hepatitis_c',
      name: 'التهاب الكبد سي (HCV Ab)',
      category: LabTestCategories.immunology,
    ),
    
    // تحاليل الهرمونات
    LabTest(
      id: 'thyroid_profile',
      name: 'هرمونات الغدة الدرقية',
      category: LabTestCategories.hormones,
      description: 'TSH, T3, T4',
    ),
    LabTest(
      id: 'testosterone',
      name: 'هرمون التستوستيرون',
      category: LabTestCategories.hormones,
    ),
    LabTest(
      id: 'prolactin',
      name: 'هرمون البرولاكتين',
      category: LabTestCategories.hormones,
    ),
    LabTest(
      id: 'fsh_lh',
      name: 'هرمونات FSH & LH',
      category: LabTestCategories.hormones,
    ),
    LabTest(
      id: 'vitamin_d',
      name: 'فيتامين د',
      category: LabTestCategories.hormones,
    ),
    
    // دلالات الأورام
    LabTest(
      id: 'cea',
      name: 'CEA',
      category: LabTestCategories.tumourMarkers,
    ),
    LabTest(
      id: 'ca_125',
      name: 'CA 125',
      category: LabTestCategories.tumourMarkers,
    ),
    LabTest(
      id: 'ca_19_9',
      name: 'CA 19-9',
      category: LabTestCategories.tumourMarkers,
    ),
    LabTest(
      id: 'psa',
      name: 'PSA',
      category: LabTestCategories.tumourMarkers,
    ),
    LabTest(
      id: 'afp',
      name: 'AFP',
      category: LabTestCategories.tumourMarkers,
    ),
    
    // تحاليل البول
    LabTest(
      id: 'urine_analysis',
      name: 'تحليل بول كامل',
      category: LabTestCategories.urine,
    ),
    
    // تحاليل البراز
    LabTest(
      id: 'stool_analysis',
      name: 'تحليل براز كامل',
      category: LabTestCategories.stool,
    ),
    
    // تحاليل الأمصال
    LabTest(
      id: 'crp',
      name: 'بروتين سي التفاعلي (CRP)',
      category: LabTestCategories.serology,
    ),
    LabTest(
      id: 'aso',
      name: 'ASO',
      category: LabTestCategories.serology,
    ),
    LabTest(
      id: 'rf',
      name: 'عامل الروماتويد (RF)',
      category: LabTestCategories.serology,
    ),
    LabTest(
      id: 'widal',
      name: 'تحليل فيدال (Widal)',
      category: LabTestCategories.serology,
    ),
  ];

  static List<String> get allTestNames => allTests.map((test) => test.name).toList();
  
  static List<String> getTestsByCategory(String category) {
    return allTests
        .where((test) => test.category == category)
        .map((test) => test.name)
        .toList();
  }

  static List<String> get allCategories => [
        LabTestCategories.hematology,
        LabTestCategories.biochemistry,
        LabTestCategories.microbiology,
        LabTestCategories.immunology,
        LabTestCategories.hormones,
        LabTestCategories.tumourMarkers,
        LabTestCategories.urine,
        LabTestCategories.stool,
        LabTestCategories.serology,
        LabTestCategories.other,
      ];
}
