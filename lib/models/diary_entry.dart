import 'emotion.dart';
import 'recommendation.dart';

class DiaryEntry {
  final String id;
  final DateTime date;
  final String content;
  final String authorId;
  final Emotion emotion;
  final Map<Emotion, double> emotionScores;
  final Recommendation recommendation;
  bool isPublic;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.content,
    required this.authorId,
    required this.emotion,
    required this.emotionScores,
    required this.recommendation,
    this.isPublic = true,
  });
}
