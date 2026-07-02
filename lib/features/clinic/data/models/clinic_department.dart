enum ClinicDepartment {
  pediatrics('أطفال وحضّانات', 'pediatrics'),
  dentistry('أسنان', 'dentistry'),
  internalMedicine('باطنة', 'internal_medicine'),
  dermatology('جلدية', 'dermatology'),
  orthopedics('عظام', 'orthopedics'),
  cardiology('قلب', 'cardiology'),
  ophthalmology('رمد', 'ophthalmology'),
  ent('أنف وأذن وحنجرة', 'ent'),
  obstetrics('نساء وولادة', 'obstetrics'),
  urology('مسالك بولية', 'urology'),
  psychiatry('نفسية وعصبية', 'psychiatry'),
  generalSurgery('جراحة عامة', 'general_surgery'),
  physiotherapy('علاج طبيعي', 'physiotherapy'),
  rehabilitation('مراكز تأهيل', 'rehabilitation'),
  other('تخصصات أخرى', 'other');

  final String arabicName;
  final String englishName;

  const ClinicDepartment(this.arabicName, this.englishName);

  static ClinicDepartment fromString(String value) {
    return ClinicDepartment.values.firstWhere(
      (dept) => dept.englishName == value,
      orElse: () => ClinicDepartment.other,
    );
  }
}
