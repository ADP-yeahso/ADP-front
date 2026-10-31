import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';

class RecordTextEditScreen extends StatefulWidget {
  final int recordId;
  final bool isTree;
  final String initialTitle;
  final String initialContent;

  const RecordTextEditScreen({
    super.key,
    required this.recordId,
    required this.isTree,
    required this.initialTitle,
    required this.initialContent,
  });

  @override
  State<RecordTextEditScreen> createState() => _RecordTextEditScreenState();
}

class _RecordTextEditScreenState extends State<RecordTextEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해 주세요.')),
      );
      return;
    }

    final titleText = _titleController.text.trim();
    final title = titleText.isEmpty ? null : titleText;
    final data = context.read<AppData>();

    final saved = widget.isTree
        ? data.updateMemoryText(widget.recordId, title, content)
        : data.updateDiaryText(widget.recordId, title, content);

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록을 찾을 수 없어 저장하지 못했어요.')),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTree ? '나무 기록 편집' : '꽃 기록 편집'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              minLines: 7,
              maxLines: null,
              decoration: const InputDecoration(labelText: '내용'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}