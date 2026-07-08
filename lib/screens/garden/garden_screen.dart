import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../data/garden_nav_controller.dart';
import '../../data/garden_range.dart';
import '../../models/diary_entry.dart';
import '../../theme/app_theme.dart';
import '../../widgets/flower_widget.dart';
import '../../widgets/tree_widget.dart';
import 'entry_detail_sheet.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  late final PageController _pageController;
  late int _pageIndex;
  late final DateTime _anchor;
  GardenNavController? _navController;

  @override
  void initState() {
    super.initState();
    _anchor = gardenAnchorMonth();
    _pageIndex = gardenMonthsBack;
    _pageController = PageController(initialPage: _pageIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<GardenNavController>();
    if (_navController != nav) {
      _navController?.removeListener(_handleNavRequest);
      _navController = nav..addListener(_handleNavRequest);
    }
  }

  @override
  void dispose() {
    _navController?.removeListener(_handleNavRequest);
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthAt(int index) => gardenMonthAt(_anchor, index);

  void _handleNavRequest() async {
    final picked = _navController?.pendingDate;
    if (picked == null || !mounted) return;
    _navController?.clear();

    final targetIndex = gardenIndexForMonth(_anchor, picked);
    await _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;

    final appData = context.read<AppData>();
    final diary = appData.diaries.where((d) => isSameDay(d.date, picked)).toList();
    final leaf = appData.leaves.where((l) => isSameDay(l.date, picked)).toList();
    if (diary.isNotEmpty) {
      showDiaryDetailSheet(context, diary.first);
    } else if (leaf.isNotEmpty) {
      showLeafDetailSheet(context, leaf.first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('해당 날짜에는 기록이 없어요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final month = _monthAt(_pageIndex);
    final season = seasonOf(month);
    final leaves = appData.leavesForMonth(month);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  const Text('마음정원', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Text(
                    '${month.year}년 ${month.month}월 · ${season.label}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: season.skyGradient,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 56,
                      child: Container(color: season.ground.withValues(alpha: 0.6)),
                    ),
                    // Only the flower layer swipes between months.
                    PageView.builder(
                      controller: _pageController,
                      itemCount: gardenTotalPages,
                      onPageChanged: (i) => setState(() => _pageIndex = i),
                      itemBuilder: (context, i) => _FlowerLayer(month: _monthAt(i)),
                    ),
                    // The tree stays fixed on screen regardless of which month is shown.
                    // (Plain Center, not Positioned — Positioned only works as a *direct*
                    // child of this Stack; nesting it inside LayoutBuilder here would silently
                    // fall back to default top-start alignment.)
                    Center(
                      child: TreeWidget(
                        leafCount: leaves.length,
                        onTap: () => showLeafListSheet(context, leaves),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FlowerLayer extends StatelessWidget {
  final DateTime month;
  const _FlowerLayer({required this.month});

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final diaries = appData.diariesForMonth(month);

    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2 + 10);
              final radius = math.min(constraints.maxWidth, constraints.maxHeight) * 0.36;
              return Stack(
                children: [
                  for (int i = 0; i < diaries.length; i++)
                    _positionedFlower(center, radius, i, diaries.length, diaries[i], context),
                ],
              );
            },
          ),
        ),
        if (diaries.isEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 70,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '이 달의 꽃이 아직 피지 않았어요. 오늘의 감정을 기록해 보세요.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _positionedFlower(
      Offset center, double radius, int i, int count, DiaryEntry diary, BuildContext context) {
    final angle = (2 * math.pi * i / count) - math.pi / 2;
    final r = radius * (0.75 + (i % 3) * 0.12);
    final dx = center.dx + r * math.cos(angle) - 23;
    final dy = center.dy + r * math.sin(angle) - 23 + 40;
    return Positioned(
      left: dx.clamp(0.0, double.infinity),
      top: dy.clamp(0.0, double.infinity),
      child: FlowerWidget(
        emotion: diary.emotion,
        onTap: () => showDiaryDetailSheet(context, diary),
      ),
    );
  }
}
