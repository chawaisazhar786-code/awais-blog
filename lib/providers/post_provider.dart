import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';
import '../repositories/storage_repository.dart';

class PostProvider extends ChangeNotifier {
  final PostRepository _postRepository = PostRepository();
  final StorageRepository _storageRepository = StorageRepository();
  List<Post> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _error;
  String? _searchQuery;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get searchQuery => _searchQuery;

  Future<void> fetchPosts({bool refresh = false}) async {
    if (_isLoading || _isLoadingMore) return;

    if (refresh) {
      _offset = 0;
      _hasMore = true;
      _posts = [];
      _error = null;
    }
    if (_isLoadingMore || !_hasMore) return;
    _isLoading = _offset == 0;
    _isLoadingMore = _offset > 0;
    notifyListeners();

    try {
      final newPosts = await _postRepository.fetchPosts(
        limit: 10,
        offset: _offset,
        search: _searchQuery,
      );
      if (newPosts.length < 10) _hasMore = false;
      _posts = [..._posts, ...newPosts];
      _offset += newPosts.length;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<Post?> getPostById(String id) async {
    try {
      return await _postRepository.getPostById(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<Post?> createPost(
      String userId,
      String title,
      String content, {
        List<XFile>? images,
        List<Map<String, String>>? uploadedImages,
      }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final postId = const Uuid().v4();
      final post = await _postRepository.createPost({
        'id': postId,
        'user_id': userId,
        'title': title,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (images != null) {
        for (final file in images) {
          final filePath = await _storageRepository.uploadPostImage(file, postId);
          final url = _storageRepository.getPublicUrl('posts', filePath);
          await _postRepository.addPostImage({
            'id': const Uuid().v4(),
            'post_id': postId,
            'image_url': url,
            'storage_path': filePath,
          });
        }
      }

      if (uploadedImages != null) {
        for (final img in uploadedImages) {
          await _postRepository.addPostImage({
            'id': const Uuid().v4(),
            'post_id': postId,
            'image_url': img['url']!,
            'storage_path': img['storagePath']!,
          });
        }
      }

      await fetchPosts(refresh: true);
      _isLoading = false;
      notifyListeners();
      return post;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updatePost(
      String postId,
      String title,
      String content, {
        List<XFile>? newImages,
        List<Map<String, String>>? deleteImages,
      }) async {
    try {
      await _postRepository.updatePost(postId, {
        'title': title,
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (deleteImages != null) {
        for (final img in deleteImages) {
          await _storageRepository.deleteImage('posts', img['storagePath']!);
          await _postRepository.deletePostImage(img['id']!);
        }
      }

      if (newImages != null) {
        for (final file in newImages) {
          final filePath = await _storageRepository.uploadPostImage(file, postId);
          final url = _storageRepository.getPublicUrl('posts', filePath);
          await _postRepository.addPostImage({
            'id': const Uuid().v4(),
            'post_id': postId,
            'image_url': url,
            'storage_path': filePath,
          });
        }
      }

      await fetchPosts(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final post = _posts.firstWhere((p) => p.id == postId);
      for (final img in post.images) {
        await _storageRepository.deleteImage('posts', img.storagePath);
        await _postRepository.deletePostImage(img.id);
      }
      await _postRepository.deletePost(postId);
      _posts = _posts.where((p) => p.id != postId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> searchPosts(String query) async {
    _searchQuery = query.isEmpty ? null : query;
    await fetchPosts(refresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}