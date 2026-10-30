import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../data/app_data.dart';
import '../../models/medication.dart';
import 'settings_components.dart';
import 'patient_details.dart';

class PatientInfoEditScreen extends StatefulWidget {
  const PatientInfoEditScreen({super.key});
  @override
  State<PatientInfoEditScreen> createState() => _PatientInfoEditScreenState();
}

class _PatientInfoEditScreenState extends State<PatientInfoEditScreen> {
  final form = GlobalKey<FormState>();
  late TextEditingController name;
  late List<String> values;
  late String relationship;
  late DateTime birthday;
  bool initialized = false;
  bool medicationsChanged = false;
  late final String initialName, initialRelationship;
  late final List<String> initialValues;
  late final DateTime initialBirthday;

  bool get hasChanges =>
      name.text != initialName ||
      relationship != initialRelationship ||
      birthday != initialBirthday ||
      !listEquals(values, initialValues);

  void onNameEdited() => setState(() {});
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    final data = context.read<AppData>();
    name = TextEditingController(text: data.patient.patientName);
    values = patientValues(data);
    relationship = data.patientRelationLabel;
    final date = data.patient.patientBirthDate.toString().padLeft(8, '0');
    birthday = DateTime(
      int.parse(date.substring(0, 4)),
      int.parse(date.substring(4, 6)),
      int.parse(date.substring(6)),
    );
    initialName = name.text;
    initialRelationship = relationship;
    initialValues = List<String>.of(values);
    initialBirthday = birthday;
    name.addListener(onNameEdited);
    initialized = true;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> edit(int index) async {
    final result = await settingsEditText(
      context,
      patientLabels[index].$2,
      values[index],
    );
    if (result != null && mounted) {
      setState(() {
        values[index] = result;
        if (index == 3) medicationsChanged = true;
      });
    }
  }

  void save() {
    if (!form.currentState!.validate()) return;
    final data = context.read<AppData>();
    final hospital = values[1].split('/');
    data.updatePatientInfo(
      patientName: name.text.trim(),
      patientBirthDate:
          birthday.year * 10000 + birthday.month * 100 + birthday.day,
      patientsNickname: relationship,
      dementiaType: values[0],
      primaryHospital: hospital.first.trim(),
      medicalDepartment: hospital.length > 1
          ? hospital.skip(1).join('/').trim()
          : '',
      diseaseStage: values[2],
      medications: medicationsChanged
          ? values[3]
                .split(',')
                .where((v) => v.trim().isNotEmpty)
                .map((v) => Medication(name: v.trim()))
                .toList()
          : data.patient.medications,
      majorDiseases: values[4]
          .split(',')
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toList(),
      behaviorPatterns: values[5],
      livingArrangement: values[6],
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => SettingsPage(
    title: settingsSvg('edit_patient', 'text_edit_patient_info', height: 55),
    child: Form(
      key: form,
      child: Column(
        children: [
          SettingsEditIdentity(
            group: 'edit_patient',
            controller: name,
            onPhoto: () => settingsUnavailable(context, '사진 변경 기능은 준비 중이에요.'),
          ),
          PatientDetails(
            relationship: relationship,
            birthday: birthday
                .toIso8601String()
                .substring(0, 10)
                .replaceAll('-', '.'),
            values: values,
            onRelationship: () async {
              final value = await settingsEditText(
                context,
                '환자를 부르는 호칭',
                relationship,
              );
              if (value != null && value.isNotEmpty && mounted) {
                setState(() => relationship = value);
              }
            },
            onBirthday: () async {
              final value = await showDatePicker(
                context: context,
                initialDate: birthday,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (value != null && mounted) setState(() => birthday = value);
            },
            onValue: edit,
          ),
          SettingsSave(
            group: 'edit_patient',
            onTap: save,
            isChanged: hasChanges,
          ),
        ],
      ),
    ),
  );
}
