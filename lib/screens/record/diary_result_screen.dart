import 'package:flutter/material.dart';

import '../../models/media.dart';
import '../../services/auth_service.dart';
import '../../services/diary_service.dart';

class DiaryResultScreen extends StatefulWidget {
  const DiaryResultScreen({
    super.key,
    required this.tokens,
    required this.draft,
    this.mediaList = const [],
  });

  final AuthTokens tokens;
  final DiaryDraft draft;
  final List<Media> mediaList;

  @override
  State<DiaryResultScreen> createState() => _DiaryResultScreenState();
}

class _DiaryResultScreenState extends State<DiaryResultScreen> {
  final _answerController = TextEditingController();
  final _service = DiaryService();
  List<EmotionTagOption> _tags = const [];
  final Set<int> _selectedTagIds = {};
  bool _isSubmitting = false;
  DiaryFinalization? _finalization;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _saveAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return _showMessage('AI 질문에 대한 답변을 작성해주세요.');
    setState(() => _isSubmitting = true);
    try {
      final tags = await _service.saveAnswerAndGetSuggestions(
        tokens: widget.tokens,
        diaryId: widget.draft.id,
        answer: answer,
      );
      if (mounted) setState(() => _tags = tags);
    } on DiaryException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toggleTag(int id) {
    if (_selectedTagIds.contains(id)) {
      setState(() => _selectedTagIds.remove(id));
      return;
    }
    if (_selectedTagIds.length == 3) {
      _showMessage('감정 태그는 3개까지 선택할 수 있어요.');
      return;
    }
    setState(() => _selectedTagIds.add(id));
  }

  Future<void> _finalize() async {
    if (_selectedTagIds.length != 3) {
      return _showMessage('감정 태그를 정확히 3개 선택해주세요.');
    }
    setState(() => _isSubmitting = true);
    try {
      final result = await _service.saveTagsAndFinalize(
        tokens: widget.tokens,
        diaryId: widget.draft.id,
        tagIds: _selectedTagIds.toList(),
      );
      if (mounted) setState(() => _finalization = result);
    } on DiaryException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final finalization = _finalization;
    return Scaffold(
      appBar: AppBar(title: Text(finalization == null ? 'AI 감정 질문' : '오늘의 감정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: finalization == null
            ? _buildQuestionStep()
            : _buildCompleteStep(finalization),
      ),
    );
  }

  Widget _buildQuestionStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'AI가 건네는 질문',
        style: TextStyle(fontSize: 13, color: Colors.black54),
      ),
      const SizedBox(height: 8),
      Text(
        widget.draft.aiQuestion,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _answerController,
        maxLines: 5,
        enabled: _tags.isEmpty && !_isSubmitting,
        decoration: const InputDecoration(
          labelText: '답변',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 16),
      if (_tags.isEmpty)
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _saveAnswer,
            child: Text(
              _isSubmitting ? '감정 태그를 찾고 있어요...' : '답변 저장하고 감정 태그 추천받기',
            ),
          ),
        )
      else ...[
        Text(
          '감정 태그를 3개 선택해주세요 (${_selectedTagIds.length}/3)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags
              .map(
                (tag) => FilterChip(
                  label: Text('${tag.emotionName} · ${tag.name}'),
                  selected: _selectedTagIds.contains(tag.id),
                  onSelected: _isSubmitting ? null : (_) => _toggleTag(tag.id),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _finalize,
            icon: const Icon(Icons.local_florist),
            label: Text(_isSubmitting ? '저장 중...' : '꽃으로 저장하기'),
          ),
        ),
      ],
      if (widget.mediaList.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text(
          '첨부한 미디어 ${widget.mediaList.length}개는 서버 업로드 API가 준비되면 함께 저장됩니다.',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    ],
  );

  Widget _buildCompleteStep(DiaryFinalization result) => Center(
    child: Column(
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.local_florist, size: 80, color: Color(0xFFE1613B)),
        const SizedBox(height: 20),
        Text(
          result.emotionName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(result.flowerName, style: const TextStyle(fontSize: 20)),
        if (result.flowerSentence.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(result.flowerSentence, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
          child: const Text('정원으로 돌아가기'),
        ),
      ],
    ),
  );
}
