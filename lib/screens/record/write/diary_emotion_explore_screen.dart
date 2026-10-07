import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../services/auth_service.dart';
import '../../../services/diary_service.dart';
import 'diary_loading_screen.dart';
import 'diary_emotion_select_screen.dart';

class DiaryEmotionExploreScreen extends StatefulWidget {
  const DiaryEmotionExploreScreen({
    super.key,
    required this.draft,
    required this.tokens,
  });

  final DiaryDraft draft;
  final AuthTokens tokens;

  @override
  State<DiaryEmotionExploreScreen> createState() =>
      _DiaryEmotionExploreScreenState();
}

class _DiaryEmotionExploreScreenState extends State<DiaryEmotionExploreScreen> {
  final TextEditingController _controller = TextEditingController();
  final _formScrollController = ScrollController();
  final _answerFieldKey = GlobalKey();
  final _answerFocusNode = FocusNode();

  bool get _isInputFocused => _answerFocusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _answerFocusNode.addListener(_handleInputFocus);
  }

  void _handleInputFocus() {
    if (!mounted) return;
    setState(() {});
    if (!_isInputFocused) return;

    for (final delay in const [
      Duration.zero,
      Duration(milliseconds: 180),
      Duration(milliseconds: 420),
    ]) {
      Future.delayed(delay, () {
        if (!mounted || !_isInputFocused) return;
        final fieldContext = _answerFieldKey.currentContext;
        if (fieldContext == null || !fieldContext.mounted) return;
        Scrollable.ensureVisible(
          fieldContext,
          alignment: 0.12,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _answerFocusNode.removeListener(_handleInputFocus);
    _controller.dispose();
    _formScrollController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFFBF0);
    final isKeyboardLayout = _isInputFocused;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardScrollSpace = keyboardInset > 0 ? keyboardInset + 24 : 320.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        toolbarHeight: isKeyboardLayout ? 40 : kToolbarHeight,
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
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            isKeyboardLayout ? 0 : 10,
            20,
            isKeyboardLayout ? 0 : 10,
          ),
          child: SingleChildScrollView(
            controller: _formScrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isKeyboardLayout) ...[
                  // 다람쥐 캐릭터 (150x150으로 확대)
                  Center(
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: _buildAssetWidget(
                        candidatePaths: const [
                          'assets/record/choice/svg/3-2-2.svg/svg/3-2-2 다람쥐3.svg',
                          'assets/record/choice/png/3-2-2.png/png/3-2-2 다람쥐3.png',
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
                  const SizedBox(height: 16),

                  // 메인 헤드라인 ("오늘 느낀 감정을 표현해볼까요?")
                  Center(
                    child: _buildAssetWidget(
                      candidatePaths: const [
                        'assets/record/choice/svg/3-0,3-2-1~3-2-5대제목 수정.svg/svg/3-2-2 메인 헤드라인.svg',
                        'assets/record/choice/svg/3-2-2.svg/svg/3-2-2 메인 헤드라인.svg',
                        'assets/record/choice/png/3-2-2.png/png/3-2-2 메인 헤드라인.png',
                      ],
                      fallback: const Text(
                        '오늘 느낀 감정을 표현해볼까요?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222222),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Text(
                  widget.draft.aiQuestion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // 입력창 (텍스트 입력) - 단일 테두리 적용 (이중 경계 제거)
                SizedBox(
                  height: isKeyboardLayout ? 230 : 300,
                  child: TextField(
                    key: _answerFieldKey,
                    controller: _controller,
                    focusNode: _answerFocusNode,
                    scrollPadding: EdgeInsets.zero,
                    maxLines: null,
                    expands: true,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: '텍스트 입력',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 하단 다음 버튼 (텍스트 입력 전까지 클릭 불가)
                Builder(
                  builder: (context) {
                    final bool isFormValid = _controller.text.trim().isNotEmpty;
                    return Center(
                      child: SizedBox(
                        width: 180,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isFormValid
                              ? () {
                                  final answer = _controller.text.trim();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DiaryLoadingScreen(
                                        loadNext: () async {
                                          final tags = await DiaryService()
                                              .saveAnswerAndGetSuggestions(
                                                tokens: widget.tokens,
                                                diaryId: widget.draft.id,
                                                answer: answer,
                                              );
                                          return DiaryEmotionSelectScreen(
                                            tags: tags,
                                            draft: widget.draft,
                                            tokens: widget.tokens,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFormValid
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
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (isKeyboardLayout) SizedBox(height: keyboardScrollSpace),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
