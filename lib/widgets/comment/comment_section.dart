import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/auth_provider.dart';
import 'comment_tile.dart';
import '../../screens/post/edit_comment.dart';
import '../../core/widgets/empty_widget.dart';

class CommentSection extends StatelessWidget {
  final String postId;
  const CommentSection({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<CommentProvider>(
      builder: (context, commentProvider, child) {
        final auth = context.watch<AuthProvider>();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Comments', style: theme.textTheme.titleMedium),
            ),

            if (commentProvider.isLoading && commentProvider.comments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              ...commentProvider.comments.map((comment) => CommentTile(
                key: ValueKey(comment.id),
                comment: comment,
                isOwner: auth.user?.id == comment.userId,
                onEdit: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => EditComment(comment: comment, postId: postId),
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
                    context.read<CommentProvider>().deleteComment(comment.id, postId);
                  }
                },
              )),

              if (commentProvider.comments.isEmpty && !commentProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: EmptyWidget(message: 'No comments yet. Be the first to comment!'),
                ),
              
              if (commentProvider.isLoading && commentProvider.comments.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: LinearProgressIndicator()),
                ),
            ],
          ],
        );
      },
    );
  }
}
