import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile.dart';
import '../repositories/profile_repository.dart';
import '../repositories/storage_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _profileRepository = ProfileRepository();
  final StorageRepository _storageRepository = StorageRepository();
  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await _profileRepository.getProfile(userId);
    } catch (e, stack) {
      print(e.toString());
      print(stack.toString());
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createInitialProfile(
      String userId, String email, String name) async {
    final profile = Profile(
      id: userId,
      name: name.isEmpty ? email.split('@').first : name,
      email: email,
      avatarUrl: null,
      avatarStoragePath: null,
      createdAt: DateTime.now(),
    );
    await _profileRepository.upsertProfile(profile);
    _profile = profile;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String userId,
    String? name,
    XFile? avatarFile,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;

      if (avatarFile != null) {
        if (_profile?.avatarStoragePath != null) {
          await _storageRepository.deleteImage('avatars', _profile!.avatarStoragePath!);
        }
        final filePath = await _storageRepository.uploadAvatar(avatarFile, userId);
        final url = _storageRepository.getPublicUrl('avatars', filePath);
        updates['avatar_url'] = url;
        updates['avatar_storage_path'] = filePath;
      }

      await _profileRepository.updateProfile(updates, userId);
      _profile = await _profileRepository.getProfile(userId);
    } catch (e, stack) {
      print(e.toString());
      print(stack.toString());
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
