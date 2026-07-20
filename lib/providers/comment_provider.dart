import 'package:awais_blog/models/comment_image.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/comment.dart';
import '../repositories/comment_repository.dart';
import '../repositories/storage_repository.dart';

class CommentProvider extends ChangeNotifier {
  final CommentRepository _commentRepository = CommentRepository();
  final StorageRepository _storageRepository = StorageRepository();
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearComments() {
    _comments = [];
    _error = null;
    notifyListeners();
  }

  Future<void> fetchComments(String postId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _comments = await _commentRepository.fetchComments(postId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createComment(
      String postId,
      String userId,
      String content, {
        List<XFile>? images,
        List<Map<String, String>>? uploadedImages,
        String? userName,
        String? userAvatar,
      }) async {
    final tempId = const Uuid().v4();
    final tempComment = Comment(
      id: tempId,
      postId: postId,
      userId: userId,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userName: userName,
      userAvatar: userAvatar,
      images: uploadedImages?.map((img) => CommentImage(
        id: const Uuid().v4(),
        commentId: tempId,
        imageUrl: img['url']!,
        storagePath: img['storagePath']!,
      )).toList() ?? [],
    );

    // Optimistic update
    _comments = [..._comments, tempComment];
    notifyListeners();

    try {
      await _commentRepository.createComment({
        'id': tempId,
        'post_id': postId,
        'user_id': userId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (images != null) {
        for (final file in images) {
          final filePath =
          await _storageRepository.uploadCommentImage(file, tempId);
          final url = _storageRepository.getPublicUrl('comments', filePath);
          await _commentRepository.addCommentImage({
            'id': const Uuid().v4(),
            'comment_id': tempId,
            'image_url': url,
            'storage_path': filePath,
          });
        }
      }

      if (uploadedImages != null) {
        for (final img in uploadedImages) {
          await _commentRepository.addCommentImage({
            'id': const Uuid().v4(),
            'comment_id': tempId,
            'image_url': img['url']!,
            'storage_path': img['storagePath']!,
          });
        }
      }

      return true;
    } catch (e) {
      _error = e.toString();
      // Revert optimistic update
      _comments = _comments.where((c) => c.id != tempId).toList();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateComment(
      String commentId,
      String postId,
      String content, {
        List<XFile>? newImages,
        List<Map<String, String>>? uploadedImages,
        List<Map<String, String>>? deleteImages,
      }) async {
    final originalComments = List<Comment>.from(_comments);
    final index = _comments.indexWhere((c) => c.id == commentId);
    
    if (index != -1) {
      _comments = [
        for (var c in _comments)
          if (c.id == commentId)
            c.copyWith(content: content, updatedAt: DateTime.now())
          else
            c
      ];
      notifyListeners();
    }

    try {
      await _commentRepository.updateComment(commentId, {
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (deleteImages != null) {
        for (final img in deleteImages) {
          await _storageRepository.deleteImage('comments', img['storagePath']!);
          await _commentRepository.deleteCommentImage(img['id']!);
        }
      }

      if (newImages != null) {
        for (final file in newImages) {
          final filePath =
          await _storageRepository.uploadCommentImage(file, commentId);
          final url = _storageRepository.getPublicUrl('comments', filePath);
          await _commentRepository.addCommentImage({
            'id': const Uuid().v4(),
            'comment_id': commentId,
            'image_url': url,
            'storage_path': filePath,
          });
        }
      }

      if (uploadedImages != null) {
        for (final img in uploadedImages) {
          await _commentRepository.addCommentImage({
            'id': const Uuid().v4(),
            'comment_id': commentId,
            'image_url': img['url']!,
            'storage_path': img['storagePath']!,
          });
        }
      }

      return true;
    } catch (e) {
      _error = e.toString();
      // Revert optimistic update
      _comments = originalComments;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComment(String commentId, String postId) async {
    final originalComments = List<Comment>.from(_comments);
    final commentToDelete = _comments.firstWhere((c) => c.id == commentId);

    // Optimistic delete
    _comments = _comments.where((c) => c.id != commentId).toList();
    notifyListeners();

    try {
      for (final img in commentToDelete.images) {
        await _storageRepository.deleteImage('comments', img.storagePath);
        await _commentRepository.deleteCommentImage(img.id);
      }
      await _commentRepository.deleteComment(commentId);
      return true;
    } catch (e) {
      _error = e.toString();
      // Revert optimistic update
      _comments = originalComments;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}