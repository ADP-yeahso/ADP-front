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
    builder: (ctx) => _MemoryListSheet(memories: memories),
  );
}

class _MemoryListSheet extends StatefulWidget {
  final List<Memory> memories;
  const _MemoryListSheet({required this.memories});

  @override
  State<_MemoryListSheet> createState() => _MemoryListSheetState();
}

class _MemoryListSheetState extends State<_MemoryListSheet> {
  bool _showOnlyMine = false;

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return '오늘';
    if (target == yesterday) return '어제';
    return '${target.month}월 ${target.day}일';
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final me = appData.me;

    // 필터링 및 정렬 (최신순)
    var filtered = widget.memories;
    if (_showOnlyMine) {
      filtered = filtered.where((m) => m.userId == me.id).toList();
    }
    filtered = List.from(filtered)..sort((a, b) => b.recordDate.compareTo(a.recordDate));

    // 날짜별 그룹화
    final Map<String, List<Memory>> grouped = {};
    for (var m in filtered) {
      final label = _getDateLabel(m.recordDate);
      grouped.putIfAbsent(label, () => []).add(m);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.92,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF9F9F9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle & Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40), // Balance the close button
                      const Text(
                        '나무 기억보기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black45),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Filter Chips
                  Row(
                    children: [
                      _buildFilterChip('전체 기록', !_showOnlyMine, () {
                        setState(() => _showOnlyMine = false);
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('내 기록', _showOnlyMine, () {
                        setState(() => _showOnlyMine = true);
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black12),
            // Timeline List
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('기록이 없습니다.', style: TextStyle(color: Colors.black45)),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final label = grouped.keys.elementAt(index);
                        final items = grouped[label]!;
                        return _buildTimelineGroup(label, items, appData, index == grouped.length - 1);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B8A61) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B8A61) : Colors.black12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineGroup(String label, List<Memory> items, AppData appData, bool isLastGroup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6B8A61), width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ],
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 2,
                margin: const EdgeInsets.only(left: 3, top: 4, bottom: 4),
                color: isLastGroup ? Colors.transparent : Colors.black12,
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  child: Column(
                    children: items.map((m) => _buildMemoryCard(m, appData)).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryCard(Memory memory, AppData appData) {
    final timeStr = '${memory.recordDate.hour.toString().padLeft(2, '0')}:${memory.recordDate.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () {
        // 상세 보기 열기
        showMemoryDetailSheet(context, memory);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: memory.mediaList.isNotEmpty
                  ? const Icon(Icons.photo_outlined, color: Colors.black26)
                  : const Icon(Icons.eco_outlined, color: Colors.black26),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.contextText != null && memory.contextText!.isNotEmpty 
                        ? memory.contextText! 
                        : '나무에 남겨진 기억입니다.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${memory.recordDate.year}.${memory.recordDate.month.toString().padLeft(2, '0')}.${memory.recordDate.day.toString().padLeft(2, '0')} $timeStr',
                        style: const TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                      const Spacer(),
                      // Profile dummy
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 9,
                            backgroundColor: const Color(0xFFE0E0E0),
                            child: const Icon(Icons.person, size: 12, color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.more_horiz, size: 16, color: Colors.black38),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
                nickname: author.nickname,
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
                nickname: author.nickname,
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
