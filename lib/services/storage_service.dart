import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final SupabaseClient client = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<String> uploadImage(String bucket, XFile file, String? folder) async {
    final bytes = await file.readAsBytes();
    final mimeType = lookupMimeType(file.name) ?? 'image/jpeg';
    final extension = mimeType.split('/').last;
    final fileName = '${_uuid.v4()}.$extension';
    final filePath = folder != null ? '$folder/$fileName' : fileName;

    await client.storage.from(bucket).uploadBinary(
      filePath,
      bytes,
      fileOptions: FileOptions(
        contentType: mimeType,
        upsert: false,
      ),
    );

    return filePath;
  }

  String getPublicUrl(String bucket, String filePath) {
    return client.storage.from(bucket).getPublicUrl(filePath);
  }

  Future<void> deleteImage(String bucket, String filePath) async {
    await client.storage.from(bucket).remove([filePath]);
  }
}