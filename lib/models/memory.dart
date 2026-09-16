import 'media.dart';

class Memory {
  final int id;
  final int patientId;
  final int userId;
  final String? contextText;
  final List<Media> mediaList;
  final bool isPublic;
  final DateTime recordDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Memory({
    required this.id,
    required this.patientId,
    required this.userId,
    this.contextText,
    required this.mediaList,
    required this.isPublic,
    required this.recordDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
}
