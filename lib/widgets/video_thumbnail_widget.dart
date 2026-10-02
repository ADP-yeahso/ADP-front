import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showPlayIcon;
  final BoxFit fit;

  const VideoThumbnailWidget({
    super.key,
    required this.videoPath,
    this.width,
    this.height,
    this.borderRadius,
    this.showPlayIcon = true,
    this.fit = BoxFit.cover,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _disposeController();
      _initVideo();
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _hasError = false;
  }

  Future<void> _initVideo() async {
    try {
      final file = File(widget.videoPath);
      if (widget.videoPath.startsWith('http://') || widget.videoPath.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else if (file.existsSync()) {
        _controller = VideoPlayerController.file(file);
      } else {
        if (mounted) setState(() => _hasError = true);
        return;
      }

      await _controller!.initialize();
      await _controller!.seekTo(Duration.zero);
      await _controller!.pause();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.videoPath.split(Platform.pathSeparator).last;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(12);

    Widget inner;
    if (_isInitialized && _controller != null) {
      // 안드로이드/스마트폰 영상의 세로 회전(rotationCorrection 90/270도)을 반영하여 정확한 표시 크기 계산
      final isRotated = _controller!.value.rotationCorrection == 90 ||
          _controller!.value.rotationCorrection == 270;
      final rawWidth = _controller!.value.size.width > 0 ? _controller!.value.size.width : 160.0;
      final rawHeight = _controller!.value.size.height > 0 ? _controller!.value.size.height : 90.0;
      final videoWidth = isRotated ? rawHeight : rawWidth;
      final videoHeight = isRotated ? rawWidth : rawHeight;

      inner = Stack(
        fit: StackFit.expand,
        children: [
          // 회전 보정된 정확한 종횡비로 타일에 꽉 차게 썸네일 렌더링 (과도한 줌 및 좌우 검은 여백 제거)
          FittedBox(
            fit: widget.fit,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: videoWidth,
              height: videoHeight,
              child: VideoPlayer(_controller!),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.12),
          ),
          if (widget.showPlayIcon)
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 28,
              ),
            ),
        ],
      );
    } else {
      inner = Container(
        color: const Color(0xFF2C3E50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_hasError)
              const Icon(Icons.videocam_off, color: Colors.white70, size: 24)
            else
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: inner,
      ),
    );
  }
}
