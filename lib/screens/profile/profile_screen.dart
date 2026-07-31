import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import 'family_management_screen.dart';
import 'help_screen.dart';
import 'notification_settings_screen.dart';
import 'visibility_settings_screen.dart';
import 'profile_edit_screen.dart';
import 'patient_info_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그아웃 되었어요 (데모 모드)')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final me = appData.me;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5EE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: me.color.withValues(alpha: 0.2),
                  child: Icon(Icons.person, size: 28, color: me.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        me.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${appData.patientRelationLabel} 보호자',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileEditScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('프로필 편집', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _StatRow(appData: appData),
          const SizedBox(height: 20),
          const Text(
            '설정',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.medical_information_outlined,
            label: '환자 정보 보기',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PatientInfoScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: '알림 설정',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen(),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: '기록 공개 범위 관리',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VisibilitySettingsScreen(),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.family_restroom_outlined,
            label: '그룹 정보 보기',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FamilyManagementScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            label: '도움말',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.logout,
            label: '로그아웃',
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final AppData appData;
  const _StatRow({required this.appData});

  @override
  Widget build(BuildContext context) {
    final myDiaries = appData.diaries
        .where((d) => d.userId == appData.me.id)
        .length;
    final myLeaves = appData.memories
        .where((l) => l.userId == appData.me.id)
        .length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: '작성한 일기',
            value: '$myDiaries개',
            icon: Icons.local_florist_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: '나무 기록',
            value: '$myLeaves개',
            icon: Icons.park_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF5C9271)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black54),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      onTap: onTap,
    );
  }
}
