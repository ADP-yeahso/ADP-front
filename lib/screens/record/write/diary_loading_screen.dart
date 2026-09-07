import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'diary_result_screen.dart';

class DiaryLoadingScreen extends StatefulWidget {
  const DiaryLoadingScreen({super.key});

  @override
  State<DiaryLoadingScreen> createState() => _DiaryLoadingScreenState();
}

class _DiaryLoadingScreenState extends State<DiaryLoadingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DiaryResultScreen(),
          ),
        );
      }
    });
  }

  Widget _buildAssetWidget({
    required List<String> candidatePaths,
    required Widget fallback,
  }) {
    return _tryPath(candidatePaths, 0, fallback);
  }

  Widget _tryPath(List<String> paths, int index, Widget fallback) {
    if (index >= paths.length) return fallback;
    final path = paths[index];
    final isSvg = path.toLowerCase().endsWith('.svg');
    if (isSvg) {
      return SvgPicture.asset(
        path,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => fallback,
      );
    } else {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _tryPath(paths, index + 1, fallback),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로딩중 다람쥐5 에셋
              SizedBox(
                width: 180,
                height: 180,
                child: _buildAssetWidget(
                  candidatePaths: const [
                    'assets/record/choice/svg/로딩중.svg/svg/로딩중 다람쥐5.svg',
                    'assets/record/choice/png/로딩중.png/png/로딩중 다람쥐5.png',
                  ],
                  fallback: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green.shade200, width: 2),
                    ),
                    child: const Icon(Icons.local_florist, size: 80, color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E7B45)),
              ),
              const SizedBox(height: 28),
              // 로딩중 메인 헤드라인 ("AI가 감정을 추출하고 있어요...")
              _buildAssetWidget(
                candidatePaths: const [
                  'assets/record/choice/svg/로딩중.svg/svg/로딩중 메인 헤드라인.svg',
                  'assets/record/choice/png/로딩중.png/png/로딩중 메인 헤드라인.png',
                ],
                fallback: const Text(
                  'AI가 감정을\n추출하고 있어요...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
