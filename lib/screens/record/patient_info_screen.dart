import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/media.dart';

class PatientInfoScreen extends StatefulWidget {
  const PatientInfoScreen({super.key});

  @override
  State<PatientInfoScreen> createState() => _PatientInfoScreenState();
}

class _PatientInfoScreenState extends State<PatientInfoScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isPublic = true;
  final List<Media> _attachedMedia = [];
  final ImagePicker _picker = ImagePicker();

  // 입력 필드 포커스 노드
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();

  bool get _hasContent =>
      _titleController.text.trim().isNotEmpty ||
      _contentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (final image in images) {
            _attachedMedia.add(
              Media(
                id: DateTime.now().microsecondsSinceEpoch,
                memoryId: null,
                diaryId: null,
                fileUrl: image.path,
                fileType: 'image',
                duration: 0,
                sortOrder: _attachedMedia.length + 1,
                createdAt: DateTime.now(),
              ),
            );
          }
        });
      }
    } catch (_) {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              _attachedMedia.add(
                Media(
                  id: DateTime.now().microsecondsSinceEpoch,
                  memoryId: null,
                  diaryId: null,
                  fileUrl: file.path!,
                  fileType: 'image',
                  duration: 0,
                  sortOrder: _attachedMedia.length + 1,
                  createdAt: DateTime.now(),
                ),
              );
            }
          }
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _attachedMedia.add(
            Media(
              id: DateTime.now().microsecondsSinceEpoch,
              memoryId: null,
              diaryId: null,
              fileUrl: video.path,
              fileType: 'video',
              duration: 0,
              sortOrder: _attachedMedia.length + 1,
              createdAt: DateTime.now(),
            ),
          );
        });
      }
    } catch (_) {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        setState(() {
          _attachedMedia.add(
            Media(
              id: DateTime.now().microsecondsSinceEpoch,
              memoryId: null,
              diaryId: null,
              fileUrl: result.files.single.path!,
              fileType: 'video',
              duration: 0,
              sortOrder: _attachedMedia.length + 1,
              createdAt: DateTime.now(),
            ),
          );
        });
      }
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'aac', 'wav', 'm4a', 'flac'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final file in result.files) {
          if (file.path != null) {
            _attachedMedia.add(
              Media(
                id: DateTime.now().microsecondsSinceEpoch,
                memoryId: null,
                diaryId: null,
                fileUrl: file.path!,
                fileType: 'audio',
                duration: 0,
                sortOrder: _attachedMedia.length + 1,
                createdAt: DateTime.now(),
              ),
            );
          }
        }
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final file in result.files) {
          if (file.path != null) {
            _attachedMedia.add(
              Media(
                id: DateTime.now().microsecondsSinceEpoch,
                memoryId: null,
                diaryId: null,
                fileUrl: file.path!,
                fileType: 'file',
                duration: 0,
                sortOrder: _attachedMedia.length + 1,
                createdAt: DateTime.now(),
              ),
            );
          }
        }
      });
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _attachedMedia.removeAt(index);
    });
  }

  void _save() {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해 주세요.')),
      );
      return;
    }
    final appData = context.read<AppData>();
    appData.addMemory(
      date: _date,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      mediaList: _attachedMedia,
      isPublic: _isPublic,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('나무에 새 잎이 달렸어요 🌿')),
    );
  }

  Widget _buildPlaceholderIcon(IconData icon, String label) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black45, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DD),
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 영역 (뒤로가기 + 헤드라인 인라인) ──
            _buildTopBar(),
            // ── 스크롤 가능한 메인 영역 ──
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // 부제목
                    _buildSubtitle(),
                    const SizedBox(height: 24),
                    // 날짜 입력
                    _buildDateField(),
                    const SizedBox(height: 16),
                    // 제목 입력
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    // 본문 입력
                    _buildBodyField(),
                    const SizedBox(height: 24),
                    // 첨부 버튼들
                    _buildAttachButtons(),
                    // 첨부된 미디어 목록
                    if (_attachedMedia.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildMediaList(),
                    ],
                    const SizedBox(height: 20),
                    // 가족 공유 토글
                    _buildShareToggle(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // ── 하단 다음 버튼 ──
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SvgPicture.asset(
              'assets/svg/screen3_1/back_button.svg',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              placeholderBuilder: (_) => Image.asset(
                'assets/images/screen3_1/back_button.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (e, err, st) => const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF4C7B43),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 헤드라인 SVG (타이틀 크기로 인라인)
          Expanded(
            child: SvgPicture.asset(
              'assets/svg/screen3_1/main_headline.svg',
              height: 22,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              placeholderBuilder: (_) => Image.asset(
                'assets/images/screen3_1/main_headline.png',
                height: 22,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                errorBuilder: (e, err, st) => const Text(
                  '환자 정보 입력',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SvgPicture.asset(
        'assets/svg/screen3_1/subtitle.svg',
        height: 14,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        placeholderBuilder: (_) => Image.asset(
          'assets/images/screen3_1/subtitle.png',
          height: 14,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          errorBuilder: (e, err, st) => const Text(
            '오늘 있었던 일을 기록해 보세요',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6F8962),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: _pickDate,
        child: AspectRatio(
          aspectRatio: 299 / 38,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 날짜 박스 배경 SVG
              SvgPicture.asset(
                'assets/svg/screen3_1/date_box.svg',
                fit: BoxFit.fill,
              ),
              // 날짜 레이블 + 값
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // 날짜 폰트 라벨 SVG
                    SvgPicture.asset(
                      'assets/svg/screen3_1/date_font.svg',
                      height: 16,
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) => Image.asset(
                        'assets/images/screen3_1/date_font.png',
                        height: 16,
                        fit: BoxFit.contain,
                        errorBuilder: (e, err, st) => const Text(
                          '날짜',
                          style: TextStyle(fontSize: 13, color: Color(0xFF6F8962)),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_date.year}년 ${_date.month}월 ${_date.day}일',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3A3A3A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6F8962)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AspectRatio(
        aspectRatio: 299 / 38,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 제목 박스 배경 SVG
            SvgPicture.asset(
              'assets/svg/screen3_1/title_box.svg',
              fit: BoxFit.fill,
            ),
            // 제목 입력 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 제목 폰트 라벨 SVG
                  SvgPicture.asset(
                    'assets/svg/screen3_1/title_font.svg',
                    height: 16,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) => Image.asset(
                      'assets/images/screen3_1/title_font.png',
                      height: 16,
                      fit: BoxFit.contain,
                      errorBuilder: (e, err, st) => const Text(
                        '제목',
                        style: TextStyle(fontSize: 13, color: Color(0xFF6F8962)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      contextMenuBuilder: (context, editableTextState) => const SizedBox.shrink(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3A3A3A),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: '예: 함께 본 옛날 사진',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFBBBBBB),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AspectRatio(
        aspectRatio: 299 / 254,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 본문 박스 배경 SVG
            SvgPicture.asset(
              'assets/svg/screen3_1/body_input_box.svg',
              fit: BoxFit.fill,
            ),
            // 본문 입력 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 본문 폰트 라벨 SVG
                  SvgPicture.asset(
                    'assets/svg/screen3_1/body_input_font.svg',
                    height: 16,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) => Image.asset(
                      'assets/images/screen3_1/body_input_font.png',
                      height: 16,
                      fit: BoxFit.contain,
                      errorBuilder: (e, err, st) => const Text(
                        '내용',
                        style: TextStyle(fontSize: 13, color: Color(0xFF6F8962)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      maxLines: null,
                      expands: true,
                      contextMenuBuilder: (context, editableTextState) => const SizedBox.shrink(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3A3A3A),
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: '오늘 있었던 일을 자유롭게 적어보세요',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFBBBBBB),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachButtons() {
    // attach_file_button.svg가 3구역 배경, 그 위에 3개 아이콘 오버레이
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AspectRatio(
        aspectRatio: 299 / 47,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경: attach_file_button.svg (3구역 구분선 포함)
            SvgPicture.asset(
              'assets/svg/screen3_1/attach_file_button.svg',
              fit: BoxFit.fill,
            ),
            // 오버레이: 3구역에 각 아이콘 배치
            Row(
              children: [
                // 구역 1: 사진
                Expanded(
                  child: GestureDetector(
                    onTap: _pickImages,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/svg/screen3_1/attach_photo.svg',
                        height: 28,
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) => Image.asset(
                          'assets/images/screen3_1/attach_photo.png',
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (e, err, st) => const Icon(
                            Icons.photo_library_outlined,
                            color: Color(0xFF4C7B43),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 구역 2: 동영상
                Expanded(
                  child: GestureDetector(
                    onTap: _pickVideo,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/svg/screen3_1/attach_video.svg',
                        height: 28,
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) => Image.asset(
                          'assets/images/screen3_1/attach_video.png',
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (e, err, st) => const Icon(
                            Icons.video_library_outlined,
                            color: Color(0xFF4C7B43),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 구역 3: 음성
                Expanded(
                  child: GestureDetector(
                    onTap: _pickAudio,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/svg/screen3_1/attach_audio.svg',
                        height: 28,
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) => Image.asset(
                          'assets/images/screen3_1/attach_audio.png',
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (e, err, st) => const Icon(
                            Icons.audiotrack_outlined,
                            color: Color(0xFF4C7B43),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _attachedMedia.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final media = _attachedMedia[index];
            final file = File(media.fileUrl);
            final exists = file.existsSync();
            final fileName = file.path.split(Platform.pathSeparator).last;

            Widget content;
            if (media.fileType == 'image' && exists) {
              content = ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  file,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholderIcon(Icons.image, '사진'),
                ),
              );
            } else if (media.fileType == 'video') {
              content = Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 9),
                      ),
                    ),
                  ],
                ),
              );
            } else if (media.fileType == 'audio') {
              content = Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBCE0FD)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mic, color: Color(0xFF2B80FF), size: 26),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1B4D89),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              content = _buildPlaceholderIcon(Icons.insert_drive_file, media.fileType);
            }

            return Stack(
              children: [
                content,
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => _removeMedia(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildShareToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 가족 공유 라벨 SVG
          SvgPicture.asset(
            'assets/svg/screen3_1/share_with_family_label.svg',
            height: 20,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => Image.asset(
              'assets/images/screen3_1/share_with_family_label.png',
              height: 20,
              fit: BoxFit.contain,
              errorBuilder: (e, err, st) => const Text(
                '가족에게 공개',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF3A3A3A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Spacer(),
          // 커스텀 토글 스위치
          GestureDetector(
            onTap: () => setState(() => _isPublic = !_isPublic),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 트랙 배경
                SvgPicture.asset(
                  _isPublic
                      ? 'assets/svg/screen3_1/switch_track_on.svg'
                      : 'assets/svg/screen3_1/switch_track_off.svg',
                  width: 52,
                  height: 30,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => Image.asset(
                    _isPublic
                        ? 'assets/images/screen3_1/switch_track_on.png'
                        : 'assets/images/screen3_1/switch_track_off.png',
                    width: 52,
                    height: 30,
                    fit: BoxFit.contain,
                    errorBuilder: (e, err, st) => Container(
                      width: 52,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _isPublic ? const Color(0xFF4C7B43) : const Color(0xFFCCCCCC),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                // 썸 (토글 버튼)
                AnimatedAlign(
                  alignment: _isPublic ? Alignment.centerRight : Alignment.centerLeft,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: SvgPicture.asset(
                      'assets/svg/screen3_1/switch_thumb.svg',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) => Image.asset(
                        'assets/images/screen3_1/switch_thumb.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (e, err, st) => Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: GestureDetector(
        onTap: _save,
        child: SvgPicture.asset(
          _hasContent
              ? 'assets/svg/screen3_1/next_button_green.svg'
              : 'assets/svg/screen3_1/next_button_yellow.svg',
          width: double.infinity,
          fit: BoxFit.fitWidth,
          placeholderBuilder: (_) => Image.asset(
            _hasContent
                ? 'assets/images/screen3_1/next_button_green.png'
                : 'assets/images/screen3_1/next_button_yellow.png',
            width: double.infinity,
            fit: BoxFit.fitWidth,
            errorBuilder: (e, err, st) => Container(
              height: 56,
              decoration: BoxDecoration(
                color: _hasContent ? const Color(0xFF4C7B43) : const Color(0xFFE8C84A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '다음',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _hasContent ? Colors.white : const Color(0xFF4C3A00),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

