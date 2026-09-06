import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/emergency_contact.dart';
import '../../models/medication.dart';
import 'patient_info_edit_screen.dart';

class PatientInfoScreen extends StatelessWidget {
  const PatientInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final patient = appData.patient;

    final majorDiseasesText = patient.majorDiseases.isEmpty
        ? '미등록'
        : patient.majorDiseases.join(', ');

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        title: const Text('환자 정보'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFFBF0),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '환자 정보 수정',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PatientInfoEditScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ProfileSummaryCard(appData: appData),
            const SizedBox(height: 16),
            _InfoCard(
              title: '기본 정보',
              children: [
                _InfoRow(label: '이름', value: patient.patientName),
                _InfoRow(label: '생년월일', value: appData.patientBirthDateLabel),
                _InfoRow(
                  label: '보호자와의 관계',
                  value: appData.patientRelationshipLabel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: '건강 정보',
              children: [
                _InfoRow(
                  label: '치매 진단 시기',
                  value: appData.dementiaDiagnosisDateLabel,
                ),
                _InfoRow(label: '주요 질환', value: majorDiseasesText),
                _InfoRow(
                  label: '주 이용 병원',
                  value: patient.primaryHospital.isEmpty
                      ? '미등록'
                      : patient.primaryHospital,
                ),
                _InfoRow(
                  label: '진료과',
                  value: patient.medicalDepartment.isEmpty
                      ? '미등록'
                      : patient.medicalDepartment,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MedicationCard(medications: patient.medications),
            const SizedBox(height: 16),
            _EmergencyContactCard(contacts: patient.emergencyContacts),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  final AppData appData;
  const _ProfileSummaryCard({required this.appData});

  @override
  Widget build(BuildContext context) {
    final profileUrl = appData.patient.profileImageUrl;
    final hasImage = profileUrl != null && profileUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE7D8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFF3EFE0),
            backgroundImage: hasImage ? NetworkImage(profileUrl) : null,
            child: !hasImage
                ? const Icon(Icons.person, size: 30, color: Colors.black45)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appData.patientRelationLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${appData.patientRelationshipLabel} · ${appData.patientBirthDateLabel}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final rowsWithDividers = <Widget>[];

    for (int i = 0; i < children.length; i++) {
      rowsWithDividers.add(children[i]);
      if (i < children.length - 1) {
        rowsWithDividers.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF2EFE6)),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE7D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          ...rowsWithDividers,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value.isEmpty ? '미등록' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final List<Medication> medications;

  const _MedicationCard({required this.medications});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (medications.isEmpty) {
      items.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '등록된 약이 없어요.',
            style: TextStyle(fontSize: 14, color: Colors.black45),
          ),
        ),
      );
    } else {
      for (int i = 0; i < medications.length; i++) {
        final med = medications[i];
        items.add(
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  size: 20,
                  color: Color(0xFF5A82A6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  med.name.isEmpty ? '미등록' : med.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                med.dosage.isEmpty ? '미등록' : med.dosage,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        );

        if (i < medications.length - 1) {
          items.add(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFF2EFE6)),
            ),
          );
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE7D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '복용 중인 약',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          ...items,
        ],
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final List<EmergencyContact> contacts;

  const _EmergencyContactCard({required this.contacts});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (contacts.isEmpty) {
      items.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '등록된 연락처가 없어요.',
            style: TextStyle(fontSize: 14, color: Colors.black45),
          ),
        ),
      );
    } else {
      for (int i = 0; i < contacts.length; i++) {
        final contact = contacts[i];
        items.add(
          Row(
            children: [
              Text(
                contact.label.isEmpty ? '미등록' : contact.label,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  contact.phoneNumber.isEmpty ? '미등록' : contact.phoneNumber,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );

        if (i < contacts.length - 1) {
          items.add(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFF2EFE6)),
            ),
          );
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE7D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '긴급 연락처',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          ...items,
        ],
      ),
    );
  }
}
