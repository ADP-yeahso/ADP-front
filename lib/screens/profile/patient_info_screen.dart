import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';

class PatientInfoScreen extends StatefulWidget {
  const PatientInfoScreen({super.key});

  @override
  State<PatientInfoScreen> createState() => _PatientInfoScreenState();
}

class _PatientInfoScreenState extends State<PatientInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _patientNameController;
  late final TextEditingController _customRelationController;

  DateTime? _selectedBirthDate;
  String _selectedRelation = '아내';
  bool _initialized = false;

  static const List<String> _relationOptions = [
    '아내',
    '아들',
    '딸',
    '기타',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    final appData = context.read<AppData>();
    final patient = appData.patient;
    final currentRelation = appData.patientRelationLabel;

    _patientNameController = TextEditingController(
      text: patient.patientName,
    );

    _selectedBirthDate = _dateTimeFromInt(
      patient.patientBirthDate,
    );

    if (_relationOptions.contains(currentRelation) &&
        currentRelation != '기타') {
      _selectedRelation = currentRelation;
      _customRelationController = TextEditingController();
    } else {
      _selectedRelation = '기타';
      _customRelationController = TextEditingController(
        text: currentRelation == '환자' ? '' : currentRelation,
      );
    }

    _initialized = true;
  }

  DateTime? _dateTimeFromInt(int value) {
    final text = value.toString().padLeft(8, '0');

    if (text.length != 8) {
      return null;
    }

    final year = int.tryParse(text.substring(0, 4));
    final month = int.tryParse(text.substring(4, 6));
    final day = int.tryParse(text.substring(6, 8));

    if (year == null || month == null || day == null) {
      return null;
    }

    try {
      final date = DateTime(year, month, day);

      if (date.year != year ||
          date.month != month ||
          date.day != day) {
        return null;
      }

      return date;
    } catch (_) {
      return null;
    }
  }

  int _dateTimeToInt(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}.$month.$day';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(1950, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      helpText: '환자의 생년월일을 선택해 주세요',
      cancelText: '취소',
      confirmText: '확인',
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedBirthDate = pickedDate;
    });
  }

  void _savePatientInfo() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('생년월일을 선택해 주세요.'),
        ),
      );
      return;
    }

    final relation = _selectedRelation == '기타'
        ? _customRelationController.text.trim()
        : _selectedRelation;

    context.read<AppData>().updatePatientInfo(
          patientName: _patientNameController.text.trim(),
          patientBirthDate: _dateTimeToInt(_selectedBirthDate!),
          patientsNickname: relation,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('환자 정보가 저장되었어요.'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _customRelationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('환자 정보 보기'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                '환자 기본 정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '환자의 정보와 내가 부르는 호칭을 수정할 수 있어요.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _patientNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '환자 이름',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '환자 이름을 입력해 주세요.';
                  }

                  if (value.trim().length < 2) {
                    return '이름은 두 글자 이상 입력해 주세요.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickBirthDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '생년월일',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                    suffixIcon: Icon(Icons.chevron_right),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedBirthDate == null
                        ? '생년월일을 선택해 주세요'
                        : _formatDate(_selectedBirthDate!),
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedBirthDate == null
                          ? Colors.black45
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '환자를 부르는 호칭',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '설정 화면과 기록 문구에 사용되는 호칭이에요.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              for (final relation in _relationOptions)
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(relation),
                  value: relation,
                  groupValue: _selectedRelation,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedRelation = value;
                    });
                  },
                ),
              if (_selectedRelation == '기타') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customRelationController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: '호칭 직접 입력',
                    hintText: '예: 남편, 어머니, 아버지',
                    prefixIcon: Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedRelation != '기타') {
                      return null;
                    }

                    if (value == null || value.trim().isEmpty) {
                      return '사용할 호칭을 입력해 주세요.';
                    }

                    return null;
                  },
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _savePatientInfo,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}