import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'write/diary_start_screen.dart';
import 'patient_info_screen.dart';

class RecordChoiceSheet extends StatelessWidget {
  final String? patientRecordAsset;
  final String? mindRecordAsset;

  const RecordChoiceSheet({
    super.key,
    this.patientRecordAsset,
    this.mindRecordAsset,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height;

    return Container(
      // 시안(Photo 2) 비율에 알맞게 바텀 시트 높이를 컴팩트하게 조정 (약 56%)
      height: height * 0.56,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F5EE), // 따뜻한 크림 베이지 배경
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상단 드래그 핸들 & 닫기 버튼 (시안 우측 상단 X 아이콘 위치)
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: _AssetOrIcon(
                    candidatePaths: const [
                      'assets/record/choice/svg/3-0svg/svg/3-0 닫힘 버튼.svg',
                      'assets/record/choice/png/3-0png/png/3-0 닫힘 버튼.png',
                    ],
                    fallbackIcon: Icons.close,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 메인 타이틀 ("기록을 남겨볼까요?")
          Center(
            child: _AssetOrText(
              candidatePaths: const [
                'assets/record/choice/svg/3-0svg/svg/3-0 메인 헤드라인.svg',
                'assets/record/choice/png/3-0png/png/3-0 메인 헤드라인.png',
              ],
              fallbackText: '기록을 남겨볼까요?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // 1. 환자 기록하기 버튼 (시안 그린 그린 박스 + 오른쪽 연두색 > 화살표)
          _ChoiceCard(
            assetPath: patientRecordAsset,
            candidatePaths: const [
              'assets/record/choice/svg/3-0svg/svg/3-0 환자기록 박스.svg',
              'assets/record/choice/png/3-0png/png/3-0 환자기록 박스.png',
            ],
            icon: Icons.park,
            badgeBgColor: const Color(0xFFE2EFE0),
            iconColor: const Color(0xFF35612F),
            title: '환자 기록하기',
            subtitle: '오늘 있었던 일, 사진을 나무의 잎으로 남겨요',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PatientInfoScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          // 2. 마음 기록하기 버튼
          _ChoiceCard(
            assetPath: mindRecordAsset,
            candidatePaths: const [
              'assets/record/choice/svg/3-0svg/svg/3-0 마음기록 박스.svg',
              'assets/record/choice/png/3-0png/png/3-0 마음기록 박스.png',
            ],
            icon: Icons.local_florist,
            badgeBgColor: const Color(0xFFFFF3D6),
            iconColor: const Color(0xFFE09D1F),
            title: '마음 기록하기',
            subtitle: '나의 돌봄 경험과 감정을 꽃으로 남겨요',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiaryStartScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String? assetPath;
  final List<String> candidatePaths;
  final IconData icon;
  final Color badgeBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    this.assetPath,
    this.candidatePaths = const [],
    required this.icon,
    required this.badgeBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pathsToTry = assetPath != null ? [assetPath!] : candidatePaths;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: _buildAssetOrFallback(pathsToTry, 0),
      ),
    );
  }

  Widget _buildAssetOrFallback(List<String> paths, int index) {
    if (index >= paths.length) {
      return _buildDefaultCard();
    }

    final path = paths[index];
    final isSvg = path.toLowerCase().endsWith('.svg');

    if (isSvg) {
      return SvgPicture.asset(
        path,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _buildDefaultCard(),
      );
    } else {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildAssetOrFallback(paths, index + 1),
      );
    }
  }

  Widget _buildDefaultCard() {
    return Ink(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF4C7B43), // 시안과 동일한 차분한 딥 그린
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C7B43).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 왼쪽 원형 아이콘 뱃지
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: badgeBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          // 중앙 텍스트 (타이틀 + 서브타이틀)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 오른쪽 화살표 아이콘 (시안 2의 연두/노란 빛 화살표)
          const Icon(
            Icons.chevron_right,
            color: Color(0xFFD4E7A2), // 밝은 라임 그린 화살표
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _AssetOrIcon extends StatelessWidget {
  final List<String> candidatePaths;
  final IconData fallbackIcon;

  const _AssetOrIcon({
    required this.candidatePaths,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return _buildStep(0);
  }

  Widget _buildStep(int index) {
    if (index >= candidatePaths.length) {
      return Icon(fallbackIcon, color: const Color(0xFF5A7A53), size: 24);
    }
    final path = candidatePaths[index];
    final isSvg = path.toLowerCase().endsWith('.svg');

    if (isSvg) {
      return SvgPicture.asset(
        path,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Icon(fallbackIcon, color: const Color(0xFF5A7A53), size: 24),
      );
    } else {
      return Image.asset(
        path,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildStep(index + 1),
      );
    }
  }
}

class _AssetOrText extends StatelessWidget {
  final List<String> candidatePaths;
  final String fallbackText;
  final TextStyle style;

  const _AssetOrText({
    required this.candidatePaths,
    required this.fallbackText,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return _buildStep(0);
  }

  Widget _buildStep(int index) {
    if (index >= candidatePaths.length) {
      return Text(
        fallbackText,
        style: style,
        textAlign: TextAlign.center,
      );
    }
    final path = candidatePaths[index];
    final isSvg = path.toLowerCase().endsWith('.svg');

    if (isSvg) {
      return SvgPicture.asset(
        path,
        height: 28,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Text(fallbackText, style: style, textAlign: TextAlign.center),
      );
    } else {
      return Image.asset(
        path,
        height: 28,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildStep(index + 1),
      );
    }
  }
}



