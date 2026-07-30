import '../models/emotions.dart';
import '../models/legacy/recommendation.dart';
import '../utils/emotion_utils.dart';

class EmotionAnalysisResult {
  final Emotion primary;
  final Map<Emotion, double> scores;

  const EmotionAnalysisResult(this.primary, this.scores);
}

final Map<Emotion, List<String>> _keywords = {
  EmotionValues.sadness: ['슬프', '눈물', '힘들', '지치', '외롭', '그립', '울었', '속상', '눈물이'],
  EmotionValues.anger: ['화나', '화가', '짜증', '답답', '분노', '억울', '열받', '화났'],
  EmotionValues.guilt: ['미안', '죄책감', '후회', '자책', '잘못한', '미안해서'],
  EmotionValues.joy: ['고맙', '행복', '웃', '기쁘', '다행', '감사', '좋았', '웃었'],
  EmotionValues.calm: ['편안', '안정', '괜찮', '차분', '평온'],
};

final Map<Emotion, Recommendation> _recommendations = {
  EmotionValues.joy: Recommendation(
    quote: '오늘의 웃음이 내일을 버티는 힘이 되어줄 거예요.',
    musicTitle: '햇살 좋은 날의 어쿠스틱 플레이리스트',
    activity: '오늘의 기쁜 순간을 사진으로 남겨 보세요.',
  ),
  EmotionValues.calm: Recommendation(
    quote: '지금처럼만 하셔도 이미 충분히 잘하고 계세요.',
    musicTitle: '숲속 새소리 백색소음',
    activity: '가벼운 스트레칭으로 하루를 정리해 보세요.',
  ),
  EmotionValues.sadness: Recommendation(
    quote: '슬퍼도 괜찮아요. 그 마음, 잠시 내려놓아도 돼요.',
    musicTitle: '위로가 되는 잔잔한 피아노 선율',
    activity: '따뜻한 차 한 잔과 함께 5분만 쉬어가세요.',
  ),
  EmotionValues.anger: Recommendation(
    quote: '화가 나는 건 그만큼 애쓰고 있다는 증거예요.',
    musicTitle: '마음을 가라앉히는 자연의 소리',
    activity: '4초 들이쉬고 7초 참았다가 8초 내쉬는 호흡을 세 번 반복해 보세요.',
  ),
  EmotionValues.guilt: Recommendation(
    quote: '당신은 이미 최선을 다하고 있어요. 스스로를 탓하지 마세요.',
    musicTitle: '마음을 다독이는 잔잔한 목소리',
    activity: '5분만 밖으로 나가 걸으며 스스로에게 다정한 말을 건네보세요.',
  ),
};

EmotionAnalysisResult analyzeEmotion(String text) {
  final counts = <Emotion, int>{for (final e in EmotionValues.values) e: 0};

  for (final entry in _keywords.entries) {
    for (final kw in entry.value) {
      if (text.contains(kw)) {
        counts[entry.key] = counts[entry.key]! + 1;
      }
    }
  }

  final total = counts.values.fold<int>(0, (a, b) => a + b);
  Map<Emotion, double> scores;
  Emotion primary;

  if (total == 0) {
    scores = {
      EmotionValues.calm: 0.6,
      EmotionValues.joy: 0.1,
      EmotionValues.sadness: 0.1,
      EmotionValues.anger: 0.1,
      EmotionValues.guilt: 0.1,
    };
    primary = EmotionValues.calm;
  } else {
    scores = counts.map((k, v) => MapEntry(k, v / total));
    primary = counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  return EmotionAnalysisResult(primary, scores);
}

Recommendation recommendationFor(Emotion emotion) => _recommendations[emotion]!;
