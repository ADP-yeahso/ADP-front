import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_data.dart';

import '../../models/media.dart';
import '../../services/auth_service.dart';
import '../../services/diary_service.dart';
import 'diary_result_screen.dart';

class DiaryLoadingScreen extends StatefulWidget {
  const DiaryLoadingScreen({
    super.key,
    required this.date,
    required this.title,
    required this.content,
    required this.tokens,
    required this.isPublic,
    this.mediaList = const [],
  });

  final DateTime date;
  final String title;
  final String content;
  final AuthTokens tokens;
  final bool isPublic;
  final List<Media> mediaList;

  @override
  State<DiaryLoadingScreen> createState() => _DiaryLoadingScreenState();
}

class _DiaryLoadingScreenState extends State<DiaryLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final _service = DiaryService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _createDiary();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _service.close();
    super.dispose();
  }

  Future<void> _createDiary() async {
    try {
      final draft = await _service.createDraftAndQuestion(
        tokens: widget.tokens,
        title: widget.title.isEmpty ? null : widget.title,
        situationText: widget.content,
        recordDate: widget.date,
        groupId: context.read<AppData>().group.id,
        mediaList: widget.mediaList,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DiaryResultScreen(
            tokens: widget.tokens,
            draft: draft,
            mediaList: widget.mediaList,
          ),
        ),
      );
    } on DiaryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F5EE),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween<double>(
              begin: .95,
              end: 1.05,
            ).animate(_animationController),
            child: const Icon(
              Icons.auto_awesome,
              size: 88,
              color: Color(0xFFE1613B),
            ),
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(strokeWidth: 2.5),
          const SizedBox(height: 12),
          const Text(
            'AI가 일기를 읽고 질문을 만들고 있어요...',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}
