import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/diary.dart';
import '../../models/memory.dart';
import '../../widgets/emotion_chip.dart';
import '../../widgets/recommendation_card.dart';
import '../../data/emotion_analyzer.dart';

String _fmtDate(DateTime d) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${d.year}년 ${d.month}월 ${d.day}일 (${weekdays[d.weekday - 1]})';
}

Future<void> showMemoryListSheet(BuildContext context, List<Memory> memories) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SheetScaffold(
      title: '이달의 나무 기록',
      child: memories.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('이번 달에 기록된 잎이 아직 없어요.'),
            )
          : Material(
              color: Colors.transparent,
              child: Column(
                children: memories
                    .map((m) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFF3ECD3),
                            child: Icon(Icons.eco, color: Color(0xFF8A6142)),
                          ),
                          title: const Text('가족 기록', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(_fmtDate(m.recordDate)),
                          onTap: () {
                            Navigator.pop(ctx);
                            showMemoryDetailSheet(context, m);
                          },
                        ))
                    .toList(),
              ),
            ),
    ),
  );
}

void showMemoryDetailSheet(BuildContext context, Memory memory) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SheetScaffold(
      title: '나무 기록',
      child: Consumer<AppData>(
        builder: (context, appData, _) {
          final author = appData.userById(memory.userId);
          final isOwner = memory.userId == appData.me.id;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_fmtDate(memory.recordDate), style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              const Text('가족 기록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (memory.mediaList.isNotEmpty)
                Container(
                  height: 140,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEAE0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_outlined, size: 32, color: Colors.black38),
                      SizedBox(height: 4),
                      Text('사진이 첨부되었어요', style: TextStyle(color: Colors.black45, fontSize: 12)),
                    ],
                  ),
                ),
              Text(memory.contextText ?? '', style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 20),
              _AuthorAndVisibility(
                nickname: author.name,
                isPublic: memory.isPublic,
                isOwner: isOwner,
                onToggle: () => appData.toggleMemoryPublic(memory.id),
              ),
            ],
          );
        },
      ),
    ),
  );
}

Future<void> showDiaryDetailSheet(BuildContext context, Diary diary) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SheetScaffold(
      title: '감정 일기',
      child: Consumer<AppData>(
        builder: (context, appData, _) {
          final author = appData.userById(diary.userId);
          final isOwner = diary.userId == appData.me.id;
          final isPublic = appData.isDiaryPublic(diary.id);
          final emotion = diary.flowerType.emotionId;
          final recommendation = recommendationFor(emotion);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(_fmtDate(diary.recordDate), style: const TextStyle(color: Colors.black54))),
                  EmotionChip(emotion: emotion),
                ],
              ),
              const SizedBox(height: 14),
              Text(diary.context, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 18),
              RecommendationCard(emotion: emotion, recommendation: recommendation),
              const SizedBox(height: 18),
              _AuthorAndVisibility(
                nickname: author.name,
                isPublic: isPublic,
                isOwner: isOwner,
                onToggle: () => appData.toggleDiaryPublic(diary.id),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _AuthorAndVisibility extends StatelessWidget {
  final String nickname;
  final bool isPublic;
  final bool isOwner;
  final VoidCallback onToggle;

  const _AuthorAndVisibility({
    required this.nickname,
    required this.isPublic,
    required this.isOwner,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 16, color: Colors.black45),
        const SizedBox(width: 4),
        Text(nickname, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const Spacer(),
        Icon(isPublic ? Icons.visibility_outlined : Icons.lock_outline, size: 16, color: Colors.black45),
        const SizedBox(width: 4),
        Text(isPublic ? '가족에게 공개' : '비공개', style: const TextStyle(fontSize: 13, color: Colors.black54)),
        if (isOwner)
          Switch(value: isPublic, onChanged: (_) => onToggle()),
      ],
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
