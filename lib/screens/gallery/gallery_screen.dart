import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../data/app_data.dart';
import '../../models/media.dart';
import 'gallery_filter_panel.dart';
import 'gallery_media_tile.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ScrollController _galleryScrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // 선택된 기록 구분
  final Set<String> _selectedRecordTypes = {'patient', 'emotion', 'custom'};

  // 선택된 파일 유형
  final List<String> _selectedFileTypes = ['image', 'video', 'audio'];

  // latest: 최신순, oldest: 오래된순
  String _sortBy = 'latest';

  bool _isFilterExpanded = false;

  // 사용자가 갤러리에서 직접 추가한 미디어
  final List<Media> _customMediaList = [];

  // 검색 조건 초기화
  void _resetFilters() {
    setState(() {
      _selectedRecordTypes
        ..clear()
        ..addAll({'patient', 'emotion', 'custom'});

      _selectedFileTypes
        ..clear()
        ..addAll(['image', 'video', 'audio']);

      _sortBy = 'latest';
    });
  }

  // 선택된 미디어 공통 저장 및 처리
  void _saveSelectedMedia(List<Media> selectedMedia, String mediaTypeText) {
    if (!mounted || selectedMedia.isEmpty) return;
    try {
      context.read<AppData>().addMemory(
        date: DateTime.now(),
        title: '갤러리 직접 추가',
        content: '',
        mediaList: selectedMedia,
        isPublic: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$mediaTypeText 파일이 추가되었습니다.'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('파일 추가 중 오류가 발생했습니다.')));
    }
  }

  // 사진 다중 선택
  Future<void> _pickImages() async {
    final List<Media> selectedMedia = [];
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (final image in images) {
          selectedMedia.add(
            Media(
              id: DateTime.now().microsecondsSinceEpoch,
              memoryId: null,
              diaryId: null,
              fileUrl: image.path,
              fileType: 'image',
              duration: 0,
              sortOrder: selectedMedia.length + 1,
              createdAt: DateTime.now(),
            ),
          );
        }
      }
    } catch (_) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.path != null) {
            selectedMedia.add(
              Media(
                id: DateTime.now().microsecondsSinceEpoch,
                memoryId: null,
                diaryId: null,
                fileUrl: file.path!,
                fileType: 'image',
                duration: 0,
                sortOrder: selectedMedia.length + 1,
                createdAt: DateTime.now(),
              ),
            );
          }
        }
      }
    }
    _saveSelectedMedia(selectedMedia, '사진');
  }

  Future<int> _getVideoDuration(String filePath) async {
    VideoPlayerController? controller;

    try {
      if (filePath.startsWith('http')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(filePath));
      } else {
        controller = VideoPlayerController.file(File(filePath));
      }

      await controller.initialize();

      final duration = controller.value.duration;

      debugPrint('동영상 길이 확인 성공: ${duration.inSeconds}초');

      return duration.inSeconds;
    } catch (e) {
      debugPrint('동영상 길이 확인 실패: $e');
      return 0;
    } finally {
      await controller?.dispose();
    }
  }

  Future<String?> _generateVideoThumbnail(String videoPath) async {
    try {
      final tempDirectory = Directory.systemTemp;

      final thumbnailPath =
          '${tempDirectory.path}/video_thumb_${DateTime.now().microsecondsSinceEpoch}.jpg';

      final plugin = FcNativeVideoThumbnail();

      final generated = await plugin.saveThumbnailToFile(
        srcFile: videoPath,
        destFile: thumbnailPath,
        width: 400,
        height: 400,
        quality: 85,
      );

      if (!generated) {
        debugPrint('동영상 썸네일 생성 실패');
        return null;
      }

      debugPrint('동영상 썸네일 생성 성공: $thumbnailPath');

      return thumbnailPath;
    } catch (e) {
      debugPrint('동영상 썸네일 오류: $e');
      return null;
    }
  }

  // 동영상 선택
  Future<void> _pickVideo() async {
    final List<Media> selectedMedia = [];
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final durationSeconds = await _getVideoDuration(video.path);
        final thumbnailPath = await _generateVideoThumbnail(video.path);

        selectedMedia.add(
          Media(
            id: DateTime.now().microsecondsSinceEpoch,
            memoryId: null,
            diaryId: null,
            fileUrl: video.path,
            fileType: 'video',
            duration: durationSeconds,
            thumbnailPath: thumbnailPath,
            sortOrder: 1,
            createdAt: DateTime.now(),
          ),
        );
      }
    } catch (_) {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null) {
        final videoPath = result.files.single.path!;

        final durationSeconds = await _getVideoDuration(videoPath);
        final thumbnailPath = await _generateVideoThumbnail(videoPath);

        selectedMedia.add(
          Media(
            id: DateTime.now().microsecondsSinceEpoch,
            memoryId: null,
            diaryId: null,
            fileUrl: videoPath,
            fileType: 'video',
            duration: durationSeconds,
            thumbnailPath: thumbnailPath,
            sortOrder: 1,
            createdAt: DateTime.now(),
          ),
        );
      }
    }
    _saveSelectedMedia(selectedMedia, '동영상');
  }

  Future<int> _getAudioDuration(String filePath) async {
    final player = AudioPlayer();

    try {
      await player.setVolume(0);

      final durationFuture = player.onDurationChanged
          .firstWhere((duration) => duration > Duration.zero)
          .timeout(const Duration(seconds: 8));

      await player.play(DeviceFileSource(filePath));

      final duration = await durationFuture;

      await player.stop();

      debugPrint('음성 길이 확인 성공: ${duration.inSeconds}초');

      return duration.inSeconds;
    } catch (e) {
      debugPrint('음성 길이 확인 실패: $e');
      return 0;
    } finally {
      await player.dispose();
    }
  }

  // 음성 선택
  Future<void> _pickAudio() async {
    final List<Media> selectedMedia = [];

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.path != null) {
            final durationSeconds = await _getAudioDuration(file.path!);
            debugPrint('최종 저장할 음성 길이: $durationSeconds초');
            selectedMedia.add(
              Media(
                id:
                    DateTime.now().microsecondsSinceEpoch +
                    selectedMedia.length,
                memoryId: null,
                diaryId: null,
                fileUrl: file.path!,
                fileType: 'audio',
                duration: durationSeconds,
                sortOrder: selectedMedia.length + 1,
                createdAt: DateTime.now(),
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('===== 음성 초기화 실패 =====');

      debugPrint('오류: $e');
      debugPrint('스택: $stackTrace');
    }

    _saveSelectedMedia(selectedMedia, '음성');
  }

  // 미디어 추가 바텀시트 표시
  void _showAddMediaDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFBF0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 닫기 버튼
                GestureDetector(
                  onTap: () => Navigator.pop(bottomSheetContext),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/gallery/screen4/4-1_x.svg',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 사진 추가
                InkWell(
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickImages();
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: SvgPicture.asset(
                      'assets/gallery/screen4/4-1_photo_add.svg',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),

                // 구분선 1
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: SizedBox(
                    width: double.infinity,
                    height: 2,
                    child: SvgPicture.asset(
                      'assets/gallery/screen4/4-1_line1.svg',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),

                // 동영상 추가
                InkWell(
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickVideo();
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: SvgPicture.asset(
                      'assets/gallery/screen4/4-1_video_add.svg',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),

                // 구분선 2
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: SizedBox(
                    width: double.infinity,
                    height: 2,
                    child: SvgPicture.asset(
                      'assets/gallery/screen4/4-1_line2.svg',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),

                // 음성 추가
                InkWell(
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickAudio();
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: SvgPicture.asset(
                      'assets/gallery/screen4/4-1_audio_add.svg',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),

                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  // 미디어가 연결된 기록의 날짜를 가져오는 함수
  DateTime _getMediaDate(Media media, AppData appData) {
    if (media.memoryId != null) {
      try {
        final memory = appData.memories.firstWhere(
          (memory) => memory.id == media.memoryId,
        );

        return memory.recordDate;
      } catch (_) {
        // 연결된 환자 기록을 찾지 못하면 아래로 계속 진행
      }
    }

    if (media.diaryId != null) {
      try {
        final diary = appData.diaries.firstWhere(
          (diary) => diary.id == media.diaryId,
        );

        return diary.recordDate;
      } catch (_) {
        // 연결된 감정 기록을 찾지 못하면 아래로 계속 진행
      }
    }

    return media.createdAt;
  }

  @override
  void dispose() {
    _galleryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);

    // 환자 기록에 포함된 미디어
    final List<Media> patientMedia = [];

    for (final memory in appData.memories) {
      patientMedia.addAll(memory.mediaList);
    }

    // 감정 기록에 포함된 미디어
    final List<Media> emotionMedia = [];

    for (final diary in appData.diaries) {
      emotionMedia.addAll(diary.mediaList);
    }

    // 선택된 기록 구분에 따라 표시할 미디어 구성
    final List<Media> displayMedia = [];

    if (_selectedRecordTypes.contains('patient')) {
      displayMedia.addAll(patientMedia);

      displayMedia.addAll(
        _customMediaList.where((media) => media.memoryId != null),
      );
    }

    if (_selectedRecordTypes.contains('emotion')) {
      displayMedia.addAll(emotionMedia);

      displayMedia.addAll(
        _customMediaList.where((media) => media.diaryId != null),
      );
    }

    if (_selectedRecordTypes.contains('custom')) {
      displayMedia.addAll(
        _customMediaList.where(
          (media) => media.memoryId == null && media.diaryId == null,
        ),
      );
    }

    // 선택된 파일 유형에 따라 필터링
    final List<Media> filteredMedia = displayMedia.where((media) {
      return _selectedFileTypes.contains(media.fileType);
    }).toList();

    // 날짜 기준 정렬
    if (_sortBy == 'latest') {
      filteredMedia.sort((a, b) {
        final dateA = _getMediaDate(a, appData);
        final dateB = _getMediaDate(b, appData);

        return dateB.compareTo(dateA);
      });
    } else {
      filteredMedia.sort((a, b) {
        final dateA = _getMediaDate(a, appData);
        final dateB = _getMediaDate(b, appData);

        return dateA.compareTo(dateB);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Safe area spacing
            SizedBox(height: MediaQuery.of(context).padding.top),
            // Title
            Expanded(
              child: Center(
                child: SvgPicture.asset(
                  'assets/gallery/screen4/4_gallery_title.svg',
                  width: 155,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Bottom line/shadow
            // Bottom line/shadow
            // Bottom line/shadow
            SizedBox(
              width: double.infinity,
              height: 14,
              child: ClipRect(
                child: OverflowBox(
                  minHeight: 0,
                  maxHeight: double.infinity,
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/gallery/screen4_png/4_top_bar.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 조건 검색 영역
          if (!_isFilterExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFilterExpanded = true;
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: SvgPicture.asset(
                      'assets/gallery/screen4/4_condition_search.svg',
                      height: 18,
                      fit: BoxFit.contain,
                    ),
                  ),

                  GestureDetector(
                    onTap: _showAddMediaDialog,
                    behavior: HitTestBehavior.opaque,
                    child: SvgPicture.asset(
                      'assets/gallery/screen4/4_file_add.svg',
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  _isFilterExpanded = false;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: GalleryFilterPanel(
                selectedRecordTypes: _selectedRecordTypes,
                selectedFileTypes: _selectedFileTypes,
                sortBy: _sortBy,
                onRecordTypeChanged: (type, isSelected) {
                  setState(() {
                    if (isSelected) {
                      _selectedRecordTypes.add(type);
                    } else {
                      _selectedRecordTypes.remove(type);
                    }
                  });
                },
                onFileTypeChanged: (type, isSelected) {
                  setState(() {
                    if (isSelected) {
                      if (!_selectedFileTypes.contains(type)) {
                        _selectedFileTypes.add(type);
                      }
                    } else {
                      _selectedFileTypes.remove(type);
                    }
                  });
                },
                onSortByChanged: (sortValue) {
                  setState(() {
                    _sortBy = sortValue;
                  });
                },
                onReset: _resetFilters,
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 20, top: 4, bottom: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showAddMediaDialog,
                  behavior: HitTestBehavior.opaque,
                  child: SvgPicture.asset(
                    'assets/gallery/screen4/4_file_add.svg',
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],

          // 미디어 그리드 영역
          Expanded(
            child: filteredMedia.isEmpty
                ? Center(
                    child: SvgPicture.asset(
                      'assets/gallery/screen4/4_illustration_text.svg',
                      fit: BoxFit.contain,
                    ),
                  )
                : Scrollbar(
                    controller: _galleryScrollController,
                    thumbVisibility: true,
                    interactive: true,
                    child: GridView.builder(
                      controller: _galleryScrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.98,
                          ),
                      itemCount: filteredMedia.length,
                      itemBuilder: (context, index) {
                        final item = filteredMedia[index];

                        final date = _getMediaDate(item, appData);

                        return GalleryMediaTile(
                          key: ValueKey(item.id),
                          item: item,
                          resolvedDate: date,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
