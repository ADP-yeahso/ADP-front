import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'diary_care_content_screen.dart';

class DiaryResultScreen extends StatelessWidget {
  const DiaryResultScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 헤드라인
              _buildAssetWidget(
                candidatePaths: const [
                  'assets/record/choice/svg/3-2-5.svg/svg/3-2-3 메인 헤드라인.svg',
                  'assets/record/choice/png/3-2-5.png/png/3-2-3 메인 헤드라인.png',
                ],
                fallback: const Text(
                  '감정 기록 완료',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '<은방울꽃>',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // 꽃카드 결과 이미지
              Expanded(
                child: Center(
                  child: _buildAssetWidget(
                    candidatePaths: const [
                      'assets/record/choice/svg/3-2-5.svg/svg/꽃카드.svg',
                      'assets/record/choice/png/3-2-5.png/png/꽃카드.png',
                    ],
                    fallback: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.green.shade200, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_florist,
                          size: 120,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // AI 요약 카드 / 컬러박스
              _buildAssetWidget(
                candidatePaths: const [
                  'assets/record/choice/svg/3-2-5.svg/svg/3-2-5 감사안도 컬러박스.svg',
                  'assets/record/choice/png/3-2-5.png/png/3-2-5 감사안도 컬러박스.png',
                  'assets/record/choice/svg/3-2-5.svg/svg/3-2-5 중립 컬러박스.svg',
                  'assets/record/choice/png/3-2-5.png/png/3-2-5 중립 컬러박스.png',
                ],
                fallback: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '오늘 마음속 피어난 꽃처럼\n따뜻한 하루가 마무리되었습니다 ✨',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // 다음 버튼
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DiaryCareContentScreen(),
                    ),
                  );
                },
                child: SizedBox(
                  height: 56,
                  child: _buildAssetWidget(
                    candidatePaths: const [
                      'assets/record/choice/svg/3-2-5.svg/svg/3-2-3 다음 버튼.svg',
                      'assets/record/choice/png/3-2-5.png/png/3-2-3 다음 버튼.png',
                    ],
                    fallback: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4E7B45),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '다음으로',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
    );
  }
}
