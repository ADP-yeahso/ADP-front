import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/emotions.dart';
import '../../../utils/emotion_utils.dart';
import '../../../services/diary_service.dart';
import 'diary_care_content_screen.dart';
import 'pending_flower_card.dart';

class DiaryResultScreen extends StatelessWidget {
  final Emotion? emotion;
  final DiaryFinalization? finalization;

  const DiaryResultScreen({super.key, this.emotion, this.finalization});

  Widget _buildAssetWidget({
    required List<String> candidatePaths,
    required Widget fallback,
  }) {
    return _tryPath(candidatePaths, 0, fallback);
  }

  Widget _tryPath(List<String> paths, int index, Widget fallback) {
    if (index >= paths.length) return fallback;
    final path = paths[index];
    final isSvg = path.toLowerCase().endsWith('.svg');
    if (isSvg) {
      return SvgPicture.asset(
        path,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => fallback,
      );
    } else {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _tryPath(paths, index + 1, fallback),
      );
    }
  }

  List<String> _getGradientCardCandidatePaths(Emotion emotion) {
    String name = '중립';
    switch (emotion.id) {
      case 1:
        name = '분노답답';
        break;
      case 2:
        name = '불안초조';
        break;
      case 3:
        name = '슬픔소진';
        break;
      case 4:
        name = '죄책감자책';
        break;
      case 5:
        name = '감사안도';
        break;
      case 6:
        name = '애틋수용';
        break;
      case 0:
      case 7:
      default:
        name = '중립';
        break;
    }
    return [
      'assets/record/choice/svg/3-2-5그라데이션 컬러카드.svg/svg/3-2-5 $name 컬러박스.svg',
      if (name == '죄책감자책')
        'assets/record/choice/svg/3-2-5그라데이션 컬러카드.svg/svg/3-2-5 죄책감자책 컬라박스.svg',
      'assets/record/choice/png/3-2-5그라데이션 컬러카드.png/png/3-2-5 $name 컬러박스@3x.png',
      if (name == '죄책감자책')
        'assets/record/choice/png/3-2-5그라데이션 컬러카드.png/png/3-2-5 죄책감자책 컬라박스@3x.png',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final finalizedEmotion = finalization?.emotionId == null
        ? null
        : EmotionValues.values.firstWhere(
            (item) => item.id == finalization!.emotionId,
            orElse: () => EmotionValues.neutral,
          );
    final recommendationEmotion = emotion ?? finalizedEmotion;
    final activeEmotion = recommendationEmotion ?? EmotionValues.neutral;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF0),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Text(
                  '감정 기록 완료',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Meetme',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 30),

                // 2. 뒤 컬러카드 + 앞 꽃카드 (시안 중첩 카드 레이아웃)
                SizedBox(
                  height: 390,
                  width: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 뒤쪽 감정별 컬러카드 (살짝 기울어진 그라디언트 카드)
                      Transform.translate(
                        offset: const Offset(18, 18),
                        child: Transform.rotate(
                          angle: 0.08,
                          child: SizedBox(
                            width: 240,
                            height: 340,
                            child: _buildAssetWidget(
                              candidatePaths: _getGradientCardCandidatePaths(
                                activeEmotion,
                              ),
                              fallback: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      activeEmotion.color,
                                      activeEmotion.color.withValues(
                                        alpha: 0.7,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const PendingFlowerCard(),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // 3. 하단 다음 버튼 (180x52 연두색 버튼)
                Center(
                  child: SizedBox(
                    width: 180,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiaryCareContentScreen(
                              emotion: recommendationEmotion,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA5DD82),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Text(
                        '다음',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
