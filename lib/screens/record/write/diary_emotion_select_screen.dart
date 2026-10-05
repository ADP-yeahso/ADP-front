import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/emotion_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/diary_service.dart';
import 'diary_loading_screen.dart';

class DiaryEmotionSelectScreen extends StatefulWidget {
  final List<EmotionTagOption> tags;
  final DiaryDraft draft;
  final AuthTokens tokens;

  const DiaryEmotionSelectScreen({
    super.key,
    required this.tags,
    required this.draft,
    required this.tokens,
  });

  /// AI가 추출한 상위 감정 2개의 하위 감정 각각 5개(총 10개)를
  /// 3-4-3 다이아몬드 구도에 감정이 서로 겹치지 않고 교차 배치(A-B-A / B-A-B-A / B-A-B)되도록 섞어주는 함수
  static List<List<EmotionModel>> mixSubEmotions(
    List<EmotionModel> listA,
    List<EmotionModel> listB,
  ) {
    final List<EmotionModel> combined = [];
    final int maxLen = listA.length > listB.length
        ? listA.length
        : listB.length;
    for (int i = 0; i < maxLen; i++) {
      if (i < listA.length) combined.add(listA[i]);
      if (i < listB.length) combined.add(listB[i]);
    }

    if (combined.length >= 10) {
      return [
        combined.sublist(0, 3), // 1행: A0, B0, A1 (A:2, B:1)
        combined.sublist(3, 7), // 2행: B1, A2, B2, A3 (A:2, B:2)
        combined.sublist(7, 10), // 3행: B3, A4, B4 (A:1, B:2)
      ];
    }
    return [combined];
  }

  @override
  State<DiaryEmotionSelectScreen> createState() =>
      _DiaryEmotionSelectScreenState();
}

class _DiaryEmotionSelectScreenState extends State<DiaryEmotionSelectScreen> {
  final List<EmotionModel> _selectedEmotions = [];
  static const int _maxSelection = 3;
  bool _isSaving = false;

  late List<List<EmotionModel>> _scatteredEmotions;

  static const List<List<EmotionModel>> _defaultEmotions = [
    [
      EmotionModel(name: '미안함', color: Color(0xFFD09ED7)),
      EmotionModel(name: '안쓰러움', color: Color(0xFFFFE367)),
      EmotionModel(name: '속상함', color: Color(0xFFE36887)),
    ],
    [
      EmotionModel(name: '억울함', color: Color(0xFFE36887)),
      EmotionModel(name: '고마움', color: Color(0xFFFFE367)),
      EmotionModel(name: '후회스러움', color: Color(0xFF5EA7FF)),
      EmotionModel(name: '자책감', color: Color(0xFFD09ED7)),
    ],
    [
      EmotionModel(name: '사랑스러움', color: Color(0xFFE36887)),
      EmotionModel(name: '다행스러움', color: Color(0xFFFFE367)),
      EmotionModel(name: '무력감', color: Color(0xFF5EA7FF)),
    ],
  ];

  @override
  void initState() {
    super.initState();
    final emotionsByCategory = <String, List<EmotionModel>>{};
    for (final tag in widget.tags) {
      final categoryEmotions =
          EmotionCategories.getSubEmotionsForCategory(
            tag.emotionId ?? tag.emotionName,
          ) ??
          <EmotionModel>[];
      final match = categoryEmotions.where(
        (emotion) => emotion.name == tag.name,
      );
      final emotion = EmotionModel(
        name: tag.name,
        color: match.isNotEmpty ? match.first.color : const Color(0xFF5EA7FF),
        tagId: tag.id,
      );
      emotionsByCategory.putIfAbsent(tag.emotionName, () => []).add(emotion);
    }

    final categories = emotionsByCategory.values.toList(growable: false);
    final listA = categories.isNotEmpty ? categories.first : null;
    final listB = categories.length > 1 ? categories[1] : null;

    if (listA != null &&
        listB != null &&
        listA.isNotEmpty &&
        listB.isNotEmpty) {
      _scatteredEmotions = DiaryEmotionSelectScreen.mixSubEmotions(
        listA,
        listB,
      );
    } else {
      _scatteredEmotions = _defaultEmotions;
    }
  }

  void _toggleEmotion(EmotionModel emotion) {
    if (_isSaving) return;
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

  Future<void> _saveSelectionAndContinue() async {
    final tagIds = _selectedEmotions.map((emotion) => emotion.tagId).toList();
    if (tagIds.length != _maxSelection || tagIds.any((id) => id == null)) {
      _showMessage('감정 태그를 정확히 3개 선택해주세요.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Persist the three tags before finalizing so the backend can calculate
      // correct_emotion_id from the selected tags.
      await DiaryService().saveTagsAndFinalize(
        tokens: widget.tokens,
        diaryId: widget.draft.id,
        tagIds: tagIds.cast<int>(),
      );
      if (!mounted) return;
      _continueToLoadingScreen();
    } on DiaryException catch (error) {
      // Finalization may fail when no flower card is mapped for the emotion.
      // The selected tags are already saved, so allow the user to continue.
      final message = error.message.toLowerCase();
      if (message.contains('flower') && message.contains('not found')) {
        _continueToLoadingScreen();
        return;
      }
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _continueToLoadingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiaryLoadingScreen()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildAssetWidget({
    required List<String> candidatePaths,
    required Widget fallback,
    double? width,
    double? height,
    ColorFilter? colorFilter,
  }) {
    return _tryPath(candidatePaths, 0, fallback, width, height, colorFilter);
  }

  Widget _tryPath(
    List<String> paths,
    int index,
    Widget fallback,
    double? width,
    double? height,
    ColorFilter? colorFilter,
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
        colorFilter: colorFilter,
        placeholderBuilder: (context) => fallback,
      );
    } else {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.contain,
        colorBlendMode: colorFilter != null ? BlendMode.srcIn : null,
        color: colorFilter != null ? Colors.white : null,
        errorBuilder: (context, error, stackTrace) =>
            _tryPath(paths, index + 1, fallback, width, height, colorFilter),
      );
    }
  }

  static const Map<String, String> _wordToCategory = {
    // 감사안도
    '고마움': '감사안도',
    '다행스러움': '감사안도',
    '따뜻함': '감사안도',
    '뿌듯함': '감사안도',
    '편안함': '감사안도',
    // 분노답답
    '무력감': '분노답답',
    '속상함': '분노답답',
    '억울함': '분노답답',
    '원망스러움': '분노답답',
    '짜증': '분노답답',
    '분노': '분노답답',
    '답답함': '분노답답',
    // 불안초조
    '당혹감': '불안초조',
    '두려움': '불안초조',
    '막막함': '불안초조',
    '압박감': '불안초조',
    '예민함': '불안초조',
    // 슬픔상실
    '상실감': '슬픔상실',
    '서러움': '슬픔상실',
    '안타까움': '슬픔상실',
    '탈진': '슬픔상실',
    '허무함': '슬픔상실',
    '슬픔': '슬픔상실',
    '후회감': '슬픔상실',
    // 애틋수용
    '그리움': '애틋수용',
    '뭉클함': '애틋수용',
    '사랑스러움': '애틋수용',
    '소중함': '애틋수용',
    '안쓰러움': '애틋수용',
    '애정': '애틋수용',
    '애틋함': '애틋수용',
    // 죄책자책
    '미안함': '죄책자책',
    '부끄러움': '죄책자책',
    '부족함': '죄책자책',
    '자책감': '죄책자책',
    '후회스러움': '죄책자책',
    '죄책감': '죄책자책',
    '자책': '죄책자책',
    // 중립일상
    '담담함': '중립일상',
    '무심함': '중립일상',
    '무탈함': '중립일상',
    '여유로움': '중립일상',
    '차분함': '중립일상',
    '안도감': '중립일상',
  };

  List<String> _getSubEmotionCandidatePaths(String name) {
    final cat = _wordToCategory[name];
    if (cat != null) {
      return [
        'assets/record/3-2-3 감정 세부단어/3-2-3 감정 세부단어/$cat/svg/$name.svg',
        'assets/record/3-2-3 감정 세부단어/3-2-3 감정 세부단어/$cat/png/$name.png',
      ];
    }
    return [];
  }

  Widget _buildEmotionButton(EmotionModel emotion) {
    final isSelected = _selectedEmotions.contains(emotion);
    final isMaxReached = _selectedEmotions.length >= _maxSelection;
    final isDisabled = !isSelected && isMaxReached;
    final candidatePaths = _getSubEmotionCandidatePaths(emotion.name);

    final textColor = isSelected
        ? ((emotion.color == const Color(0xFFFFE367))
              ? Colors.black87
              : Colors.white)
        : ((isDisabled && !isSelected) ? Colors.grey : Colors.black87);

    return GestureDetector(
      onTap: isDisabled ? null : () => _toggleEmotion(emotion),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? emotion.color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (isDisabled && !isSelected)
                ? Colors.grey.shade300
                : emotion.color,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: emotion.color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: _buildAssetWidget(
          candidatePaths: candidatePaths,
          height: 18,
          colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          fallback: Text(
            emotion.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: textColor,
            ),
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
                horizontal: 16.0,
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
                        'assets/record/choice/svg/3-0,3-2-1~3-2-5대제목 수정.svg/svg/3-2-3 메인 헤드라인-1.svg',
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

                  // 감정 태그 선택 영역 (3-4-3 대칭 다이아몬드 균형 배치)
                  Column(
                    children: _scatteredEmotions.map((row) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: row.map((emotion) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: _buildEmotionButton(emotion),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

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
                        onPressed: isComplete && !_isSaving
                            ? _saveSelectionAndContinue
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
                        child: Text(
                          _isSaving ? '저장 중...' : '다음',
                          style: const TextStyle(
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
