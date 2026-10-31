import 'dart:math';

import '../models/emotions.dart';
import '../models/flower.dart';

class FlowerCardInfo {
  final int id;
  final int emotionId;
  final String name;
  final String meaning;
  final String assetPath;

  const FlowerCardInfo({
    required this.id,
    required this.emotionId,
    required this.name,
    required this.meaning,
    required this.assetPath,
  });

  Flower toFlower(Emotion emotion) => Flower(
    id: id,
    emotionId: emotion,
    flowerName: name,
    colorCode: '#88C24D',
    sentence: meaning,
  );
}

class FlowerCatalog {
  static const Map<int, List<FlowerCardInfo>> _cardsByEmotion = {
    1: [
      FlowerCardInfo(id: 1, emotionId: 1, name: '애기금어초', meaning: '내 마음을 알아주세요.', assetPath: 'assets/record/flower_card_pack/png/하양_애기금어초.png'),
      FlowerCardInfo(id: 2, emotionId: 1, name: '플록스', meaning: '내 가슴은 불타고 있습니다. 온화함, 안심', assetPath: 'assets/record/flower_card_pack/png/하양_플록스.png'),
      FlowerCardInfo(id: 3, emotionId: 1, name: '백일홍', meaning: '인연, 애정, 그리움', assetPath: 'assets/record/flower_card_pack/png/하양_백일홍.png'),
      FlowerCardInfo(id: 4, emotionId: 1, name: '거베라', meaning: '열정, 사랑, 당신을 사랑합니다.', assetPath: 'assets/record/flower_card_pack/png/하양_거베라.png'),
    ],
    2: [
      FlowerCardInfo(id: 5, emotionId: 2, name: '헬레보루스', meaning: '나의 불안을 진정시켜 주세요.', assetPath: 'assets/record/flower_card_pack/png/하양_헬레보루스.png'),
      FlowerCardInfo(id: 6, emotionId: 2, name: '스토크', meaning: '영원한 아름다움, 불안의 치유', assetPath: 'assets/record/flower_card_pack/png/하양_스토크.png'),
      FlowerCardInfo(id: 7, emotionId: 2, name: '제라늄', meaning: '그대가 있어 안심입니다, 평안', assetPath: 'assets/record/flower_card_pack/png/하양_제라늄.png'),
      FlowerCardInfo(id: 8, emotionId: 2, name: '보리지', meaning: '두려움을 없애다, 용기', assetPath: 'assets/record/flower_card_pack/png/하양_보리지.png'),
    ],
    3: [
      FlowerCardInfo(id: 9, emotionId: 3, name: '은방울꽃', meaning: '틀림없이 행복해집니다.', assetPath: 'assets/record/flower_card_pack/png/하양_은방울꽃.png'),
      FlowerCardInfo(id: 10, emotionId: 3, name: '아퀼레기아', meaning: '우둔, 과거의 소중한 추억, 상처받은 마음의 치유', assetPath: 'assets/record/flower_card_pack/png/하양_아퀼레기아.png'),
      FlowerCardInfo(id: 11, emotionId: 3, name: '용담초', meaning: '당신이 슬플 때 나는 사랑한다', assetPath: 'assets/record/flower_card_pack/png/하양_용담초.png'),
      FlowerCardInfo(id: 12, emotionId: 3, name: '물망초', meaning: '나를 잊지 마세요.', assetPath: 'assets/record/flower_card_pack/png/하양_물망초.png'),
    ],
    4: [
      FlowerCardInfo(id: 13, emotionId: 4, name: '델피늄', meaning: '당신을 행복하게 해줄게요, 정제된 슬픔, 영원한 기억의 유대', assetPath: 'assets/record/flower_card_pack/png/하양_델피늄.png'),
      FlowerCardInfo(id: 14, emotionId: 4, name: '칸나', meaning: '빛나는 성취, 존경, 건실한 희망', assetPath: 'assets/record/flower_card_pack/png/하양_칸나.png'),
      FlowerCardInfo(id: 15, emotionId: 4, name: '클레마티스', meaning: '고결함, 당신의 마음은 참으로 아름답습니다', assetPath: 'assets/record/flower_card_pack/png/하양_클레마티스.png'),
      FlowerCardInfo(id: 16, emotionId: 4, name: '아이리스', meaning: '행운, 지혜, 존경, 칭찬', assetPath: 'assets/record/flower_card_pack/png/하양_아이리스.png'),
    ],
    5: [
      FlowerCardInfo(id: 17, emotionId: 5, name: '캄파눌라', meaning: '감사, 성실', assetPath: 'assets/record/flower_card_pack/png/하양_캄파눌라.png'),
      FlowerCardInfo(id: 18, emotionId: 5, name: '프리지아', meaning: '새로운 시작, 응원, 활기', assetPath: 'assets/record/flower_card_pack/png/하양_프리지아.png'),
      FlowerCardInfo(id: 19, emotionId: 5, name: '영춘화', meaning: '희망, 사랑하는 마음', assetPath: 'assets/record/flower_card_pack/png/하양_영춘화.png'),
      FlowerCardInfo(id: 20, emotionId: 5, name: '메리골드', meaning: '반드시 찾아올 행복', assetPath: 'assets/record/flower_card_pack/png/하양_메리골드.png'),
    ],
    6: [
      FlowerCardInfo(id: 21, emotionId: 6, name: '한련화', meaning: '애국심, 어려움을 극복하는 강인함', assetPath: 'assets/record/flower_card_pack/png/하양_한련화.png'),
      FlowerCardInfo(id: 22, emotionId: 6, name: '메꽃', meaning: '서서히 깊숙이 들어가다', assetPath: 'assets/record/flower_card_pack/png/하양_메꽃.png'),
      FlowerCardInfo(id: 23, emotionId: 6, name: '리시안셔스', meaning: '변치 않는 사랑', assetPath: 'assets/record/flower_card_pack/png/하양_리시안셔스.png'),
      FlowerCardInfo(id: 24, emotionId: 6, name: '금잔화', meaning: '겸손과 인내', assetPath: 'assets/record/flower_card_pack/png/하양_금잔화.png'),
    ],
    7: [
      FlowerCardInfo(id: 25, emotionId: 7, name: '클로버', meaning: '행운과 평화', assetPath: 'assets/record/flower_card_pack/png/하양_클로버.png'),
      FlowerCardInfo(id: 26, emotionId: 7, name: '강아지풀', meaning: '순수한 마음과 추억', assetPath: 'assets/record/flower_card_pack/png/하양_강아지풀.png'),
    ],
  };

  static FlowerCardInfo randomCardForEmotion(
    Emotion emotion, {
    Random? random,
  }) {
    final options = _cardsByEmotion[emotion.id] ?? _cardsByEmotion[7]!;
    return options[(random ?? Random()).nextInt(options.length)];
  }

  static FlowerCardInfo? cardForName(String name) {
    for (final cards in _cardsByEmotion.values) {
      for (final card in cards) {
        if (card.name == name) return card;
      }
    }
    return null;
  }

  static Flower randomFlowerForEmotion(
    Emotion emotion, {
    Random? random,
  }) => randomCardForEmotion(emotion, random: random).toFlower(emotion);
}
