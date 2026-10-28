import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'care_notebook_widgets.dart';
import './care_record_view_data.dart';

class CareNotebookWriteScreen extends StatefulWidget {
  const CareNotebookWriteScreen({super.key});

  @override
  State<CareNotebookWriteScreen> createState() =>
      _CareNotebookWriteScreenState();
}

class _CareNotebookWriteScreenState extends State<CareNotebookWriteScreen> {
  static const _mealOptions = ['좋음', '보통', '적음'];

  static const _sleepOptions = ['좋음', '보통', '나쁨'];

  static const _bowelOptions = ['정상', '변화 있음'];

  static const _medicationOptions = ['완료', '누락'];

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

  bool? _hasUnusualChanges = false;
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

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _pickNextVisitDate() async {
    final initialDate =
        _nextVisitDate ?? _selectedDate.add(const Duration(days: 30));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(_selectedDate)
          ? _selectedDate
          : initialDate.isAfter(DateTime(_selectedDate.year + 5))
          ? DateTime(_selectedDate.year + 5)
          : initialDate,
      firstDate: _selectedDate,
      lastDate: DateTime(_selectedDate.year + 5),
      helpText: '다음 진료일을 선택해 주세요',
      cancelText: '취소',
      confirmText: '확인',
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _nextVisitDate = pickedDate;
    });
  }

  bool get _canSave =>
      _mealStatus != null &&
      _sleepStatus != null &&
      _bowelStatus != null &&
      _medicationStatus != null &&
      _hasUnusualChanges != null &&
      (_hasUnusualChanges == false || _selectedUnusualChanges.isNotEmpty);

  void _saveRecord() {
    if (_mealStatus == null ||
        _sleepStatus == null ||
        _bowelStatus == null ||
        _medicationStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식사, 수면, 배변, 복약 상태를 모두 선택해 주세요.')),
      );
      return;
    }

    if (_hasUnusualChanges == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('평소와 다른 점이 있었는지 선택해 주세요.')));
      return;
    }

    if (_hasUnusualChanges == true && _selectedUnusualChanges.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('평소와 다른 점을 하나 이상 선택해 주세요.')));
      return;
    }

    final hasMedicalContent =
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
      unusualChanges: _hasUnusualChanges == true ? selectedChanges : const [],
      note: _noteController.text.trim(),
      hasMedicalUpdate: hasMedicalContent,
      hospitalDepartment: _hospitalDepartmentController.text.trim(),
      visitDetails: _visitDetailsController.text.trim(),
      medicationChanges: _medicationChangesController.text.trim(),
      nextVisitDate: _nextVisitDate,
    );

    // 현재는 서버 저장 대신 최근 기록 화면으로 데이터를 돌려줍니다.
    Navigator.pop(context, record);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: careBackground,
    appBar: careAppBar(),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            key: const ValueKey('care-write-scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 88),
            children: [
              const CarePatientCard(),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: _pickRecordDate,
                          style: TextButton.styleFrom(
                            backgroundColor: careBackground,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('yyyy년 M월 d일').format(_selectedDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const Icon(
                                Icons.expand_more,
                                color: careGreen,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          '의 돌봄 기록',
                          style: TextStyle(
                            color: Color(0xFF243B17),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '선택형 * 짧은 메모로 간단히 기록해보세요',
                      style: TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    _status(
                      '식사',
                      _mealOptions,
                      ['good', 'normal', 'low'],
                      _mealStatus,
                      (v) => setState(() => _mealStatus = v),
                    ),
                    _status(
                      '수면',
                      _sleepOptions,
                      ['good', 'normal', 'bad'],
                      _sleepStatus,
                      (v) => setState(() => _sleepStatus = v),
                    ),
                    _status(
                      '배변',
                      _bowelOptions,
                      ['bowel_normal', 'bowel_changed'],
                      _bowelStatus,
                      (v) => setState(() => _bowelStatus = v),
                    ),
                    _status(
                      '복약',
                      _medicationOptions,
                      ['medication_taken', 'medication_missed'],
                      _medicationStatus,
                      (v) => setState(() => _medicationStatus = v),
                    ),
                    _status(
                      '평소와 다른 점',
                      const ['있음', '없음'],
                      const ['unusual_yes', 'unusual_no'],
                      _hasUnusualChanges == true ? '있음' : '없음',
                      (v) => setState(() => _hasUnusualChanges = v == '있음'),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.topCenter,
                      child: _hasUnusualChanges == true
                          ? Padding(
                              padding: const EdgeInsets.only(
                                left: 80,
                                bottom: 8,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) => Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    for (
                                      var i = 0;
                                      i < _unusualChangeOptions.length;
                                      i++
                                    )
                                      SizedBox(
                                        width: (constraints.maxWidth - 8) / 3,
                                        child: CareAssetButton(
                                          asset:
                                              'option_unusual_${const ['repeated_questions', 'wandering', 'anxiety', 'aggression', 'sleep_change', 'refusing_meals', 'other'][i]}_${_selectedUnusualChanges.contains(_unusualChangeOptions[i]) ? 'selected' : 'unselected'}',
                                          label: _unusualChangeOptions[i],
                                          selected: _selectedUnusualChanges
                                              .contains(
                                                _unusualChangeOptions[i],
                                              ),
                                          height: 26,
                                          onTap: () => setState(() {
                                            if (!_selectedUnusualChanges.add(
                                              _unusualChangeOptions[i],
                                            )) {
                                              _selectedUnusualChanges.remove(
                                                _unusualChangeOptions[i],
                                              );
                                            }
                                          }),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const Text(
                      '특이사항 메모',
                      style: TextStyle(fontSize: 12, color: Color(0xFF243B17)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _noteController,
                      style: const TextStyle(fontSize: 12, height: 1.5),
                      scrollPadding: const EdgeInsets.only(bottom: 100),
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: '오늘 있었던 특이사항을 입력하세요.',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA4B58D),
                        ),
                        fillColor: careBackground,
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: const BorderSide(
                            color: Color(0xFF7F9F5A),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: const BorderSide(
                            color: careGreen,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => setState(
                        () => _showMedicalSection = !_showMedicalSection,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF243B17),
                        backgroundColor: careBackground,
                        side: const BorderSide(color: Color(0xFF7F9F5A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 18),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              '진료 · 약 변경 내용 추가',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Icon(
                            _showMedicalSection
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _showMedicalSection
                          ? Column(
                              children: [
                                _medicalField(
                                  _hospitalDepartmentController,
                                  '병원/진료과',
                                ),
                                _medicalField(_visitDetailsController, '진료 내용'),
                                _medicalField(
                                  _medicationChangesController,
                                  '약 변경',
                                ),
                                TextButton.icon(
                                  onPressed: _pickNextVisitDate,
                                  icon: const Icon(
                                    Icons.calendar_month_outlined,
                                  ),
                                  label: Text(
                                    _nextVisitDate == null
                                        ? '다음 진료일 선택'
                                        : DateFormat(
                                            'yyyy.MM.dd',
                                          ).format(_nextVisitDate!),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              CareAssetButton(
                asset: _canSave ? 'save_green_button' : 'save_yellow_button',
                label: '저장하기',
                height: 48,
                onTap: _saveRecord,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _medicalField(TextEditingController controller, String label) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: controller,
          minLines: 1,
          maxLines: 4,
          style: const TextStyle(fontSize: 12, height: 1.5),
          scrollPadding: const EdgeInsets.only(bottom: 100),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 12, color: careGreen),
            fillColor: careBackground,
            contentPadding: const EdgeInsets.all(10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFBECDA9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: careGreen),
            ),
          ),
        ),
      );
  Widget _status(
    String label,
    List<String> options,
    List<String> assets,
    String? selected,
    ValueChanged<String> onSelected,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF3F5630)),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < options.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CareAssetButton(
                      asset:
                          'option_${assets[i]}_${selected == options[i] ? 'selected' : 'unselected'}',
                      label: '$label ${options[i]}',
                      text: options[i],
                      selected: selected == options[i],
                      height: 30,
                      onTap: () => onSelected(options[i]),
                    ),
                  ),
                ),
              if (options.length == 2) const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ],
    ),
  );
}
