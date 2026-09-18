import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../services/auth_service.dart';
import '../../../services/diary_service.dart';
import 'diary_loading_screen.dart';
import 'diary_result_screen.dart';

class DiaryEmotionSelectScreen extends StatefulWidget {
  const DiaryEmotionSelectScreen({
    super.key,
    required this.diaryId,
    required this.tokens,
    required this.tags,
  });
  final int diaryId;
  final AuthTokens tokens;
  final List<EmotionTagOption> tags;

  @override
  State<DiaryEmotionSelectScreen> createState() =>
      _DiaryEmotionSelectScreenState();
}

class _DiaryEmotionSelectScreenState extends State<DiaryEmotionSelectScreen> {
  final List<EmotionTagOption> _selectedEmotions = [];
  static const int _maxSelection = 3;

  void _toggleEmotion(EmotionTagOption emotion) {
    setState(() {
      if (_selectedEmotions.contains(emotion)) {
        _selectedEmotions.remove(emotion);
      } else {
        if (_selectedEmotions.length < _maxSelection) {
          _selectedEmotions.add(emotion);
        }
      }
    });
  }

  Widget _buildAssetWidget({
    required List<String> candidatePaths,
    required Widget fallback,
    double? width,
    double? height,
  }) {
    return _tryPath(candidatePaths, 0, fallback, width, height);
  }

  Widget _tryPath(
    List<String> paths,
    int index,
    Widget fallback,
    double? width,
    double? height,
  ) {
    if (index >= paths.length) return fallback;
    final path = paths[index];
    final isSvg = path.toLowerCase().endsWith('.svg');
    if (isSvg) {
      return SvgPicture.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => fallback,
      );
    } else {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _tryPath(paths, index + 1, fallback, width, height),
      );
    }
  }

  Color _colorFor(int id) => const [
    Color(0xFFD09ED7),
    Color(0xFFFFE367),
    Color(0xFFE36887),
    Color(0xFF5EA7FF),
  ][id % 4];

  EmotionTagOption _tag(int index) => widget.tags[index % widget.tags.length];

  Widget _buildEmotionButton(EmotionTagOption emotion) {
    final color = _colorFor(emotion.id);
    final isSelected = _selectedEmotions.contains(emotion);
    final isMaxReached = _selectedEmotions.length >= _maxSelection;
    final isDisabled = !isSelected && isMaxReached;

    return GestureDetector(
      onTap: isDisabled ? null : () => _toggleEmotion(emotion),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (isDisabled && !isSelected) ? Colors.grey.shade300 : color,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          emotion.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? ((color == const Color(0xFFFFE367))
                      ? Colors.black87
                      : Colors.white)
                : ((isDisabled && !isSelected) ? Colors.grey : Colors.black87),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isComplete = _selectedEmotions.length == _maxSelection;
    const backgroundColor = Color(0xFFFFFBF0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 다람쥐 캐릭터 (150x150 확대)
                  Center(
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: _buildAssetWidget(
                        candidatePaths: const [
                          'assets/record/choice/svg/3-2-3.svg/svg/3-2-3 다람쥐4.svg',
                          'assets/record/choice/png/3-2-3.png/png/3-2-3 다람쥐4.png',
                        ],
                        fallback: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCDCDC),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 메인 헤드라인 ("오늘 느낀 감정은 무엇인가요?")
                  Center(
                    child: _buildAssetWidget(
                      candidatePaths: const [
                        'assets/record/choice/svg/3-2-3.svg/svg/3-2-3 메인 헤드라인.svg',
                        'assets/record/choice/png/3-2-3.png/png/3-2-3 메인 헤드라인.png',
                      ],
                      fallback: const Text(
                        '오늘 느낀 감정은 무엇인가요?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222222),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 감정 태그 선택 영역 (총 10개)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEmotionButton(_tag(0)),
                      const SizedBox(width: 12),
                      _buildEmotionButton(_tag(1)),
                      const SizedBox(width: 12),
                      _buildEmotionButton(_tag(2)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildEmotionButton(_tag(3)),
                        const SizedBox(width: 14),
                        _buildEmotionButton(_tag(4)),
                        const SizedBox(width: 12),
                        _buildEmotionButton(_tag(5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEmotionButton(_tag(6)),
                      const SizedBox(width: 14),
                      _buildEmotionButton(_tag(7)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEmotionButton(_tag(8)),
                      const SizedBox(width: 14),
                      _buildEmotionButton(_tag(9)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 하위감정 선택 게이지 바 (0/3, 1/3, 2/3, 3/3)
                  Center(
                    child: Container(
                      width: 100,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // 채워지는 프로그래스 바 (ffcb0f / 3개 달성 시 연두색)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final double fillWidth =
                                  constraints.maxWidth *
                                  (_selectedEmotions.length / _maxSelection);
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: fillWidth,
                                height: constraints.maxHeight,
                                decoration: BoxDecoration(
                                  color: isComplete
                                      ? const Color(0xFFA5DD82)
                                      : const Color(0xFFFFCB0F),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              );
                            },
                          ),
                          // 게이지 표시 텍스트 (0/3 ~ 3/3)
                          Center(
                            child: Text(
                              '${_selectedEmotions.length}/$_maxSelection',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 하단 다음 버튼 (감정 3개 선택 완료 전까지 클릭 불가)
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isComplete
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DiaryLoadingScreen(
                                      loadNext: () async {
                                        final result = await DiaryService()
                                            .saveTagsAndFinalize(
                                              tokens: widget.tokens,
                                              diaryId: widget.diaryId,
                                              tagIds: _selectedEmotions
                                                  .map((tag) => tag.id)
                                                  .toList(),
                                            );
                                        return DiaryResultScreen(
                                          result: result,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isComplete
                              ? const Color(0xFFA5DD82)
                              : const Color(0xFFFFF2B2),
                          disabledBackgroundColor: const Color(0xFFFFF2B2),
                          foregroundColor: Colors.black87,
                          disabledForegroundColor: Colors.black45,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: const Text(
                          '다음',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
