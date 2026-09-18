import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/media.dart';
import '../../../data/auth_session.dart';
import '../../../services/diary_service.dart';
import 'diary_emotion_explore_screen.dart';
import 'diary_loading_screen.dart';

class DiarySituationScreen extends StatefulWidget {
  const DiarySituationScreen({super.key});

  @override
  State<DiarySituationScreen> createState() => _DiarySituationScreenState();
}

class _DiarySituationScreenState extends State<DiarySituationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // 하단 미디어 선택 타일의 노출 여부 (최초 진입 시 false로 설정되어 타일이 뜨지 않음)
  bool _isTileRowVisible = false;

  // 현재 활성화된 미디어 타입 ('image', 'video', 'audio')
  String _activeMediaType = 'image';

  // 기기 내 최근 미디어 전체 목록
  final List<Media> _allDeviceMedia = [];

  // 현재 활성화된 미디어 타입의 필터링된 최근 목록
  final List<Media> _recentDeviceMedia = [];

  // 사용자가 선택(첨부)한 미디어 ID 목록
  final Set<int> _selectedMediaIds = {};

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _scanDeviceMediaFiles();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 기기 내 저장소 실제 미디어 전체 스캔 (재귀 탐색)
  Future<void> _scanDeviceMediaFiles() async {
    final List<Media> scanned = [];
    final List<String> directoriesToScan = [
      '/storage/emulated/0/DCIM/Camera',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Movies',
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Pictures/Screenshots',
      '/sdcard/DCIM',
      '/sdcard/Pictures',
      '/sdcard/Download',
    ];

    for (final dirPath in directoriesToScan) {
      try {
        final dir = Directory(dirPath);
        if (dir.existsSync()) {
          final List<FileSystemEntity> entities = dir.listSync(
            recursive: true,
            followLinks: false,
          );
          for (final entity in entities) {
            if (entity is File) {
              final ext = entity.path.toLowerCase();
              final isImg =
                  ext.endsWith('.jpg') ||
                  ext.endsWith('.jpeg') ||
                  ext.endsWith('.png') ||
                  ext.endsWith('.webp');
              final isVid =
                  ext.endsWith('.mp4') ||
                  ext.endsWith('.mov') ||
                  ext.endsWith('.mkv');
              final isAud =
                  ext.endsWith('.mp3') ||
                  ext.endsWith('.wav') ||
                  ext.endsWith('.m4a') ||
                  ext.endsWith('.flac');

              if (isImg || isVid || isAud) {
                DateTime modTime = DateTime.now();
                try {
                  modTime = entity.lastModifiedSync();
                } catch (_) {}

                scanned.add(
                  Media(
                    id: DateTime.now().microsecondsSinceEpoch + scanned.length,
                    memoryId: null,
                    diaryId: null,
                    fileUrl: entity.path,
                    fileType: isImg ? 'image' : (isVid ? 'video' : 'audio'),
                    duration: 0,
                    sortOrder: scanned.length + 1,
                    createdAt: modTime,
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error scanning dir $dirPath: $e');
      }
    }

    // 최신 파일 순 정렬
    scanned.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _allDeviceMedia.clear();
    _allDeviceMedia.addAll(scanned);
  }

  // 특정 미디어 타입의 실제 최근 파일 타일 목록 업데이트
  void _updateActiveMediaList(String type) {
    _activeMediaType = type;
    final filtered = _allDeviceMedia.where((m) => m.fileType == type).toList();

    _recentDeviceMedia.clear();
    if (filtered.isNotEmpty) {
      _recentDeviceMedia.addAll(filtered);
    }
  }

  // '사진 첨부' 누를 때: 타일 영역을 띄우고 최근 사진 타일로 갱신 (팝업은 열리지 않음)
  void _pickImages() {
    setState(() {
      _isTileRowVisible = true;
      _updateActiveMediaList('image');
    });
  }

  // '영상 첨부' 누를 때: 타일 영역을 띄우고 최근 영상 타일로 갱신 (팝업은 열리지 않음)
  void _pickVideo() {
    setState(() {
      _isTileRowVisible = true;
      _updateActiveMediaList('video');
    });
  }

  // '음성 첨부' 누를 때: 타일 영역을 띄우고 최근 음성 타일로 갱신 (팝업은 열리지 않음)
  void _pickAudio() {
    setState(() {
      _isTileRowVisible = true;
      _updateActiveMediaList('audio');
    });
  }

  // 팝업 내부에서 갤러리 추가 선택
  Future<void> _pickFromSystemGallery(StateSetter setModalState) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (final image in images) {
            final media = Media(
              id:
                  DateTime.now().microsecondsSinceEpoch +
                  _allDeviceMedia.length,
              memoryId: null,
              diaryId: null,
              fileUrl: image.path,
              fileType: 'image',
              duration: 0,
              sortOrder: _allDeviceMedia.length + 1,
              createdAt: DateTime.now(),
            );
            _allDeviceMedia.insert(0, media);
            _recentDeviceMedia.insert(0, media);
            _selectedMediaIds.add(media.id);
          }
        });
        setModalState(() {});
      }
    } catch (e) {
      debugPrint('Error picking system gallery: $e');
    }
  }

  // 4번째 '+4' 타일을 눌렀을 때만 열리는 미디어 선택 팝업
  void _showAllMediaOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFBF0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final height = MediaQuery.of(modalContext).size.height;
            final activeTypeName = _activeMediaType == 'image'
                ? '사진'
                : (_activeMediaType == 'video' ? '영상' : '음성');

            return Container(
              height: height * 0.7,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                children: [
                  // 상단 드래그 바 & 닫기 버튼
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC7C3B6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () => Navigator.pop(modalContext),
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF4C7B43),
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 상단 헤더 (최근 미디어 수 & 앨범 선택 버튼)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '최근 $activeTypeName 미디어 (${_recentDeviceMedia.length}개)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222222),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _pickFromSystemGallery(setModalState),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                          color: Color(0xFF4C7B43),
                        ),
                        label: const Text(
                          '앨범 선택',
                          style: TextStyle(
                            color: Color(0xFF4C7B43),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 최근 미디어 전체 그리드 (터치 시 선택/해제 토글)
                  Expanded(
                    child: _recentDeviceMedia.isEmpty
                        ? const Center(
                            child: Text(
                              '최근 파일이 없습니다.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : GridView.builder(
                            itemCount: _recentDeviceMedia.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.0,
                                ),
                            itemBuilder: (context, index) {
                              final item = _recentDeviceMedia[index];
                              final isSelected = _selectedMediaIds.contains(
                                item.id,
                              );

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedMediaIds.remove(item.id);
                                    } else {
                                      _selectedMediaIds.add(item.id);
                                    }
                                  });
                                  setModalState(() {});
                                },
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: _buildMediaThumbnail(item),
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.25,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFA5DD82),
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (isSelected)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFA5DD82),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMediaThumbnail(Media item) {
    final file = File(item.fileUrl);
    final fileExists = item.fileUrl.isNotEmpty && file.existsSync();

    if (item.fileType == 'image') {
      if (fileExists) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F3E5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.nature_people_outlined,
            color: Color(0xFF4C7B43),
            size: 36,
          ),
        ),
      );
    } else if (item.fileType == 'video') {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFF2C3E50),
            child: fileExists
                ? Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.videocam, color: Colors.white54),
                  )
                : const Icon(Icons.landscape, color: Colors.white38, size: 40),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
        ],
      );
    } else {
      // audio
      final fileName = fileExists
          ? file.path.split(Platform.pathSeparator).last
          : '음성 파일';
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF9E6), Color(0xFFE2F0D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, color: Color(0xFF4C7B43), size: 26),
            const SizedBox(height: 4),
            Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C4A28),
              ),
            ),
          ],
        ),
      );
    }
  }

  // 본문 입력창 하단 최근 미디어 빠른 첨부 타일 (사진/영상/음성 첨부 클릭 시에만 뜸)
  Widget _buildInlinePreviewRow() {
    if (!_isTileRowVisible) return const SizedBox.shrink();

    if (_recentDeviceMedia.isEmpty) {
      final typeName = _activeMediaType == 'image'
          ? '사진'
          : (_activeMediaType == 'video' ? '영상' : '음성');
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '기기에 최근 $typeName 파일이 없습니다.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            TextButton.icon(
              onPressed: () => _pickFromSystemGallery((fn) => setState(fn)),
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 16,
                color: Color(0xFF4C7B43),
              ),
              label: const Text(
                '앨범에서 선택',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4C7B43),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final visibleCount = _recentDeviceMedia.length > 3
        ? 4
        : _recentDeviceMedia.length;
    final extraCount = _recentDeviceMedia.length - 3;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: List.generate(visibleCount, (index) {
          final isFourthSlot = index == 3 && extraCount > 0;
          final item = _recentDeviceMedia[index];
          final isSelected = _selectedMediaIds.contains(item.id);

          return Expanded(
            child: GestureDetector(
              // 1, 2, 3번째 타일은 터치 시 첨부 선택/해제
              // 4번째 (+N) 타일 터치 시에만 팝업 실행
              onTap: isFourthSlot
                  ? () => _showAllMediaOverlay(context)
                  : () {
                      setState(() {
                        if (isSelected) {
                          _selectedMediaIds.remove(item.id);
                        } else {
                          _selectedMediaIds.add(item.id);
                        }
                      });
                    },
              child: Container(
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildMediaThumbnail(item),
                      // 선택 완료 표시 체크 아이콘
                      if (!isFourthSlot && isSelected) ...[
                        Container(color: Colors.black.withValues(alpha: 0.25)),
                        const Center(
                          child: Icon(
                            Icons.check_circle,
                            color: Color(0xFFA5DD82),
                            size: 24,
                          ),
                        ),
                      ],
                      // 4번째 '+4' 타일 오버레이
                      if (isFourthSlot)
                        Container(
                          color: const Color(0xFF1E242B),
                          alignment: Alignment.center,
                          child: Text(
                            '+$extraCount',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAssetWidget({
    required List<String> candidatePaths,
    required Widget fallback,
    double? width,
    double? height,
  }) {
    return _tryPath(candidatePaths, 0, fallback, width, height);
  }

  Widget _tryPath(
    List<String> paths,
    int index,
    Widget fallback,
    double? width,
    double? height,
  ) {
    if (index >= paths.length) return fallback;
    final path = paths[index];
    final isSvg = path.toLowerCase().endsWith('.svg');
    if (isSvg) {
      return SvgPicture.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => fallback,
      );
    } else {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _tryPath(paths, index + 1, fallback, width, height),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFFBF0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 다람쥐 캐릭터 (150x150)
              Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: _buildAssetWidget(
                    candidatePaths: const [
                      'assets/record/choice/svg/3-2-1.svg/svg/3-2-1 다람쥐2.svg',
                      'assets/record/choice/png/3-2-1.png/png/3-2-1 다람쥐2.png',
                    ],
                    fallback: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCDCDC),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 헤드라인 ("오늘은 무슨 일이 있으셨나요?")
              Center(
                child: _buildAssetWidget(
                  candidatePaths: const [
                    'assets/record/choice/svg/3-2-1.svg/svg/3-2-1 메인 헤드라인.svg',
                    'assets/record/choice/png/3-2-1.png/png/3-2-1 메인 헤드라인.png',
                  ],
                  fallback: const Text(
                    '오늘은 무슨 일이 있으셨나요?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 제목 입력창 (선택)
              TextField(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: '제목 입력창 (선택)',
                  hintStyle: const TextStyle(fontSize: 15, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 본문 텍스트 입력창 + 최근 미디어 타일 퀵 선택 바
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            hintText: '텍스트 입력',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      // 사진/영상/음성 첨부 누를 때만 보여지는 최근 미디어 타일 바
                      _buildInlinePreviewRow(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 미디어 첨부 버튼 바 (사진 첨부 | 영상 첨부 | 음성 첨부)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: _pickImages,
                      child: Row(
                        children: const [
                          Icon(
                            Icons.crop_original,
                            size: 20,
                            color: Colors.black54,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '사진 첨부',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 18,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    InkWell(
                      onTap: _pickVideo,
                      child: Row(
                        children: const [
                          Icon(
                            Icons.add_to_queue_outlined,
                            size: 20,
                            color: Colors.black54,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '영상 첨부',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 18,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    InkWell(
                      onTap: _pickAudio,
                      child: Row(
                        children: const [
                          Icon(Icons.mic_none, size: 20, color: Colors.black54),
                          SizedBox(width: 6),
                          Text(
                            '음성 첨부',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 하단 다음 버튼 (제목 및 텍스트 모두 입력 시 연두색으로 변경 및 클릭 가능)
              Builder(
                builder: (context) {
                  final bool isFormValid =
                      _titleController.text.trim().isNotEmpty &&
                      _contentController.text.trim().isNotEmpty;
                  return Center(
                    child: SizedBox(
                      width: 180,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isFormValid
                            ? () {
                                final tokens = context
                                    .read<AuthSession>()
                                    .tokens;
                                if (tokens == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('다이어리를 작성하려면 먼저 로그인해주세요.'),
                                    ),
                                  );
                                  return;
                                }
                                final title = _titleController.text.trim();
                                final situation = _contentController.text
                                    .trim();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DiaryLoadingScreen(
                                      loadNext: () async {
                                        final draft = await DiaryService()
                                            .createDraftAndQuestion(
                                              tokens: tokens,
                                              title: title,
                                              situationText: situation,
                                            );
                                        return DiaryEmotionExploreScreen(
                                          draft: draft,
                                          tokens: tokens,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFormValid
                              ? const Color(0xFFA5DD82)
                              : const Color(0xFFFFF2B2),
                          disabledBackgroundColor: const Color(0xFFFFF2B2),
                          foregroundColor: Colors.black87,
                          disabledForegroundColor: Colors.black45,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: const Text(
                          '다음',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
