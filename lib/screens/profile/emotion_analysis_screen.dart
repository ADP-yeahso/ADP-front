import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../data/emotion_analyzer.dart';
import '../../models/diary.dart';
import '../../models/emotions.dart';
import '../../utils/emotion_utils.dart';
import 'package:fl_chart/fl_chart.dart';

enum EmotionAnalysisPeriod { week, month, sixMonths, year }

extension EmotionAnalysisPeriodInfo on EmotionAnalysisPeriod {
  String get label {
    switch (this) {
      case EmotionAnalysisPeriod.week:
        return '1주';
      case EmotionAnalysisPeriod.month:
        return '1개월';
      case EmotionAnalysisPeriod.sixMonths:
        return '6개월';
      case EmotionAnalysisPeriod.year:
        return '1년';
    }
  }
}

/// 화면에 보여줄 기간의 시작일과 종료일을 함께 관리한다.
class EmotionDateRange {
  final DateTime start;
  final DateTime end;

  const EmotionDateRange({required this.start, required this.end});
}

class EmotionDistributionData {
  final int diaryCount;
  final Map<Emotion, double> percentages;

  const EmotionDistributionData({
    required this.diaryCount,
    required this.percentages,
  });

  bool get hasData => diaryCount > 0;
}

class EmotionTrendPoint {
  final String label;
  final Map<Emotion, double> percentages;

  const EmotionTrendPoint({required this.label, required this.percentages});
}

class EmotionSummaryData {
  final String title;
  final String description;
  final Emotion? primaryEmotion;

  const EmotionSummaryData({
    required this.title,
    required this.description,
    required this.primaryEmotion,
  });
}

class EmotionAnalysisScreen extends StatefulWidget {
  const EmotionAnalysisScreen({super.key});

  @override
  State<EmotionAnalysisScreen> createState() => _EmotionAnalysisScreenState();
}

class _EmotionAnalysisScreenState extends State<EmotionAnalysisScreen> {
  EmotionAnalysisPeriod _selectedPeriod = EmotionAnalysisPeriod.week;

  /// 0: 현재 기간
  /// -1: 바로 이전 기간
  /// -2: 그 이전 기간
  int _periodOffset = 0;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 월요일을 한 주의 시작일로 계산한다.
  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  /// 현재 선택된 탭과 offset을 기준으로 날짜 범위를 계산한다.
  EmotionDateRange _calculateDateRange() {
    final today = _today;

    switch (_selectedPeriod) {
      case EmotionAnalysisPeriod.week:
        final currentWeekStart = _startOfWeek(today);
        final start = currentWeekStart.add(Duration(days: _periodOffset * 7));
        final end = start.add(const Duration(days: 6));

        return EmotionDateRange(start: start, end: end);

      case EmotionAnalysisPeriod.month:
        final start = DateTime(today.year, today.month + _periodOffset, 1);

        final end = DateTime(start.year, start.month + 1, 0);

        return EmotionDateRange(start: start, end: end);

      case EmotionAnalysisPeriod.sixMonths:

        /// 현재 달을 포함한 최근 6개월을 하나의 구간으로 사용한다.
        ///
        /// 예:
        /// 현재가 8월이면 3월 1일 ~ 8월 31일
        final lastMonthOfRange = DateTime(
          today.year,
          today.month + (_periodOffset * 6),
          1,
        );

        final start = DateTime(
          lastMonthOfRange.year,
          lastMonthOfRange.month - 5,
          1,
        );

        final end = DateTime(
          lastMonthOfRange.year,
          lastMonthOfRange.month + 1,
          0,
        );

        return EmotionDateRange(start: start, end: end);

      case EmotionAnalysisPeriod.year:
        final selectedYear = today.year + _periodOffset;

        return EmotionDateRange(
          start: DateTime(selectedYear, 1, 1),
          end: DateTime(selectedYear, 12, 31),
        );
    }
  }

  String _dateRangeLabel(EmotionDateRange range) {
    switch (_selectedPeriod) {
      case EmotionAnalysisPeriod.week:
        if (range.start.year == range.end.year) {
          return '${DateFormat('yyyy년 M월 d일').format(range.start)}'
              ' ~ '
              '${DateFormat('M월 d일').format(range.end)}';
        }

        return '${DateFormat('yyyy년 M월 d일').format(range.start)}'
            ' ~ '
            '${DateFormat('yyyy년 M월 d일').format(range.end)}';

      case EmotionAnalysisPeriod.month:
        return DateFormat('yyyy년 M월').format(range.start);

      case EmotionAnalysisPeriod.sixMonths:
        return '${DateFormat('yyyy년 M월').format(range.start)}'
            ' ~ '
            '${DateFormat('yyyy년 M월').format(range.end)}';

      case EmotionAnalysisPeriod.year:
        return DateFormat('yyyy년').format(range.start);
    }
  }

  String _periodStatusLabel() {
    if (_periodOffset == 0) {
      switch (_selectedPeriod) {
        case EmotionAnalysisPeriod.week:
          return '이번 주';
        case EmotionAnalysisPeriod.month:
          return '이번 달';
        case EmotionAnalysisPeriod.sixMonths:
          return '최근 6개월';
        case EmotionAnalysisPeriod.year:
          return '올해';
      }
    }

    switch (_selectedPeriod) {
      case EmotionAnalysisPeriod.week:
        if (_periodOffset == -1) return '지난주';
        return '${-_periodOffset}주 전';

      case EmotionAnalysisPeriod.month:
        if (_periodOffset == -1) return '지난달';
        return '${-_periodOffset}개월 전';

      case EmotionAnalysisPeriod.sixMonths:
        return '이전 6개월';

      case EmotionAnalysisPeriod.year:
        if (_periodOffset == -1) return '작년';
        return '${-_periodOffset}년 전';
    }
  }

  void _changePeriod(EmotionAnalysisPeriod period) {
    setState(() {
      _selectedPeriod = period;

      /// 탭을 변경하면 해당 기간의 현재 구간으로 되돌린다.
      _periodOffset = 0;
    });
  }

  void _moveToPreviousPeriod() {
    setState(() {
      _periodOffset--;
    });
  }

  void _moveToNextPeriod() {
    /// 미래 기록은 보여주지 않으므로 현재 기간보다 앞으로 갈 수 없다.
    if (_periodOffset >= 0) {
      return;
    }

    setState(() {
      _periodOffset++;
    });
  }

  void _handleDistributionSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    // 손가락을 왼쪽으로 밀었을 때
    // 지난주, 지난달 등 이전 기간으로 이동
    if (velocity < -250) {
      _moveToPreviousPeriod();
      return;
    }

    // 손가락을 오른쪽으로 밀었을 때
    // 현재 기간 방향으로 이동
    if (velocity > 250 && _periodOffset < 0) {
      _moveToNextPeriod();
    }
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<Diary> _diariesInRange(AppData appData, EmotionDateRange range) {
    final start = _dateOnly(range.start);
    final end = _dateOnly(range.end);

    final diaries = appData.diaries.where((diary) {
      final diaryDate = _dateOnly(diary.recordDate);

      final isMyDiary = diary.userId == appData.me.id;
      final isAfterStart =
          diaryDate.isAtSameMomentAs(start) || diaryDate.isAfter(start);
      final isBeforeEnd =
          diaryDate.isAtSameMomentAs(end) || diaryDate.isBefore(end);

      return isMyDiary && isAfterStart && isBeforeEnd;
    }).toList();

    diaries.sort((a, b) => a.recordDate.compareTo(b.recordDate));

    return diaries;
  }

  EmotionDistributionData _buildEmotionDistribution(List<Diary> diaries) {
    final totals = <Emotion, double>{
      for (final emotion in EmotionValues.values) emotion: 0,
    };

    for (final diary in diaries) {
      final result = analyzeEmotion(diary.context);

      for (final entry in result.scores.entries) {
        totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
      }
    }

    final totalScore = totals.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    if (diaries.isEmpty || totalScore == 0) {
      return EmotionDistributionData(
        diaryCount: diaries.length,
        percentages: {for (final emotion in EmotionValues.values) emotion: 0},
      );
    }

    final percentages = totals.map(
      (emotion, score) => MapEntry(emotion, score / totalScore * 100),
    );

    return EmotionDistributionData(
      diaryCount: diaries.length,
      percentages: percentages,
    );
  }

  Map<Emotion, double> _percentagesForDiaries(List<Diary> diaries) {
    final distribution = _buildEmotionDistribution(diaries);

    return distribution.percentages;
  }

  List<Diary> _diariesBetween(
    List<Diary> diaries,
    DateTime start,
    DateTime end,
  ) {
    final normalizedStart = _dateOnly(start);
    final normalizedEnd = _dateOnly(end);

    return diaries.where((diary) {
      final diaryDate = _dateOnly(diary.recordDate);

      final isAfterStart =
          diaryDate.isAtSameMomentAs(normalizedStart) ||
          diaryDate.isAfter(normalizedStart);

      final isBeforeEnd =
          diaryDate.isAtSameMomentAs(normalizedEnd) ||
          diaryDate.isBefore(normalizedEnd);

      return isAfterStart && isBeforeEnd;
    }).toList();
  }

  List<EmotionTrendPoint> _buildWeeklyTrend(
    List<Diary> diaries,
    EmotionDateRange range,
  ) {
    const dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    return List.generate(7, (index) {
      final day = range.start.add(Duration(days: index));

      final dayDiaries = _diariesBetween(diaries, day, day);

      return EmotionTrendPoint(
        label: dayLabels[index],
        percentages: _percentagesForDiaries(dayDiaries),
      );
    });
  }

  List<EmotionTrendPoint> _buildMonthlyTrend(
    List<Diary> diaries,
    EmotionDateRange range,
  ) {
    final result = <EmotionTrendPoint>[];

    var weekStart = range.start;
    var weekNumber = 1;

    while (!weekStart.isAfter(range.end)) {
      var weekEnd = weekStart.add(const Duration(days: 6));

      if (weekEnd.isAfter(range.end)) {
        weekEnd = range.end;
      }

      final weekDiaries = _diariesBetween(diaries, weekStart, weekEnd);

      result.add(
        EmotionTrendPoint(
          label: '$weekNumber주',
          percentages: _percentagesForDiaries(weekDiaries),
        ),
      );

      weekStart = weekEnd.add(const Duration(days: 1));

      weekNumber++;
    }

    return result;
  }

  List<EmotionTrendPoint> _buildMonthlyIntervalTrend(
    List<Diary> diaries,
    EmotionDateRange range,
  ) {
    final result = <EmotionTrendPoint>[];

    var monthCursor = DateTime(range.start.year, range.start.month, 1);

    while (!monthCursor.isAfter(range.end)) {
      final monthEnd = DateTime(monthCursor.year, monthCursor.month + 1, 0);

      final actualEnd = monthEnd.isAfter(range.end) ? range.end : monthEnd;

      final monthDiaries = _diariesBetween(diaries, monthCursor, actualEnd);

      result.add(
        EmotionTrendPoint(
          label: '${monthCursor.month}월',
          percentages: _percentagesForDiaries(monthDiaries),
        ),
      );

      monthCursor = DateTime(monthCursor.year, monthCursor.month + 1, 1);
    }

    return result;
  }

  List<EmotionTrendPoint> _buildEmotionTrend(
    List<Diary> diaries,
    EmotionDateRange range,
  ) {
    switch (_selectedPeriod) {
      case EmotionAnalysisPeriod.week:
        return _buildWeeklyTrend(diaries, range);

      case EmotionAnalysisPeriod.month:
        return _buildMonthlyTrend(diaries, range);

      case EmotionAnalysisPeriod.sixMonths:
      case EmotionAnalysisPeriod.year:
        return _buildMonthlyIntervalTrend(diaries, range);
    }
  }

  EmotionSummaryData _buildEmotionSummary(
    EmotionDistributionData distribution,
  ) {
    if (!distribution.hasData) {
      return const EmotionSummaryData(
        title: '아직 분석할 기록이 없어요',
        description: '이 기간에 일기를 작성하면 감정의 흐름을 확인할 수 있어요.',
        primaryEmotion: null,
      );
    }

    final sortedEntries = distribution.percentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final primaryEntry = sortedEntries.first;
    final secondaryEntry = sortedEntries.length > 1 ? sortedEntries[1] : null;

    final primaryName = primaryEntry.key.displayName;
    final primaryPercentage = primaryEntry.value;

    String description;

    if (primaryPercentage >= 70) {
      description = '작성한 기록에서 $primaryName 감정이 뚜렷하게 나타났어요.';
    } else if (primaryPercentage >= 45) {
      description = '이번 기간에는 $primaryName 감정이 가장 많이 나타났어요.';
    } else if (secondaryEntry != null && secondaryEntry.value > 0) {
      description =
          '$primaryName과 ${secondaryEntry.key.displayName} 감정이 함께 나타났어요.';
    } else {
      description = '이번 기간의 기록에서 $primaryName 감정이 가장 많이 나타났어요.';
    }

    return EmotionSummaryData(
      title: '이번 기간의 대표 감정은 $primaryName이에요',
      description: description,
      primaryEmotion: primaryEntry.key,
    );
  }

  Color _emotionColor(Emotion emotion) {
    switch (emotion.name.toLowerCase()) {
      case 'calm':
        return const Color(0xFF6FBF8B); // 초록

      case 'joy':
        return const Color(0xFFF5C34D); // 노랑

      case 'sadness':
        return const Color(0xFF8B7CC6); // 보라

      case 'anger':
        return const Color(0xFFEF6464); // 빨강

      case 'guilt':
        return const Color(0xFF6B93D1); // 파랑

      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();

    final dateRange = _calculateDateRange();
    final dateRangeText = _dateRangeLabel(dateRange);

    final diaries = _diariesInRange(appData, dateRange);

    final distribution = _buildEmotionDistribution(diaries);
    final trendPoints = _buildEmotionTrend(diaries, dateRange);
    final summary = _buildEmotionSummary(distribution);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      appBar: AppBar(
        title: const Text(
          '감정 분석',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFAF9F5),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _PeriodSelector(
            selectedPeriod: _selectedPeriod,
            onChanged: _changePeriod,
          ),
          const SizedBox(height: 18),

          _DateRangeNavigator(
            statusLabel: _periodStatusLabel(),
            dateRangeLabel: dateRangeText,
            canMoveNext: _periodOffset < 0,
            onPrevious: _moveToPreviousPeriod,
            onNext: _moveToNextPeriod,
          ),
          const SizedBox(height: 20),

          _EmotionSummaryCard(
            key: ValueKey('summary-${_selectedPeriod.name}-$_periodOffset'),
            summary: summary,
            diaryCount: distribution.diaryCount,
            emotionColor: _emotionColor,
          ),
          const SizedBox(height: 24),

          _EmotionDistributionPreview(
            key: ValueKey('${_selectedPeriod.name}-$_periodOffset'),
            dateRangeLabel: dateRangeText,
            distribution: distribution,
            emotionColor: _emotionColor,
            canMoveNext: _periodOffset < 0,
            onSwipeEnd: _handleDistributionSwipe,
          ),

          const SizedBox(height: 24),

          _EmotionTrendChart(
            key: ValueKey('trend-${_selectedPeriod.name}-$_periodOffset'),
            dateRangeLabel: dateRangeText,
            trendPoints: trendPoints,
            emotions: EmotionValues.values,
            emotionColor: _emotionColor,
          ),
          const SizedBox(height: 24),

          const _EncouragementCard(),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final EmotionAnalysisPeriod selectedPeriod;
  final ValueChanged<EmotionAnalysisPeriod> onChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0EC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: EmotionAnalysisPeriod.values.map((period) {
          final isSelected = period == selectedPeriod;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4F9669)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  period.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DateRangeNavigator extends StatelessWidget {
  final String statusLabel;
  final String dateRangeLabel;
  final bool canMoveNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _DateRangeNavigator({
    required this.statusLabel,
    required this.dateRangeLabel,
    required this.canMoveNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: '이전 기간',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
          color: const Color(0xFF4F9669),
          iconSize: 30,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                statusLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F9669),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateRangeLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '다음 기간',
          onPressed: canMoveNext ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
          color: const Color(0xFF4F9669),
          disabledColor: Colors.black12,
          iconSize: 30,
        ),
      ],
    );
  }
}

class _EmotionSummaryCard extends StatelessWidget {
  final EmotionSummaryData summary;
  final int diaryCount;
  final Color Function(Emotion emotion) emotionColor;

  const _EmotionSummaryCard({
    super.key,
    required this.summary,
    required this.diaryCount,
    required this.emotionColor,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = summary.primaryEmotion == null
        ? const Color(0xFF9EB9A7)
        : emotionColor(summary.primaryEmotion!);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey('${summary.title}-${summary.description}-$diaryCount'),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withValues(alpha: 0.20)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                summary.primaryEmotion == null
                    ? Icons.local_florist_outlined
                    : Icons.spa_rounded,
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '감정 요약',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary.description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: Colors.black54,
                    ),
                  ),
                  if (diaryCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '총 $diaryCount개의 일기를 바탕으로 분석했어요.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmotionDistributionPreview extends StatelessWidget {
  final String dateRangeLabel;
  final EmotionDistributionData distribution;
  final Color Function(Emotion emotion) emotionColor;
  final bool canMoveNext;
  final GestureDragEndCallback onSwipeEnd;

  const _EmotionDistributionPreview({
    super.key,
    required this.dateRangeLabel,
    required this.distribution,
    required this.emotionColor,
    required this.canMoveNext,
    required this.onSwipeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final emotionEntries = distribution.percentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final chartEntries = emotionEntries
        .where((entry) => entry.value > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '감정 분포',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: onSwipeEnd,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey(dateRangeLabel),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: distribution.hasData
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateRangeLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '총 ${distribution.diaryCount}개의 일기 분석',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black38,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 230,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 58,
                                  startDegreeOffset: -90,
                                  pieTouchData: PieTouchData(enabled: true),
                                  sections: chartEntries.map((entry) {
                                    return PieChartSectionData(
                                      value: entry.value,
                                      color: emotionColor(entry.key),
                                      radius: 48,
                                      showTitle: entry.value >= 7,
                                      title:
                                          '${entry.value.toStringAsFixed(0)}%',
                                      titleStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _chartTextColor(
                                          emotionColor(entry.key),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '일기',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${distribution.diaryCount}개',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF315F43),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _EmotionLegendGrid(
                          entries: emotionEntries,
                          emotionColor: emotionColor,
                        ),
                        const SizedBox(height: 14),
                        _SwipeGuide(canMoveNext: canMoveNext),
                      ],
                    )
                  : Column(
                      children: [
                        _EmptyEmotionData(dateRangeLabel: dateRangeLabel),
                        _SwipeGuide(canMoveNext: canMoveNext),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Color _chartTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.65
        ? Colors.black87
        : Colors.white;
  }
}

class _SwipeGuide extends StatelessWidget {
  final bool canMoveNext;

  const _SwipeGuide({required this.canMoveNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.chevron_left_rounded, size: 18, color: Colors.black26),
        const SizedBox(width: 4),
        Text(
          canMoveNext ? '좌우로 밀어 다른 기간 보기' : '왼쪽으로 밀어 이전 기간 보기',
          style: const TextStyle(fontSize: 11, color: Colors.black38),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: canMoveNext ? Colors.black26 : Colors.black12,
        ),
      ],
    );
  }
}

class _EmotionLegendGrid extends StatelessWidget {
  final List<MapEntry<Emotion, double>> entries;
  final Color Function(Emotion emotion) emotionColor;

  const _EmotionLegendGrid({required this.entries, required this.emotionColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 14,
          children: entries.map((entry) {
            return SizedBox(
              width: itemWidth,
              child: Row(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: emotionColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.value.toStringAsFixed(1)}%',
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _EmptyEmotionData extends StatelessWidget {
  final String dateRangeLabel;

  const _EmptyEmotionData({required this.dateRangeLabel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_florist_outlined,
              size: 42,
              color: Color(0xFFB7C9BC),
            ),
            const SizedBox(height: 12),
            Text(
              dateRangeLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '이 기간에는 작성한 일기가 없어요.',
              style: TextStyle(fontSize: 13, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmotionTrendChart extends StatelessWidget {
  final String dateRangeLabel;
  final List<EmotionTrendPoint> trendPoints;
  final List<Emotion> emotions;
  final Color Function(Emotion emotion) emotionColor;

  const _EmotionTrendChart({
    super.key,
    required this.dateRangeLabel,
    required this.trendPoints,
    required this.emotions,
    required this.emotionColor,
  });

  bool get _hasAnyData {
    for (final point in trendPoints) {
      for (final value in point.percentages.values) {
        if (value > 0) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '감정 변화 추세',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _hasAnyData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        dateRangeLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 260,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: trendPoints.length > 1
                              ? (trendPoints.length - 1).toDouble()
                              : 1,
                          minY: 0,
                          maxY: 100,
                          clipData: const FlClipData.all(),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 25,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.black.withValues(alpha: 0.07),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 38,
                                interval: 25,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Text(
                                      '${value.toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black38,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.round();

                                  if (index < 0 ||
                                      index >= trendPoints.length) {
                                    return const SizedBox.shrink();
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      trendPoints[index].label,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) {
                                return spots.map((spot) {
                                  final emotion = emotions[spot.barIndex];

                                  return LineTooltipItem(
                                    '${emotion.displayName}\n'
                                    '${spot.y.toStringAsFixed(1)}%',
                                    TextStyle(
                                      color: emotionColor(emotion),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: emotions.map((emotion) {
                            final spots = <FlSpot>[];

                            for (
                              var index = 0;
                              index < trendPoints.length;
                              index++
                            ) {
                              final percentage =
                                  trendPoints[index].percentages[emotion] ?? 0;

                              spots.add(FlSpot(index.toDouble(), percentage));
                            }

                            return LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              curveSmoothness: 0.25,
                              color: emotionColor(emotion),
                              barWidth: 2.5,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: trendPoints.length <= 7),
                              belowBarData: BarAreaData(show: false),
                            );
                          }).toList(),
                        ),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _EmotionTrendLegend(
                      emotions: emotions,
                      emotionColor: emotionColor,
                    ),
                  ],
                )
              : _EmptyTrendData(dateRangeLabel: dateRangeLabel),
        ),
      ],
    );
  }
}

class _EmotionTrendLegend extends StatelessWidget {
  final List<Emotion> emotions;
  final Color Function(Emotion emotion) emotionColor;

  const _EmotionTrendLegend({
    required this.emotions,
    required this.emotionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        children: emotions.map((emotion) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 3,
                decoration: BoxDecoration(
                  color: emotionColor(emotion),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                emotion.displayName,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyTrendData extends StatelessWidget {
  final String dateRangeLabel;

  const _EmptyTrendData({required this.dateRangeLabel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.show_chart_rounded,
              size: 42,
              color: Color(0xFFB7C9BC),
            ),
            const SizedBox(height: 12),
            Text(
              dateRangeLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '감정 변화를 확인할 기록이 없어요.',
              style: TextStyle(fontSize: 13, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final double height;

  const _SectionPlaceholder({
    required this.title,
    required this.description,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EncouragementCard extends StatelessWidget {
  const _EncouragementCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4ED),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_border, color: Color(0xFFE7BEB5)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '당신의 마음을 돌보는 시간은 충분히 의미 있어요.\n'
              '오늘도 수고했어요, 당신은 잘하고 있어요.',
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Color(0xFF6F645E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
