import 'post_image.dart';

class Post {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PostImage> images;
  final int? commentCount;
  final String? authorName;
  final String? authorAvatar;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
    this.commentCount,
    this.authorName,
    this.authorAvatar,
  });

  factory Post.fromJson(Map<String, dynamic> json, {List<PostImage>? images}) {
    final commentsData = json['comments'];
    int? count;
    if (commentsData is List && commentsData.isNotEmpty) {
      count = commentsData[0]['count'];
    } else if (commentsData is Map) {
      count = commentsData['count'];
    }

    return Post(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      images: images ?? [],
      commentCount: count,
      authorName: json['profiles']?['name'],
      authorAvatar: json['profiles']?['avatar_url'],
    );
  }

  Post copyWith({String? authorName, String? authorAvatar}) {
    return Post(
      id: id,
      userId: userId,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      images: images,
      commentCount: commentCount,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
    );
  }
}