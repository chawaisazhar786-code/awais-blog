class PostImage {
  final String id;
  final String postId;
  final String imageUrl;
  final String storagePath;

  PostImage({
    required this.id,
    required this.postId,
    required this.imageUrl,
    required this.storagePath,
  });

  factory PostImage.fromJson(Map<String, dynamic> json) => PostImage(
    id: json['id'],
    postId: json['post_id'],
    imageUrl: json['image_url'],
    storagePath: json['storage_path'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'post_id': postId,
    'image_url': imageUrl,
    'storage_path': storagePath,
  };
}