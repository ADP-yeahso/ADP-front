import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/garden_nav_controller.dart';

class DiaryCareContentScreen extends StatelessWidget {
  const DiaryCareContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // 솔루션 레이아웃 화이트 카드 영역 (시안 3-2-6 반영)
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 타이틀 ("이런 활동은 어떤가요?")
                        const Text(
                          '이런 활동은 어떤가요?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4개의 딥그린 솔루션 미니 박스 (2x2 그리드)
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            physics: const NeverScrollableScrollPhysics(),
                            children: List.generate(4, (index) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF386629), // 시안 딥 그린
                                  borderRadius: BorderRadius.circular(24),
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
              const SizedBox(height: 36),

              // 하단 노란색 원형 홈 버튼 (시안 3-2-6 반영)
              Center(
                child: GestureDetector(
                  onTap: () {
                    context.read<GardenNavController>().requestDate(DateTime.now());
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2B2), // 시안 소프트 노랑
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.home_rounded,
                        color: Color(0xFF2A4225), // 딥 그린 홈 아이콘
                        size: 32,
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
    );
  }
}
