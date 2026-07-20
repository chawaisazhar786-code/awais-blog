import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

class AuthService {
  final SupabaseClient client = Supabase.instance.client;

  Future<AppUser?> signUpWithEmail(String email, String password) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        return AppUser(
          id: user.id,
          email: user.email ?? email,
        );
      }

      return null;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<AppUser?> signInWithEmail(String email, String password) async {
    final response =
    await client.auth.signInWithPassword(email: email, password: password);
    final user = response.user;
    if (user != null) {
      return AppUser(id: user.id, email: user.email ?? email);
    }
    return null;
  }

  Future<bool> emailExists(String email) async {
    final result = await client.rpc(
      'email_exists',
      params: {
        'email_to_check': email,
      },
    );

    return result == true;
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  AppUser? currentUser() {
    final user = client.auth.currentUser;
    if (user != null) {
      return AppUser(id: user.id, email: user.email ?? '');
    }
    return null;
  }

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}