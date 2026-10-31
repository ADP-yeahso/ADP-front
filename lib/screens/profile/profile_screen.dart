import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_data.dart';
import '../auth/login_screen.dart';
import 'settings_components.dart';
import 'profile_edit_screen.dart';
import 'patient_info_screen.dart';
import 'family_management_screen.dart';
import 'help_screen.dart';
import 'app_settings_screen.dart';
import 'emotion_analysis_menu.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onBack});
  final VoidCallback? onBack;
  void open(BuildContext c, Widget w) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => w));
  Future<void> logout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    SettingsAction action(
      String icon,
      String text,
      String label,
      VoidCallback tap,
    ) => SettingsAction(
      group: 'my_page',
      icon: icon,
      text: text,
      label: label,
      onTap: tap,
    );
    return SettingsPage(
      title: settingsTitle('my_page', '마이페이지'),
      onBack: onBack,
      child: Column(
        children: [
          SettingsIdentity(
            group: 'my_page',
            box: 'box_my_info',
            name: data.me.name,
            subtitle: settingsSvg('my_page', 'text_memory_prompt', height: 14),
            onEdit: () => open(context, const ProfileEditScreen()),
          ),
          const SizedBox(height: 12),
          SettingsPanel(
            group: 'my_page',
            asset: 'box_info',
            height: 141,
            children: [
              action(
                'icon_patient',
                'text_view_patient_info',
                '환자 정보 보기',
                () => open(context, const PatientInfoScreen()),
              ),
              action(
                'icon_group',
                'text_view_group_info',
                '그룹 정보 보기',
                () => open(context, const FamilyManagementScreen()),
              ),
              action(
                'icon_bookmark',
                'text_view_bookmarks',
                '북마크 보기',
                () => settingsUnavailable(context, '북마크 기능은 준비 중이에요.'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const EmotionAnalysisMenu(),
          const SizedBox(height: 6),
          SettingsPanel(
            group: 'my_page',
            asset: 'box_manual',
            height: 51,
            children: [
              action(
                'icon_manual',
                'text_view_manual',
                '매뉴얼 보기',
                () => open(context, const HelpScreen()),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SettingsPanel(
            group: 'my_page',
            asset: 'box_account',
            height: 186,
            children: [
              action(
                'icon_contact',
                'text_contact',
                '문의하기',
                () => open(context, const HelpScreen()),
              ),
              action(
                'icon_settings',
                'text_app_settings',
                '앱 설정',
                () => open(context, const AppSettingsScreen()),
              ),
              action(
                'icon_logout',
                'text_logout',
                '로그아웃',
                () => logout(context),
              ),
              action(
                'icon_delete',
                'text_delete_account',
                '계정 삭제',
                () => settingsUnavailable(context, '계정 삭제는 현재 지원되지 않아요.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
