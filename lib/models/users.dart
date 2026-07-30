class User {
  final int id;
  final String email;
  final String password;
  final String name;
  final String phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.phoneNumber,
    required this.profileImageUrl,
    required this.createdAt,
  });
}
