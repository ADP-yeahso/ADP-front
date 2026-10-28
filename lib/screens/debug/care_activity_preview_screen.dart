import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/care_activity_catalog.dart';
import '../../utils/emotion_utils.dart';
import '../record/write/diary_result_screen.dart';

/// An isolated preview entry; it does not change authentication or diary state.
class CareActivityPreviewScreen extends StatelessWidget {
  const CareActivityPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(title: const Text('추천 활동 미리보기')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '테스트할 감정을 골라주세요.\n서버 호출과 일기 저장 없이 결과·추천 화면을 확인할 수 있어요.',
            style: TextStyle(height: 1.6),
          ),
          const SizedBox(height: 20),
          for (final emotion in EmotionValues.values)
            ListTile(
              leading: Icon(
                Icons.circle,
                color: CareActivityCatalog.groupFor(emotion.name)!.color,
              ),
              title: Text(CareActivityCatalog.groupFor(emotion.name)!.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiaryResultScreen(emotion: emotion),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
