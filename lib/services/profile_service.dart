import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ProfileService {
  final SupabaseClient client = Supabase.instance.client;

  Future<Profile?> getProfile(String userId) async {
    final data = await client.from('profiles').select().eq('id', userId).maybeSingle();
    if (data != null) return Profile.fromJson(data);
    return null;
  }

  Future<void> upsertProfile(Profile profile) async {
    await client.from('profiles').upsert(profile.toJson());
  }

  Future<void> updateProfile(Map<String, dynamic> updates, String userId) async {
    await client.from('profiles').update(updates).eq('id', userId);
  }
}