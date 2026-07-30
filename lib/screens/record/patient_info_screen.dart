import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';

class PatientInfoScreen extends StatefulWidget {
  const PatientInfoScreen({super.key});

  @override
  State<PatientInfoScreen> createState() => _PatientInfoScreenState();
}

class _PatientInfoScreenState extends State<PatientInfoScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _hasPhoto = false;
  bool _isPublic = true;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해 주세요.')),
      );
      return;
    }
    context.read<AppData>().addMemory(
          date: _date,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          hasPhoto: _hasPhoto,
          isPublic: _isPublic,
        );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('나무에 새 잎이 달렸어요 🌿')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.read<AppData>();
    return Scaffold(
      appBar: AppBar(title: const Text('환자 정보 입력')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘 ${appData.patientRelationLabel}과 있었던 일을 나무의 잎으로 남겨보세요.',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '날짜'),
                child: Text('${_date.year}년 ${_date.month}월 ${_date.day}일'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목', hintText: '예: 함께 본 옛날 사진'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '내용',
                hintText: '오늘 있었던 일을 자유롭게 적어보세요',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilterChip(
              avatar: Icon(_hasPhoto ? Icons.check_circle : Icons.add_photo_alternate_outlined,
                  color: _hasPhoto ? Theme.of(context).colorScheme.primary : Colors.black45),
              label: const Text('사진 · 영상 첨부'),
              selected: _hasPhoto,
              onSelected: (v) => setState(() => _hasPhoto = v),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('가족에게 공개'),
              subtitle: const Text('가족 공유 화면에서 함께 볼 수 있어요'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('나무에 저장하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
