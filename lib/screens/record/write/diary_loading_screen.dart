import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiaryLoadingScreen extends StatefulWidget {
  const DiaryLoadingScreen({super.key, required this.loadNext});

  final Future<Widget> Function() loadNext;

  @override
  State<DiaryLoadingScreen> createState() => _DiaryLoadingScreenState();
}

class _DiaryLoadingScreenState extends State<DiaryLoadingScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final next = await widget.loadNext();
      if (mounted)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => next),
        );
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error.toString().replaceFirst('DiaryException: ', ''),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFBF0),
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: SvgPicture.asset(
                'assets/record/choice/svg/로딩중.svg/svg/로딩중 다람쥐5.svg',
                placeholderBuilder: (_) => const Icon(
                  Icons.local_florist,
                  size: 100,
                  color: Color(0xFF4E7B45),
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (_error == null) ...[
              const CircularProgressIndicator(color: Color(0xFF4E7B45)),
              const SizedBox(height: 22),
              const Text('AI가 감정을 정리하고 있어요...', textAlign: TextAlign.center),
            ] else ...[
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ],
        ),
      ),
    ),
  );
}
