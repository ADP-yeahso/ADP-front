import 'package:flutter/material.dart';

import '../models/emotions.dart';
import '../utils/emotion_utils.dart';
class FlowerWidget extends StatelessWidget {
  final Emotion emotion;
  final double size;
  final VoidCallback onTap;

  const FlowerWidget({
    super.key,
    required this.emotion,
    required this.onTap,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: emotion.color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: emotion.color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            alignment: Alignment.center,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(emotion.color, BlendMode.srcIn),
              child: Image.asset(
                'assets/images/flower.png',
                width: size * 0.82,
                height: size * 0.82,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(width: 3, height: 14, color: const Color(0xFF7FA36B)),
        ],
      ),
    );
  }
}
