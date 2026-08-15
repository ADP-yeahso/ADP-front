import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../models/media.dart';

class GalleryMediaTile extends StatefulWidget {
  final Media item;
  final DateTime resolvedDate;

  const GalleryMediaTile({
    super.key,
    required this.item,
    required this.resolvedDate,
  });

  @override
  State<GalleryMediaTile> createState() => _GalleryMediaTileState();
}

class _AudioPlayerDialog extends StatefulWidget {
  final String filePath;
  final DateTime date;
  final int durationSeconds;

  const _AudioPlayerDialog({
    required this.filePath,
    required this.date,
    required this.durationSeconds,
  });

  @override
  State<_AudioPlayerDialog> createState() => _AudioPlayerDialogState();
}

class _AudioPlayerDialogState extends State<_AudioPlayerDialog> {
  late final AudioPlayer _player;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  PlayerState _playerState = PlayerState.stopped;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();
    _player.positionUpdater = TimerPositionUpdater(
      getPosition: _player.getCurrentPosition,
      interval: const Duration(milliseconds: 100),
    );
    _duration = Duration(seconds: widget.durationSeconds);

    _player.onDurationChanged.listen((duration) {
      if (!mounted) return;

      setState(() {
        _duration = duration;
      });
    });

    _player.onPositionChanged.listen((position) {
      if (!mounted) return;

      setState(() {
        _position = position;
      });
    });

    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;

      setState(() {
        _playerState = state;
      });
    });

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;

      setState(() {
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlay() async {
    if (_isLoading) return;

    try {
      if (_playerState == PlayerState.playing) {
        await _player.pause();
        return;
      }

      if (_playerState == PlayerState.paused) {
        await _player.resume();
        return;
      }

      setState(() {
        _isLoading = true;
      });

      await _player.play(
        DeviceFileSource(widget.filePath),
        position: _position,
      );
    } catch (e) {
      debugPrint('음성 재생 오류: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('음성을 재생하지 못했습니다.')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _seek(double value) async {
    if (_duration == Duration.zero) return;

    final newPosition = Duration(milliseconds: value.round());

    setState(() {
      _position = newPosition;
    });

    await _player.seek(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;

    final maxValue = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;

    final positionValue = _position.inMilliseconds
        .clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 0)
        .toDouble();

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '음성 재생',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_isLoading)
              const SizedBox(
                width: 64,
                height: 64,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              )
            else
              IconButton(
                onPressed: _togglePlay,
                iconSize: 64,
                padding: EdgeInsets.zero,
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: const Color(0xFF5C9271),
                ),
              ),

            const SizedBox(height: 18),

            Slider(
              value: positionValue,
              max: maxValue,
              onChanged: _duration == Duration.zero ? null : _seek,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              DateFormat('yyyy.M.d').format(widget.date),
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryMediaTileState extends State<GalleryMediaTile> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final min = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;

    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  void _handleTap() {
    if (widget.item.fileType == 'image') {
      _showImageViewer(context);
    } else if (widget.item.fileType == 'video') {
      _showVideoViewer(context);
    } else if (widget.item.fileType == 'audio') {
      _showAudioViewer(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final dateStr = DateFormat('yyyy.M.d').format(widget.resolvedDate);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _handleTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                  child: _buildMediaArea(),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (item.fileType == 'video')
                      Text(
                        _formatDuration(Duration(seconds: item.duration ?? 0)),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                        ),
                      ),

                    if (item.fileType == 'audio')
                      Text(
                        _formatDuration(Duration(seconds: item.duration ?? 0)),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaArea() {
    final item = widget.item;

    if (item.fileType == 'image') {
      return _buildThumbnail(item);
    }

    if (item.fileType == 'video') {
      return _buildVideoPlayer();
    }

    return _buildAudioPlayer();
  }

  Widget _buildVideoPlayer() {
    final thumbnailPath = widget.item.thumbnailPath;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbnailPath != null && File(thumbnailPath).existsSync())
          Image.file(File(thumbnailPath), fit: BoxFit.cover)
        else
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(
                Icons.videocam_outlined,
                color: Colors.grey,
                size: 36,
              ),
            ),
          ),

        Container(color: Colors.black.withValues(alpha: 0.12)),

        const Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white, size: 44),
        ),
      ],
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      color: const Color(0xFFF3F1E9),
      child: const Center(
        child: Icon(Icons.play_circle_fill, color: Color(0xFF5C9271), size: 38),
      ),
    );
  }

  void _showVideoViewer(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (dialogContext) {
        return _VideoPlayerDialog(filePath: widget.item.fileUrl);
      },
    );
  }

  void _showAudioViewer(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogContext) {
        return _AudioPlayerDialog(
          filePath: widget.item.fileUrl,
          date: widget.resolvedDate,
          durationSeconds: widget.item.duration ?? 0,
        );
      },
    );
  }

  void _showImageViewer(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: SizedBox.expand(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: Center(child: _buildFullImage()),
                  ),
                ),

                Positioned(
                  top: 40,
                  right: 16,
                  child: SafeArea(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: '닫기',
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullImage() {
    if (widget.item.fileUrl.startsWith('http')) {
      return Image.network(
        widget.item.fileUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white,
            size: 60,
          );
        },
      );
    }

    final file = File(widget.item.fileUrl);

    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.contain);
    }

    return Image.asset('assets/images/flower.png', fit: BoxFit.contain);
  }

  Widget _buildThumbnail(Media item) {
    if (item.fileUrl.startsWith('http')) {
      return Image.network(
        item.fileUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
          );
        },
      );
    }

    final file = File(item.fileUrl);

    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
          );
        },
      );
    }

    return Image.asset(
      'assets/images/flower.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
        );
      },
    );
  }
}

class _VideoPlayerDialog extends StatefulWidget {
  final String filePath;

  const _VideoPlayerDialog({required this.filePath});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  VideoPlayerController? _controller;

  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.filePath.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.filePath),
        );
      } else {
        _controller = VideoPlayerController.file(File(widget.filePath));
      }

      await _controller!.initialize();

      _controller!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

      if (!mounted) return;

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      debugPrint('동영상 초기화 오류: $e');

      if (!mounted) return;

      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_controller == null || !_initialized) return;

    if (_controller!.value.isPlaying) {
      await _controller!.pause();
    } else {
      await _controller!.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Dialog(
        backgroundColor: Colors.black,
        child: SizedBox(
          height: 420,
          child: Stack(
            children: [
              const Center(
                child: Text(
                  '동영상을 재생하지 못했습니다.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return Dialog(
        backgroundColor: Colors.black,
        child: SizedBox(
          height: 420,
          child: Stack(
            children: [
              const Center(child: CircularProgressIndicator()),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller!;
    final duration = controller.value.duration;
    final position = controller.value.position;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(controller),

              Center(
                child: IconButton(
                  onPressed: _togglePlay,
                  iconSize: 72,
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Colors.white,
                  ),
                ),
              ),

              Positioned(
                left: 12,
                right: 12,
                bottom: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
