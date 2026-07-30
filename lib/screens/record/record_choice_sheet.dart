import 'package:flutter/material.dart';

import 'diary_write_screen.dart';
import 'patient_info_screen.dart';

class RecordChoiceSheet extends StatelessWidget {
  const RecordChoiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height;

    return Container(
      height: height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F5EE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '기록을 남겨볼까요?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
          ),
          const SizedBox(height: 36),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ChoiceCard(
                  icon: Icons.park_outlined,
                  iconColor: const Color(0xFF6FBF8B),
                  title: '환자 기록하기',
                  subtitle: '오늘 있었던 일, 사진을 나무의 잎으로 남겨요',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientInfoScreen()));
                  },
                ),
                const SizedBox(height: 20),
                _ChoiceCard(
                  icon: Icons.local_florist_outlined,
                  iconColor: const Color(0xFFE1613B),
                  title: '마음 기록하기',
                  subtitle: '나의 돌봄 경험과 감정을 꽃으로 남겨요',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DiaryWriteScreen()));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: iconColor.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
