# Blog Forum - Flutter App

A complete Flutter blog/forum application with authentication, posts, comments, image uploads, and profiles.

**Tech Stack:** Flutter, Provider, GoRouter, Supabase.

## Features
- Email/password authentication
- CRUD posts with multiple images
- CRUD comments with multiple images
- User profile with avatar
- Pagination (infinite scroll)
- Search posts by title
- Pull-to-refresh
- Hero animations, fullscreen image viewer
- Responsive design (mobile/web)
- Dark theme support
- Real-time form validation
- Environment variables

## Folder Structure (follows Feature + Service architecture)

lib/
├── main.dart
├── app.dart
├── config/
├── core/
├── models/
├── providers/
├── repositories/
├── screens/
├── services/
└── widgets/

## Deployment
Build for web: `flutter build web`