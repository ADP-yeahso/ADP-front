class UserGroup {
  final int id;
  final int userId;
  final int groupId;
  final String patientsNickname;
  final DateTime joinedAt;

  UserGroup({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.patientsNickname,
    required this.joinedAt,
  });
}
