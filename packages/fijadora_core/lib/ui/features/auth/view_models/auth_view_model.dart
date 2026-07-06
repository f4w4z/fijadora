import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../domain/models/app_user.dart';
import '../../../../domain/models/user_role.dart';

class RateLimitExceeded implements Exception {
  final int secondsRemaining;
  RateLimitExceeded(this.secondsRemaining);
}

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

  bool _signUpJustCompleted = false;
  bool get signUpJustCompleted => _signUpJustCompleted;

  String? _signUpEmail;
  String? get signUpEmail => _signUpEmail;

  @Deprecated('Use signUpJustCompleted instead')
  bool get needsEmailVerification => _signUpJustCompleted;

  int _cooldownSeconds = 0;
  int get cooldownSeconds => _cooldownSeconds;

  DateTime? _lastSentAt;

  static const int _cooldownDuration = 30;

  void _startCooldown() {
    _lastSentAt = DateTime.now();
    _cooldownSeconds = _cooldownDuration;
    notifyListeners();
    _tickCooldown();
  }

  void _tickCooldown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_lastSentAt == null) return;
      final elapsed = DateTime.now().difference(_lastSentAt!).inSeconds;
      final remaining = _cooldownDuration - elapsed;
      if (remaining > 0) {
        _cooldownSeconds = remaining;
        notifyListeners();
        _tickCooldown();
      } else {
        _cooldownSeconds = 0;
        notifyListeners();
      }
    });
  }

  void _init() {
    _user = _authRepository.currentUser;
    _subscription = _authRepository.authStateChanges.listen(
      (user) {
        final wasSignUpMode = _signUpJustCompleted;
        _user = user;
        _isLoading = false;
        _errorMessage = null;
        if (user != null && user.emailConfirmedAt != null) {
          _signUpJustCompleted = false;
          _signUpEmail = null;
        }
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.signUp(email: email, password: password, name: name, role: role);
      _signUpEmail = email;
      _signUpJustCompleted = true;
      _startCooldown();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.signIn(email: email, password: password);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resendVerification({required String email}) async {
    if (_lastSentAt != null) {
      final elapsed = DateTime.now().difference(_lastSentAt!).inSeconds;
      if (elapsed < _cooldownDuration) {
        throw RateLimitExceeded(_cooldownDuration - elapsed);
      }
    }
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.resendEmailVerification(email: email);
      _startCooldown();
      notifyListeners();
    } catch (e) {
      if (e is RateLimitExceeded) rethrow;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.signOut();
      _user = null;
      _signUpJustCompleted = false;
      _signUpEmail = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.deleteAccount();
      _user = null;
      _signUpJustCompleted = false;
      _signUpEmail = null;
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

  void resetVerification() {
    _signUpJustCompleted = false;
    _signUpEmail = null;
    notifyListeners();
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

final authViewModelProvider = ChangeNotifierProvider<AuthViewModel>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthViewModel(repository);
});
