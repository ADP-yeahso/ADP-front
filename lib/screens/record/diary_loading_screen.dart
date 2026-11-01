import 'package:flutter/material.dart';

import '../../models/media.dart';
import '../../services/auth_service.dart';
import '../../services/diary_service.dart';
import 'diary_result_screen.dart';

class DiaryLoadingScreen extends StatefulWidget {
  const DiaryLoadingScreen({
    super.key,
    required this.date,
    this.title,
    required this.content,
    required this.tokens,
    required this.isPublic,
    this.mediaList = const [],
    this.gifAssetPath,
  });

  final DateTime date;
  final String? title;
  final String content;
  final AuthTokens tokens;
  final bool isPublic;
  final List<Media> mediaList;
  final String? gifAssetPath;

  @override
  State<DiaryLoadingScreen> createState() => _DiaryLoadingScreenState();
}

class _DiaryLoadingScreenState extends State<DiaryLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  final DiaryService _service = DiaryService();
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _startAnalysis();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _service.close();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final draft = await _service.createDraftAndQuestion(
        tokens: widget.tokens,
        situationText: widget.content,
        title: widget.title,
        recordDate: widget.date,
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
      if (mounted) setState(() => _error = error.message);
    } on Exception {
      if (mounted) {
        setState(() => _error = '감정 분석을 시작하지 못했어요. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF0),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE1613B).withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: widget.gifAssetPath == null
                          ? _buildDefaultMotion()
                          : Image.asset(
                              widget.gifAssetPath!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => _buildDefaultMotion(),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_error == null) ...[
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFFE1613B),
                        ),
                      ),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'AI가 감정을 추출하고 있어요...',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '일기 속 마음의 결을 따뜻하게 읽어내고 있습니다 ✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                ] else ...[
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _startAnalysis,
                    child: const Text('다시 시도'),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultMotion() => ScaleTransition(
    scale: _scaleAnimation,
    child: Center(
      child: Image.asset(
        'assets/record/squirrels/diary_loading.png',
        width: 280,
        height: 280,
        fit: BoxFit.contain,
      ),
    ),
  );
}
