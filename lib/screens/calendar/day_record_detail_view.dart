import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/diary.dart';
import '../../models/memory.dart';
import '../../widgets/emotion_chip.dart';
import '../garden/entry_detail_sheet.dart';

enum _RecordViewType { tree, flower }

class DayRecordDetailView extends StatefulWidget {
  final DateTime day;

  const DayRecordDetailView({
    super.key,
    required this.day,
  });

  @override
  State<DayRecordDetailView> createState() =>
      _DayRecordDetailViewState();
}

class _DayRecordDetailViewState extends State<DayRecordDetailView> {
  // 상세 화면 진입 시 초기에는 나무 기록 선택
  _RecordViewType _selectedType = _RecordViewType.tree;

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();

    final treeRecords = appData.memories
        .where((memory) => isSameDay(memory.recordDate, widget.day))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final flowerRecords = appData.diaries
        .where((diary) => isSameDay(diary.recordDate, widget.day))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          _RecordTypeSelector(
            selectedType: _selectedType,
            onChanged: (type) {
              setState(() {
                _selectedType = type;
              });
            },
          ),
          const SizedBox(height: 18),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selectedType == _RecordViewType.tree
                  ? _TreeRecordList(
                      key: const ValueKey('tree-records'),
                      records: treeRecords,
                    )
                  : _FlowerRecordList(
                      key: const ValueKey('flower-records'),
                      records: flowerRecords,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTypeSelector extends StatelessWidget {
  final _RecordViewType selectedType;
  final ValueChanged<_RecordViewType> onChanged;

  const _RecordTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _button(
            type: _RecordViewType.tree,
            label: '나무 기록',
            icon: Icons.park_outlined,
          ),
          _button(
            type: _RecordViewType.flower,
            label: '꽃 기록',
            icon: Icons.local_florist_outlined,
          ),
        ],
      ),
    );
  }

  Widget _button({
    required _RecordViewType type,
    required String label,
    required IconData icon,
  }) {
    final selected = selectedType == type;

    return Expanded(
      child: InkWell(
        onTap: () => onChanged(type),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF7CE3B8)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected
                    ? const Color(0xFF12281F)
                    : Colors.white60,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xFF12281F)
                      : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreeRecordList extends StatelessWidget {
  final List<Memory> records;

  const _TreeRecordList({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyRecordView(
        icon: Icons.park_outlined,
        message: '이 날짜에는 나무 기록이 없어요.',
      );
    }

    final appData = context.read<AppData>();

    return ListView.separated(
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final memory = records[index];
        final author = appData.userById(memory.userId);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              showMemoryDetailSheet(context, memory);
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.eco,
                        color: Color(0xFF5C9271),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        '나무 기록',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        memory.isPublic ? '가족 공개' : '비공개',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (memory.mediaList.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F1E9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.black45,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '첨부 파일 ${memory.mediaList.length}개',
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    memory.contextText ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '작성자 ${author.name}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FlowerRecordList extends StatelessWidget {
  final List<Diary> records;

  const _FlowerRecordList({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyRecordView(
        icon: Icons.local_florist_outlined,
        message: '이 날짜에는 꽃 기록이 없어요.',
      );
    }

    final appData = context.read<AppData>();

    return ListView.separated(
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final diary = records[index];
        final author = appData.userById(diary.userId);
        final emotion = diary.flowerType.emotionId;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              showDiaryDetailSheet(context, diary);
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_florist,
                        color: Color(0xFFCB7DA8),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        '꽃 기록',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      EmotionChip(emotion: emotion),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    diary.context,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '작성자 ${author.name}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyRecordView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyRecordView({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Colors.white30),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

