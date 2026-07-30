class Patient {
  final int id;
  final int groupId;
  final String patientName;
  final int patientBirthDate;
  final DateTime createdAt;

  Patient({
    required this.id,
    required this.groupId,
    required this.patientName,
    required this.patientBirthDate,
    required this.createdAt,
  });
}
