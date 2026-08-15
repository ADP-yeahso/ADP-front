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

class _GalleryMediaTileState extends State<GalleryMediaTile> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;

  bool _videoInitialized = false;
  bool _audioInitialized = false;

  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    if (widget.item.fileType == 'video') {
      _initializeVideo();
    }

    // audio는 여기서 초기화하지 않음.
    // 사용자가 재생 버튼을 눌렀을 때만 초기화.
  }

  Future<void> _initializeVideo() async {
    try {
      final fileUrl = widget.item.fileUrl;

      if (fileUrl.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(fileUrl));
      } else {
        _videoController = VideoPlayerController.file(File(fileUrl));
      }

      await _videoController!.initialize();

      if (!mounted) return;

      setState(() {
        _videoInitialized = true;
      });

      _videoController!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      debugPrint('영상 초기화 오류: $e');
    }
  }

  Future<void> _initializeAudio() async {
    try {
      debugPrint('===== 음성 초기화 시작 =====');
      debugPrint('파일 경로: ${widget.item.fileUrl}');

      final file = File(widget.item.fileUrl);

      debugPrint('파일 존재 여부: ${file.existsSync()}');
      debugPrint('파일 크기: ${file.existsSync() ? file.lengthSync() : -1}');

      if (!file.existsSync()) {
        debugPrint('음성 파일이 존재하지 않음');
        return;
      }

      _audioPlayer ??= AudioPlayer();

      // 재생 위치
      _audioPlayer!.onPositionChanged.listen((position) {
        if (!mounted) return;

        setState(() {
          _audioPosition = position;
        });
      });

      // 전체 길이
      _audioPlayer!.onDurationChanged.listen((duration) {
        if (!mounted) return;

        setState(() {
          _audioDuration = duration;
        });
      });

      // 재생 완료
      _audioPlayer!.onPlayerComplete.listen((_) {
        if (!mounted) return;

        setState(() {
          _audioPosition = Duration.zero;
        });
      });

      // 파일을 실제로 재생하기 전에 source 설정
      await _audioPlayer!.setSource(DeviceFileSource(widget.item.fileUrl));

      final duration = await _audioPlayer!.getDuration();

      if (!mounted) return;

      setState(() {
        _audioInitialized = true;
        _audioDuration = duration ?? Duration.zero;
      });

      debugPrint('===== 음성 초기화 성공 =====');
      debugPrint('duration: $_audioDuration');
    } catch (e, stackTrace) {
      debugPrint('===== 음성 초기화 오류 =====');
      debugPrint('오류: $e');
      debugPrint('스택: $stackTrace');

      _audioInitialized = false;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final min = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;

    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleVideo() async {
    if (_videoController == null || !_videoInitialized) return;

    if (_videoController!.value.isPlaying) {
      await _videoController!.pause();
    } else {
      await _videoController!.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleAudio() async {
    debugPrint('===== 음성 재생 버튼 클릭 =====');
    debugPrint('파일 경로: ${widget.item.fileUrl}');

    try {
      if (_audioPlayer == null || !_audioInitialized) {
        debugPrint('플레이어 미초기화 → 초기화 시작');

        await _initializeAudio();

        if (_audioPlayer == null || !_audioInitialized) {
          debugPrint('음성 초기화 실패 → 재생 중단');
          return;
        }
      }

      final state = _audioPlayer!.state;

      if (state == PlayerState.playing) {
        await _audioPlayer!.pause();
      } else {
        if (_audioDuration != Duration.zero &&
            _audioPosition >= _audioDuration) {
          await _audioPlayer!.seek(Duration.zero);
        }

        await _audioPlayer!.resume();
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      debugPrint('===== 음성 재생 오류 =====');
      debugPrint('오류: $e');
      debugPrint('스택: $stackTrace');
    }
  }

  void _handleTap() {
    if (widget.item.fileType == 'image') {
      _showImageViewer(context);
    } else if (widget.item.fileType == 'video') {
      _toggleVideo();
    } else if (widget.item.fileType == 'audio') {
      _toggleAudio();
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

                    if (item.fileType == 'video' && _videoInitialized)
                      Text(
                        _formatDuration(_videoController!.value.duration),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                        ),
                      ),

                    if (item.fileType == 'audio')
                      Text(
                        _formatDuration(_audioDuration),
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
    if (!_videoInitialized || _videoController == null) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final controller = _videoController!;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),

        Center(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _toggleVideo,
              icon: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPlayer() {
    final isPlaying = _audioPlayer?.state == PlayerState.playing;

    final maxMilliseconds = _audioDuration.inMilliseconds > 0
        ? _audioDuration.inMilliseconds.toDouble()
        : 1.0;

    final positionMilliseconds = _audioPosition.inMilliseconds
        .clamp(
          0,
          _audioDuration.inMilliseconds > 0 ? _audioDuration.inMilliseconds : 0,
        )
        .toDouble();

    return Container(
      color: const Color(0xFFF3F1E9),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            onPressed: _audioInitialized ? _toggleAudio : null,
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: const Color(0xFF5C9271),
              size: 32,
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(
                value: positionMilliseconds,
                max: maxMilliseconds,
                onChanged: !_audioInitialized
                    ? null
                    : (value) {
                        _audioPlayer?.seek(
                          Duration(milliseconds: value.round()),
                        );
                      },
              ),
            ),
          ),

          const SizedBox(width: 4),

          Text(
            _formatDuration(_audioDuration),
            style: const TextStyle(fontSize: 9, color: Colors.black54),
          ),
        ],
      ),
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
