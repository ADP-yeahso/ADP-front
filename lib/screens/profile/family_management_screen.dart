import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import 'settings_components.dart';

class FamilyManagementScreen extends StatelessWidget {
  const FamilyManagementScreen({super.key});

  void _showInviteDialog(BuildContext context, String inviteCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('가족 초대하기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('아래 초대 코드를 가족에게 공유해 주세요.'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F1E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                inviteCode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: inviteCode));
              if (!ctx.mounted || !context.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('초대 코드가 복사되었어요')));
            },
            child: const Text('코드 복사'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    return SettingsPage(
      title: settingsSvg('group_info', 'text_group_info', height: 55),
      child: Column(
        children: [
          SettingsIdentity(
            group: 'group_info',
            box: 'box_group_info',
            name: data.group.groupName,
            subtitle: Text(
              '그룹 코드  ${data.group.inviteCode}',
              style: const TextStyle(fontSize: 12, color: settingsGreen),
            ),
            onEdit: () async {
              final name = await settingsEditText(
                context,
                '그룹 이름 수정',
                data.group.groupName,
              );
              if (name != null && context.mounted) data.updateGroupName(name);
            },
          ),
          const SizedBox(height: 12),
          SettingsPanel(
            group: 'group_info',
            asset: 'box_member',
            height: data.users.length > 5 ? data.users.length * 45 + 6 : 231,
            children: [
              for (final user in data.users)
                Row(
                  children: [
                    const SizedBox(width: 14),
                    settingsSvg(
                      'group_info',
                      'icon_person',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              for (var i = data.users.length; i < 5; i++)
                const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 6),
          SettingsPanel(
            group: 'group_info',
            asset: 'box_leave_group',
            height: 96,
            children: [
              SettingsAction(
                group: 'group_info',
                icon: 'icon_add',
                text: 'text_invite',
                label: '초대하기',
                onTap: () => _showInviteDialog(context, data.group.inviteCode),
              ),
              SettingsAction(
                group: 'group_info',
                icon: 'icon_leave_group',
                text: 'text_leave_group',
                label: '그룹 탈퇴',
                onTap: () =>
                    settingsUnavailable(context, '그룹 탈퇴는 현재 지원되지 않아요.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
