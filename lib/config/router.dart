import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/post/post_detail.dart';
import '../screens/post/create_post.dart';
import '../screens/post/edit_post.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/post/:id',
      builder: (_, state) => PostDetail(postId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/create-post', builder: (_, __) => const CreatePost()),
    GoRoute(
      path: '/edit-post/:id',
      builder: (_, state) => EditPost(postId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfile()),
  ],
);