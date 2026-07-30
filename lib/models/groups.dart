class Group {
  final int id;
  final String inviteCode;
  final String groupName;
  final String? groupProfileImageUrl;
  final int members;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.inviteCode,
    required this.groupName,
    this.groupProfileImageUrl,
    required this.members,
    required this.createdAt,
  });
}
