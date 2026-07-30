import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/users.dart';

class FamilyManagementScreen extends StatelessWidget {
  const FamilyManagementScreen({super.key});

  void _showInviteDialog(BuildContext context) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    final code = List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();

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
              decoration: BoxDecoration(color: const Color(0xFFF3F1E9), borderRadius: BorderRadius.circular(12)),
              child: Text(
                code,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
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
      appBar: AppBar(title: const Text('가족 구성원 관리')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${appData.patientRelationLabel}을 함께 돌보는 가족 구성원이에요.',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          for (final member in appData.users) _MemberTile(member: member),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showInviteDialog(context),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('가족 초대하기'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final User member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
      ]),
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
                    Text(member.nickname, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    if (member.isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFFEFEAE0), borderRadius: BorderRadius.circular(8)),
                        child: const Text('나', style: TextStyle(fontSize: 10, color: Colors.black54)),
                      ),
                    ],
                  ],
                ),
                Text(member.relation, style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
          if (!member.isMe)
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black38),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.nickname} 관리 메뉴는 준비 중이에요 (데모)')),
                );
              },
            ),
        ],
      ),
    );
  }
}
