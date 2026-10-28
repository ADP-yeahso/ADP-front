import 'package:flutter/material.dart';

class PendingFlowerCard extends StatelessWidget {
  const PendingFlowerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '꽃 카드 자리',
      child: Container(
        key: const ValueKey('pending-flower-card'),
        width: 240,
        height: 340,
        decoration: BoxDecoration(
          color: const Color(0xFF8BC34A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(3, 5),
            ),
          ],
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.all(20),
        child: const Text(
          '꽃 카드 준비 중',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}
