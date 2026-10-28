import 'flower.dart';
import 'media.dart';

class Diary {
  final int id;
  final String userId;
  final String? title;
  final String context;
  final Flower flowerType;
  final List<Media> mediaList;
  final DateTime recordDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isFinalized;

  bool get hasFlower => flowerType.id > 0;

  /// A draft is displayable only after the server has persisted all three
  /// selected tags and their majority label against the saved AI snapshot.
  static bool hasSavedEmotion(Map<String, dynamic> value) {
    final finalId = value['final_emotion_id'];
    if (finalId is! int || value['deleted_at'] != null) return false;
    if (value['status'] == 'completed') return true;
    if (value['status'] != 'draft' || value['correct_emotion_id'] is! int) {
      return false;
    }
    final predictions = value['ai_emotion_predictions'];
    final selected = value['selected_emotion_tags'];
    if (predictions is! List ||
        predictions.length != 2 ||
        selected is! List ||
        selected.length != 3) {
      return false;
    }
    final primary = predictions.first;
    if (primary is! Map || primary['emotion_id'] != finalId) return false;
    final parents = <int, int>{};
    for (final prediction in predictions) {
      if (prediction is! Map ||
          prediction['emotion_id'] is! int ||
          prediction['tags'] is! List) {
        return false;
      }
      for (final tag in prediction['tags'] as List) {
        if (tag is Map && tag['id'] is int) {
          parents[tag['id'] as int] = prediction['emotion_id'] as int;
        }
      }
    }
    final ids = <int>{};
    final votes = <int, int>{};
    for (final tag in selected) {
      if (tag is! Map || tag['id'] is! int) return false;
      final id = tag['id'] as int;
      final parent = parents[id];
      if (parent == null || !ids.add(id)) return false;
      votes[parent] = (votes[parent] ?? 0) + 1;
    }
    return (votes[value['correct_emotion_id']] ?? 0) >= 2;
  }

  Diary({
    required this.id,
    required this.userId,
    this.title,
    required this.context,
    required this.flowerType,
    required this.mediaList,
    required this.recordDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isFinalized = true,
  });
}
