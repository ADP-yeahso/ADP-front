import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'diary_emotion_select_screen.dart';

class DiaryEmotionExploreScreen extends StatefulWidget {
  const DiaryEmotionExploreScreen({super.key});

  @override
  State<DiaryEmotionExploreScreen> createState() =>
      _DiaryEmotionExploreScreenState();
}

class _DiaryEmotionExploreScreenState extends State<DiaryEmotionExploreScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
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

  Widget _tryPath(List<String> paths, int index, Widget fallback, double? width, double? height) {
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
        errorBuilder: (context, error, stackTrace) => _tryPath(paths, index + 1, fallback, width, height),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF7F5EE);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              // 입력창 (텍스트 입력) - 단일 테두리 적용 (이중 경계 제거)
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: '텍스트 입력',
                    hintStyle: const TextStyle(fontSize: 15, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 하단 다음 버튼 (180x52로 확대)
              Center(
                child: SizedBox(
                  width: 180,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DiaryEmotionSelectScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA5DD82),
                      foregroundColor: Colors.black87,
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
                        color: Colors.black87,
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
    );
  }
}


