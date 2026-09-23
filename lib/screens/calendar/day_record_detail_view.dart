import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/diary.dart';
import '../../models/memory.dart';
import '../../models/media.dart';
import '../garden/entry_detail_sheet.dart';

enum _RecordViewType { tree, flower }

class DayRecordDetailView extends StatefulWidget {
  final DateTime day;
  final Memory? selectedMemory;
  final Diary? selectedDiary;

  const DayRecordDetailView({super.key, required this.day, this.selectedMemory, this.selectedDiary});

  @override
  State<DayRecordDetailView> createState() => _DayRecordDetailViewState();
}

class _DayRecordDetailViewState extends State<DayRecordDetailView> {
  // 상세 화면 진입 시 초기에는 나무 기록 선택
  _RecordViewType _selectedType = _RecordViewType.tree;

  @override
  void initState() {
   super.initState();

    if (widget.selectedDiary != null) {
      _selectedType = _RecordViewType.flower;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();

    final treeRecords = widget.selectedMemory != null
      ? [widget.selectedMemory!]
      : appData.memories
            .where((memory) => isSameDay(memory.recordDate, widget.day))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final flowerRecords = widget.selectedDiary != null
        ? [widget.selectedDiary!]
        : appData.diaries
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
    final isTreeSelected = selectedType == _RecordViewType.tree;

    return SizedBox(
      width: 162,
      height: 42,
      child: Stack(
        children: [
          SvgPicture.asset(
            'assets/page2/record_detail/record_tabs.svg',
            width: 162,
            height: 42,
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            left: isTreeSelected ? 2 : 83,
            top: 2,
            child: SvgPicture.asset(
              'assets/page2/record_detail/selected_tab.svg',
              width: 77,
              height: 37,
            ),
          ),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(_RecordViewType.tree),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/page2/record_detail/tree_record_label.svg',
                      width: 57,
                      height: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(_RecordViewType.flower),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/page2/record_detail/flower_record_label.svg',
                      width: 58,
                      height: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TreeRecordList extends StatelessWidget {
  final List<Memory> records;

  const _TreeRecordList({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyRecordView(
        message: '이 날짜에는 나무 기록이 없어요.',
      );
    }

    return ListView.separated(
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final memory = records[index];

        return _TreeRecordCard(
          memory: memory,
          onTap: () {
            showMemoryDetailSheet(context, memory);
          },
        );
      },
    );
  }
}

class _TreeRecordCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;

  const _TreeRecordCard({required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasAudio = memory.mediaList.any((item) => item.fileType == 'audio');

    return Card(
      color: const Color(0xFFFFFBF0),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 20),
          child: Column(
            children: [
              _DetailTitleBlock(
                title: memory.title,
              ),
              const SizedBox(height: 18),

              _MediaImageRow(media: memory.mediaList),

              if (hasAudio) ...[
                const SizedBox(height: 12),
                const _DetailAudioBar(),
              ],

              const SizedBox(height: 22),
              _DetailContentLines(
                text: memory.contextText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowerRecordList extends StatelessWidget {
  final List<Diary> records;

  const _FlowerRecordList({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyRecordView(
        message: '이 날짜에는 꽃 기록이 없어요.',
      );
    }

    return ListView.separated(
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final diary = records[index];

        return _FlowerRecordCard(
          diary: diary,
          onTap: () {
            showDiaryDetailSheet(context, diary);
          },
        );
      },
    );
  }
}

class _FlowerRecordCard extends StatelessWidget {
  final Diary diary;
  final VoidCallback onTap;

  const _FlowerRecordCard({
    required this.diary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAudio = diary.mediaList.any((item) => item.fileType == 'audio');

    return Card(
      color: const Color(0xFFFFFBF0),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 20),
          child: Column(
            children: [
              _DetailTitleBlock(
                title: diary.title,
              ),
              const SizedBox(height: 18),

              _MediaImageRow(media: diary.mediaList),

              if (hasAudio) ...[
                const SizedBox(height: 12),
                const _DetailAudioBar(),
              ],

              if (diary.mediaList.any((item) => item.fileType == 'image'))
                const SizedBox(height: 14),

              _FlowerInfoCard(
                diary: diary,
                compact: diary.mediaList.any(
                  (item) => item.fileType == 'image' || item.fileType == 'video',
                ),
              ),
              
              const SizedBox(height: 22),
              _DetailContentLines(
                text: diary.context,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailTitleBlock extends StatelessWidget {
  final String? title;

  const _DetailTitleBlock({
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null && title!.trim().isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 248,
        height: 29,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SvgPicture.asset(
                'assets/page2/record_detail/title_line.svg',
                width: 248,
                height: 3,
                fit: BoxFit.fill,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: hasTitle
                  ? Text(
                      title!.trim(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    )
                  : SvgPicture.asset(
                      'assets/page2/record_detail/record_title.svg',
                      width: 30,
                      height: 18,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailContentLines extends StatelessWidget {
  final String? text;

  const _DetailContentLines({
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    const lineCount = 6;
    const lineHeight = 36.0;

    return SizedBox(
      width: double.infinity,
      height: lineCount * lineHeight,
      child: Stack(
        children: [
          Column(
            children: List.generate(
              lineCount,
              (index) => SizedBox(
                height: lineHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SvgPicture.asset(
                    'assets/page2/record_detail/content_line.svg',
                    width: double.infinity,
                    height: 3,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),

          if (text != null && text!.trim().isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              top: 2,
              child: Text(
                text!.trim(),
                maxLines: lineCount,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  fontSize: 14,
                  height: 2.57,
                  color: Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailAudioBar extends StatelessWidget {
  const _DetailAudioBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'assets/page2/record_detail/audio_frame.svg',
            width: double.infinity,
            height: 46,
            fit: BoxFit.fill,
          ),
          const Positioned(
            left: 14,
            child: Text(
              '00:00',
              style: TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
          Positioned(
            left: 70,
            right: 48,
            top: 22,
            child: SvgPicture.asset(
              'assets/page2/record_detail/audio_dotted_line.svg',
              width: double.infinity,
              height: 2,
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            right: 6,
            child: SvgPicture.asset(
              'assets/page2/record_detail/play_button.svg',
              width: 34,
              height: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecordView extends StatelessWidget {
  final String message;

  const _EmptyRecordView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: const TextStyle(fontSize: 13, color: Colors.black38, fontWeight: FontWeight.w400,)),
    );
  }
}

class _MediaImageRow extends StatelessWidget {
  final List<Media> media;

  const _MediaImageRow({required this.media});

  @override
  Widget build(BuildContext context) {
    final images = media
        .where((item) => item.fileType == 'image')
        .take(2)
        .toList();

    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        for (int i = 0; i < images.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: i == 0 && images.length > 1 ? 8 : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _MediaImage(media: images[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _MediaImage extends StatelessWidget {
  final Media media;

  const _MediaImage({required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.fileUrl.startsWith('http')) {
      return Image.network(media.fileUrl, height: 190, fit: BoxFit.cover);
    }

    return Image.file(
      File(media.fileUrl),
      height: 190,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          'assets/images/flower.png',
          height: 190,
          fit: BoxFit.cover,
        );
      },
    );
  }
}

class _FlowerInfoCard extends StatelessWidget {
  final Diary diary;
  final bool compact;

  const _FlowerInfoCard({
    required this.diary,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final flower = diary.flowerType;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        14,
        compact ? 8 : 14,
        14,
        compact ? 8 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 140,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF6B9FBD), width: 2),
            ),
            child: Image.asset('assets/images/flower.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  '꽃 이름',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF365B45),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '꽃말',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
