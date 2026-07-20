import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _user = _authRepository.getCurrentUser();
    _authRepository.authStateChanges().listen((event) {
      if (event is AuthState) {
        if (event.event == AuthChangeEvent.signedIn) {
          _user = _authRepository.getCurrentUser();
          notifyListeners();
        } else if (event.event == AuthChangeEvent.signedOut) {
          _user = null;
          notifyListeners();
        }
      }
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _authRepository.login(email, password);
      _user = user;
      _isLoading = false;
      return user != null;
    } catch (e) {
      _error = e.toString();

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if email already exists
      final exists = await _authRepository.emailExists(email);

      if (exists) {
        _error = "An account with this email already exists.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _authRepository.register(email, password);

      _user = null;

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}