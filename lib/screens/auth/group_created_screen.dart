import 'package:flutter/material.dart';
import '../root_shell.dart';

class GroupCreatedScreen extends StatelessWidget {
  const GroupCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              // 일러스트 플레이스홀더
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.spa_outlined,
                    size: 60,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '그룹 생성 완료',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  // 메인 정원 화면으로 이동하며 모든 이전 스택을 제거
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const RootShell()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: primaryColor, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('정원 들어가기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // 임시 초대 코드 복사 알림
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('초대 코드가 복사되었습니다.')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: primaryColor, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('구성원 초대하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '초대 코드 복사',
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryColor.withValues(alpha: 0.7),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
