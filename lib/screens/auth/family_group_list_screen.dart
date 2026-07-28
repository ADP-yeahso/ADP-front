import 'package:flutter/material.dart';
import 'create_family_screen.dart';
import 'group_created_screen.dart';

class FamilyGroupListScreen extends StatelessWidget {
  const FamilyGroupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
        title: Text('가족 그룹', style: TextStyle(color: primaryColor, fontSize: 16)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.family_restroom, color: primaryColor, size: 40),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '가족 그룹',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '그룹을 선택하거나\n새로 만들 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: primaryColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              '현재 참여 중인 그룹',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            _GroupCard(
              groupName: '그룹 이름',
              memberCount: 3,
              primaryColor: primaryColor,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatedScreen()));
              },
            ),
            const SizedBox(height: 12),
            _GroupCard(
              groupName: '그룹 이름',
              memberCount: 4,
              primaryColor: primaryColor,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatedScreen()));
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: primaryColor.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '또는',
                    style: TextStyle(color: primaryColor.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: primaryColor.withValues(alpha: 0.3))),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateFamilyScreen()));
              },
              icon: Icon(Icons.add_circle_outline, color: primaryColor),
              label: Text('새 가족 그룹 만들기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: primaryColor, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '가족 그룹 참여하기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: '그룹 코드 입력',
                            hintStyle: const TextStyle(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: primaryColor, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: 코드 검증 후 그룹 참여
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatedScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String groupName;
  final int memberCount;
  final Color primaryColor;
  final VoidCallback onTap;

  const _GroupCard({
    required this.groupName,
    required this.memberCount,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: 1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Text(
                  '구성원 $memberCount명',
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              side: BorderSide(color: primaryColor, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Text('입장하기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
          ),
        ],
      ),
    );
  }
}
