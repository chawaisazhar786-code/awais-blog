import 'dart:typed_data';
import 'package:awais_blog/models/upload_task.dart';
import 'package:awais_blog/providers/post_provider.dart';
import 'package:awais_blog/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/upload_provider.dart';
import '../../widgets/comment/comment_tile.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/empty_widget.dart';
import '../../core/widgets/image_fullscreen.dart';
import '../../core/widgets/hero_image.dart';
import '../../core/utils/relative_time.dart';
import 'edit_comment.dart';

class PostDetail extends StatefulWidget {
  final String postId;
  const PostDetail({super.key, required this.postId});

  @override
  State<PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {

  final PageController _pageController = PageController();
  Post? _post;
  bool _isLoading = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPost();
    final commentProvider = context.read<CommentProvider>();
    commentProvider.clearComments(); // Clear stale comments
    commentProvider.fetchComments(widget.postId);
    
    // Add listener for errors
    commentProvider.addListener(_onCommentError);

    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      context.read<ProfileProvider>().loadProfile(auth.user!.id);
    }
  }

  void _onCommentError() {
    final error = context.read<CommentProvider>().error;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Clear',
            textColor: Colors.white,
            onPressed: () => context.read<CommentProvider>().clearError(),
          ),
        ),
      );
    }
  }

  Future<void> _loadPost() async {
    final post = await context.read<PostProvider>().getPostById(widget.postId);
    if (mounted) {
      setState(() {
        _post = post;
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await context.read<PostProvider>().deletePost(widget.postId);
      if (success && mounted) context.go('/home');
    }
  }

  @override
  void dispose() {
    context.read<CommentProvider>().removeListener(_onCommentError);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentProvider = context.watch<CommentProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    if (_isLoading) return const Scaffold(body: LoadingWidget());
    if (_post == null) return const Scaffold(body: EmptyWidget(message: 'Post not found'));

    final post = _post!;
    final isOwner = auth.user?.id == post.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/edit-post/${post.id}'),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePost,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image gallery
                  if (post.images.isNotEmpty)
                    SizedBox(
                      height: 250,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: post.images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            itemBuilder: (_, index) => GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ImageFullscreen(
                                    imageUrl: post.images[index].imageUrl,
                                  ),
                                ),
                              ),
                              child: HeroImage(
                                tag: post.images[index].imageUrl,
                                imageUrl: post.images[index].imageUrl,
                              ),
                            ),
                          ),

                          // Previous button
                          if (post.images.length > 1 && _currentPage > 0)
                            Positioned(
                              left: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      _pageController.previousPage(
                                        duration: const Duration(milliseconds: 250),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                          // Next button
                          if (post.images.length > 1 &&
                              _currentPage < post.images.length - 1)
                            Positioned(
                              right: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      _pageController.nextPage(
                                        duration: const Duration(milliseconds: 250),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(post.title, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),

                        // Author row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: post.authorAvatar != null
                                  ? CachedNetworkImageProvider(post.authorAvatar!)
                                  : null,
                              child: post.authorAvatar == null
                                  ? Text(post.authorName?.isNotEmpty == true
                                  ? post.authorName![0].toUpperCase()
                                  : '?')
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(post.authorName ?? 'Anonymous')),
                            const Spacer(),
                            Text(relativeTime(post.createdAt),
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Content
                        Text(post.content),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Comments header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Comments', style: theme.textTheme.titleMedium),
                  ),

                  // Comments list
                  ...commentProvider.comments.map((comment) => CommentTile(
                    comment: comment,
                    isOwner: auth.user?.id == comment.userId,
                    onEdit: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => EditComment(comment: comment, postId: widget.postId),
                    ),
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Comment'),
                          content: const Text('Are you sure?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        context.read<CommentProvider>().deleteComment(comment.id, widget.postId);
                      }
                    },
                  )),

                  if (commentProvider.comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: EmptyWidget(message: 'No comments yet'),
                    ),
                ],
              ),
            ),
          ),

          // Comment input area (sticky at bottom)
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: _buildCommentInput(theme, auth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(ThemeData theme, AuthProvider auth) {
    if (auth.user == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.grey),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Log in to leave a comment',
                  style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }

    return CommentInputWidget(postId: widget.postId);
  }
}

class CommentInputWidget extends StatefulWidget {
  final String postId;
  const CommentInputWidget({super.key, required this.postId});

  @override
  State<CommentInputWidget> createState() => _CommentInputWidgetState();
}

class _CommentInputWidgetState extends State<CommentInputWidget> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadProvider = context.watch<UploadProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.image_outlined),
                onPressed: () => uploadProvider.pickImages(folder: widget.postId, bucket: 'comments'),
                tooltip: 'Attach images',
              ),
            ],
          ),
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
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              FutureBuilder<Uint8List>(
                                future: task.file.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const SizedBox(
                                      width: 70,
                                      height: 70,
                                      child: Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    );
                                  }

                                  return Image.memory(
                                    snapshot.data!,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                              if (task.status == UploadStatus.uploading)
                                Container(
                                  color: Colors.black26,
                                  width: 70,
                                  height: 70,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              if (task.status == UploadStatus.error)
                                const Icon(Icons.error, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                          onPressed: () => uploadProvider.removeImage(index),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          if (uploadProvider.tasks.isNotEmpty ||
              _textController.text.trim().isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: (uploadProvider.isUploading || uploadProvider.hasError) ? null : () async {
                  final content = _textController.text.trim();
                  final hasSuccessfulUploads = uploadProvider.tasks.any((t) => t.status == UploadStatus.complete);
                  
                  if (content.isEmpty && !hasSuccessfulUploads) return;
                  
                  final commentProvider = context.read<CommentProvider>();
                  final auth = context.read<AuthProvider>();
                  
                  // Clear input immediately for reactivity
                  _textController.clear();
                  uploadProvider.clearSelection();

                  final uploadedImages = uploadProvider.tasks
                      .where((t) => t.status == UploadStatus.complete)
                      .map((t) => {'url': t.url!, 'storagePath': t.storagePath!})
                      .toList();

                  final profile = profileProvider.profile;

                  await commentProvider.createComment(
                    widget.postId,
                    auth.user!.id,
                    content,
                    uploadedImages: uploadedImages,
                    userName: profile?.name,
                    userAvatar: profile?.avatarUrl,
                  );
                },
                icon: uploadProvider.isUploading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : Icon(uploadProvider.hasError ? Icons.error_outline : Icons.send),
                label: Text(
                  uploadProvider.isUploading 
                      ? 'Uploading...' 
                      : (uploadProvider.hasError ? 'Fix Errors' : 'Send')
                ),
              ),
            ),
        ],
      ),
    );
  }
}