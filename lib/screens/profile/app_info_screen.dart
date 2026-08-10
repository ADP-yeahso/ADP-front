import 'package:flutter/material.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  static const String _appVersion = '1.0.0';

  void _showDocument(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DocumentScreen(
          title: title,
          content: content,
        ),
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: '모아온',
      applicationVersion: _appVersion,
      applicationLegalese:
          '치매 환자 보호자를 위한 감정 케어 서비스',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 정보'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          const Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFF0F5F1),
                  child: Icon(
                    Icons.local_florist_outlined,
                    size: 42,
                    color: Color(0xFF5C9271),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '모아온',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '치매 환자 보호자를 위한 감정 케어 서비스',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _InfoTile(
            icon: Icons.info_outline,
            title: '버전 정보',
            value: _appVersion,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('현재 최신 버전이에요.'),
                ),
              );
            },
          ),
          _InfoTile(
            icon: Icons.description_outlined,
            title: '이용약관',
            onTap: () {
              _showDocument(
                context,
                title: '이용약관',
                content: _termsOfService,
              );
            },
          ),
          _InfoTile(
            icon: Icons.privacy_tip_outlined,
            title: '개인정보 처리방침',
            onTap: () {
              _showDocument(
                context,
                title: '개인정보 처리방침',
                content: _privacyPolicy,
              );
            },
          ),
          _InfoTile(
            icon: Icons.code_outlined,
            title: '오픈소스 라이선스',
            onTap: () => _showLicenses(context),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 3,
        ),
        leading: Icon(
          icon,
          color: const Color(0xFF5C9271),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: value == null
            ? const Icon(
                Icons.chevron_right,
                color: Colors.black26,
              )
            : Text(
                value!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}

class _DocumentScreen extends StatelessWidget {
  final String title;
  final String content;

  const _DocumentScreen({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.7,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

const String _termsOfService = '''
모아온 이용약관

제1조 목적
본 약관은 모아온 서비스의 이용과 관련하여 서비스 제공자와 이용자 간의 권리, 의무 및 필요한 사항을 정하는 것을 목적으로 합니다.

제2조 서비스의 내용
모아온은 치매 환자 보호자가 감정과 돌봄 경험을 기록하고, 가족과 환자에 관한 기억을 보관할 수 있도록 지원하는 서비스입니다.

제3조 이용자의 의무
이용자는 다른 사람의 개인정보와 기록을 권한 없이 등록하거나 공유해서는 안 됩니다. 또한 서비스의 정상적인 운영을 방해하는 행위를 해서는 안 됩니다.

제4조 기록 및 콘텐츠
이용자가 작성하거나 등록한 일기, 사진, 영상, 음성 등의 콘텐츠에 대한 권리는 원칙적으로 이용자에게 있습니다.

제5조 서비스 변경 및 중단
서비스 개선, 점검 또는 부득이한 사정에 따라 서비스의 일부 기능이 변경되거나 일시적으로 중단될 수 있습니다.

제6조 책임의 한계
모아온이 제공하는 감정 분석과 돌봄 관련 안내는 참고용이며, 의료인의 진단이나 전문적인 치료를 대신하지 않습니다.

본 내용은 서비스 시연을 위한 임시 약관이며, 정식 출시 전에 법률 검토를 거쳐 수정될 예정입니다.
''';

const String _privacyPolicy = '''
모아온 개인정보 처리방침

1. 수집하는 개인정보
모아온은 서비스 제공을 위해 이름, 이메일 주소, 비밀번호, 전화번호, 환자 정보 및 이용자가 직접 등록한 기록을 수집할 수 있습니다.

2. 개인정보 이용 목적
수집된 개인정보는 회원 관리, 가족 그룹 운영, 기록 저장, 맞춤형 감정 케어 및 서비스 개선을 위해 사용됩니다.

3. 민감한 정보
이용자가 작성한 감정 일기와 환자 관련 기록에는 민감한 내용이 포함될 수 있습니다. 해당 정보는 서비스 제공에 필요한 범위에서만 처리되어야 합니다.

4. 가족 공유
이용자가 가족 그룹에 공개하도록 선택한 정보는 해당 가족 그룹의 구성원에게 표시될 수 있습니다.

5. 개인정보 보관 및 파기
개인정보는 서비스 이용 기간 동안 보관되며, 회원 탈퇴 또는 보관 목적이 달성되면 관련 법령에 따라 삭제됩니다.

6. 개인정보 보호
모아온은 개인정보의 분실, 유출 및 무단 접근을 방지하기 위해 적절한 보호 조치를 적용합니다.

7. 이용자의 권리
이용자는 자신의 개인정보를 확인하거나 수정할 수 있으며, 개인정보 삭제 및 회원 탈퇴를 요청할 수 있습니다.

본 내용은 서비스 시연을 위한 임시 방침이며, 정식 출시 전에 실제 데이터 처리 방식과 관련 법령에 맞추어 수정될 예정입니다.
''';