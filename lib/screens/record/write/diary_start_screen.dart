import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'diary_situation_screen.dart';

class DiaryStartScreen extends StatelessWidget {
  const DiaryStartScreen({super.key});

  Widget _buildAssetWidget({
    required List<String> candidatePaths,
    required Widget fallback,
    double? width,
    double? height,
  }) {
    return _tryPath(candidatePaths, 0, fallback, width, height);
  }

  Widget _tryPath(List<String> paths, int index, Widget fallback, double? width, double? height) {
    if (index >= paths.length) return fallback;
    final path = paths[index];
    final isSvg = path.toLowerCase().endsWith('.svg');
    if (isSvg) {
      return SvgPicture.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => fallback,
      );
    } else {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _tryPath(paths, index + 1, fallback, width, height),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2C3E50), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 캐릭터 원형 영역 (280x280)
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: _buildAssetWidget(
                      candidatePaths: const [
                        'assets/record/choice/svg/3-2-0.svg/svg/3-2-0 다람쥐아이콘1.svg',
                        'assets/record/choice/png/3-2-0.png/png/3-2-0 다람쥐아이콘1.png',
                      ],
                      fallback: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCDCDC),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 메인 헤드라인 ("오늘의 꽃을 심어볼까요?")
                  _buildAssetWidget(
                    height: 32,
                    candidatePaths: const [
                      'assets/record/choice/svg/3-2-0.svg/svg/3-2-0 메인 헤드라인.svg',
                      'assets/record/choice/png/3-2-0.png/png/3-2-0 메인 헤드라인.png',
                    ],
                    fallback: const Text(
                      '오늘의 꽃을 심어볼까요?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 44),

                  // 1. 심을래요! 버튼 (220x54)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DiarySituationScreen(),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 220,
                      height: 54,
                      child: _buildAssetWidget(
                        candidatePaths: const [
                          'assets/record/choice/svg/3-2-0.svg/svg/3-2-0 심을래요 버튼.svg',
                          'assets/record/choice/png/3-2-0.png/png/3-2-0 심을래요 버튼.png',
                        ],
                        fallback: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFA5DD82),
                            borderRadius: BorderRadius.circular(27),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '심을래요',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. 나중에요... 버튼 (220x54)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SizedBox(
                      width: 220,
                      height: 54,
                      child: _buildAssetWidget(
                        candidatePaths: const [
                          'assets/record/choice/svg/3-2-0.svg/svg/3-2-0 나중에요...버튼.svg',
                          'assets/record/choice/png/3-2-0.png/png/3-2-0 나중에요...버튼.png',
                        ],
                        fallback: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2B2),
                            borderRadius: BorderRadius.circular(27),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '나중에요..',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

