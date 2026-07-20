import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/post.dart';
import '../../core/utils/relative_time.dart';
import '../../core/widgets/hero_image.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  const PostCard({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.images.isNotEmpty)
              HeroImage(
                tag: post.images.first.imageUrl,
                imageUrl: post.images.first.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: post.authorAvatar != null
                            ? CachedNetworkImageProvider(post.authorAvatar!)
                            : null,
                        child: post.authorAvatar == null
                            ? Text(post.authorName?.isNotEmpty == true ? post.authorName![0] : '?')
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(post.authorName ?? 'Anonymous'),
                      const Spacer(),
                      Text(relativeTime(post.createdAt)),
                      const SizedBox(width: 8),
                      const Icon(Icons.comment, size: 16),
                      const SizedBox(width: 4),
                      Text('${post.commentCount ?? 0}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}