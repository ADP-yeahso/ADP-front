import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/media.dart';
import 'diary_loading_screen.dart';

class DiaryWriteScreen extends StatefulWidget {
  const DiaryWriteScreen({super.key});

  @override
  State<DiaryWriteScreen> createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _date = DateTime.now();
  final List<Media> _attachedMedia = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
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

  void _removeMedia(int index) {
    setState(() {
      _attachedMedia.removeAt(index);
    });
  }

  void _analyze() {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘의 감정을 조금이라도 적어주세요.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryLoadingScreen(
          date: _date,
          content: _contentController.text.trim(),
          isPublic: true,
          mediaList: List.from(_attachedMedia),
        ),
      ),
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
      appBar: AppBar(title: const Text('오늘의 감정 일기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘의 돌봄 경험과 감정을 편하게 적어보세요. 작성한 글은 AI가 분석해 감정에 맞는 콘텐츠를 추천해드려요.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '날짜'),
                child: Text('${_date.year}년 ${_date.month}월 ${_date.day}일'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              contextMenuBuilder: (context, editableTextState) => const SizedBox.shrink(),
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '예: 오늘 하루의 감정',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 6,
              contextMenuBuilder: (context, editableTextState) => const SizedBox.shrink(),
              decoration: const InputDecoration(
                labelText: '오늘의 감정 일기',
                hintText: '오늘 하루는 어떠셨나요?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '미디어 첨부',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${_attachedMedia.length}개 첨부됨',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('사진', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.video_library_outlined, size: 18),
                    label: const Text('동영상', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickAudio,
                    icon: const Icon(Icons.audiotrack_outlined, size: 18),
                    label: const Text('음성파일', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            if (_attachedMedia.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
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
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(Icons.image, '사진'),
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
                                style: const TextStyle(color: Color(0xFF1B4D89), fontSize: 9, fontWeight: FontWeight.w600),
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
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _analyze,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('감정 분석하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

