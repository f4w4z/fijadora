import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../domain/models/app_user.dart';
import '../../../../domain/models/user_role.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authRepository) {
    _init();
  }

  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _subscription;

  AppUser? _user;
  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _init() {
    // Set initial user if repository has one synchronously
    _user = _authRepository.currentUser;

    _subscription = _authRepository.authStateChanges.listen(
      (user) {
        _user = user;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();
    try {
      _user = await _authRepository.signInWithEmail(email: email, password: password);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    debugPrint('AUTHVM: signUp called email=$email role=$role');
    _setLoading(true);
    _clearError();
    try {
      _user = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      debugPrint('AUTHVM: signUpWithEmail succeeded userId=${_user?.id}');
    } catch (e) {
      debugPrint('AUTHVM: signUpWithEmail failed: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
      debugPrint('AUTHVM: signUp finished, isLoading=false');
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.sendPasswordResetEmail(email: email);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resendVerification() async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.resendVerificationEmail();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.updatePassword(newPassword: newPassword);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// Riverpod Provider for AuthViewModel using ChangeNotifierProvider
final authViewModelProvider = ChangeNotifierProvider<AuthViewModel>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthViewModel(repository);
});
