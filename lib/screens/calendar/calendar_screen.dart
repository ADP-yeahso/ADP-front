import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import 'day_record_detail_view.dart';
import '../../data/garden_range.dart';

import '../../models/diary.dart';
import '../../models/emotions.dart';
import '../../utils/emotion_utils.dart';

const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

const _bgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF12281F), Color(0xFF1E4A38)],
);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final DateTime _anchor;
  late int _year;
  DateTime? _drilldownMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _anchor = gardenAnchorMonth();
    _year = _anchor.year;
  }

  DateTime get _minMonth => gardenMonthAt(_anchor, 0);
  DateTime get _maxMonth => gardenMonthAt(_anchor, gardenTotalPages - 1);

  bool _isNavigable(DateTime month) {
    final afterMin =
        month.year > _minMonth.year ||
        (month.year == _minMonth.year && month.month >= _minMonth.month);
    final beforeMax =
        month.year < _maxMonth.year ||
        (month.year == _maxMonth.year && month.month <= _maxMonth.month);
    return afterMin && beforeMax;
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
  }

  void _goBack() {
    if (_selectedDay != null) {
      setState(() {
        _selectedDay = null;
      });
      return;
    }

    if (_drilldownMonth != null) {
      setState(() {
        _drilldownMonth = null;
      });
    }
  }

  String _formatDay(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');

    return '${day.year}. $month. $date';
  }

  String get _screenTitle {
    // 날짜 상세 화면
    if (_selectedDay != null) {
      return _formatDay(_selectedDay!);
    }

    // 월 달력 화면
    if (_drilldownMonth != null) {
      return '${_drilldownMonth!.year}년 ${_drilldownMonth!.month}월';
    }

    // 연도 화면
    return '$_year년 전체보기';
  }

  Widget _buildContent() {
    // 날짜를 선택한 경우 날짜 상세 기록 화면을 보여준다.
    if (_selectedDay != null) {
      return DayRecordDetailView(
        key: ValueKey(_selectedDay!),
        day: _selectedDay!,
      );
    }

    if (_drilldownMonth == null) {
      return _YearGrid(
        year: _year,
        isNavigable: _isNavigable,
        onYearChange: (delta) {
          setState(() {
            _year += delta;
          });
        },
        onSelectMonth: (month) {
          setState(() {
            _drilldownMonth = month;
          });
        },
      );
    }

    return _DayGrid(month: _drilldownMonth!, onSelectDay: _selectDay);
  }

  @override
  Widget build(BuildContext context) {
    final showBack = _selectedDay != null || _drilldownMonth != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                showBack: showBack,
                onBack: _goBack,
                title: _screenTitle,
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('정원 공유는 준비 중이에요 (목업)')),
                  );
                },
              ),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool showBack;
  final VoidCallback onBack;
  final String title;
  final VoidCallback onShare;

  const _TopBar({
    required this.showBack,
    required this.onBack,
    required this.title,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: showBack
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: onBack,
                  )
                : null,
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(
                Icons.ios_share,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: onShare,
            ),
          ),
        ],
      ),
    );
  }
}

class _YearGrid extends StatelessWidget {
  final int year;
  final bool Function(DateTime) isNavigable;
  final void Function(int delta) onYearChange;
  final void Function(DateTime month) onSelectMonth;

  const _YearGrid({
    required this.year,
    required this.isNavigable,
    required this.onYearChange,
    required this.onSelectMonth,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
              onPressed: () => onYearChange(-1),
            ),
            Text(
              '$year',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white70),
              onPressed: () => onYearChange(1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 24,
            crossAxisSpacing: 16,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, i) {
            final month = DateTime(year, i + 1);
            final active = true;
            final isCurrent =
                month.year == today.year && month.month == today.month;

            return _MiniMonthCalendar(
              month: month,
              active: active,
              isCurrentMonth: isCurrent,
              today: today,
              onTap: () => onSelectMonth(month),
            );
          },
        ),
      ],
    );
  }
}

class _MiniMonthCalendar extends StatelessWidget {
  final DateTime month;
  final bool active;
  final bool isCurrentMonth;
  final DateTime today;
  final VoidCallback onTap;

  const _MiniMonthCalendar({
    required this.month,
    required this.active,
    required this.isCurrentMonth,
    required this.today,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // 연도 화면의 미니 달력은 일요일 시작으로 정렬한다.
    final leadingBlanks = firstDay.weekday % 7;

    return Opacity(
      opacity: active ? 1 : 0.35,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${month.month}월',
                style: TextStyle(
                  color: isCurrentMonth
                      ? const Color(0xFF7CE3B8)
                      : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (int i = 0; i < leadingBlanks; i++)
                      const SizedBox.shrink(),
                    for (int day = 1; day <= daysInMonth; day++)
                      _MiniDayNumber(
                        day: day,
                        isToday: isSameDay(
                          DateTime(month.year, month.month, day),
                          today,
                        ),
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

class _MiniDayNumber extends StatelessWidget {
  final int day;
  final bool isToday;

  const _MiniDayNumber({
    required this.day,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isToday ? const Color(0xFF7CE3B8) : Colors.transparent,
        ),
        child: Text(
          '$day',
          style: TextStyle(
            color: isToday ? const Color(0xFF12281F) : Colors.white,
            fontSize: 8.5,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}


class _DayGrid extends StatelessWidget {
  final DateTime month;
  final void Function(DateTime day) onSelectDay;

  const _DayGrid({required this.month, required this.onSelectDay});

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final today = DateTime.now();

    final memoryDays = appData
        .memoriesForMonth(month)
        .where((memory) => memory.deletedAt == null)
        .map((memory) => memory.recordDate.day)
        .toSet();

    final latestDiaryByDay = <int, Diary>{};

    for (final diary in appData.diariesForMonth(month)) {
      if (diary.deletedAt != null) continue;

      final day = diary.recordDate.day;
      final current = latestDiaryByDay[day];

      if (current == null || diary.createdAt.isAfter(current.createdAt)) {
        latestDiaryByDay[day] = diary;
      }
    }

    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: _weekdayLabels
              .map(
                (w) => Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          childAspectRatio: 0.82,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (int i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (int day = 1; day <= daysInMonth; day++)
              _DayCell(
                date: DateTime(month.year, month.month, day),
                isToday: isSameDay(
                  DateTime(month.year, month.month, day),
                  today,
                ),
                hasMemory: memoryDays.contains(day),
                flowerEmotion: latestDiaryByDay[day]?.flowerType.emotionId,
                onTap: () =>
                    onSelectDay(DateTime(month.year, month.month, day)),
              ),
          ],
        ),
      ],
    );
  }
}

const _calendarLeafColor = Color(0xFF7FA36B);

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool hasMemory;
  final Emotion? flowerEmotion;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.isToday,
    required this.hasMemory,
    required this.flowerEmotion,
    required this.onTap,
  });

  Widget _buildRecordMarker() {
    if (!hasMemory && flowerEmotion == null) {
      return const SizedBox(height: 17);
    }

    final leaf = const Icon(
      Icons.eco_rounded,
      size: 13,
      color: _calendarLeafColor,
    );

    final flower = flowerEmotion == null
        ? null
        : ColorFiltered(
            colorFilter: ColorFilter.mode(
              flowerEmotion!.color,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              'assets/images/flower.png',
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          );

    if (hasMemory && flower != null) {
      return SizedBox(
        width: 22,
        height: 17,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(left: 1, top: 0, child: flower),
            Positioned(
              right: 0,
              bottom: 0,
              child: Transform.rotate(angle: -0.55, child: leaf),
            ),
          ],
        ),
      );
    }

    return SizedBox(height: 17, child: Center(child: flower ?? leaf));
  }

  @override
  Widget build(BuildContext context) {
    final hasRecord = hasMemory || flowerEmotion != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? const Color(0xFF7CE3B8) : Colors.transparent,
              boxShadow: hasRecord && !isToday
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7CE3B8).withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: isToday ? const Color(0xFF12281F) : Colors.white,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 3),
          _buildRecordMarker(),
        ],
      ),
    );
  }
}
