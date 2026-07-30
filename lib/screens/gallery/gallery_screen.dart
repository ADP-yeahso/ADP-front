import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/media.dart';
import 'gallery_filter_panel.dart';
import 'gallery_media_tile.dart';
import 'gallery_add_dialog.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // 필터 상태 변수들
  String _selectedRecordType = '전체'; // '전체', '환자', '감정'
  final List<String> _selectedFileTypes = ['image', 'video', 'audio']; // 'image', 'video', 'audio'
  String _sortBy = 'latest'; // 'latest' (최신순), 'oldest' (오래된순)

  // 사용자가 직접 갤러리에 추가한 개별 미디어 목록 (세션 동안 임시 유지하여 병합 충돌 방지)
  final List<Media> _customMediaList = [];

  // 가상의 ID 생성을 위한 카운터
  int _customIdCounter = 5000;

  // 검색 초기화 함수
  void _resetFilters() {
    setState(() {
      _selectedRecordType = '전체';
      _selectedFileTypes.clear();
      _selectedFileTypes.addAll(['image', 'video', 'audio']);
      _sortBy = 'latest';
    });
  }

  // 개별 미디어 추가 다이얼로그 호출 함수
  void _showAddMediaDialog() {
    showDialog(
      context: context,
      builder: (context) {
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
              createdAt: DateTime.now(), // 추가 시점을 생성시점으로 저장
            );

            setState(() {
              _customMediaList.insert(0, mediaWithId); // 최신 등록 미디어를 맨 앞에 삽입
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${newMedia.fileType == 'image' ? '사진' : (newMedia.fileType == 'video' ? '동영상' : '음성')} 파일이 추가되었습니다.',
                ),
                backgroundColor: Theme.of(context).primaryColor,
              ),
            );
          },
        );
      },
    );
  }

  // 미디어의 실제 날짜 확인 메서드 (최신순/오래된순 정렬 작동 버그 해결용)
  // AppData의 Memory/Diary의 recordDate를 가져오고, 없으면 Media의 createdAt을 반환
  DateTime _getMediaDate(Media media, AppData appData) {
    if (media.memoryId != null) {
      try {
        final memory = appData.memories.firstWhere((m) => m.id == media.memoryId);
        return memory.recordDate;
      } catch (_) {}
    }
    if (media.diaryId != null) {
      try {
        final diary = appData.diaries.firstWhere((d) => d.id == media.diaryId);
        return diary.recordDate;
      } catch (_) {}
    }
    return media.createdAt; // 직접 업로드한 미디어 등은 생성일자 기준
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);

    // 1. AppData의 환자 기록(Memory)에서 미디어 가져오기
    final List<Media> patientMedia = [];
    for (var memory in appData.memories) {
      for (var media in memory.mediaList) {
        patientMedia.add(media);
      }
    }

    // 2. AppData의 감정 기록(Diary)에서 미디어 가져오기
    final List<Media> emotionMedia = [];
    for (var diary in appData.diaries) {
      for (var media in diary.mediaList) {
        emotionMedia.add(media);
      }
    }

    // 3. 필터 규칙 적용하여 미디어 리스트 구성
    final List<Media> displayMedia = [];

    // 기록 구분 필터 적용 ('전체', '환자', '감정')
    if (_selectedRecordType == '전체') {
      displayMedia.addAll(patientMedia);
      displayMedia.addAll(emotionMedia);
      displayMedia.addAll(_customMediaList);
    } else if (_selectedRecordType == '환자') {
      displayMedia.addAll(patientMedia);
      displayMedia.addAll(_customMediaList.where((m) => m.memoryId != null));
    } else if (_selectedRecordType == '감정') {
      displayMedia.addAll(emotionMedia);
      displayMedia.addAll(_customMediaList.where((m) => m.diaryId != null));
    }

    // 파일 유형 필터 적용 (사진, 동영상, 음성)
    final filteredMedia = displayMedia.where((m) {
      return _selectedFileTypes.contains(m.fileType);
    }).toList();

    // 부모 기록의 날짜 기준으로 실시간 정렬 구현 (최신순 / 오래된순 완벽 분기 작동 확인)
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
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: '미디어 추가',
            onPressed: _showAddMediaDialog,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- 조건 검색 영역 (컴포넌트 분리) ----------------
          GalleryFilterPanel(
            selectedRecordType: _selectedRecordType,
            selectedFileTypes: _selectedFileTypes,
            sortBy: _sortBy,
            onRecordTypeChanged: (type) {
              setState(() => _selectedRecordType = type);
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
              setState(() => _sortBy = sortValue);
            },
            onReset: _resetFilters,
          ),

          // ---------------- 그리드 미디어 영역 (컴포넌트 분리) ----------------
          Expanded(
            child: filteredMedia.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        const Text(
                          '조건에 맞는 미디어가 없습니다.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.0, // 정사각형 타일
                    ),
                    itemCount: filteredMedia.length,
                    itemBuilder: (context, index) {
                      final item = filteredMedia[index];
                      final date = _getMediaDate(item, appData);
                      return GalleryMediaTile(
                        item: item,
                        resolvedDate: date,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}