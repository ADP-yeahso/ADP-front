import 'package:flutter/material.dart';

class CareActivity {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isCommon;
  const CareActivity(this.id, this.title, this.description, this.icon, {this.isCommon = false});
}

class CareActivityCatalog {
  static const common = <CareActivity>[
    CareActivity('letter', '익명 편지함 작성하기', '마음을 담아 익명의 응원 편지를 작성해 보세요.', Icons.mail_outline, isCommon: true),
    CareActivity('manual', '치매 관리 매뉴얼', '돌봄에 도움이 되는 정보를 확인해 보세요.', Icons.menu_book_outlined, isCommon: true),
  ];

  static const byEmotion = <int, List<CareActivity>>{
    1: [
      CareActivity('anger_breathe', '4-4-6 호흡하기', '4초 들이마시고, 4초 멈춘 뒤, 6초 동안 천천히 내쉬어 보세요. 편한 만큼만 반복해요.', Icons.air),
      CareActivity('anger_break', '잠깐 자리 옮기기', '물 한 잔을 마시거나 잠시 다른 공간으로 이동해 숨을 돌려도 괜찮아요.', Icons.local_drink_outlined),
    ],
    2: [
      CareActivity('anxiety_sky', '하늘 바라보기', '창밖이나 하늘을 잠깐 바라보며 눈에 보이는 것을 천천히 살펴봐요.', Icons.wb_cloudy_outlined),
      CareActivity('anxiety_kind', '나에게 다정한 말 건네기', '마음속으로 “지금 많이 애쓰고 있구나”라고 말해보세요.', Icons.favorite_border),
    ],
    3: [
      CareActivity('sad_music', '좋아하는 노래 한 곡 듣기', '지금 떠오르는 노래 한 곡을 편안한 자세로 들어봐요.', Icons.music_note_outlined),
      CareActivity('sad_rest', '5분 쉬어가기', '잠시 쉬거나 오늘 할 일 하나를 미뤄도 괜찮아요.', Icons.self_improvement),
    ],
    4: [
      CareActivity('guilt_care', '오늘 해낸 돌봄 떠올리기', '오늘 내가 해낸 돌봄 한 가지를 떠올려보세요. 작은 일도 괜찮아요.', Icons.check_circle_outline),
      CareActivity('guilt_praise', '나에게 칭찬 한마디', '친한 사람에게 하듯 “오늘도 애썼어”라고 말해줘요.', Icons.volunteer_activism_outlined),
    ],
    5: [
      CareActivity('gratitude_note', '고마웠던 순간 적어두기', '오늘 마음에 남은 작은 좋은 순간을 한 줄로 남겨보세요.', Icons.edit_note),
      CareActivity('gratitude_self', '오늘의 나에게 고맙다고 하기', '“오늘도 애썼고, 고마워”라고 스스로에게 말해봐요.', Icons.favorite_border),
    ],
    6: [
      CareActivity('affection_touch', '손잡거나 다정한 말 건네기', '상대가 편안해하신다면 손을 잡거나 다정한 말을 건네보세요.', Icons.front_hand_outlined),
      CareActivity('affection_photo', '함께한 사진 한 장 보기', '함께한 사진을 한 장 골라 천천히 바라봐요. 보고 싶지 않다면 건너뛰어도 괜찮아요.', Icons.photo_outlined),
    ],
    7: [
      CareActivity('neutral_music', '좋아하는 노래 한 곡 듣기', '지금 떠오르는 노래 한 곡을 편안한 자세로 들어봐요.', Icons.music_note_outlined),
      CareActivity('neutral_photo', '함께한 사진 한 장 보기', '함께한 사진을 한 장 골라 천천히 바라봐요. 보고 싶지 않다면 건너뛰어도 괜찮아요.', Icons.photo_outlined),
    ],
  };

  static const labels = <int, String>{
    1: '분노·답답함', 2: '불안·초조', 3: '슬픔·소진',
    4: '죄책감·자책', 5: '감사·안도', 6: '애틋함·수용', 7: '중립',
  };

  static const colors = <int, Color>{
    1: Color(0xFFE36887), 2: Color(0xFFAEAEAE), 3: Color(0xFF5EA7FF),
    4: Color(0xFFD09ED7), 5: Color(0xFFFFE367), 6: Color(0xFFFF9131),
    7: Color(0xFF88C24D),
  };

  static List<CareActivity> activitiesFor(int emotionId) => [
    ...common,
    ...(byEmotion[emotionId] ?? byEmotion[7]!),
  ];
}
