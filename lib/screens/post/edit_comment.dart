import 'package:awais_blog/models/upload_task.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/upload_provider.dart';
import '../../models/comment.dart';

class EditComment extends StatefulWidget {
  final Comment comment;
  final String postId;
  const EditComment({super.key, required this.comment, required this.postId});

  @override
  State<EditComment> createState() => _EditCommentState();
}

class _EditCommentState extends State<EditComment> {
  late TextEditingController _textController;
  final Set<String> _deletedImageIds = {};
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.comment.content);
    // Verify ownership
    final auth = context.read<AuthProvider>();
    _isOwner = (auth.user?.id == widget.comment.userId);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If user is not logged in or not the owner, show a message
    if (!_isOwner) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('You cannot edit this comment.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    final uploadProvider = context.watch<UploadProvider>();
    final existingImages =
    widget.comment.images.where((img) => !_deletedImageIds.contains(img.id)).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit Comment', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Comment',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),

          if (existingImages.isNotEmpty) ...[
            Text('Current Images', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: existingImages
                  .map((img) => Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(img.imageUrl,
                        width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 24),
                      onPressed: () => setState(() => _deletedImageIds.add(img.id)),
                    ),
                  ),
                ],
              ))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          if (uploadProvider.tasks.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: uploadProvider.tasks.length,
                itemBuilder: (_, index) {
                  final task = uploadProvider.tasks[index];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            kIsWeb
                                ? Image.network(task.file.path, width: 80, height: 80, fit: BoxFit.cover)
                                : Image.file(File(task.file.path), width: 80, height: 80, fit: BoxFit.cover),
                            if (task.status == UploadStatus.uploading)
                              const CircularProgressIndicator(),
                            if (task.status == UploadStatus.error)
                              const Icon(Icons.error, color: Colors.red),
                          ],
                        ),
                      ),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 24),
                          onPressed: () => uploadProvider.removeImage(index),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => uploadProvider.pickImages(folder: widget.comment.id, bucket: 'comments'),
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Images'),
              ),
              ElevatedButton.icon(
                onPressed: (uploadProvider.isUploading || uploadProvider.hasError) ? null : () async {
                  final content = _textController.text.trim();
                  final hasSuccessfulNewImages = uploadProvider.tasks.any((t) => t.status == UploadStatus.complete);
                  if (content.isEmpty && existingImages.isEmpty && !hasSuccessfulNewImages) return;

                  final commentProvider = context.read<CommentProvider>();
                  final deleteImages = widget.comment.images
                      .where((img) => _deletedImageIds.contains(img.id))
                      .map((img) => {'id': img.id, 'storagePath': img.storagePath})
                      .toList();

                  final uploadedImages = uploadProvider.tasks
                      .where((t) => t.status == UploadStatus.complete)
                      .map((t) => {'url': t.url!, 'storagePath': t.storagePath!})
                      .toList();

                  // Close immediately for reactivity
                  Navigator.pop(context);
                  uploadProvider.clearSelection();

                  await commentProvider.updateComment(
                    widget.comment.id,
                    widget.postId,
                    content,
                    uploadedImages: uploadedImages,
                    deleteImages: deleteImages,
                  );
                },
                icon: uploadProvider.isUploading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(uploadProvider.hasError ? Icons.error_outline : Icons.check),
                label: Text(
                  uploadProvider.isUploading 
                      ? 'Uploading...' 
                      : (uploadProvider.hasError ? 'Fix Errors' : 'Update')
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}