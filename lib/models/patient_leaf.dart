class PatientLeaf {
  final String id;
  final DateTime date;
  final String title;
  final String content;
  final String authorId;
  final bool hasPhoto;
  bool isPublic;

  PatientLeaf({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.authorId,
    this.hasPhoto = false,
    this.isPublic = true,
  });
}
