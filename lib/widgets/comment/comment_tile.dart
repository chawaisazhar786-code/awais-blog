import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/comment.dart';
import '../../core/utils/relative_time.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/widgets/image_fullscreen.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CommentTile({
    super.key,
    required this.comment,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarWidget(
            imageUrl: comment.userAvatar,
            name: comment.userName ?? 'Anonymous',
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.userName ?? 'Anonymous',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(relativeTime(comment.createdAt)),
                    if (isOwner) ...[
                      const Spacer(),
                      GestureDetector(onTap: onEdit, child: const Icon(Icons.edit, size: 16)),
                      const SizedBox(width: 4),
                      GestureDetector(onTap: onDelete, child: const Icon(Icons.delete, size: 16)),
                    ],
                  ],
                ),
                if (comment.content.isNotEmpty) Text(comment.content),
                if (comment.images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: comment.images
                          .map((img) => GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ImageFullscreen(imageUrl: img.imageUrl))),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: img.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}