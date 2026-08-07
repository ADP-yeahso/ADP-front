import '../models/emotions.dart';
import '../models/legacy/recommendation.dart';
import '../utils/emotion_utils.dart';

// Text matching logic removed. AI model will handle classification later.

final Map<Emotion, Recommendation> _recommendations = {
  EmotionValues.anger: Recommendation(
    quote: '화가 나는 건 그만큼 애쓰고 있다는 증거예요.',
    musicTitle: '마음을 가라앉히는 자연의 소리',
    activity: '4초 들이쉬고 7초 참았다가 8초 내쉬는 호흡을 세 번 반복해 보세요.',
  ),
  EmotionValues.anxiety: Recommendation(
    quote: '불안한 마음은 당연한 거예요. 크게 심호흡을 해볼까요?',
    musicTitle: '마음이 편안해지는 백색소음',
    activity: '따뜻한 차 한 잔을 마시며 긴장을 풀어보세요.',
  ),
  EmotionValues.sadness: Recommendation(
    quote: '슬퍼도 괜찮아요. 그 마음, 잠시 내려놓아도 돼요.',
    musicTitle: '위로가 되는 잔잔한 피아노 선율',
    activity: '눈을 감고 가장 좋았던 기억을 떠올려 보세요.',
  ),
  EmotionValues.guilt: Recommendation(
    quote: '당신은 이미 최선을 다하고 있어요. 스스로를 탓하지 마세요.',
    musicTitle: '마음을 다독이는 잔잔한 목소리',
    activity: '5분만 밖으로 나가 걸으며 스스로에게 다정한 말을 건네보세요.',
  ),
  EmotionValues.gratitude: Recommendation(
    quote: '작은 감사함이 내일을 살아갈 큰 힘이 될 거예요.',
    musicTitle: '기분 좋은 아침의 어쿠스틱',
    activity: '오늘 가장 감사했던 일 하나를 주변에 나눠보세요.',
  ),
  EmotionValues.affection: Recommendation(
    quote: '누군가를 사랑하고 아끼는 마음이 오늘을 따뜻하게 만드네요.',
    musicTitle: '부드러운 재즈 플레이리스트',
    activity: '사랑하는 사람에게 따뜻한 안부 메시지를 보내보세요.',
  ),
};

// analyzeEmotion removed.

Recommendation recommendationFor(Emotion emotion) => _recommendations[emotion]!;
