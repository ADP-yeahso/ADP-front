import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../services/api_service.dart';

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
  bool _isSaving = false;

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

  Future<void> _save() async {
    if (_isSaving) return;
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내용을 입력해 주세요.')));
      return;
    }

    final titleText = _titleController.text.trim();
    final title = titleText.isEmpty ? null : titleText;
    final data = context.read<AppData>();

    setState(() => _isSaving = true);
    try {
      final saved = widget.isTree
          ? await data.updateMemoryText(widget.recordId, title, content)
          : await data.updateDiaryText(widget.recordId, title, content);
      if (!mounted) return;
      if (!saved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('기록을 찾을 수 없어 저장하지 못했어요.')));
        return;
      }
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !widget.isTree && error.statusCode == 409
                ? '저장 완료된 꽃 기록은 현재 수정할 수 없어요.'
                : error.message,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isTree ? '나무 기록 편집' : '꽃 기록 편집')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              enabled: !_isSaving,
              maxLength: widget.isTree ? null : 255,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              enabled: !_isSaving,
              maxLength: widget.isTree ? null : 20000,
              minLines: 7,
              maxLines: null,
              decoration: const InputDecoration(labelText: '내용'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isSaving ? '저장 중...' : '저장'),
            ),
          ],
        ),
      ),
    );
  }
}
