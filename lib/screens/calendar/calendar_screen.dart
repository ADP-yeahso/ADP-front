import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import 'day_record_detail_view.dart';
import '../../data/garden_range.dart';

const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
const _monthLabels = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];

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
        month.year > _minMonth.year || (month.year == _minMonth.year && month.month >= _minMonth.month);
    final beforeMax =
        month.year < _maxMonth.year || (month.year == _maxMonth.year && month.month <= _maxMonth.month);
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
        if (!_isNavigable(month)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('아직 이동할 수 없는 달이에요.'),
            ),
          );

          return;
        }

        setState(() {
          _drilldownMonth = month;
        });
      },
    );
  }

  return _DayGrid(
    month: _drilldownMonth!,
    onSelectDay: _selectDay,
  );
}

  @override
  Widget build(BuildContext context) {
    final showBack =
        _selectedDay != null || _drilldownMonth != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: _bgGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                showBack: showBack,
                onBack: _goBack,
                title: _screenTitle,
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('정원 공유는 준비 중이에요 (목업)'),
                    ),
                  );
                },
              ),
              Expanded(
                child: _buildContent(),
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(Icons.ios_share, color: Colors.white70, size: 20),
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
    final appData = context.watch<AppData>();
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
            Text('$year', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
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
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, i) {
            final month = DateTime(year, i + 1);
            final leafCount = appData.memoriesForMonth(month).length;
            final diaryCount = appData.diariesForMonth(month).length;
            final active = isNavigable(month);
            final isCurrent = month.year == today.year && month.month == today.month;
            return _MonthTile(
              label: _monthLabels[i],
              leafCount: leafCount,
              diaryCount: diaryCount,
              active: active,
              isCurrent: isCurrent,
              onTap: () => onSelectMonth(month),
            );
          },
        ),
      ],
    );
  }
}

class _MonthTile extends StatelessWidget {
  final String label;
  final int leafCount;
  final int diaryCount;
  final bool active;
  final bool isCurrent;
  final VoidCallback onTap;

  const _MonthTile({
    required this.label,
    required this.leafCount,
    required this.diaryCount,
    required this.active,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasEntries = leafCount + diaryCount > 0;
    final glowColor = hasEntries ? const Color(0xFF7CE3B8) : const Color(0xFF3E6B58);

    return Opacity(
      opacity: active ? 1 : 0.35,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrent ? const Color(0xFF7CE3B8) : Colors.white.withValues(alpha: 0.08),
              width: isCurrent ? 1.4 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glowColor.withValues(alpha: hasEntries ? 0.28 : 0.12),
                  boxShadow: hasEntries
                      ? [BoxShadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 1)]
                      : null,
                ),
                alignment: Alignment.center,
                child: Icon(
                  hasEntries ? Icons.park : Icons.park_outlined,
                  color: hasEntries ? const Color(0xFF9FF0CE) : Colors.white24,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                hasEntries ? '잎 $leafCount · 꽃 $diaryCount' : '기록 없음',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
              ),
            ],
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
    final entryDays = appData.entryDatesForMonth(month).map((d) => d.day).toSet();

    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: _weekdayLabels
              .map((w) => Expanded(
                    child: Center(
                      child: Text(w, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (int i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (int day = 1; day <= daysInMonth; day++)
              _DayCell(
                day: day,
                isToday: isSameDay(DateTime(month.year, month.month, day), today),
                hasEntry: entryDays.contains(day),
                onTap: () => onSelectDay(DateTime(month.year, month.month, day)),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool hasEntry;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.hasEntry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              boxShadow: hasEntry && !isToday
                  ? [BoxShadow(color: const Color(0xFF7CE3B8).withValues(alpha: 0.4), blurRadius: 8)]
                  : null,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                color: isToday ? const Color(0xFF12281F) : Colors.white,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasEntry ? const Color(0xFF7CE3B8) : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
