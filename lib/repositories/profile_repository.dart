import '../models/profile.dart';
import '../services/profile_service.dart';

class ProfileRepository {
  final ProfileService _profileService = ProfileService();

  Future<Profile?> getProfile(String userId) => _profileService.getProfile(userId);

  Future<void> upsertProfile(Profile profile) =>
      _profileService.upsertProfile(profile);

  Future<void> updateProfile(Map<String, dynamic> updates, String userId) =>
      _profileService.updateProfile(updates, userId);
}