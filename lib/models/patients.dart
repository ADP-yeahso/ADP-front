import 'emergency_contact.dart';
import 'medication.dart';

class Patient {
  final String dementiaType;
  final String diseaseStage;
  final String behaviorPatterns;
  final String livingArrangement;
  final int id;
  final int groupId;
  final String patientName;
  final int patientBirthDate;
  final DateTime createdAt;
  final String? profileImageUrl;
  final int? dementiaDiagnosisYearMonth;
  final List<String> majorDiseases;
  final String primaryHospital;
  final String medicalDepartment;
  final List<Medication> medications;
  final List<EmergencyContact> emergencyContacts;

  Patient({
    this.dementiaType = '',
    this.diseaseStage = '',
    this.behaviorPatterns = '',
    this.livingArrangement = '',
    required this.id,
    required this.groupId,
    required this.patientName,
    required this.patientBirthDate,
    required this.createdAt,
    this.profileImageUrl,
    this.dementiaDiagnosisYearMonth,
    this.majorDiseases = const [],
    this.primaryHospital = '',
    this.medicalDepartment = '',
    this.medications = const [],
    this.emergencyContacts = const [],
  });
}
