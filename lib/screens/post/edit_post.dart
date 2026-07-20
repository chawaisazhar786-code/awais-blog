import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/upload_provider.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/loading_widget.dart';

class EditPost extends StatefulWidget {
  final String postId;
  const EditPost({super.key, required this.postId});

  @override
  State<EditPost> createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  Post? _post;
  bool _isLoading = true;
  final Set<String> _deletedImageIds = {};
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _checkAccessAndLoadPost();
  }

  Future<void> _checkAccessAndLoadPost() async {
    final auth = context.read<AuthProvider>();
    final post = await context.read<PostProvider>().getPostById(widget.postId);

    if (!mounted) return;
    if (auth.user == null || post == null || auth.user!.id != post.userId) {
      // Not authorized: show dialog and go back
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Access Denied'),
          content: const Text('You cannot edit this post.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/home');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _post = post;
      _isOwner = true;
      _titleController.text = post.title;
      _contentController.text = post.content;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _post == null || !_isOwner) return;
    final postProvider = context.read<PostProvider>();
    final uploadProvider = context.read<UploadProvider>();

    final deleteImages = _post!.images
        .where((img) => _deletedImageIds.contains(img.id))
        .map((img) => {'id': img.id, 'storagePath': img.storagePath})
        .toList();

    final success = await postProvider.updatePost(
      widget.postId,
      _titleController.text.trim(),
      _contentController.text.trim(),
      newImages: uploadProvider.selectedImages,
      deleteImages: deleteImages,
    );
    if (success && mounted) {
      uploadProvider.clearSelection();
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update post')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget());
    }
    if (!_isOwner || _post == null) {
      return const Scaffold(
        body: Center(child: Text('Post not found or you do not have permission.')),
      );
    }

    final uploadProvider = context.watch<UploadProvider>();
    final existingImages =
    _post!.images.where((img) => !_deletedImageIds.contains(img.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Title required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              maxLines: 8,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Content required' : null,
            ),
            const SizedBox(height: 16),

            // Existing Images
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
                          width: 100, height: 100, fit: BoxFit.cover),
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
              const SizedBox(height: 16),
            ],

            // New Images
            Text('Add New Images', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
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
                            child: kIsWeb
                                ? Image.network(task.file.path,
                                    width: 100, height: 100, fit: BoxFit.cover)
                                : Image.file(File(task.file.path),
                                    width: 100, height: 100, fit: BoxFit.cover),
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
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.add_a_photo,
                              color: Theme.of(context).colorScheme.primary),
                          onPressed: uploadProvider.pickImages,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!uploadProvider.canAddMore && uploadProvider.selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Maximum 5 images',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 24),
            AppButton(
              onPressed: _submit,
              text: 'Update Post',
              isLoading: context.watch<PostProvider>().isLoading,
            ),
          ],
        ),
      ),
    );
  }
}