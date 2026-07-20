class AppUser {
  final String id;
  final String email;
  AppUser({required this.id, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      AppUser(id: json['id'], email: json['email'] ?? '');
}