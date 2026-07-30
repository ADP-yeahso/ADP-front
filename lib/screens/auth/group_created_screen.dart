import 'package:flutter/material.dart';
import '../../widgets/image_asset_button.dart';
import '../../widgets/image_asset_placeholder.dart';
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
              // 일러스트 플레이스홀더 (에셋이 오면 imagePath 속성 추가)
              Center(
                child: ImageAssetPlaceholder(
                  // imagePath: 'assets/images/illust_group_created.png',
                  width: 120,
                  height: 120,
                  isCircle: true,
                  fallbackText: '완료\n일러스트',
                  fallbackColor: primaryColor,
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
              ImageAssetButton(
                // imagePath: 'assets/images/btn_enter_garden.png',
                fallbackText: '정원 들어가기',
                fallbackColor: primaryColor,
                onPressed: () {
                  // 메인 정원 화면으로 이동하며 모든 이전 스택을 제거
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const RootShell()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 16),
              ImageAssetButton(
                // imagePath: 'assets/images/btn_invite.png',
                fallbackText: '구성원 초대하기',
                fallbackColor: primaryColor,
                onPressed: () {
                  // 임시 초대 코드 복사 알림
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('초대 코드가 복사되었습니다.')),
                  );
                },
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
