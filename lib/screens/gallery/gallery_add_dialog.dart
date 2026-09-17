import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/media.dart';

class GalleryAddDialog extends StatelessWidget {
  final VoidCallback? onPickImages;
  final VoidCallback? onPickVideo;
  final VoidCallback? onPickAudio;
  final Function(Media, String)? onMediaAdded;

  const GalleryAddDialog({
    super.key,
    this.onPickImages,
    this.onPickVideo,
    this.onPickAudio,
    this.onMediaAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFCFBF7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: SvgPicture.asset(
                      'assets/gallery/screen4/4-1_x.svg',
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                onPickImages?.call();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/gallery/screen4/4-1_photo_add.svg',
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      '사진 추가',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF182F0D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                width: double.infinity,
                height: 6,
                child: SvgPicture.asset(
                  'assets/gallery/screen4/4-1_line1.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                onPickVideo?.call();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/gallery/screen4/4-1_video_add.svg',
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      '동영상 추가',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF182F0D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                width: double.infinity,
                height: 6,
                child: SvgPicture.asset(
                  'assets/gallery/screen4/4-1_line2.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                onPickAudio?.call();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/gallery/screen4/4-1_audio_add.svg',
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      '음성 추가',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF182F0D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
