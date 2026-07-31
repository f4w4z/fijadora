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

  bool _showOnboarding = false;
  bool get showOnboarding => _showOnboarding;

  String? _signUpEmail;
  String? get signUpEmail => _signUpEmail;

  bool _isVerifyingOtp = false;
  bool get isVerifyingOtp => _isVerifyingOtp;

  DateTime? _lastSignInAt;
  DateTime? _lastSignUpAt;

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
        if (_showOnboarding) return;
        _isLoading = false;
        _errorMessage = null;
        if (_signUpJustCompleted && (user == null || user.emailConfirmedAt == null)) {
          return;
        }
        _user = user;
        if (user != null && user.emailConfirmedAt != null) {
          _signUpJustCompleted = false;
          _signUpEmail = null;
        }
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Something went wrong. Please try again.';
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
      if (_lastSignUpAt != null && DateTime.now().difference(_lastSignUpAt!).inSeconds < _cooldownDuration) {
        throw RateLimitExceeded(_cooldownDuration - DateTime.now().difference(_lastSignUpAt!).inSeconds);
      }
      await _authRepository.signUp(email: email, password: password, name: name, role: role);
      _lastSignUpAt = DateTime.now();
      _signUpEmail = email;
      _signUpJustCompleted = true;
      _startCooldown();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Could not create account. Please try again.';
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
      if (_lastSignInAt != null && DateTime.now().difference(_lastSignInAt!).inSeconds < _cooldownDuration) {
        throw RateLimitExceeded(_cooldownDuration - DateTime.now().difference(_lastSignInAt!).inSeconds);
      }
      await _authRepository.signIn(email: email, password: password);
      _lastSignInAt = DateTime.now();
    } catch (e) {
      _errorMessage = 'Invalid email or password.';
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
      await _authRepository.resendOtp(email: email);
      _startCooldown();
      notifyListeners();
    } catch (e) {
      if (e is RateLimitExceeded) rethrow;
      _errorMessage = 'Could not resend verification code.';
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyOtp({required String email, required String token}) async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.verifyOtp(email: email, token: token);
      _signUpJustCompleted = false;
      _signUpEmail = null;
      await _authRepository.refreshUser();
      _user = _authRepository.currentUser;
      _showOnboarding = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Invalid or expired code. Please try again.';
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void completeOnboarding() {
    _showOnboarding = false;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    await _authRepository.refreshUser();
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.signOut();
      _user = null;
      _signUpJustCompleted = false;
      _showOnboarding = false;
      _signUpEmail = null;
    } catch (e) {
      _errorMessage = 'Could not sign out.';
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
      _showOnboarding = false;
      _signUpEmail = null;
    } catch (e) {
      _errorMessage = 'Could not delete account.';
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
      _errorMessage = 'Could not send password reset email.';
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
      _errorMessage = 'Could not update password.';
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void resetVerification() {
    _signUpJustCompleted = false;
    _showOnboarding = false;
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
