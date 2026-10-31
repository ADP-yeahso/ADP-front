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
  static const _labelWidth = 64.0;
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
  resizeToAvoidBottomInset: true,
  body: SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            8,
            18,
            MediaQuery.viewInsetsOf(context).bottom > 0 ? 16 : 52,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CarePatientCard(),
              const SizedBox(height: 10),
              Expanded(
                child: _buildRecordForm(context),
              ),
              const SizedBox(height: 16),
              CareAssetButton(
                asset: _canSave
                    ? 'save_green_button'
                    : 'save_yellow_button',
                label: '저장하기',
                height: 48,
                onTap: _saveRecord,
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  Widget _buildRecordForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage(
            'assets/images/care_note/record_form_frame.png',
          ),
          fit: BoxFit.fill,
        ),
      ),
      child: ListView(
        key: const ValueKey('care-write-scroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.zero,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              TextButton(
                onPressed: _pickRecordDate,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                child: Container(
                  width: 170,
                  height: 33,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/images/care_note/date_picker_frame.png',
                      ),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat(
                            'yyyy년 M월 d일',
                          ).format(_selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          child: careAsset(
                            'dropdown_arrow',
                            width: 12,
                            height: 7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Semantics(
                label: '의 돌봄 기록',
                excludeSemantics: true,
                child: careAsset(
                  'record_type_label',
                  width: 72,
                  height: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: '선택형 + 짧은 메모로 간단히 기록해보세요',
            excludeSemantics: true,
            child: Align(
              alignment: Alignment.centerLeft,
              child: careAsset('record_prompt_text', height: 11),
            ),
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
                      left: _labelWidth,
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
                                height: 30,
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
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              color: Color(0xFF3F5630),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: LayoutBuilder(
              builder: (context, constraints) => ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxWidth * 81 / 286,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/care_note/notes_frame.png',
                        scale: 3,
                        centerSlice: const Rect.fromLTRB(
                          12,
                          12,
                          272,
                          67,
                        ),
                        filterQuality: FilterQuality.high,
                        fit: BoxFit.fill,
                        excludeFromSemantics: true,
                      ),
                    ),
                    TextField(
                      controller: _noteController,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                      ),
                      scrollPadding: const EdgeInsets.only(
                        bottom: 100,
                      ),
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: '오늘 있었던 특이사항을 입력하세요.',
                        hintStyle: const TextStyle(
                          color: Colors.transparent,
                        ),
                        filled: false,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.fromLTRB(
                          10,
                          10,
                          10,
                          18,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 20,
                      top: 10,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child:
                              ValueListenableBuilder<
                                TextEditingValue
                              >(
                                valueListenable: _noteController,
                                builder: (context, value, child) =>
                                    value.text.isEmpty
                                    ? Align(
                                        alignment:
                                            Alignment.centerLeft,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: careAsset(
                                            'notes_placeholder',
                                            width: 167,
                                            height: 11,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 20,
                      top:
                          12 +
                          MediaQuery.textScalerOf(context).scale(12) *
                              1.5,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: SizedBox(
                            height: 2,
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: careAsset(
                                'notes_input_underline',
                                width: 254,
                                height: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
              label: '진료 · 약 변경 내용 추가',
              button: true,
              expanded: _showMedicalSection,
              excludeSemantics: true,
              child: InkWell(
                onTap: () => setState(
                  () => _showMedicalSection = !_showMedicalSection,
                ),
                child: careFrame(
                  'medical_change_frame',
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            careAsset(
                              'add_icon',
                              width: 15,
                              height: 15,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: careAsset(
                                  'add_medical_change_text',
                                  height: 11,
                                ),
                              ),
                            ),
                            RotatedBox(
                              quarterTurns: _showMedicalSection
                                  ? 2
                                  : 0,
                              child: careAsset(
                                'dropdown_arrow',
                                width: 17,
                                height: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 19,
                        right: 22,
                        bottom: 0,
                        child: careDivider('medical_change_divider'),
                      ),
                    ],
                  ),
                ),
              ),
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
    );
  }
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
          width: _labelWidth,
          child: Semantics(
            label: label,
            excludeSemantics: true,
            child: Center(
              child: careAsset(
                const {
                  '식사': 'meal_label',
                  '수면': 'sleep_label',
                  '배변': 'bowel_label',
                  '복약': 'medication_label',
                  '평소와 다른 점': 'unusual_change_label',
                }[label]!,
                height: 11,
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: i < options.length
                      ? CareAssetButton(
                          asset:
                              'option_${assets[i]}_${selected == options[i] ? 'selected' : 'unselected'}',
                          label: '$label ${options[i]}',
                          text: options[i],
                          selected: selected == options[i],
                          height: 30,
                          onTap: () => onSelected(options[i]),
                        )
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
