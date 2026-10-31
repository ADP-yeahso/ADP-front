import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GardenHomeHeader extends StatelessWidget {
  const GardenHomeHeader({
    super.key,
    required this.month,
    required this.groupName,
    required this.hasUnreadRecords,
    required this.onOpenMailbox,
    required this.onOpenNotebook,
    this.showTitleAndActions = true,
  });

  final DateTime month;
  final String groupName;
  final bool hasUnreadRecords;
  final VoidCallback onOpenMailbox;
  final VoidCallback onOpenNotebook;
  final bool showTitleAndActions;

  static const _assetBase = 'assets/garden/home';
  static const _green = Color(0xFF386622);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 64),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _gardenAction(
                  SvgPicture.asset(
                    '$_assetBase/title.svg',
                    width: 150,
                    height: 76,
                    semanticsLabel: '기억의 정원, 우리의 소중한 시간',
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 124,
                  height: 33,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        '$_assetBase/date_frame.svg',
                        width: 124,
                        height: 33,
                        excludeFromSemantics: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${month.month.toString().padLeft(2, '0')} . ${month.year.toString().substring(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _green,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        groupName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      '$_assetBase/dropdown.svg',
                      width: 17,
                      height: 10,
                      excludeFromSemantics: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _gardenAction(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 76),
                IconButton(
                  tooltip: '돌봄수첩',
                  onPressed: onOpenNotebook,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints.tightFor(
                    width: 64,
                    height: 64,
                  ),
                  icon: SvgPicture.asset(
                    '$_assetBase/care_notebook.svg',
                    width: 42,
                    height: 49,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(height: 16),
                IconButton(
                  tooltip: hasUnreadRecords
                      ? '편지함 · 읽지 않은 편지 또는 새 공유 기록'
                      : '편지함',
                  onPressed: onOpenMailbox,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints.tightFor(
                    width: 64,
                    height: 64,
                  ),
                  icon: SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.asset(
                          '$_assetBase/mailbox.svg',
                          width: 55,
                          height: 50,
                          excludeFromSemantics: true,
                        ),
                        if (hasUnreadRecords)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: SvgPicture.asset(
                              '$_assetBase/unread_badge.svg',
                              width: 20,
                              height: 20,
                              excludeFromSemantics: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gardenAction(Widget child) => IgnorePointer(
    ignoring: !showTitleAndActions,
    child: AnimatedOpacity(
      opacity: showTitleAndActions ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: child,
    ),
  );
}
