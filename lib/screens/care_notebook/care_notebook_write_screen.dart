import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../profile/patient_info_screen.dart';
import './care_record_view_data.dart';

class CareNotebookWriteScreen extends StatefulWidget {
  final PatientSummaryViewData patientSummary;

  const CareNotebookWriteScreen({
    super.key,
    this.patientSummary = mockPatientSummary,
  });

  @override
  State<CareNotebookWriteScreen> createState() =>
      _CareNotebookWriteScreenState();
}

class _CareNotebookWriteScreenState
    extends State<CareNotebookWriteScreen> {
  static const _mealOptions = [
    '좋음',
    '보통',
    '적음',
    '거의 못함',
  ];

  static const _sleepOptions = [
    '좋음',
    '보통',
    '나쁨',
  ];

  static const _bowelOptions = [
    '정상',
    '변화 있음',
    '없음',
  ];

  static const _medicationOptions = [
    '완료',
    '일부 누락',
    '미복용',
  ];

  static const _unusualChangeOptions = [
    '같은 질문 반복',
    '배회',
    '불안·초조',
    '공격적 행동',
    '수면 변화',
    '식사 거부',
    '기타',
  ];

  DateTime _selectedDate = DateTime.now();
  DateTime? _nextVisitDate;

  String? _mealStatus;
  String? _sleepStatus;
  String? _bowelStatus;
  String? _medicationStatus;

  bool? _hasUnusualChanges;
  final Set<String> _selectedUnusualChanges = {};

  bool _showMedicalSection = false;

  final _noteController = TextEditingController();
  final _hospitalDepartmentController = TextEditingController();
  final _visitDetailsController = TextEditingController();
  final _medicationChangesController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    _hospitalDepartmentController.dispose();
    _visitDetailsController.dispose();
    _medicationChangesController.dispose();
    super.dispose();
  }

  Future<void> _pickRecordDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: '돌봄 기록 날짜를 선택해 주세요',
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

  Future<void> _pickNextVisitDate() async {
    final initialDate = _nextVisitDate ??
        _selectedDate.add(const Duration(days: 30));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _selectedDate,
      lastDate: DateTime(_selectedDate.year + 5),
      helpText: '다음 진료일을 선택해 주세요',
      cancelText: '취소',
      confirmText: '확인',
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _nextVisitDate = pickedDate;
    });
  }

  void _openPatientInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientInfoScreen(),
      ),
    );
  }

  void _saveRecord() {
    if (_mealStatus == null ||
        _sleepStatus == null ||
        _bowelStatus == null ||
        _medicationStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('식사, 수면, 배변, 복약 상태를 모두 선택해 주세요.'),
        ),
      );
      return;
    }

    if (_hasUnusualChanges == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('평소와 다른 점이 있었는지 선택해 주세요.'),
        ),
      );
      return;
    }

    if (_hasUnusualChanges == true &&
        _selectedUnusualChanges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('평소와 다른 점을 하나 이상 선택해 주세요.'),
        ),
      );
      return;
    }

    final hasMedicalContent = _showMedicalSection &&
        (_hospitalDepartmentController.text.trim().isNotEmpty ||
            _visitDetailsController.text.trim().isNotEmpty ||
            _medicationChangesController.text.trim().isNotEmpty ||
            _nextVisitDate != null);

    final selectedChanges = _unusualChangeOptions
        .where(_selectedUnusualChanges.contains)
        .toList();

    final record = CareRecordViewData(
      date: _selectedDate,
      mealStatus: _mealStatus!,
      sleepStatus: _sleepStatus!,
      bowelStatus: _bowelStatus!,
      medicationStatus: _medicationStatus!,
      unusualChanges:
          _hasUnusualChanges == true ? selectedChanges : const [],
      note: _noteController.text.trim(),
      hasMedicalUpdate: hasMedicalContent,
      hospitalDepartment:
          _hospitalDepartmentController.text.trim(),
      visitDetails: _visitDetailsController.text.trim(),
      medicationChanges:
          _medicationChangesController.text.trim(),
      nextVisitDate: _nextVisitDate,
    );

    // 현재는 서버 저장 대신 최근 기록 화면으로 데이터를 돌려줍니다.
    Navigator.pop(context, record);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('돌봄 수첩'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _PatientSummaryCard(
              patient: widget.patientSummary,
              onDetailPressed: _openPatientInfo,
            ),
            const SizedBox(height: 20),

            _DateTitle(
              selectedDate: _selectedDate,
              onTap: _pickRecordDate,
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: '생활 상태',
              description: '오늘의 기본적인 생활 상태를 선택해 주세요.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusSelector(
                    label: '식사',
                    options: _mealOptions,
                    selectedValue: _mealStatus,
                    onSelected: (value) {
                      setState(() {
                        _mealStatus = value;
                      });
                    },
                  ),
                  const Divider(height: 28),
                  _StatusSelector(
                    label: '수면',
                    options: _sleepOptions,
                    selectedValue: _sleepStatus,
                    onSelected: (value) {
                      setState(() {
                        _sleepStatus = value;
                      });
                    },
                  ),
                  const Divider(height: 28),
                  _StatusSelector(
                    label: '배변',
                    options: _bowelOptions,
                    selectedValue: _bowelStatus,
                    onSelected: (value) {
                      setState(() {
                        _bowelStatus = value;
                      });
                    },
                  ),
                  const Divider(height: 28),
                  _StatusSelector(
                    label: '복약 여부',
                    options: _medicationOptions,
                    selectedValue: _medicationStatus,
                    onSelected: (value) {
                      setState(() {
                        _medicationStatus = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: '오늘 평소와 다른 점',
              description: '평소와 다른 행동이나 변화가 있었나요?',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusSelector(
                    label: '평소와 다른 점',
                    options: const ['없음', '있음'],
                    selectedValue: _hasUnusualChanges == null
                        ? null
                        : (_hasUnusualChanges! ? '있음' : '없음'),
                    onSelected: (value) {
                      setState(() {
                        _hasUnusualChanges = value == '있음';

                        if (_hasUnusualChanges == false) {
                          _selectedUnusualChanges.clear();
                        }
                      });
                    },
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _hasUnusualChanges == true
                        ? Padding(
                            key: const ValueKey(
                              'unusual-change-options',
                            ),
                            padding: const EdgeInsets.only(top: 20),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final option
                                    in _unusualChangeOptions)
                                  _FilterOptionChip(
                                    label: option,
                                    selected:
                                        _selectedUnusualChanges
                                            .contains(option),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedUnusualChanges
                                              .add(option);
                                        } else {
                                          _selectedUnusualChanges
                                              .remove(option);
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey(
                              'unusual-change-empty',
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: '특이사항',
              description: '오늘 기억해둘 일이 있다면 적어주세요.',
              child: TextField(
                controller: _noteController,
                minLines: 4,
                maxLines: 7,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: '오늘 평소와 달랐던 점이나 기억해둘 일을 적어주세요.',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: '진료·약 변경',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showMedicalSection =
                            !_showMedicalSection;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      alignment: Alignment.centerLeft,
                    ),
                    icon: Icon(
                      _showMedicalSection
                          ? Icons.expand_less
                          : Icons.add,
                    ),
                    label: Text(
                      _showMedicalSection
                          ? '진료·약 변경 내용 닫기'
                          : '진료·약 변경 내용 추가',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _showMedicalSection
                        ? Padding(
                            key: const ValueKey(
                              'medical-section',
                            ),
                            padding: const EdgeInsets.only(top: 18),
                            child: Column(
                              children: [
                                TextField(
                                  controller:
                                      _hospitalDepartmentController,
                                  textInputAction:
                                      TextInputAction.next,
                                  decoration:
                                      const InputDecoration(
                                    labelText: '병원/진료과',
                                    hintText: '예: ○○병원 신경과',
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller:
                                      _visitDetailsController,
                                  minLines: 2,
                                  maxLines: 4,
                                  decoration:
                                      const InputDecoration(
                                    labelText: '진료 내용',
                                    hintText:
                                        '진료에서 안내받은 내용을 입력해 주세요.',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller:
                                      _medicationChangesController,
                                  minLines: 2,
                                  maxLines: 4,
                                  decoration:
                                      const InputDecoration(
                                    labelText: '약 변경',
                                    hintText:
                                        '추가되거나 변경된 약을 입력해 주세요.',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                InkWell(
                                  onTap: _pickNextVisitDate,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  child: InputDecorator(
                                    decoration:
                                        const InputDecoration(
                                      labelText: '다음 진료일',
                                      suffixIcon: Icon(
                                        Icons.calendar_month_outlined,
                                      ),
                                    ),
                                    child: Text(
                                      _nextVisitDate == null
                                          ? '날짜를 선택해 주세요.'
                                          : DateFormat(
                                              'yyyy.MM.dd',
                                            ).format(
                                              _nextVisitDate!,
                                            ),
                                      style: TextStyle(
                                        color:
                                            _nextVisitDate == null
                                                ? Colors.black45
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey(
                              'medical-section-empty',
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _saveRecord,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
              ),
              child: const Text(
                '저장하기',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientSummaryCard extends StatelessWidget {
  final PatientSummaryViewData patient;
  final VoidCallback onDetailPressed;

  const _PatientSummaryCard({
    required this.patient,
    required this.onDetailPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFFE9E9E9),
            child: Icon(
              Icons.person,
              size: 38,
              color: Colors.black38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '생년월일 ${patient.birthDate}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '치매 진단 ${patient.diagnosisMonth}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  patient.hospitalName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onDetailPressed,
            child: const Text('자세히 보기'),
          ),
        ],
      ),
    );
  }
}

class _DateTitle extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;

  const _DateTitle({
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black26),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('yyyy년 M월 d일').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.expand_more),
              ],
            ),
          ),
        ),
        const Text(
          '의 돌봄 기록',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (description != null) ...[
            const SizedBox(height: 5),
            Text(
              description!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  const _StatusSelector({
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(option),
                selected: selectedValue == option,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                selectedColor: primary,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selectedValue == option
                      ? primary
                      : Colors.black26,
                ),
                labelStyle: TextStyle(
                  color: selectedValue == option
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => onSelected(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _FilterOptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterOptionChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      selectedColor: primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? primary : Colors.black26,
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      onSelected: onSelected,
    );
  }
}