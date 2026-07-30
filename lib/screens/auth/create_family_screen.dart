import 'package:flutter/material.dart';
import '../../widgets/image_asset_button.dart';
import 'group_created_screen.dart';

class CreateFamilyScreen extends StatelessWidget {
  const CreateFamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('새 가족 그룹 만들기', style: TextStyle(color: primaryColor, fontSize: 16)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.person_outline, color: primaryColor, size: 40),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '새 가족 그룹 만들기',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '그룹에서 케어할 환자의 정보를\n정확히 입력해 주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: primaryColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 40),
            _LabelInputRow(label: '환자 이름', primaryColor: primaryColor),
            const SizedBox(height: 16),
            _LabelInputRow(label: '생년월일', primaryColor: primaryColor),
            const SizedBox(height: 16),
            _LabelInputRow(label: '환자 관계', primaryColor: primaryColor),
            const SizedBox(height: 40),
            ImageAssetButton(
              // imagePath: 'assets/images/btn_create_family.png',
              fallbackText: '만들기',
              fallbackColor: primaryColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroupCreatedScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelInputRow extends StatelessWidget {
  final String label;
  final Color primaryColor;

  const _LabelInputRow({
    required this.label,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
