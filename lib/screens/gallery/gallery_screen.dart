import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/media.dart';
import 'gallery_add_dialog.dart';
import 'gallery_filter_panel.dart';
import 'gallery_media_tile.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ScrollController _galleryScrollController =
      ScrollController();

  // 선택된 기록 구분
  final Set<String> _selectedRecordTypes = {
    'patient',
    'emotion',
    'custom',
  };

  // 선택된 파일 유형
  final List<String> _selectedFileTypes = [
    'image',
    'video',
    'audio',
  ];

  // latest: 최신순, oldest: 오래된순
  String _sortBy = 'latest';

  // 사용자가 갤러리에서 직접 추가한 미디어
  final List<Media> _customMediaList = [];

  // 직접 추가 미디어의 임시 ID
  int _customIdCounter = 5000;

  // 검색 조건 초기화
  void _resetFilters() {
    setState(() {
      _selectedRecordTypes
        ..clear()
        ..addAll({
          'patient',
          'emotion',
          'custom',
        });

      _selectedFileTypes
        ..clear()
        ..addAll([
          'image',
          'video',
          'audio',
        ]);

      _sortBy = 'latest';
    });
  }

  // 미디어 추가 다이얼로그 표시
  void _showAddMediaDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return GalleryAddDialog(
          onMediaAdded: (newMedia, recordAssoc) {
            final mediaWithId = Media(
              id: _customIdCounter++,
              memoryId: newMedia.memoryId,
              diaryId: newMedia.diaryId,
              fileUrl: newMedia.fileUrl,
              fileType: newMedia.fileType,
              duration: newMedia.duration,
              sortOrder: newMedia.sortOrder,
              createdAt: DateTime.now(),
            );

            setState(() {
              _customMediaList.insert(
                0,
                mediaWithId,
              );
            });

            final String mediaTypeText;

            if (newMedia.fileType == 'image') {
              mediaTypeText = '사진';
            } else if (newMedia.fileType == 'video') {
              mediaTypeText = '동영상';
            } else {
              mediaTypeText = '음성';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$mediaTypeText 파일이 추가되었습니다.',
                ),
                backgroundColor:
                    Theme.of(context).primaryColor,
              ),
            );
          },
        );
      },
    );
  }

  // 미디어가 연결된 기록의 날짜를 가져오는 함수
  DateTime _getMediaDate(
    Media media,
    AppData appData,
  ) {
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
        _customMediaList.where(
          (media) => media.memoryId != null,
        ),
      );
    }

    if (_selectedRecordTypes.contains('emotion')) {
      displayMedia.addAll(emotionMedia);

      displayMedia.addAll(
        _customMediaList.where(
          (media) => media.diaryId != null,
        ),
      );
    }

    if (_selectedRecordTypes.contains('custom')) {
      displayMedia.addAll(
        _customMediaList.where(
          (media) =>
              media.memoryId == null &&
              media.diaryId == null,
        ),
      );
    }

    // 선택된 파일 유형에 따라 필터링
    final List<Media> filteredMedia =
        displayMedia.where((media) {
      return _selectedFileTypes.contains(
        media.fileType,
      );
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
      backgroundColor: const Color(0xFFFBF9F3),
      appBar: AppBar(
        title: const Text(
          '< 기억 갤러리 >',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 12,
            ),
            child: TextButton.icon(
              onPressed: _showAddMediaDialog,
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 26,
              ),
              label: const Text(
                '추가',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor:
                    Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 조건 검색 영역
          GalleryFilterPanel(
            selectedRecordTypes:
                _selectedRecordTypes,
            selectedFileTypes:
                _selectedFileTypes,
            sortBy: _sortBy,
            onRecordTypeChanged: (
              type,
              isSelected,
            ) {
              setState(() {
                if (isSelected) {
                  _selectedRecordTypes.add(type);
                } else {
                  _selectedRecordTypes.remove(type);
                }
              });
            },
            onFileTypeChanged: (
              type,
              isSelected,
            ) {
              setState(() {
                if (isSelected) {
                  if (!_selectedFileTypes.contains(
                    type,
                  )) {
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

          // 미디어 그리드 영역
          Expanded(
            child: filteredMedia.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '조건에 맞는 미디어가 없습니다.',
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : Scrollbar(
                    controller:
                        _galleryScrollController,
                    thumbVisibility: true,
                    interactive: true,
                    child: GridView.builder(
                      controller:
                          _galleryScrollController,
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        8,
                        20,
                        24,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemCount:
                          filteredMedia.length,
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        final item =
                            filteredMedia[index];

                        final date =
                            _getMediaDate(
                          item,
                          appData,
                        );

                        return GalleryMediaTile(
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