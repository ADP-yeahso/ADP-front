import 'package:flutter/material.dart';

class DementiaCareManualScreen extends StatelessWidget {
  const DementiaCareManualScreen({super.key});

  static const _sections = [
    (
      Icons.chat_bubble_outline,
      '편안하게 대화하기',
      '짧고 쉬운 문장으로 한 번에 한 가지씩 말해주세요. 틀린 기억을 바로잡기보다 감정을 먼저 인정해주는 것이 도움이 됩니다.',
    ),
    (
      Icons.schedule_outlined,
      '익숙한 일과 유지하기',
      '식사·복약·수면 시간을 가능한 일정하게 유지하고, 새로운 활동은 충분한 설명과 함께 천천히 시작해주세요.',
    ),
    (
      Icons.health_and_safety_outlined,
      '안전한 환경 만들기',
      '미끄러운 물건과 걸려 넘어질 장애물을 치우고, 자주 쓰는 물건은 눈에 잘 띄는 일정한 자리에 두세요.',
    ),
    (
      Icons.warning_amber_rounded,
      '갑작스러운 변화 살피기',
      '의식·행동·식사량이 갑자기 달라지거나 통증, 발열, 호흡곤란이 있으면 의료기관에 문의하세요.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(title: const Text('치매 관리 안내')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '일상 돌봄에서 기억해 주세요',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            '아래 내용은 일상 돌봄을 위한 일반적인 안내이며 의료인의 진단이나 치료를 대신하지 않습니다.',
            style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          for (final section in _sections)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(section.$1, color: const Color(0xFF386629)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.$2,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            section.$3,
                            style: const TextStyle(fontSize: 14, height: 1.55),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            '응급 상황이 의심되면 119 또는 가까운 응급의료기관에 연락하세요.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
