class Media {
  final int id;
  final int? memoryId;
  final int? diaryId;
  final String fileUrl;
  final String fileType; // 'image', 'video' 또는 'audio'
  final int? duration; // 비디오의 경우 duration을 저장, 이미지의 경우 0으로 설정
  final String? thumbnailPath;
  final int sortOrder; // 미디어의 정렬 순서를 나타내는 필드
  final DateTime createdAt;

  Media({
    required this.id,
    required this.memoryId,
    required this.diaryId,
    required this.fileUrl,
    required this.fileType,
    required this.duration,
    this.thumbnailPath,
    required this.sortOrder,
    required this.createdAt,
  });
}
