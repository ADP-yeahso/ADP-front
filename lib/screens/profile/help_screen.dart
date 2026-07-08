import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      q: '나무와 꽃은 각각 무엇을 의미하나요?',
      a: '중앙의 나무는 고정되어 있고, 환자분에 대한 기록(오늘 있었던 일, 사진·영상)이 잎으로 쌓여요. 나무 주변의 꽃은 보호자가 작성한 감정 일기이며, 꽃의 색은 그날 느낀 감정을 나타내요.',
    ),
    (
      q: '감정 분석은 어떻게 이루어지나요?',
      a: '일기를 작성하면 AI가 글의 내용을 분석해 기쁨·평온·슬픔·분노·죄책감 중 가장 두드러진 감정을 찾아내고, 그에 맞는 위로 문구·음악·행동을 추천해드려요.',
    ),
    (
      q: '가족 공유는 어떻게 설정하나요?',
      a: '일기나 나무 기록을 작성할 때 공개/비공개를 선택할 수 있어요. 공개로 설정한 기록만 가족 공유 화면에 표시되며, 마이 > 기록 공개 범위 관리에서 언제든 다시 바꿀 수 있어요.',
    ),
    (
      q: '환자의 목소리는 어떻게 들을 수 있나요?',
      a: '위로 문구 옆의 스피커 아이콘을 누르면 AI로 복원한 환자분의 목소리로 문구를 들을 수 있어요. (현재 데모 버전에서는 준비 중이에요)',
    ),
    (
      q: '기록은 삭제할 수 있나요?',
      a: '작성한 기록은 나무나 꽃을 눌러 상세 화면에서 확인할 수 있어요. 삭제 기능은 다음 업데이트에서 제공될 예정이에요.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('도움말')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final faq in _faqs)
            ExpansionTile(
              title: Text(faq.q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(faq.a, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.5)),
              ],
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('더 궁금한 점이 있으신가요?', style: TextStyle(fontSize: 13, color: Colors.black45)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('1:1 문의 기능은 준비 중이에요 (데모)')),
                  ),
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('1:1 문의하기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
