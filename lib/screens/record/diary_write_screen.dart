import 'package:flutter/material.dart';

import 'diary_result_screen.dart';

class DiaryWriteScreen extends StatefulWidget {
  const DiaryWriteScreen({super.key});

  @override
  State<DiaryWriteScreen> createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen> {
  final _contentController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isPublic = true;

  @override
  void dispose() {
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

  void _analyze() {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘의 감정을 조금이라도 적어주세요.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryResultScreen(
          date: _date,
          content: _contentController.text.trim(),
          isPublic: _isPublic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('오늘의 감정 일기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘의 돌봄 경험과 감정을 편하게 적어보세요. 작성한 글은 AI가 분석해 감정에 맞는 콘텐츠를 추천해드려요.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
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
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: '오늘의 감정 일기',
                hintText: '오늘 하루는 어떠셨나요?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('가족에게 공개'),
              subtitle: const Text('끄면 나만 볼 수 있는 비공개 기록이 돼요'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _analyze,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('감정 분석하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
