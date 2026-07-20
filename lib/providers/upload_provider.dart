import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/upload_task.dart';
import '../repositories/storage_repository.dart';

class UploadProvider extends ChangeNotifier {
  final StorageRepository _storageRepository = StorageRepository();
  final List<UploadTask> _tasks = [];
  final ImagePicker _picker = ImagePicker();
  static const int maxImages = 5;

  List<UploadTask> get tasks => _tasks;
  List<XFile> get selectedImages => _tasks.map((t) => t.file).toList();
  bool get canAddMore => _tasks.length < maxImages;
  bool get isUploading => _tasks.any((t) => t.status == UploadStatus.uploading || t.status == UploadStatus.pending);
  bool get hasError => _tasks.any((t) => t.status == UploadStatus.error);

  Future<void> pickImages({String? folder, String bucket = 'posts'}) async {
    if (!canAddMore) return;
    final List<XFile>? files = await _picker.pickMultiImage(
      imageQuality: 85,
      limit: maxImages - _tasks.length,
    );
    if (files != null) {
      for (final xFile in files) {
        final task = UploadTask(file: xFile);
        _tasks.add(task);
        _startUpload(task, folder, bucket);
      }
      notifyListeners();
    }
  }

  Future<void> _startUpload(UploadTask task, String? folder, String bucket) async {
    task.status = UploadStatus.uploading;
    task.progress = 0.1;
    notifyListeners();

    try {
      final path = await _storageRepository.uploadImage(bucket, task.file, folder);
      task.storagePath = path;
      task.url = _storageRepository.getPublicUrl(bucket, path);
      task.status = UploadStatus.complete;
      task.progress = 1.0;
    } catch (e) {
      task.status = UploadStatus.error;
      task.error = e.toString();
      print('Upload failed: $e');
    }
    notifyListeners();
  }

  void removeImage(int index) {
    _tasks.removeAt(index);
    notifyListeners();
  }

  void clearSelection() {
    _tasks.clear();
    notifyListeners();
  }
}
