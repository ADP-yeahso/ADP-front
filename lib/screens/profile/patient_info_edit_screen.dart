import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/medication.dart';
import '../../models/emergency_contact.dart';

class PatientInfoEditScreen extends StatefulWidget {
  const PatientInfoEditScreen({super.key});

  @override
  State<PatientInfoEditScreen> createState() => _PatientInfoEditScreenState();
}

class _PatientInfoEditScreenState extends State<PatientInfoEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _patientNameController;
  late final TextEditingController _customRelationshipController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _diagnosisYearMonthController;
  late final TextEditingController _majorDiseasesController;
  late final TextEditingController _primaryHospitalController;
  late final TextEditingController _medicalDepartmentController;

  DateTime? _selectedBirthDate;
  String _selectedRelationship = '기타';
  List<Medication> _medications = [];
  List<EmergencyContact> _emergencyContacts = [];
  bool _initialized = false;

  static const List<String> _relationshipOptions = [
    '아버지',
    '어머니',
    '남편',
    '아내',
    '할아버지',
    '할머니',
    '시아버지',
    '시어머니',
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
    final currentRelationship = appData.patientRelationshipLabel;
    final currentNickname = appData.patientRelationLabel;

    _patientNameController = TextEditingController(text: patient.patientName);
    _nicknameController = TextEditingController(
      text: currentNickname == '환자' ? '' : currentNickname,
    );
    _diagnosisYearMonthController = TextEditingController(
      text: patient.dementiaDiagnosisYearMonth?.toString() ?? '',
    );
    _majorDiseasesController = TextEditingController(
      text: patient.majorDiseases.join(', '),
    );
    _primaryHospitalController = TextEditingController(
      text: patient.primaryHospital,
    );
    _medicalDepartmentController = TextEditingController(
      text: patient.medicalDepartment,
    );
    _medications = List<Medication>.from(patient.medications);
    _emergencyContacts = List<EmergencyContact>.from(patient.emergencyContacts);

    _selectedBirthDate = _dateTimeFromInt(patient.patientBirthDate);

    if (_relationshipOptions.contains(currentRelationship) &&
        currentRelationship != '기타') {
      _selectedRelationship = currentRelationship;
      _customRelationshipController = TextEditingController();
    } else {
      _selectedRelationship = '기타';
      _customRelationshipController = TextEditingController(
        text: currentRelationship == '관계 미설정' ? '' : currentRelationship,
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

      if (date.year != year || date.month != month || date.day != day) {
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

  Future<void> _showMedicationDialog({int? index}) async {
    final existingMedication = index == null ? null : _medications[index];

    final nameController = TextEditingController(
      text: existingMedication?.name ?? '',
    );
    final dosageController = TextEditingController(
      text: existingMedication?.dosage ?? '',
    );
    final medicationFormKey = GlobalKey<FormState>();

    final medication = await showDialog<Medication>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(index == null ? '복용약 추가' : '복용약 수정'),
          content: Form(
            key: medicationFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '약 이름',
                      hintText: '예: 도네페질',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '약 이름을 입력해 주세요.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: dosageController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: '복용 방법',
                      hintText: '예: 1일 1회',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '복용 방법을 입력해 주세요.';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                if (!medicationFormKey.currentState!.validate()) {
                  return;
                }

                Navigator.of(dialogContext).pop(
                  Medication(
                    name: nameController.text.trim(),
                    dosage: dosageController.text.trim(),
                  ),
                );
              },
              child: Text(index == null ? '추가' : '완료'),
            ),
          ],
        );
      },
    );

    if (!mounted || medication == null) {
      return;
    }

    setState(() {
      if (index == null) {
        _medications.add(medication);
      } else {
        _medications[index] = medication;
      }
    });
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  Future<void> _showEmergencyContactDialog({int? index}) async {
    final existingContact = index == null ? null : _emergencyContacts[index];

    final labelController = TextEditingController(
      text: existingContact?.label ?? '',
    );
    final phoneController = TextEditingController(
      text: existingContact?.phoneNumber ?? '',
    );
    final contactFormKey = GlobalKey<FormState>();

    final contact = await showDialog<EmergencyContact>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(index == null ? '긴급 연락처 추가' : '긴급 연락처 수정'),
          content: Form(
            key: contactFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: labelController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '연락처 구분',
                      hintText: '예: 보호자, 가족 연락처',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '연락처 구분을 입력해 주세요.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: '전화번호',
                      hintText: '예: 010-1234-5678',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '전화번호를 입력해 주세요.';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                if (!contactFormKey.currentState!.validate()) {
                  return;
                }

                Navigator.of(dialogContext).pop(
                  EmergencyContact(
                    label: labelController.text.trim(),
                    phoneNumber: phoneController.text.trim(),
                  ),
                );
              },
              child: Text(index == null ? '추가' : '완료'),
            ),
          ],
        );
      },
    );

    if (!mounted || contact == null) {
      return;
    }

    setState(() {
      if (index == null) {
        _emergencyContacts.add(contact);
      } else {
        _emergencyContacts[index] = contact;
      }
    });
  }

  void _removeEmergencyContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
  }

  void _savePatientInfo() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('생년월일을 선택해 주세요.')));
      return;
    }
    final relationship = _selectedRelationship == '기타'
        ? _customRelationshipController.text.trim()
        : _selectedRelationship;
    final diagnosisText = _diagnosisYearMonthController.text.trim();
    final diagnosisYearMonth = diagnosisText.isEmpty
        ? null
        : int.parse(diagnosisText);

    final majorDiseases = _majorDiseasesController.text
        .split(',')
        .map((disease) => disease.trim())
        .where((disease) => disease.isNotEmpty)
        .toList();

    context.read<AppData>().updatePatientInfo(
      patientName: _patientNameController.text.trim(),
      patientBirthDate: _dateTimeToInt(_selectedBirthDate!),
      patientsNickname: _nicknameController.text.trim(),
      relationship: relationship,
      dementiaDiagnosisYearMonth: diagnosisYearMonth,
      majorDiseases: majorDiseases,
      primaryHospital: _primaryHospitalController.text.trim(),
      medicalDepartment: _medicalDepartmentController.text.trim(),
      medications: List<Medication>.from(_medications),
      emergencyContacts: List<EmergencyContact>.from(_emergencyContacts),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('환자 정보가 저장되었어요.')));

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _customRelationshipController.dispose();
    _nicknameController.dispose();
    _diagnosisYearMonthController.dispose();
    _majorDiseasesController.dispose();
    _primaryHospitalController.dispose();
    _medicalDepartmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('환자 정보 수정')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                '환자 기본 정보',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '환자의 정보와 내가 부르는 호칭을 수정할 수 있어요.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
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
                '보호자와의 관계',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '환자가 나에게 어떤 관계인지 선택해 주세요.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedRelationship,
                decoration: const InputDecoration(
                  labelText: '보호자와의 관계',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _relationshipOptions.map((relationship) {
                  return DropdownMenuItem<String>(
                    value: relationship,
                    child: Text(relationship),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedRelationship = value;
                  });
                },
              ),
              if (_selectedRelationship == '기타') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customRelationshipController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '관계 직접 입력',
                    hintText: '예: 이모, 고모, 어머님',
                    prefixIcon: Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedRelationship != '기타') {
                      return null;
                    }

                    if (value == null || value.trim().isEmpty) {
                      return '환자와의 관계를 입력해 주세요.';
                    }

                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                '환자를 부르는 호칭',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '설정 화면과 기록 문구에 사용되는 호칭이에요.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nicknameController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '환자를 부르는 호칭',
                  hintText: '예: 엄마, 아빠, 여보, 어머님',
                  prefixIcon: Icon(Icons.favorite_border),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '사용할 호칭을 입력해 주세요.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),
              const Text(
                '건강 정보',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '환자의 진단 및 주 이용 병원 정보를 입력해 주세요.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _diagnosisYearMonthController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '치매 진단 시기',
                  hintText: '예: 202403',
                  helperText: '연도와 월을 숫자 6자리로 입력해 주세요.',
                  prefixIcon: Icon(Icons.event_outlined),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return null;
                  }

                  if (!RegExp(r'^\d{6}$').hasMatch(text)) {
                    return '예: 202403 형식으로 입력해 주세요.';
                  }

                  final month = int.parse(text.substring(4, 6));

                  if (month < 1 || month > 12) {
                    return '월은 01부터 12까지 입력해 주세요.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _majorDiseasesController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '주요 질환',
                  hintText: '예: 고혈압, 당뇨',
                  helperText: '여러 질환은 쉼표로 구분해 주세요.',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _primaryHospitalController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '주 이용 병원',
                  hintText: '예: ○○대학교병원',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _medicalDepartmentController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '진료과',
                  hintText: '예: 신경과',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),
              const Text(
                '복용 중인 약',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '현재 복용 중인 약과 복용 방법을 관리할 수 있어요.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              if (_medications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '등록된 약이 없어요.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              else
                ...List.generate(_medications.length, (index) {
                  final medication = _medications[index];

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.medication_outlined),
                        title: Text(medication.name),
                        subtitle: Text(medication.dosage),
                        onTap: () => _showMedicationDialog(index: index),
                        trailing: IconButton(
                          tooltip: '약 삭제',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeMedication(index),
                        ),
                      ),
                      if (index < _medications.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _showMedicationDialog,
                icon: const Icon(Icons.add),
                label: const Text('복용약 추가'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),
              const Text(
                '긴급 연락처',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '필요할 때 바로 확인할 수 있는 연락처를 등록해 주세요.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              if (_emergencyContacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '등록된 연락처가 없어요.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              else
                ...List.generate(_emergencyContacts.length, (index) {
                  final contact = _emergencyContacts[index];

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.contact_phone_outlined),
                        title: Text(contact.label),
                        subtitle: Text(contact.phoneNumber),
                        onTap: () => _showEmergencyContactDialog(index: index),
                        trailing: IconButton(
                          tooltip: '연락처 삭제',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeEmergencyContact(index),
                        ),
                      ),
                      if (index < _emergencyContacts.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _showEmergencyContactDialog,
                icon: const Icon(Icons.add),
                label: const Text('긴급 연락처 추가'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
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
