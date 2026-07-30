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

  // 재생 시간 포맷팅 함수 (예: 72초 -> 1:12)
  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy.M.d').format(resolvedDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 썸네일/플레이스홀더 영역
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
                  
                  // 비디오 아이콘 표시
                  if (item.fileType == 'video')
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                      ),
                    ),
                    
                  // 오디오 아이콘 표시
                  if (item.fileType == 'audio')
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0x155C9271),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic, color: Color(0xFF5C9271), size: 26),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // 하단 메타데이터 영역 (날짜 및 재생시간)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                  style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                if (item.fileType != 'image' && item.duration != null)
                  Text(
                    _formatDuration(item.duration!),
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 파일 타입별 썸네일 빌더
  Widget _buildThumbnail(Media item) {
    if (item.fileType == 'image') {
      if (item.fileUrl.startsWith('http')) {
        return Image.network(
          item.fileUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.image_not_supported_outlined, color: Colors.grey);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[100],
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        );
      } else {
        // 더미 파일이거나 로컬 경로일 경우 fallback
        return Image.asset(
          'assets/images/flower.png',
          fit: BoxFit.cover,
        );
      }
    } else if (item.fileType == 'video') {
      // 비디오 썸네일용 가상 그라디언트 및 아이콘 배경
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[200]!, Colors.grey[400]!],
          ),
        ),
      );
    } else {
      // 오디오 썸네일용 음파/마이크 배경
      return Container(
        color: const Color(0xFFF3F1E9),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.waves, color: const Color(0xFF5C9271).withValues(alpha: 0.5), size: 20),
          ],
        ),
      );
    }
  }
}
