import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../data/garden_nav_controller.dart';

class DiaryCareContentScreen extends StatelessWidget {
  const DiaryCareContentScreen({super.key});

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                '은방울꽃',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // 추천 컨텐츠 / 솔루션 박스 영역
              Expanded(
                child: Center(
                  child: _buildAssetWidget(
                    candidatePaths: const [
                      'assets/record/choice/svg/3-2-6.svg/svg/3-2-6 솔루션 박스.svg',
                      'assets/record/choice/png/3-2-6.png/png/3-2-6 솔루션 박스.png',
                      'assets/record/choice/svg/3-2-6.svg/svg/3-2-6 솔루션레이아웃.svg',
                      'assets/record/choice/png/3-2-6.png/png/3-2-6 솔루션레이아웃.png',
                    ],
                    fallback: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.blueAccent.shade100, width: 2),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '지금 추천하는 활동',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              physics: const NeverScrollableScrollPhysics(),
                              children: List.generate(4, (index) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.blueAccent.shade100, width: 1.5),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // 홈 버튼 (3-2-6 홈 버튼)
              Center(
                child: GestureDetector(
                  onTap: () {
                    context.read<GardenNavController>().requestDate(DateTime.now());
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: _buildAssetWidget(
                      candidatePaths: const [
                        'assets/record/choice/svg/3-2-6.svg/svg/3-2-6 홈 버튼.svg',
                        'assets/record/choice/png/3-2-6.png/png/3-2-6 홈 버튼.png',
                      ],
                      fallback: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.home_outlined, color: Colors.blueAccent, size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
