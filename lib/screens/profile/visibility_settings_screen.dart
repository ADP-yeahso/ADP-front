import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../utils/emotion_utils.dart';

class VisibilitySettingsScreen extends StatelessWidget {
  const VisibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final myMemories = appData.memories.where((m) => m.userId == appData.me.id).toList()
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));
    final myDiaries = appData.diaries.where((d) => d.userId == appData.me.id).toList()
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

    return Scaffold(
      appBar: AppBar(title: const Text('기록 공개 범위 관리')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '공개로 설정한 기록만 가족 공유 화면에 표시돼요. 언제든 바꿀 수 있어요.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          if (myMemories.isEmpty && myDiaries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('아직 작성한 기록이 없어요.', style: TextStyle(color: Colors.black45)),
            ),
          if (myMemories.isNotEmpty) ...[
            const _SectionLabel('나무 기록 (잎)'),
            for (final memory in myMemories)
              _RecordRow(
                icon: Icons.eco,
                iconColor: const Color(0xFF6FBF8B),
                title: '가족 기록',
                date: memory.recordDate,
                isPublic: memory.isPublic,
                onToggle: () => appData.toggleMemoryPublic(memory.id),
              ),
            const SizedBox(height: 12),
          ],
          if (myDiaries.isNotEmpty) ...[
            const _SectionLabel('감정 일기 (꽃)'),
            for (final diary in myDiaries)
              _RecordRow(
                icon: diary.flowerType.emotionId.flowerIcon,
                iconColor: diary.flowerType.emotionId.color,
                title: diary.flowerType.emotionId.label,
                date: diary.recordDate,
                isPublic: appData.isDiaryPublic(diary.id),
                onToggle: () => appData.toggleDiaryPublic(diary.id),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black45)),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final DateTime date;
  final bool isPublic;
  final VoidCallback onToggle;

  const _RecordRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.date,
    required this.isPublic,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
      ]),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: iconColor.withValues(alpha: 0.15), child: Icon(icon, color: iconColor, size: 18)),
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text('${date.month}월 ${date.day}일', style: const TextStyle(fontSize: 12)),
          trailing: Switch(value: isPublic, onChanged: (_) => onToggle()),
        ),
      ),
    );
  }
}
