import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import 'day_record_detail_view.dart';
import '../../data/garden_range.dart';
import '../../models/memory.dart';

import '../../models/diary.dart';
import '../../models/emotions.dart';
import '../../utils/emotion_utils.dart';

import 'package:flutter_svg/flutter_svg.dart';

const _weekdayAssetPaths = [
  'assets/page2/weekdays/sunday_red.svg',
  'assets/page2/weekdays/monday.svg',
  'assets/page2/weekdays/tuesday.svg',
  'assets/page2/weekdays/wednesday.svg',
  'assets/page2/weekdays/thursday.svg',
  'assets/page2/weekdays/friday.svg',
  'assets/page2/weekdays/saturday_blue.svg',
  ];

const _bgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF12281F), Color(0xFF1E4A38)],
);

class CalendarScreen extends StatefulWidget {
  final DateTime? initialDay;
  final Memory? initialMemory;
  final Diary? initialDiary;
  const CalendarScreen({super.key, this.initialDay, this.initialMemory, this.initialDiary});

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
    _selectedDay = widget.initialDay;
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
      if (widget.initialDay != null) {  
        Navigator.of(context).pop();
        return;
      }
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

  void _changeMonth(int delta) {
  final currentMonth = _drilldownMonth;
  if (currentMonth == null) return;

  final nextMonth = DateTime(
    currentMonth.year,
    currentMonth.month + delta,
    1,
  );

  if (!_isNavigable(nextMonth)) return;

  setState(() {
    _drilldownMonth = nextMonth;
  });
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

  bool get _isMonthCalendar =>
    _drilldownMonth != null && _selectedDay == null;

  bool get _isDetail =>
    _selectedDay != null;

  Widget _buildContent() {
    // 날짜를 선택한 경우 날짜 상세 기록 화면을 보여준다.
    if (_selectedDay != null) {
      return DayRecordDetailView(
        key: ValueKey(
          '${_selectedDay!}-'
          '${widget.initialMemory?.id ?? 'memory'}-'
          '${widget.initialDiary?.id ?? 'diary'}'
        ),
        day: _selectedDay!,
        selectedMemory: widget.initialMemory,
        selectedDiary: widget.initialDiary,
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

    return _DayGrid(month: _drilldownMonth!, onSelectDay: _selectDay, onMonthChange: _changeMonth,
      onBackToYear: () {
        setState(() {
          _drilldownMonth = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBack = _selectedDay != null || _drilldownMonth != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF0),
        ),
        
        child: SafeArea(
          child: Column(
            children: [
              if (!_isMonthCalendar)
                _TopBar(
                  isDetail: _selectedDay != null,
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
  final bool isDetail;

  const _TopBar({
    required this.showBack,
    required this.onBack,
    required this.title,
    required this.onShare,
    required this.isDetail,
  });

  @override
  Widget build(BuildContext context) {
    if (isDetail) {
      return SizedBox(
        width: double.infinity,
        height: 69,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
             'assets/page2/record_detail/top_bar.svg',
              width: double.infinity,
              height: 69,
              fit: BoxFit.fill,
           ),
           Positioned(
              left: 20,
              child: GestureDetector(
                onTap: onBack,
                child: SvgPicture.asset(
                  'assets/page2/record_detail/back_button.svg',
                 width: 12,
                 height: 22,
                ),
             ),
            ),
           Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
    );
}
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
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.black),
              onPressed: () => onYearChange(-1),
            ),
            Text(
              '$year',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.black),
              onPressed: () => onYearChange(1),
            ),
          ],
        ),
        const SizedBox(height: 2),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 8,
            childAspectRatio: 0.88,
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

    final leadingBlanks = firstDay.weekday % 7;

    final appData = context.watch<AppData>();
    final latestDiaryByDay = <int, Diary>{};

    for (final diary in appData.diariesForMonth(month)) {
      if (diary.deletedAt != null) continue;

      final day = diary.recordDate.day;
      final current = latestDiaryByDay[day];

      if (current == null || diary.createdAt.isAfter(current.createdAt)) {
        latestDiaryByDay[day] = diary;
      }
    }

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
                  color: Colors.black,
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
                        date: DateTime(month.year, month.month, day),
                        isToday: isSameDay(
                          DateTime(month.year, month.month, day),
                          today,
                        ),
                        flowerEmotion: latestDiaryByDay[day]?.flowerType.emotionId,
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
  final DateTime date;
  final bool isToday;
  final Emotion? flowerEmotion;

  const _MiniDayNumber({
    required this.date,
    required this.isToday,
    required this.flowerEmotion,
  });

  @override
  Widget build(BuildContext context) {
    String numberAsset;

    if (date.weekday == DateTime.sunday) {
      numberAsset = 'assets/page2/numbers/red/red_${date.day}.svg';
    } else if (date.weekday == DateTime.saturday) {
      numberAsset = 'assets/page2/numbers/blue/blue_${date.day}.svg';
    } else {
      numberAsset = 'assets/page2/numbers/black/${date.day}.svg';
    }

    String? moodAsset;
    switch (flowerEmotion?.id) {
      case 1:
        moodAsset = 'assets/page2/moods/b_d.svg';
        break;
      case 2:
        moodAsset = 'assets/page2/moods/b_ch.svg';
        break;
      case 3:
        moodAsset = 'assets/page2/moods/s_s.svg';
        break;
      case 4:
        moodAsset = 'assets/page2/moods/j_j.svg';
        break;
      case 5:
        moodAsset = 'assets/page2/moods/g_a.svg';
        break;
      case 6:
        moodAsset = 'assets/page2/moods/a_s.svg';
        break;
      case 7:
        moodAsset = 'assets/page2/moods/joonglib.svg';
       break;
    }

    return Center(
     child: SizedBox(
        width: 17,
        height: 17,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (moodAsset != null)
              SvgPicture.asset(
                moodAsset,
                width: 17,
                height: 17,
              ),
            if (moodAsset == null && isToday)
              Container(
                width: 17,
                height: 17,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF7FA36B),
                ),
              ),
            SvgPicture.asset(
              numberAsset,
              width: 10,
              height: 10,
            ),
          ],
        ),
      ),
    );
  }
}


class _DayGrid extends StatelessWidget {
  final DateTime month;
  final void Function(DateTime day) onSelectDay;
  final void Function(int delta) onMonthChange;
  final VoidCallback onBackToYear;

  const _DayGrid({required this.month, required this.onSelectDay, required this.onMonthChange, required this.onBackToYear});

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
    final leadingBlanks = firstDay.weekday % 7;

    return Container(
      color: const Color(0xFFFFFBF0),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [

          Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 4,
                bottom: 12,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE5E1D8),
                    width: 1,
                  ),
                ),
              ),
              child: const Center(
                child: Text(
                  '기억 되돌아보기',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
             ),
          

          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: () => onMonthChange(-1),
                    ),
                    Text(
                      '${month.year}년 ${month.month}월',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: () => onMonthChange(1),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  child: IconButton(
                    icon: SvgPicture.asset(
                      'assets/page2/record_detail/back_button.svg',
                      width: 12,
                      height: 22,
                    ),
                    onPressed: onBackToYear,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Row(
            children: _weekdayAssetPaths
                .map((assetPath) {
                  final isFriday = assetPath.endsWith('friday.svg');
                  final isSaturday = assetPath.endsWith('saturday_blue.svg');

                  final scale = isFriday ? 0.9 : isSaturday ? 0.8 : 1.0;

                  return Expanded(
                    child: Center(
                      child: Transform.scale(
                        scale: scale,
                        child: SvgPicture.asset(
                          assetPath,
                          width: 14,
                          height: 15,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                })
                .toList(),
          ),

          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 7,
            childAspectRatio: 0.70,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (int i = 0; i < leadingBlanks; i++)
                const SizedBox.shrink(),

              for (int day = 1; day <= daysInMonth; day++)
                _DayCell(
                  date: DateTime(month.year, month.month, day),
                  isToday: isSameDay(
                    DateTime(month.year, month.month, day),
                    today,
                  ),
                  hasMemory: memoryDays.contains(day),
                  flowerEmotion: latestDiaryByDay[day]?.flowerType.emotionId,
                  onTap: () {
                    onSelectDay(
                      DateTime(month.year, month.month, day),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
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

  String _numberAssetPath() {
    if (date.weekday == DateTime.sunday) {
      return 'assets/page2/numbers/red/red_${date.day}.svg';
    }

    if (date.weekday == DateTime.saturday) {
      return 'assets/page2/numbers/blue/blue_${date.day}.svg';
    }

    return 'assets/page2/numbers/black/${date.day}.svg';
  }

  String? _moodAssetPath() {
    final emotion = flowerEmotion;
    if (emotion == null) return null;
    
    switch (emotion.id) {
      case 1:
       return 'assets/page2/moods/b_d.svg'; // 분노·답답함
      case 2:
       return 'assets/page2/moods/b_ch.svg'; // 불안·초조함
      case 3:
        return 'assets/page2/moods/s_s.svg'; // 슬픔·소진
      case 4:
        return 'assets/page2/moods/j_j.svg'; // 죄책감·자책
      case 5:
        return 'assets/page2/moods/g_a.svg'; // 감사·안도
      case 6:
        return 'assets/page2/moods/a_s.svg'; // 애틋함·수용
      case 7:
       return 'assets/page2/moods/joonglib.svg'; // 중립
      default:
       return null;
    }
  }

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
    final moodAssetPath = _moodAssetPath();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 55,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (moodAssetPath != null)
                  SvgPicture.asset(
                    moodAssetPath,
                    width: 55,
                    height: 46,
                    fit: BoxFit.contain,
                  ),
                SvgPicture.asset(
                  _numberAssetPath(),
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        const SizedBox(height: 17),
        ],
      ),
    );
  }
}