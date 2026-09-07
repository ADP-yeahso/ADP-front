import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'diary_emotion_explore_screen.dart';

class DiarySituationScreen extends StatefulWidget {
  const DiarySituationScreen({super.key});

  @override
  State<DiarySituationScreen> createState() => _DiarySituationScreenState();
}

class _DiarySituationScreenState extends State<DiarySituationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
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
                      'assets/record/choice/svg/3-2-1.svg/svg/3-2-1 다람쥐2.svg',
                      'assets/record/choice/png/3-2-1.png/png/3-2-1 다람쥐2.png',
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

              // 헤드라인 ("오늘은 무슨 일이 있으셨나요?")
              Center(
                child: _buildAssetWidget(
                  candidatePaths: const [
                    'assets/record/choice/svg/3-2-1.svg/svg/3-2-1 메인 헤드라인.svg',
                    'assets/record/choice/png/3-2-1.png/png/3-2-1 메인 헤드라인.png',
                  ],
                  fallback: const Text(
                    '오늘은 무슨 일이 있으셨나요?',
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

              // 제목 입력창 (선택) - 단일 테두리 적용 (이중 경계 제거)
              TextField(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: '제목 입력창 (선택)',
                  hintStyle: const TextStyle(fontSize: 15, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              const SizedBox(height: 12),

              // 본문 텍스트 입력창 - 단일 테두리 적용 (이중 경계 제거)
              Expanded(
                child: TextField(
                  controller: _contentController,
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
              const SizedBox(height: 14),

              // 미디어 첨부 버튼 바 (사진 첨부 | 영상 첨부 | 음성 첨부)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: const [
                          Icon(Icons.crop_original, size: 20, color: Colors.black54),
                          SizedBox(width: 6),
                          Text('사진 첨부', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Container(height: 18, width: 1, color: Colors.grey.shade300),
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: const [
                          Icon(Icons.add_to_queue_outlined, size: 20, color: Colors.black54),
                          SizedBox(width: 6),
                          Text('영상 첨부', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Container(height: 18, width: 1, color: Colors.grey.shade300),
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: const [
                          Icon(Icons.mic_none, size: 20, color: Colors.black54),
                          SizedBox(width: 6),
                          Text('음성 첨부', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
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
                        MaterialPageRoute(builder: (context) => const DiaryEmotionExploreScreen()),
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


