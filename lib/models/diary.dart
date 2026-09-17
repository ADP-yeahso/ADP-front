import 'flower.dart';
import 'media.dart';

class Diary {
  final int id;
  final int userId;
  final String context;
  final Flower flowerType;
  final List<Media> mediaList;
  final DateTime recordDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Diary({
    required this.id,
    required this.userId,
    required this.context,
    required this.flowerType,
    required this.mediaList,
    required this.recordDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
}
