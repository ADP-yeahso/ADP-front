import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/users.dart';

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
            const Text('아래 초대 코드를 가족에게 공유해 주세요. 코드는 24시간 동안 유효해요.'),
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
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('초대 코드가 복사되었어요 (데모)')),
              );
            },
            child: const Text('코드 복사'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();

    return Scaffold(
      appBar: AppBar(title: const Text('그룹 정보 보기')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${appData.group.groupName}의 구성원과 초대 코드를 확인할 수 있어요.',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '그룹 기본 정보',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                _GroupInfoRow(label: '그룹 이름', value: appData.group.groupName),
                const SizedBox(height: 10),
                _GroupInfoRow(
                  label: '환자 이름',
                  value: appData.patient.patientName,
                ),
                const SizedBox(height: 10),
                _GroupInfoRow(
                  label: '구성원 수',
                  value: '${appData.users.length}명',
                ),
                const SizedBox(height: 10),
                _GroupInfoRow(label: '초대 코드', value: appData.group.inviteCode),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '가족 구성원',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final member in appData.users)
            _MemberTile(
              member: member,
              isMe: appData.isCurrentUser(member.id),
              relation: appData.userRelationOf(member.id),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                _showInviteDialog(context, appData.group.inviteCode),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('가족 초대하기'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
class _GroupInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _GroupInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final User member;
  final bool isMe;
  final String relation;

  const _MemberTile({
    required this.member,
    required this.isMe,
    required this.relation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: member.color.withValues(alpha: 0.18),
            child: Icon(Icons.person, color: member.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEAE0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '나',
                          style: TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  relation,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          if (!isMe)
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black38),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.name} 관리 메뉴는 준비 중이에요 (데모)')),
                );
              },
            ),
        ],
      ),
    );
  }
}
