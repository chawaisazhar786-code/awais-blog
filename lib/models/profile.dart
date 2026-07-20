class Profile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? avatarStoragePath;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.avatarStoragePath,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'],
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    avatarUrl: json['avatar_url'],
    avatarStoragePath: json['avatar_storage_path'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar_url': avatarUrl,
    'avatar_storage_path': avatarStoragePath,
    'created_at': createdAt.toIso8601String(),
  };
}