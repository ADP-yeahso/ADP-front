import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'care_notebook_write_screen.dart';
import 'care_record_view_data.dart';
import 'care_notebook_detail_screen.dart';

class CareNotebookListScreen extends StatefulWidget {
  const CareNotebookListScreen({super.key});

  @override
  State<CareNotebookListScreen> createState() =>
      _CareNotebookListScreenState();
}

class _CareNotebookListScreenState
    extends State<CareNotebookListScreen> {
  late final List<CareRecordViewData> _records;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    _records = List.of(mockCareRecords)
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
  }

  List<CareRecordViewData> get _visibleRecords {
    if (_selectedDate == null) {
      return _records;
    }

    return _records
      .where(
        (record) => _isSameDay(record.date, _selectedDate!),
      )
      .toList();
  }

  Future<void> _pickFilterDate() async {
    final pickedDate = await showDatePicker(
     context: context,
     initialDate: _selectedDate ?? DateTime.now(),
     firstDate: DateTime(2020),
    lastDate: DateTime.now(),
     helpText: '확인할 돌봄 기록 날짜를 선택해 주세요',
     cancelText: '취소',
     confirmText: '확인',
    );

    if (pickedDate == null) {
     return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _showAllRecords() {
   setState(() {
     _selectedDate = null;
    });
  }

  void _openDetailScreen(CareRecordViewData record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CareNotebookDetailScreen(
          record: record,
        ),
      ),
    );
  }

  Future<void> _openWriteScreen() async {
    final createdRecord =
        await Navigator.push<CareRecordViewData>(
      context,
      MaterialPageRoute(
        builder: (_) => const CareNotebookWriteScreen(),
      ),
    );

    if (createdRecord == null || !mounted) {
      return;
    }

    setState(() {
      _records.add(createdRecord);
      _records.sort((a, b) => b.date.compareTo(a.date));

      _selectedDate = createdRecord.date;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('돌봄 기록이 임시로 저장되었어요.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecords = _visibleRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Text('돌봄 수첩'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '최근 기록',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _openWriteScreen,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 54),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                    ),
                    icon: const Icon(Icons.edit_note),
                    label: const Text(
                      '기록 작성하기',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '날짜별로 기록한 돌봄 내용을 확인할 수 있어요.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),

              _DateFilterBar(
               selectedDate: _selectedDate,
               onDatePressed: _pickFilterDate,
               onShowAllPressed: _showAllRecords,
              ),

              const SizedBox(height: 22),

              Expanded(
               child: visibleRecords.isEmpty
                    ? _EmptyCareRecordView(
                       selectedDate: _selectedDate,
                      )
                    : ListView.builder(
                       itemCount: visibleRecords.length,
                       itemBuilder: (context, index) {
                          final record = visibleRecords[index];

                          return _TimelineRecordTile(
                            record: record,
                            isLast: index == visibleRecords.length - 1,
                            onTap: () => _openDetailScreen(record),
                          );
                       },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateFilterBar extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onDatePressed;
  final VoidCallback onShowAllPressed;

  const _DateFilterBar({
    required this.selectedDate,
    required this.onDatePressed,
    required this.onShowAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDatePressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
            ),
            icon: const Icon(
              Icons.calendar_month_outlined,
            ),
            label: Text(
              selectedDate == null
                  ? '날짜 선택'
                  : DateFormat('yyyy년 M월 d일').format(
                      selectedDate!,
                    ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (selectedDate != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onShowAllPressed,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 52),
            ),
            child: const Text(
              '전체 보기',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TimelineRecordTile extends StatelessWidget {
  final CareRecordViewData record;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineRecordTile({
    required this.record,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.25),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: primary.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : 16,
              ),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          record.hasMedicalUpdate
                              ? Icons.medical_services_outlined
                              : Icons.note_alt_outlined,
                          color: primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('M월 d일').format(
                                  record.date,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                record.summary,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              if (record.note.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  record.note,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCareRecordView extends StatelessWidget {
  final DateTime? selectedDate;

  const _EmptyCareRecordView({
    this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.note_alt_outlined,
            size: 54,
            color: Colors.black26,
          ),
          const SizedBox(height: 14),
          const Text(
            '아직 작성된 돌봄 기록이 없어요.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '첫 번째 돌봄 기록을 작성해 보세요.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}