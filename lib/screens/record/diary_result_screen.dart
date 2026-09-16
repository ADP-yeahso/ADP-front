import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../data/emotion_analyzer.dart';
import '../../models/emotions.dart';
import '../../models/media.dart';
import '../../utils/emotion_utils.dart';
import '../../widgets/emotion_chip.dart';
import '../../widgets/recommendation_card.dart';

class DiaryResultScreen extends StatelessWidget {
  final DateTime date;
  final String content;
  final Emotion emotion;
  final bool isPublic;
  final List<Media> mediaList;

  const DiaryResultScreen({
    super.key,
    required this.date,
    required this.content,
    required this.emotion,
    required this.isPublic,
    this.mediaList = const [],
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = recommendationFor(emotion);

    return Scaffold(
      appBar: AppBar(title: const Text('감정 분석 결과')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('오늘 기록에서 이런 감정이 느껴져요', style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 10),
            EmotionChip(emotion: emotion),
            if (mediaList.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.perm_media_outlined, color: Color(0xFF6FBF8B)),
                    const SizedBox(width: 12),
                    Text(
                      '첨부된 미디어 ${mediaList.length}개 (사진/동영상/음성)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            RecommendationCard(emotion: emotion, recommendation: recommendation),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.local_florist),
                label: const Text('꽃으로 저장하기'),
                onPressed: () {
                  context.read<AppData>().addDiary(
                    date: date, 
                    content: content, 
                    emotion: emotion,
                    mediaList: mediaList,
                    isPublic: isPublic,
                  );
                  Navigator.popUntil(context, (route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('오늘의 감정이 꽃으로 피어났어요 🌸')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
