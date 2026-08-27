import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'care_record_view_data.dart';

class CareNotebookDetailScreen extends StatelessWidget {
  final CareRecordViewData record;

  const CareNotebookDetailScreen({
    super.key,
    required this.record,
  });

  String _displayValue(String value) {
    return value.trim().isEmpty ? '미입력' : value;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('돌봄 기록 상세'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.note_alt_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('yyyy년 M월 d일').format(
                            record.date,
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          record.summary,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _DetailSection(
              title: '생활 상태',
              child: Column(
                children: [
                  _DetailRow(
                    label: '식사',
                    value: record.mealStatus,
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    label: '수면',
                    value: record.sleepStatus,
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    label: '배변',
                    value: record.bowelStatus,
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    label: '복약 여부',
                    value: record.medicationStatus,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _DetailSection(
              title: '평소와 다른 점',
              child: record.unusualChanges.isEmpty
                  ? const Text(
                      '없음',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    )
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final change
                            in record.unusualChanges)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    primary.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              change,
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            _DetailSection(
              title: '특이사항',
              child: Text(
                record.note.trim().isEmpty
                    ? '작성된 특이사항이 없어요.'
                    : record.note,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: record.note.trim().isEmpty
                      ? Colors.black45
                      : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _DetailSection(
              title: '진료·약 변경',
              child: record.hasMedicalUpdate
                  ? Column(
                      children: [
                        _DetailRow(
                          label: '병원/진료과',
                          value: _displayValue(
                            record.hospitalDepartment,
                          ),
                        ),
                        const Divider(height: 1),
                        _DetailRow(
                          label: '진료 내용',
                          value: _displayValue(
                            record.visitDetails,
                          ),
                        ),
                        const Divider(height: 1),
                        _DetailRow(
                          label: '약 변경',
                          value: _displayValue(
                            record.medicationChanges,
                          ),
                        ),
                        const Divider(height: 1),
                        _DetailRow(
                          label: '다음 진료일',
                          value: record.nextVisitDate == null
                              ? '미입력'
                              : DateFormat('yyyy.MM.dd').format(
                                  record.nextVisitDate!,
                                ),
                        ),
                      ],
                    )
                  : const Text(
                      '추가된 진료·약 변경 내용이 없어요.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black45,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    color: value == '미입력'
                        ? Colors.black38
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
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