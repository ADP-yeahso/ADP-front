import 'package:flutter/material.dart';

import '../../models/media.dart';
import 'diary_result_screen.dart';

class DiaryLoadingScreen extends StatefulWidget {
  final DateTime date;
  final String content;
  final bool isPublic;
  final List<Media> mediaList;
  final String? gifAssetPath;

  const DiaryLoadingScreen({
    super.key,
    required this.date,
    required this.content,
    required this.isPublic,
    this.mediaList = const [],
    this.gifAssetPath,
  });

  @override
  State<DiaryLoadingScreen> createState() => _DiaryLoadingScreenState();
}

class _DiaryLoadingScreenState extends State<DiaryLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _startAnalysis();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryResultScreen(
          date: widget.date,
          content: widget.content,
          isPublic: widget.isPublic,
          mediaList: widget.mediaList,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // GIF / 모션 프레임 영역 (스케치 디자인 반영)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE1613B).withValues(alpha: 0.3), width: 2),
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
                    child: widget.gifAssetPath != null
                        ? Image.asset(
                            widget.gifAssetPath!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => _buildDefaultFlowerMotion(),
                          )
                        : _buildDefaultFlowerMotion(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // 하단 감정 추출 중 텍스트 (스케치 텍스트 반영)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE1613B)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI가 감정을 추출하고 있어요...',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '일기 속 마음의 결을 따뜻하게 읽어내고 있습니다 ✨',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultFlowerMotion() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD591), width: 2),
              ),
              child: const Icon(
                Icons.filter_vintage_outlined,
                size: 84,
                color: Color(0xFFE1613B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '민들레',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '- 감사와 행복 -',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
