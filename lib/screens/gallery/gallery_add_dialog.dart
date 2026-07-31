import 'package:flutter/material.dart';
import '../../models/media.dart';

class GalleryAddDialog extends StatefulWidget {
  final Function(Media, String) onMediaAdded;

  const GalleryAddDialog({
    super.key,
    required this.onMediaAdded,
  });

  @override
  State<GalleryAddDialog> createState() => _GalleryAddDialogState();
}

class _GalleryAddDialogState extends State<GalleryAddDialog> {
  String type = 'image'; // 기본값
  String recordAssoc = 'none'; // 'none', 'patient', 'emotion'
  final durationController = TextEditingController(text: '15');
  int selectedPresetIndex = 0;

  // 예쁜 모의 이미지 리스트
  final presetImages = [
    {'label': '벚꽃', 'url': 'https://images.unsplash.com/photo-1522748906645-95d8adfd52c7?w=500&auto=format&fit=crop'},
    {'label': '소나무', 'url': 'https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=500&auto=format&fit=crop'},
    {'label': '튤립 정원', 'url': 'https://images.unsplash.com/photo-1550950158-d0d960dff51b?w=500&auto=format&fit=crop'},
    {'label': '가족 산책', 'url': 'https://images.unsplash.com/photo-1476900543704-4312b78631f8?w=500&auto=format&fit=crop'},
    {'label': '따뜻한 차', 'url': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500&auto=format&fit=crop'},
  ];

  @override
  void dispose() {
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFFBF9F3),
      title: Row(
        children: [
          Icon(Icons.add_photo_alternate, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('미디어 추가', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('파일 유형 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ChoiceChip(
                  label: const Text('사진'),
                  selected: type == 'image',
                  onSelected: (val) {
                    if (val) setState(() => type = 'image');
                  },
                ),
                ChoiceChip(
                  label: const Text('동영상'),
                  selected: type == 'video',
                  onSelected: (val) {
                    if (val) setState(() => type = 'video');
                  },
                ),
                ChoiceChip(
                  label: const Text('음성'),
                  selected: type == 'audio',
                  onSelected: (val) {
                    if (val) setState(() => type = 'audio');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (type == 'image') ...[
              const Text('이미지 프리셋 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: presetImages.length,
                  itemBuilder: (ctx, idx) {
                    final isSelected = selectedPresetIndex == idx;
                    return GestureDetector(
                      onTap: () => setState(() => selectedPresetIndex = idx),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            presetImages[idx]['url']!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '선택된 템플릿: ${presetImages[selectedPresetIndex]['label']}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ] else ...[
              const Text('재생 시간 설정 (초)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '초 단위로 입력 (예: 15)',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('기록 구분', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: recordAssoc,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'patient',
                  child: Text('환자 기록에 연결'),
                ),
                DropdownMenuItem(
                  value: 'emotion',
                  child: Text('감정 기록에 연결'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => recordAssoc = val);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            final duration = int.tryParse(durationController.text) ?? 10;
            final fileUrl = type == 'image'
                ? presetImages[selectedPresetIndex]['url']!
                : (type == 'video' ? 'video.mp4' : 'audio.mp3');

            final newMedia = Media(
              id: 0, // Parent/Caller can assign its own ID
              memoryId: recordAssoc == 'patient' ? 9999 : null,
              diaryId: recordAssoc == 'emotion' ? 9999 : null,
              fileUrl: fileUrl,
              fileType: type,
              duration: type == 'image' ? null : duration,
              sortOrder: 1,
              createdAt: DateTime.now(),
            );

            widget.onMediaAdded(newMedia, recordAssoc);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('추가'),
        ),
      ],
    );
  }
}
