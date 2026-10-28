class PatientSummaryViewData {
  final String name;
  final String birthDate;
  final String diagnosisMonth;
  final String hospitalName;

  const PatientSummaryViewData({
    required this.name,
    required this.birthDate,
    required this.diagnosisMonth,
    required this.hospitalName,
  });
}

class CareRecordViewData {
  final DateTime date;
  final String activityStatus;
  final String moodStatus;
  final String cognitiveStatus;

  final String mealStatus;
  final String sleepStatus;
  final String bowelStatus;
  final String medicationStatus;

  final List<String> unusualChanges;
  final String note;

  final bool hasMedicalUpdate;
  final String hospitalDepartment;
  final String visitDetails;
  final String medicationChanges;
  final DateTime? nextVisitDate;

  const CareRecordViewData({
    required this.date,
    this.activityStatus = '',
    this.moodStatus = '',
    this.cognitiveStatus = '',
    required this.mealStatus,
    required this.sleepStatus,
    required this.bowelStatus,
    required this.medicationStatus,
    this.unusualChanges = const [],
    this.note = '',
    this.hasMedicalUpdate = false,
    this.hospitalDepartment = '',
    this.visitDetails = '',
    this.medicationChanges = '',
    this.nextVisitDate,
  });

  String get summary {
    final values = <String>['식사 $mealStatus', '수면 $sleepStatus'];

    if (hasMedicalUpdate) {
      values.add('진료·약 변경');
    }

    return values.join(' · ');
  }
}
