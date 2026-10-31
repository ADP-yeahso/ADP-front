import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/care_activity_catalog.dart';
import '../../../data/garden_nav_controller.dart';
import '../../../models/emotions.dart';

class DiaryCareContentScreen extends StatefulWidget {
  const DiaryCareContentScreen({
    super.key,
    this.emotion,
    this.onOpenLetter,
    this.onOpenManual,
  });

  /// Pass the final emotion from the caller's existing state or API adapter.
  /// Missing emotion data is kept distinct from an actual neutral emotion.
  final Emotion? emotion;
  // Connect existing feature routes here when they are integrated.
  final VoidCallback? onOpenLetter;
  final VoidCallback? onOpenManual;

  @override
  State<DiaryCareContentScreen> createState() => _DiaryCareContentScreenState();
}

class _DiaryCareContentScreenState extends State<DiaryCareContentScreen> {
  final Set<String> _completedIds = {};

  Future<void> _openActivity(CareActivity activity) async {
    if (activity.isCommon) {
      final open = activity.kind == CareActivityKind.letter
          ? widget.onOpenLetter
          : widget.onOpenManual;
      if (open != null) {
        open();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              activity.kind == CareActivityKind.letter
                  ? '익명 편지함은 준비 중이에요.'
                  : '치매 관리 매뉴얼은 준비 중이에요.',
            ),
          ),
        );
      }
      return;
    }
    final completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFBF0),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(activity.icon, size: 36, color: const Color(0xFF386629)),
              const SizedBox(height: 16),
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                activity.description,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.6,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: const Color(0xFF386629),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('활동 완료'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: const Color(0xFF2A4225),
                ),
                onPressed: () => Navigator.pop(sheetContext, false),
                child: const Text('나중에 할게요'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || completed != true) return;
    setState(() => _completedIds.add(activity.id));
  }

  Widget _activityCard(CareActivity activity, Color emotionColor) {
    final completed = _completedIds.contains(activity.id);
    final foreground = activity.isCommon
        ? Colors.white
        : const Color(0xFF222222);
    return Semantics(
      button: true,
      label: '${activity.title}, ${completed ? '완료' : '활동 보기'}',
      excludeSemantics: true,
      onTap: () => _openActivity(activity),
      child: Material(
        color: activity.isCommon ? const Color(0xFF386629) : emotionColor,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('care-activity-${activity.id}'),
          onTap: () => _openActivity(activity),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  completed ? Icons.check_circle : activity.icon,
                  color: foreground,
                  size: 30,
                ),
                const SizedBox(height: 14),
                Text(
                  activity.title,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 12),
                Text(
                  completed ? '완료했어요' : '활동 보기',
                  style: TextStyle(color: foreground, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = CareActivityCatalog.groupFor(widget.emotion?.name);
    final activities = CareActivityCatalog.activitiesFor(widget.emotion?.name);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '이런 활동은 어떤가요?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '마음이 가는 활동을 편한 만큼 해봐요.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF555555),
                        ),
                      ),
                      if (group == null) ...[
                        const SizedBox(height: 12),
                        const Text(
                          '맞춤 활동을 불러오지 못했어요. 공통 활동을 먼저 살펴보세요.',
                          style: TextStyle(height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 24),
                      for (var start = 0; start < activities.length; start += 2)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: start + 2 < activities.length ? 12 : 0,
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _activityCard(
                                    activities[start],
                                    group?.color ?? Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _activityCard(
                                    activities[start + 1],
                                    group?.color ?? Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
              child: IconButton.filled(
                tooltip: '홈으로',
                iconSize: 32,
                style: IconButton.styleFrom(
                  fixedSize: const Size(64, 64),
                  backgroundColor: const Color(0xFFFFF2B2),
                  foregroundColor: const Color(0xFF2A4225),
                ),
                onPressed: () {
                  context.read<GardenNavController>().requestDate(
                    DateTime.now(),
                  );
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
