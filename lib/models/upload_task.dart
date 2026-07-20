import 'package:image_picker/image_picker.dart';

enum UploadStatus { pending, uploading, complete, error }

class UploadTask {
  final XFile file;
  UploadStatus status;
  double progress;
  String? url;
  String? storagePath;
  String? error;

  UploadTask({
    required this.file,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.url,
    this.storagePath,
    this.error,
  });
}
