import '../models/emotions.dart';
import '../models/legacy/recommendation.dart';
import '../utils/emotion_utils.dart';

class EmotionAnalysisResult {
  final Emotion primary;
  final Map<Emotion, double> scores;

  const EmotionAnalysisResult(this.primary, this.scores);
}

final Map<Emotion, List<String>> _keywords = {
  // 분노 / 답답함
  EmotionValues.anger: [
    '화나',
    '화가',
    '짜증',
    '답답',
    '분노',
    '억울',
    '열받',
    '화났',
    '참기 힘들',
    '미치겠',
  ],

  // 불안 / 초조
  EmotionValues.anxiety: [
    '불안',
    '걱정',
    '초조',
    '두렵',
    '무섭',
    '긴장',
    '조마조마',
    '어떡하지',
    '신경 쓰',
    '마음이 놓이지',
  ],

  // 슬픔 / 소진
  EmotionValues.sadness: [
    '슬프',
    '눈물',
    '힘들',
    '지치',
    '외롭',
    '그립',
    '울었',
    '속상',
    '눈물이',
    '버겁',
    '기운이 없',
    '지쳤',
  ],

  // 죄책감 / 자책
  EmotionValues.guilt: [
    '미안',
    '죄책감',
    '후회',
    '자책',
    '잘못한',
    '미안해서',
    '내 탓',
    '더 잘할걸',
    '내가 잘못',
  ],

  // 감사 / 안도
  EmotionValues.gratitude: [
    '고맙',
    '감사',
    '다행',
    '안도',
    '안심',
    '마음이 놓',
    '행복',
    '기쁘',
    '좋았',
    '웃었',
  ],

  // 애틋함 / 수용
  EmotionValues.affection: [
    '사랑',
    '소중',
    '애틋',
    '그립',
    '함께',
    '추억',
    '보고 싶',
    '곁에',
    '받아들이',
    '이해하게',
    '안아주',
  ],

  // 중립
  EmotionValues.neutral: [
    '평범',
    '그냥',
    '보통',
    '괜찮',
    '무난',
    '평소',
    '특별한 일 없',
    '별일 없',
    '일상',
  ],
};

final Map<Emotion, Recommendation> _recommendations = {
  EmotionValues.anger: Recommendation(
    quote: '잠시 멈추고 마음의 속도를 늦춰도 괜찮아요.',
    musicTitle: '마음을 가라앉히는 자연의 소리',
    activity: '잠시 자리를 벗어나 천천히 세 번 호흡해 보세요.',
  ),

  EmotionValues.anxiety: Recommendation(
    quote: '지금 모든 일을 한 번에 해결하지 않아도 괜찮아요.',
    musicTitle: '긴장을 풀어주는 잔잔한 음악',
    activity: '지금 가장 걱정되는 일을 한 문장으로 적어 보세요.',
  ),

  EmotionValues.sadness: Recommendation(
    quote: '지친 마음도 돌봄이 필요한 마음이에요.',
    musicTitle: '위로가 되는 잔잔한 피아노 선율',
    activity: '따뜻한 차 한 잔과 함께 잠시 쉬어가세요.',
  ),

  EmotionValues.guilt: Recommendation(
    quote: '완벽한 돌봄보다 지속할 수 있는 돌봄이 더 중요해요.',
    musicTitle: '마음을 다독이는 잔잔한 음악',
    activity: '오늘 내가 해낸 일을 한 가지 떠올려 보세요.',
  ),

  EmotionValues.gratitude: Recommendation(
    quote: '작은 안도와 감사도 오늘을 버티게 해주는 힘이에요.',
    musicTitle: '따뜻하고 편안한 어쿠스틱 음악',
    activity: '오늘 고마웠던 순간을 짧게 기록해 보세요.',
  ),

  EmotionValues.affection: Recommendation(
    quote: '함께한 기억은 오래도록 마음에 남아 있어요.',
    musicTitle: '따뜻한 추억을 떠올리는 잔잔한 음악',
    activity: '오늘 떠오른 소중한 기억 하나를 기록해 보세요.',
  ),

  EmotionValues.neutral: Recommendation(
    quote: '특별하지 않은 하루도 충분히 소중한 기록이에요.',
    musicTitle: '편안하게 들을 수 있는 잔잔한 음악',
    activity: '오늘 하루를 한 문장으로 정리해 보세요.',
  ),
};

EmotionAnalysisResult analyzeEmotion(String text) {
  final counts = <Emotion, int>{
    for (final emotion in EmotionValues.values) emotion: 0,
  };

  for (final entry in _keywords.entries) {
    for (final keyword in entry.value) {
      if (text.contains(keyword)) {
        counts[entry.key] = counts[entry.key]! + 1;
      }
    }
  }

  final total = counts.values.fold<int>(
    0,
    (sum, value) => sum + value,
  );

  Map<Emotion, double> scores;
  Emotion primary;

  if (total == 0) {
    // 감정 키워드를 찾지 못했을 때는 중립으로 처리
    scores = {
      EmotionValues.anger: 0.0,
      EmotionValues.anxiety: 0.0,
      EmotionValues.sadness: 0.0,
      EmotionValues.guilt: 0.0,
      EmotionValues.gratitude: 0.0,
      EmotionValues.affection: 0.0,
      EmotionValues.neutral: 1.0,
    };

    primary = EmotionValues.neutral;
  } else {
    scores = counts.map(
      (emotion, count) => MapEntry(
        emotion,
        count / total,
      ),
    );

    primary = counts.entries.reduce(
      (current, next) =>
          next.value > current.value ? next : current,
    ).key;
  }

  return EmotionAnalysisResult(
    primary,
    scores,
  );
}

Recommendation recommendationFor(Emotion emotion) {
  return _recommendations[emotion]!;
}