import '../models/post.dart';
import '../models/post_image.dart';
import '../services/post_service.dart';

class PostRepository {
  final PostService _postService = PostService();

  Future<List<Post>> fetchPosts(
      {int limit = 10, int offset = 0, String? search}) async {
    final data = await _postService.fetchPosts(
        limit: limit, offset: offset, searchQuery: search);
    return data.map((item) {
      final images = (item['post_images'] as List<dynamic>?)
          ?.map((img) => PostImage.fromJson(img))
          .toList() ??
          [];
      return Post.fromJson(item, images: images);
    }).toList();
  }

  Future<Post?> getPostById(String id) async {
    final data = await _postService.fetchPostById(id);
    if (data == null) return null;
    final images = (data['post_images'] as List<dynamic>?)
        ?.map((img) => PostImage.fromJson(img))
        .toList() ??
        [];
    return Post.fromJson(data, images: images);
  }

  Future<Post> createPost(Map<String, dynamic> post) async {
    final data = await _postService.createPost(post);
    return Post.fromJson(data);
  }

  Future<void> updatePost(String id, Map<String, dynamic> updates) =>
      _postService.updatePost(id, updates);

  Future<void> deletePost(String id) => _postService.deletePost(id);

  Future<void> addPostImage(Map<String, dynamic> image) =>
      _postService.addPostImage(image);

  Future<void> deletePostImage(String id) => _postService.deletePostImage(id);
}