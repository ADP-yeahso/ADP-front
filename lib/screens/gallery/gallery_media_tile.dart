import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/media.dart';

class GalleryMediaTile extends StatelessWidget {
  final Media item;
  final DateTime resolvedDate;

  const GalleryMediaTile({
    super.key,
    required this.item,
    required this.resolvedDate,
  });

  // 재생 시간 포맷
  // 예: 72초 → 1:12
  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;

    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy.M.d').format(resolvedDate);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        // 사진 타일을 누르면 큰 화면으로 표시
        onTap: () {
          if (item.fileType == 'image') {
            _showImageViewer(context);
          }
        },

        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
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
              // 썸네일 영역
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildThumbnail(item),

                      // 동영상 아이콘
                      if (item.fileType == 'video')
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                      // 음성 아이콘
                      if (item.fileType == 'audio')
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0x155C9271),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: Color(0xFF5C9271),
                              size: 26,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 날짜 및 재생 시간
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (item.fileType != 'image' &&
                        item.duration != null)
                      Text(
                        _formatDuration(item.duration!),
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

  // 사진을 전체 화면으로 보여주는 함수
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
                // 사진 영역
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: Center(
                      child: _buildFullImage(),
                    ),
                  ),
                ),

                // 닫기 버튼
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

  // 큰 화면에서 표시할 사진
  Widget _buildFullImage() {
    if (item.fileUrl.startsWith('http')) {
      return Image.network(
        item.fileUrl,
        fit: BoxFit.contain,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white,
            size: 60,
          );
        },
        loadingBuilder: (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }

          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        },
      );
    }

    // 현재 코드의 로컬 이미지 fallback
    return Image.asset(
      'assets/images/flower.png',
      fit: BoxFit.contain,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white,
          size: 60,
        );
      },
    );
  }

  // 파일 유형별 썸네일
  Widget _buildThumbnail(Media item) {
    if (item.fileType == 'image') {
      if (item.fileUrl.startsWith('http')) {
        return Image.network(
          item.fileUrl,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return const Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey,
            );
          },
          loadingBuilder: (
            context,
            child,
            loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }

            return Container(
              color: Colors.grey[100],
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          },
        );
      }

      // 더미 파일 또는 로컬 경로일 때
      return Image.asset(
        'assets/images/flower.png',
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
          );
        },
      );
    }

    if (item.fileType == 'video') {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[200]!,
              Colors.grey[400]!,
            ],
          ),
        ),
      );
    }

    // 음성 썸네일
    return Container(
      color: const Color(0xFFF3F1E9),
      child: Center(
        child: Icon(
          Icons.waves,
          color: const Color(0xFF5C9271)
              .withOpacity(0.5),
          size: 28,
        ),
      ),
    );
  }
}