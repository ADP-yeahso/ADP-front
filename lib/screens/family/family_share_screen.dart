import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/diary.dart';
import '../../models/emotions.dart';
import '../../utils/emotion_utils.dart';
import '../../models/users.dart';
import '../../models/memory.dart';
import '../../widgets/emotion_chip.dart';
import '../garden/entry_detail_sheet.dart';

class FamilyShareScreen extends StatefulWidget {
  const FamilyShareScreen({super.key});

  @override
  State<FamilyShareScreen> createState() => _FamilyShareScreenState();
}

class _FamilyShareScreenState extends State<FamilyShareScreen> {
  int? _filterMemberId;

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();

    final feedItems = <_FeedItem>[
      ...appData.sharedMemories.map((m) => _FeedItem.memory(m)),
      ...appData.sharedDiaries.map((d) => _FeedItem.diary(d)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final filtered = _filterMemberId == null
        ? feedItems
        : feedItems.where((f) => f.authorId == _filterMemberId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('가족 공유'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${appData.patientRelationLabel}을 함께 돌보는 가족들의 기록과 감정 상태예요',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final member in appData.users)
                  _MemberAvatar(
                    member: member,
                    emotion: appData.latestEmotionFor(member.id),
                    selected: _filterMemberId == member.id,
                    isMe: appData.isCurrentUser(member.id),
                    relation: appData.userRelationOf(member.id),
                    onTap: () => setState(() {
                      _filterMemberId = _filterMemberId == member.id ? null : member.id;
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 24),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _filterMemberId == null ? '전체 공유 기록' : '${appData.userById(_filterMemberId!).name}의 공유 기록',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Text('아직 공유된 기록이 없어요.', style: TextStyle(color: Colors.black45)),
            )
          else
            for (final item in filtered)
              _FeedCard(
                item: item,
                author: appData.userById(item.authorId),
                onTap: () {
                  if (item.memory != null) {
                    showMemoryDetailSheet(context, item.memory!);
                  } else {
                    showDiaryDetailSheet(context, item.diary!);
                  }
                },
              ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final User member;
  final Emotion? emotion;
  final bool selected;
  final bool isMe;
  final String relation;
  final VoidCallback onTap;

  const _MemberAvatar({
    required this.member,
    required this.emotion,
    required this.selected,
    required this.isMe,
    required this.relation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: selected ? member.color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? member.color : Colors.transparent),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: member.color.withValues(alpha: 0.18),
                  child: Icon(Icons.person, color: member.color),
                ),
                if (emotion != null)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: emotion!.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isMe ? '나' : member.name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            Text(relation, style: const TextStyle(fontSize: 10, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}

class _FeedItem {
  final Memory? memory;
  final Diary? diary;

  _FeedItem.memory(this.memory) : diary = null;
  _FeedItem.diary(this.diary) : memory = null;

  DateTime get date => (memory?.recordDate ?? diary!.recordDate);
  int get authorId => (memory?.userId ?? diary!.userId);
}

class _FeedCard extends StatelessWidget {
  final _FeedItem item;
  final User author;
  final VoidCallback onTap;

  const _FeedCard({required this.item, required this.author, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isMemory = item.memory != null;
    final title = isMemory ? '가족 기록' : '감정 일기';
    final content = isMemory ? (item.memory!.contextText ?? '') : item.diary!.context;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ]),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: (isMemory ? const Color(0xFF6FBF8B) : item.diary!.flowerType.emotionId.color).withValues(alpha: 0.15),
                child: Icon(
                  isMemory ? Icons.eco : item.diary!.flowerType.emotionId.flowerIcon,
                  size: 18,
                  color: isMemory ? const Color(0xFF6FBF8B) : item.diary!.flowerType.emotionId.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(author.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Text('· ${item.date.month}월 ${item.date.day}일', style: const TextStyle(fontSize: 11, color: Colors.black38)),
                        const Spacer(),
                        if (!isMemory) EmotionChip(emotion: item.diary!.flowerType.emotionId),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
