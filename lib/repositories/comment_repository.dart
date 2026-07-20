import '../models/comment.dart';
import '../models/comment_image.dart';
import '../services/comment_service.dart';

class CommentRepository {
  final CommentService _commentService = CommentService();

  Future<List<Comment>> fetchComments(String postId) async {
    final data = await _commentService.fetchComments(postId);
    return data.map((item) {
      final images = (item['comment_images'] as List<dynamic>?)
          ?.map((img) => CommentImage.fromJson(img))
          .toList() ??
          [];
      return Comment.fromJson(item, images: images);
    }).toList();
  }

  Future<Comment> createComment(Map<String, dynamic> comment) async {
    final data = await _commentService.createComment(comment);
    return Comment.fromJson(data);
  }

  Future<void> updateComment(String id, Map<String, dynamic> updates) =>
      _commentService.updateComment(id, updates);

  Future<void> deleteComment(String id) => _commentService.deleteComment(id);

  Future<void> addCommentImage(Map<String, dynamic> image) =>
      _commentService.addCommentImage(image);

  Future<void> deleteCommentImage(String id) =>
      _commentService.deleteCommentImage(id);
}