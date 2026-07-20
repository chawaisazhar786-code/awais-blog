import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/post_provider.dart';
import '../../widgets/post/post_card.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/empty_widget.dart';
import '../../core/widgets/error_widget.dart';

class PostList extends StatefulWidget {
  const PostList({super.key});

  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final postProvider = context.read<PostProvider>();
      if (!postProvider.isLoadingMore && postProvider.hasMore) {
        postProvider.fetchPosts();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();

    if (postProvider.isLoading && postProvider.posts.isEmpty) {
      return const LoadingWidget();
    }

    if (postProvider.error != null && postProvider.posts.isEmpty) {
      return AppErrorWidget(
        message: postProvider.error!,
        onRetry: () => postProvider.fetchPosts(refresh: true),
      );
    }

    if (postProvider.posts.isEmpty) {
      return const EmptyWidget(message: 'No posts yet');
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: postProvider.posts.length + (postProvider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == postProvider.posts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final post = postProvider.posts[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: PostCard(
            post: post,
            onTap: () async {
              FocusScope.of(context).unfocus();
              await context.push('/post/${post.id}');
              if (mounted) {
                context.read<PostProvider>().fetchPosts(refresh: true);
              }
            },
          ),
        );
      },
    );
  }
}