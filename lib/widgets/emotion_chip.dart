import 'package:flutter/material.dart';

import '../models/emotion.dart';

class EmotionChip extends StatelessWidget {
  final Emotion emotion;
  const EmotionChip({super.key, required this.emotion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: emotion.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(emotion.flowerIcon, size: 14, color: emotion.color),
          const SizedBox(width: 6),
          Text(
            emotion.label,
            style: TextStyle(color: emotion.color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
