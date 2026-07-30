import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../data/emotion_analyzer.dart';
import '../../models/emotions.dart';
import '../../utils/emotion_utils.dart';
import '../../widgets/emotion_chip.dart';
import '../../widgets/recommendation_card.dart';

class DiaryResultScreen extends StatelessWidget {
  final DateTime date;
  final String content;
  final bool isPublic;

  const DiaryResultScreen({
    super.key,
    required this.date,
    required this.content,
    required this.isPublic,
  });

  @override
  Widget build(BuildContext context) {
    final analysis = analyzeEmotion(content);
    final recommendation = recommendationFor(analysis.primary);
    final sortedScores = analysis.scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('감정 분석 결과')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('오늘 기록에서 이런 감정이 느껴져요', style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 10),
            EmotionChip(emotion: analysis.primary),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF7F5EE), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('감정 분포', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 12),
                  for (final e in sortedScores) _ScoreBar(emotion: e.key, value: e.value),
                ],
              ),
            ),
            const SizedBox(height: 20),
            RecommendationCard(emotion: analysis.primary, recommendation: recommendation),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.local_florist),
                label: const Text('꽃으로 저장하기'),
                onPressed: () {
                  context.read<AppData>().addDiary(date: date, content: content, isPublic: isPublic);
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

class _ScoreBar extends StatelessWidget {
  final Emotion emotion;
  final double value;
  const _ScoreBar({required this.emotion, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text(emotion.label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: emotion.color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(emotion.color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text('${(value * 100).round()}%', style: const TextStyle(fontSize: 11, color: Colors.black45)),
          ),
        ],
      ),
    );
  }
}
