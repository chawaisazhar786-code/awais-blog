import 'comment_image.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CommentImage> images;
  final String? userName;
  final String? userAvatar;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
    this.userName,
    this.userAvatar,
  });

  factory Comment.fromJson(Map<String, dynamic> json,
      {List<CommentImage>? images}) {
    return Comment(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      images: images ?? [],
      userName: json['profiles'] != null ? json['profiles']['name'] : null,
      userAvatar:
      json['profiles'] != null ? json['profiles']['avatar_url'] : null,
    );
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CommentImage>? images,
    String? userName,
    String? userAvatar,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
    );
  }
}
