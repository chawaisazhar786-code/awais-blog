import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import 'post_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts();
      _authProvider = context.read<AuthProvider>();
      _authProvider?.addListener(_onAuthChanged);
    });
  }

  void _onAuthChanged() {
    if (mounted) {
      context.read<PostProvider>().fetchPosts(refresh: true);
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<PostProvider>().searchPosts(query);
    });
  }

  Future<void> _handleFABPress() async {
    _searchFocusNode.unfocus();
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You need to log in to create a post.'),
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
      if (result == true && mounted) {
        await context.push('/login');
      }
    } else {
      await context.push('/create-post');
      if (mounted) context.read<PostProvider>().fetchPosts(refresh: true);
    }
  }

  Future<void> _handleLogout() async {
    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      auth.logout();
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.user != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BlogForum'),
        actions: isLoggedIn
            ? [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              _searchFocusNode.unfocus();
              await context.push('/profile');
              if (mounted) context.read<PostProvider>().fetchPosts(refresh: true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _searchFocusNode.unfocus();
              _handleLogout();
            },
          ),
        ]
            : [
          TextButton(
            onPressed: () async {
              _searchFocusNode.unfocus();
              await context.push('/login');
            },
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () async {
              _searchFocusNode.unfocus();
              await context.push('/register');
            },
            child: const Text('Sign Up'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search posts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<PostProvider>().fetchPosts(refresh: true),
        child: const PostList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleFABPress,
        child: const Icon(Icons.add),
      ),
    );
  }
}