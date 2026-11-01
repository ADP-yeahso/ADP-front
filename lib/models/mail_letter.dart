class MailLetter {
  final String id;
  final int groupId;

  /// 받은 익명 편지는 백엔드에서 null로 내려올 수 있습니다.
  final String? senderUserId;
  final String? receiverUserId;

  final String sender;
  final String receiver;
  final String content;
  final bool isAnonymous;
  final bool isGroupLetter;
  final DateTime createdAt;

  bool isRead;

  MailLetter({
    required this.id,
    required this.groupId,
    required this.senderUserId,
    required this.receiverUserId,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.isAnonymous,
    required this.isGroupLetter,
    required this.createdAt,
    this.isRead = false,
  });

  /// 백엔드 API 응답을 MailLetter 객체로 변환할 때 사용합니다.
  factory MailLetter.fromJson(Map<String, dynamic> json) {
    final receiverUserId = json['receiver_user_id']?.toString();
    return MailLetter(
      id: '${json['id']}',
      groupId: switch (json['group_id']) {
        int value => value,
        num value => value.toInt(),
        _ => int.tryParse('${json['group_id']}') ?? 0,
      },
      senderUserId: json['sender_user_id']?.toString(),
      receiverUserId: receiverUserId,
      sender: (json['sender_name'] ?? '가족').toString(),
      receiver: (json['receiver_name'] ?? '가족 모두에게').toString(),
      content: (json['content'] ?? '').toString(),
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      isGroupLetter: json['is_group_letter'] as bool? ?? receiverUserId == null,
      createdAt:
          DateTime.tryParse('${json['created_at']}')?.toLocal() ??
          DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  bool isSentBy(String userId) {
    return senderUserId == userId;
  }

  bool isReceivedBy(String userId) {
    if (senderUserId == userId) {
      return false;
    }

    return isGroupLetter || receiverUserId == userId;
  }

  String get date {
    final now = DateTime.now();
    final localCreatedAt = createdAt.toLocal();
    final difference = now.difference(localCreatedAt);

    if (difference.inMinutes < 1) {
      return '방금 전';
    }

    final isToday =
        now.year == localCreatedAt.year &&
        now.month == localCreatedAt.month &&
        now.day == localCreatedAt.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        yesterday.year == localCreatedAt.year &&
        yesterday.month == localCreatedAt.month &&
        yesterday.day == localCreatedAt.day;

    final period = localCreatedAt.hour < 12 ? '오전' : '오후';
    final hour = localCreatedAt.hour % 12 == 0 ? 12 : localCreatedAt.hour % 12;
    final minute = localCreatedAt.minute.toString().padLeft(2, '0');

    if (isToday) {
      return '오늘 $period $hour:$minute';
    }

    if (isYesterday) {
      return '어제 $period $hour:$minute';
    }

    return '${localCreatedAt.year}.${localCreatedAt.month.toString().padLeft(2, '0')}.${localCreatedAt.day.toString().padLeft(2, '0')}';
  }
}
