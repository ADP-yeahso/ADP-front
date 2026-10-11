class MemoryRecordComment {
  final int id;
  final int memoryRecordId;
  final int userId;
  final String commentText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  MemoryRecordComment({
    required this.id,
    required this.memoryRecordId,
    required this.userId,
    required this.commentText,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  int get memoryId => memoryRecordId;
  String get content => commentText;

  factory MemoryRecordComment.fromJson(Map<String, dynamic> json) {
    return MemoryRecordComment(
      id: json['id'] as int,
      memoryRecordId: json['memory_record_id'] as int,
      userId: json['user_id'] is int ? json['user_id'] as int : int.parse(json['user_id'].toString()),
      commentText: json['comment_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memory_record_id': memoryRecordId,
      'user_id': userId,
      'comment_text': commentText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

typedef Comment = MemoryRecordComment;
