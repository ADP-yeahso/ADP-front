import 'package:flutter/material.dart';
import '../../data/app_data.dart';
import 'settings_components.dart';

const patientLabels = [
  ('text_dementia_type', '치매 유형'),
  ('text_hospital_physician', '병원 / 주치의'),
  ('text_disease_stage', '진행 단계'),
  ('text_medications', '복용 약물'),
  ('text_comorbidities', '동반 질환'),
  ('text_behavior_patterns', '특이 행동 패턴'),
  ('text_living_arrangement', '거주 형태'),
];
List<String> patientValues(AppData data) => [
  data.patient.dementiaType,
  [
    data.patient.primaryHospital,
    data.patient.medicalDepartment,
  ].where((s) => s.isNotEmpty).join(' / '),
  data.patient.diseaseStage,
  data.patient.medications
      .map((m) => [m.name, m.dosage].where((s) => s.isNotEmpty).join(' '))
      .join(', '),
  data.patient.majorDiseases.join(', '),
  data.patient.behaviorPatterns,
  data.patient.livingArrangement,
];

class PatientDetails extends StatelessWidget {
  const PatientDetails({
    super.key,
    required this.relationship,
    required this.birthday,
    required this.values,
    this.onRelationship,
    this.onBirthday,
    this.onValue,
  });
  final String relationship, birthday;
  final List<String> values;
  final VoidCallback? onRelationship, onBirthday;
  final void Function(int)? onValue;
  Widget value(String text, VoidCallback? tap) => InkWell(
    onTap: tap,
    child: Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        text.isEmpty ? '미등록' : text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SettingsPanel(
        group: 'patient_info',
        asset: 'box_basic_info',
        height: 96,
        children: [
          value(relationship, onRelationship),
          value(birthday, onBirthday),
        ],
      ),
      const SizedBox(height: 6),
      SettingsPanel(
        group: 'patient_info',
        asset: 'box_disease_info',
        height: 321,
        children: [
          for (var i = 0; i < patientLabels.length; i++)
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: SizedBox(
                    width: 100,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: settingsSvg(
                        'patient_info',
                        patientLabels[i].$1,
                        height: 13,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Semantics(
                    key: ValueKey('patient_field_$i'),
                    label: patientLabels[i].$2,
                    child: value(
                      values[i],
                      onValue == null ? null : () => onValue!(i),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
