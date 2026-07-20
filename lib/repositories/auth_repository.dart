import '../services/auth_service.dart';
import '../models/app_user.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  Future<AppUser?> login(String email, String password) =>
      _authService.signInWithEmail(email, password);

  Future<AppUser?> register(String email, String password) =>
      _authService.signUpWithEmail(email, password);

  Future<bool> emailExists(String email) =>
      _authService.emailExists(email);

  Future<void> logout() => _authService.signOut();

  AppUser? getCurrentUser() => _authService.currentUser();

  Stream<dynamic> authStateChanges() => _authService.authStateChanges;
}