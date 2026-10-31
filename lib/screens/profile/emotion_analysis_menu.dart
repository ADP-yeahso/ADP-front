import 'package:flutter/material.dart';

import 'emotion_analysis_screen.dart';
import 'settings_components.dart';

/// Replace [icon] and [label] with the supplied SVG assets when available.
/// The menu layout and destination can stay the same.
class EmotionAnalysisMenu extends StatelessWidget {
  const EmotionAnalysisMenu({super.key, this.icon, this.label});

  final Widget? icon;
  final Widget? label;

  @override
  Widget build(BuildContext context) => SettingsPanel(
    group: 'my_page',
    asset: 'box_manual',
    height: 51,
    children: [
      Semantics(
        button: true,
        label: '감정 분석하기',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmotionAnalysisScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                icon ??
                    const Icon(
                      Icons.donut_large,
                      size: 17,
                      color: settingsGreen,
                    ),
                const SizedBox(width: 6),
                label ??
                    const Text(
                      '감정 분석하기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
