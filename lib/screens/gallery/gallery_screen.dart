import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_data.dart';
import '../../models/media.dart';
import 'gallery_filter_panel.dart';
import 'gallery_media_tile.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ScrollController _galleryScrollController = ScrollController();

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

  void _showAddMediaDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('갤러리 직접 추가는 준비 중입니다. 감정 일기에 첨부한 파일을 여기서 볼 수 있어요.'),
      ),
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
                    child: SizedBox(
                      width: 110,
                      height: 36,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/gallery/screen4_png/4_condition_search_button_frame.png',
                              fit: BoxFit.fill,
                            ),
                          ),

                          SvgPicture.asset(
                            'assets/gallery/screen4/4_condition_search.svg',
                            height: 18,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: _showAddMediaDialog,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 82,
                      height: 36,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/gallery/screen4_png/4_add_button_frame.png',
                              fit: BoxFit.fill,
                            ),
                          ),

                          SvgPicture.asset(
                            'assets/gallery/screen4/4_file_add.svg',
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
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
                  child: SizedBox(
                    width: 82,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/gallery/screen4_png/4_add_button_frame.png',
                            fit: BoxFit.fill,
                          ),
                        ),

                        SvgPicture.asset(
                          'assets/gallery/screen4/4_file_add.svg',
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
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
