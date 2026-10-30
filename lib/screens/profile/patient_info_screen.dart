import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_data.dart';
import 'settings_components.dart';
import 'patient_details.dart';
import 'patient_info_edit_screen.dart';

class PatientInfoScreen extends StatelessWidget {
  const PatientInfoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    return SettingsPage(
      title: settingsSvg('patient_info', 'text_patient_info', height: 34),
      child: Column(
        children: [
          SettingsIdentity(
            group: 'patient_info',
            box: 'box_patient_info',
            subtitleFirst: true,
            name: data.patient.patientName,
            subtitle: settingsSvg(
              'patient_info',
              'text_patient_name',
              height: 14,
            ),
            onEdit: () => Navigator.push(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: 'edit_patient'),
                builder: (_) => const PatientInfoEditScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          PatientDetails(
            relationship: data.patientRelationLabel,
            birthday: data.patientBirthDateLabel
                .replaceAll('년 ', '.')
                .replaceAll('월 ', '.')
                .replaceAll('일', ''),
            values: patientValues(data),
          ),
        ],
      ),
    );
  }
}
