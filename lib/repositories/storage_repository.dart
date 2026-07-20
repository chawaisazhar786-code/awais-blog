import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';

class StorageRepository {
  final StorageService _storageService = StorageService();

  Future<String> uploadImage(String bucket, XFile file, String? folder) =>
      _storageService.uploadImage(bucket, file, folder);

  Future<String> uploadAvatar(XFile file, String userId) =>
      _storageService.uploadImage('avatars', file, userId);

  Future<String> uploadPostImage(XFile file, String postId) =>
      _storageService.uploadImage('posts', file, postId);

  Future<String> uploadCommentImage(XFile file, String commentId) =>
      _storageService.uploadImage('comments', file, commentId);

  String getPublicUrl(String bucket, String filePath) =>
      _storageService.getPublicUrl(bucket, filePath);

  Future<void> deleteImage(String bucket, String filePath) =>
      _storageService.deleteImage(bucket, filePath);
}