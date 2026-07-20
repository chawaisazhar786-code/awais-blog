import 'package:awais_blog/models/upload_task.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/upload_provider.dart';
import '../../core/widgets/app_button.dart';

class CreatePost extends StatefulWidget {
  const CreatePost({super.key});

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) {
        _showLoginRequiredDialog();
      } else {
        setState(() => _isCheckingAuth = false);
      }
    });
  }

  Future<void> _showLoginRequiredDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please log in to create a post.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Login'),
          ),
        ],
      ),
    );
    if (mounted) {
      if (result == true) {
        context.go('/login');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final postProvider = context.read<PostProvider>();
    final uploadProvider = context.read<UploadProvider>();

    if (uploadProvider.isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for images to finish uploading')),
      );
      return;
    }

    final uploadedImages = uploadProvider.tasks
        .where((t) => t.status == UploadStatus.complete)
        .map((t) => {'url': t.url!, 'storagePath': t.storagePath!})
        .toList();

    final post = await postProvider.createPost(
      auth.user!.id,
      _titleController.text.trim(),
      _contentController.text.trim(),
      uploadedImages: uploadedImages,
    );
    if (post != null && mounted) {
      uploadProvider.clearSelection();
      context.pop(true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create post')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (_isCheckingAuth || auth.user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final uploadProvider = context.watch<UploadProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Title required' : null,
            ),
            const SizedBox(height: 16),

            // Content field
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              maxLines: 8,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Content required' : null,
            ),
            const SizedBox(height: 16),

            // Image picker section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Images (${uploadProvider.selectedImages.length}/5)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...uploadProvider.tasks.asMap().entries.map((entry) {
                          final task = entry.value;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    kIsWeb
                                        ? Image.network(
                                            task.file.path,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(task.file.path),
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                    if (task.status == UploadStatus.uploading)
                                      Container(
                                        color: Colors.black26,
                                        width: 100,
                                        height: 100,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: task.progress,
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    if (task.status == UploadStatus.error)
                                      Container(
                                        color: Colors.red.withOpacity(0.4),
                                        width: 100,
                                        height: 100,
                                        child: const Icon(Icons.error, color: Colors.white),
                                      ),
                                    if (task.status == UploadStatus.complete)
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Positioned(
                                right: -4,
                                top: -4,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red, size: 24),
                                  onPressed: () => uploadProvider.removeImage(entry.key),
                                ),
                              ),
                            ],
                          );
                        }),
                        if (uploadProvider.canAddMore)
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add_a_photo,
                                  color: Theme.of(context).colorScheme.primary),
                              onPressed: () => uploadProvider.pickImages(folder: auth.user?.id),
                            ),
                          ),
                      ],
                    ),
                    if (!uploadProvider.canAddMore)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Maximum 5 images',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            AppButton(
              onPressed: (uploadProvider.isUploading || uploadProvider.hasError) ? null : _submit,
              text: uploadProvider.isUploading 
                  ? 'Uploading Images...' 
                  : (uploadProvider.hasError ? 'Fix Upload Errors' : 'Publish Post'),
              isLoading: context.watch<PostProvider>().isLoading,
            ),
          ],
        ),
      ),
    );
  }
}