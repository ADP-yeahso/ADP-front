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
    final values = <String>[
      '식사 $mealStatus',
      '수면 $sleepStatus',
    ];

    if (hasMedicalUpdate) {
      values.add('진료·약 변경');
    }

    return values.join(' · ');
  }
}

/// UI 확인용 mock 데이터.
/// 백엔드 API 연결 시 실제 응답 데이터로 교체합니다.
const mockPatientSummary = PatientSummaryViewData(
  name: '엄마',
  birthDate: '1942.05.13',
  diagnosisMonth: '2024.03',
  hospitalName: '○○대학교병원',
);

final mockCareRecords = <CareRecordViewData>[
  CareRecordViewData(
    date: DateTime(2026, 8, 12),
    mealStatus: '적음',
    sleepStatus: '나쁨',
    bowelStatus: '정상',
    medicationStatus: '완료',
    unusualChanges: const ['수면 변화'],
    note: '밤에 여러 번 깨셔서 오전에 피곤해하셨어요.',
  ),
  CareRecordViewData(
    date: DateTime(2026, 8, 10),
    mealStatus: '보통',
    sleepStatus: '보통',
    bowelStatus: '정상',
    medicationStatus: '완료',
    note: '정기 진료를 다녀왔어요.',
    hasMedicalUpdate: true,
    hospitalDepartment: '○○대학교병원 신경과',
    visitDetails: '정기 진료',
    medicationChanges: '복용약 용량 변경',
    nextVisitDate: DateTime(2026, 9, 10),
  ),
];