import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// An asset scrollbar sharing the editable text's scroll position.
class AssetTextScrollbar extends StatefulWidget {
  const AssetTextScrollbar({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<AssetTextScrollbar> createState() => _AssetTextScrollbarState();
}

class _AssetTextScrollbarState extends State<AssetTextScrollbar> {
  double _extent = 0;
  double _offset = 0;

  void _updateMetrics(ScrollMetrics metrics) {
    final extent = metrics.maxScrollExtent - metrics.minScrollExtent;
    final offset = metrics.pixels - metrics.minScrollExtent;
    if (_extent == extent && _offset == offset) return;
    setState(() {
      _extent = extent;
      _offset = offset;
    });
  }

  void _jumpTo(double fraction) {
    if (!widget.controller.hasClients || _extent <= 0) return;
    final position = widget.controller.position;
    widget.controller.jumpTo(
      position.minScrollExtent + fraction.clamp(0.0, 1.0) * _extent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        if (notification.depth == 0) _updateMetrics(notification.metrics);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0) _updateMetrics(notification.metrics);
          return false;
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: widget.child),
            const SizedBox(width: 4),
            SizedBox(
              width: 24,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackHeight = math.min(150.0, constraints.maxHeight);
                  final thumbHeight = math.min(44.0, trackHeight);
                  final travel = trackHeight - thumbHeight;
                  final fraction = _extent > 0
                      ? (_offset / _extent).clamp(0.0, 1.0)
                      : 0.0;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: trackHeight,
                      width: 24,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: _extent > 0 && travel > 0
                            ? (details) => _jumpTo(
                                (details.localPosition.dy - thumbHeight / 2) /
                                    travel,
                              )
                            : null,
                        child: Stack(
                          children: [
                            Center(
                              child: SvgPicture.asset(
                                'assets/svg/screen3_1/scroll_track.svg',
                                width: 10,
                                height: trackHeight,
                                fit: BoxFit.fill,
                              ),
                            ),
                            Positioned(
                              top: fraction * travel,
                              left: 0,
                              right: 0,
                              height: thumbHeight,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onVerticalDragUpdate: _extent > 0 && travel > 0
                                    ? (details) => _jumpTo(
                                        _offset / _extent + details.delta.dy / travel,
                                      )
                                    : null,
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/svg/screen3_1/scroll_thumb.svg',
                                    width: 5,
                                    height: thumbHeight,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
