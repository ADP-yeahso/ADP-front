import 'package:flutter/material.dart';

class TreeWidget extends StatelessWidget {
  final int leafCount;
  final VoidCallback onTap;

  const TreeWidget({
    super.key,
    required this.leafCount,
    required this.onTap,
  });

  static const _leafOffsets = [
    Offset(-38, -70),
    Offset(30, -85),
    Offset(-10, -100),
    Offset(50, -55),
    Offset(-52, -40),
    Offset(10, -50),
    Offset(-25, -95),
    Offset(45, -95),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleLeaves = leafCount.clamp(0, _leafOffsets.length);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 190,
        height: 190,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 0,
              child: Image.asset(
                'assets/images/tree.png',
                width: 190,
                height: 190,
                fit: BoxFit.contain,
              ),
            ),
            // leaf badges (patient records)
            for (int i = 0; i < visibleLeaves; i++)
              Positioned(
                bottom: 95 - _leafOffsets[i].dy,
                left: 95 + _leafOffsets[i].dx - 9,
                child: const _LeafBadge(),
              ),
            if (leafCount > _leafOffsets.length)
              Positioned(
                bottom: 150,
                child: _CountBadge(count: leafCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _LeafBadge extends StatelessWidget {
  const _LeafBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFFE7C65C),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: const Icon(Icons.eco, size: 11, color: Color(0xFF8A6142)),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
      ),
      child: Text('잎 $count개', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
