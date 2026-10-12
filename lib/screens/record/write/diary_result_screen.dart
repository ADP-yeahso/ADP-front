import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/emotions.dart';
import '../../../utils/emotion_utils.dart';
import 'diary_care_content_screen.dart';

class DiaryResultScreen extends StatelessWidget {
  final Emotion? emotion;

  const DiaryResultScreen({
    super.key,
    this.emotion,
  });

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
        errorBuilder: (context, error, stackTrace) => _tryPath(paths, index + 1, fallback),
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
    final activeEmotion = emotion ?? EmotionValues.neutral;
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // 1. 헤드라인 ("감정 기록 완료")
                _buildAssetWidget(
                  candidatePaths: const [
                    'assets/record/choice/svg/3-0,3-2-1~3-2-5대제목 수정.svg/svg/3-2-5 메인 헤드라인.svg',
                    'assets/record/choice/svg/3-2-5.svg/svg/3-2-5 메인 헤드라인.svg',
                    'assets/record/choice/png/3-2-5.png/png/3-2-5 메인 헤드라인.png',
                  ],
                  fallback: const Text(
                    '감정 기록 완료',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                    textAlign: TextAlign.center,
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
                              candidatePaths: _getGradientCardCandidatePaths(activeEmotion),
                              fallback: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [activeEmotion.color, activeEmotion.color.withValues(alpha: 0.7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
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

                      // 앞쪽 꽃카드 (메인 이미지 asset 또는 시안 다크 카드 렌더링)
                      _buildAssetWidget(
                        candidatePaths: const [
                          'assets/record/choice/svg/3-2-5.svg/svg/꽃카드.svg',
                          'assets/record/choice/png/3-2-5.png/png/꽃카드.png',
                        ],
                        fallback: Container(
                          width: 240,
                          height: 340,
                          decoration: BoxDecoration(
                            color: const Color(0xFF191919), // 시안 다크 톤
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // 위치 20*30 폰트크기 40 (은방울꽃)
                              const Positioned(
                                top: 24,
                                left: 20,
                                child: Text(
                                  '은방울꽃',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              // 위치 20*80 폰트크기 16 (꽃말)
                              const Positioned(
                                top: 68,
                                left: 20,
                                child: Text(
                                  '행복이 반드시 찾아옵니다',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              // 중앙 꽃 라인아트 드로잉
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 40),
                                  child: Icon(
                                    Icons.local_florist_outlined,
                                    size: 130,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                              // 우측 하단 배지 (크기 37*17, 위치 right 16, bottom 16)
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C4A28),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.park, size: 12, color: Color(0xFFA5DD82)),
                                      SizedBox(width: 2),
                                      Icon(Icons.local_florist, size: 12, color: Color(0xFFFFCB0F)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                            builder: (context) => const DiaryCareContentScreen(),
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
