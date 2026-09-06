class UserGroup {
  final int id;
  final int userId;
  final int groupId;
  final String patientsNickname;
  final String relationship;
  final DateTime joinedAt;

  UserGroup({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.patientsNickname,
    this.relationship = '',
    required this.joinedAt,
  });
}
