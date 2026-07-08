import 'package:flutter/material.dart';

import '../models/emotion.dart';
import '../models/recommendation.dart';

class RecommendationCard extends StatelessWidget {
  final Emotion emotion;
  final Recommendation recommendation;
  final VoidCallback? onPlayVoice;

  const RecommendationCard({
    super.key,
    required this.emotion,
    required this.recommendation,
    this.onPlayVoice,
  });

  @override
  Widget build(BuildContext context) {
    final r = recommendation;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emotion.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: emotion.color),
              const SizedBox(width: 6),
              Text('맞춤 감정 케어', style: TextStyle(fontWeight: FontWeight.w700, color: emotion.color)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text('"${r.quote}"', style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4))),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.volume_up_outlined),
                tooltip: '환자 목소리로 듣기',
                onPressed: onPlayVoice ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AI 음성 복원 재생은 준비 중이에요 (목업)')),
                      );
                    },
              ),
            ],
          ),
          const SizedBox(height: 6),
          _RecoRow(icon: Icons.music_note_outlined, text: r.musicTitle),
          const SizedBox(height: 4),
          _RecoRow(icon: Icons.self_improvement_outlined, text: r.activity),
        ],
      ),
    );
  }
}

class _RecoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RecoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87))),
      ],
    );
  }
}
