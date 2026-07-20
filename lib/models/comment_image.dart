class CommentImage {
  final String id;
  final String commentId;
  final String imageUrl;
  final String storagePath;

  CommentImage({
    required this.id,
    required this.commentId,
    required this.imageUrl,
    required this.storagePath,
  });

  factory CommentImage.fromJson(Map<String, dynamic> json) => CommentImage(
    id: json['id'],
    commentId: json['comment_id'],
    imageUrl: json['image_url'],
    storagePath: json['storage_path'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'comment_id': commentId,
    'image_url': imageUrl,
    'storage_path': storagePath,
  };
}