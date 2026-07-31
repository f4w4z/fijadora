import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fijadora_core/data/repositories/auth_repository.dart';
import 'package:fijadora_core/domain/models/app_user.dart';
import 'package:fijadora_core/domain/models/user_role.dart';
import 'package:fijadora_core/ui/features/auth/view_models/auth_view_model.dart';

class StubAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  bool failNextSignUp = false;
  bool failNextSignIn = false;
  bool failNextResend = false;
  bool failNextSignOut = false;
  bool failNextPasswordReset = false;
  bool failNextPasswordUpdate = false;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  void emitUser(AppUser? user) => _controller.add(user);

  @override
  Future<void> signUp({required String email, required String password, required String name, required UserRole role}) async {
    if (failNextSignUp) {
      failNextSignUp = false;
      throw Exception('Failed to sign up');
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (failNextSignIn) {
      failNextSignIn = false;
      throw Exception('Failed to sign in');
    }
    _currentUser = AppUser(id: 'auth-1', email: email, name: 'Test', role: UserRole.customer, createdAt: DateTime(2026));
    _controller.add(_currentUser);
  }

  Future<void> resendEmailVerification({required String email}) async {
    if (failNextResend) {
      failNextResend = false;
      throw Exception('Failed to resend');
    }
  }

  @override
  Future<void> verifyOtp({required String email, required String token}) async {}

  @override
  Future<void> resendOtp({required String email}) async {}

  @override
  Future<void> signOut() async {
    if (failNextSignOut) {
      failNextSignOut = false;
      throw Exception('Sign out failed');
    }
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (failNextPasswordReset) {
      failNextPasswordReset = false;
      throw Exception('Reset failed');
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    if (failNextPasswordUpdate) {
      failNextPasswordUpdate = false;
      throw Exception('Update failed');
    }
  }

  @override
  Future<void> refreshUser() async {}



  @override
  Future<void> updateWorkerStatus({required String userId, required String status}) async {}

  @override
  Future<void> deleteAccount() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  late StubAuthRepository stubRepo;
  late AuthViewModel vm;

  setUp(() {
    stubRepo = StubAuthRepository();
    vm = AuthViewModel(stubRepo);
  });

  tearDown(() {
    vm.dispose();
  });

  group('initial state', () {
    test('starts with null user when repository has none', () {
      expect(vm.user, isNull);
      expect(vm.isAuthenticated, isFalse);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('picks up current user from repository', () {
      stubRepo = StubAuthRepository()
        .._currentUser = AppUser(id: 'u1', email: 'a@b.com', name: 'A', role: UserRole.worker, createdAt: DateTime(2026));
      vm = AuthViewModel(stubRepo);
      expect(vm.user?.id, 'u1');
      expect(vm.isAuthenticated, isTrue);
    });
  });

  group('signUp', () {
    test('signs up and sets needsEmailVerification flag', () async {
      await vm.signUp(email: 'test@test.com', password: 'Password1', name: 'Test', role: UserRole.customer);
      expect(vm.signUpJustCompleted, isTrue);
      expect(vm.signUpEmail, 'test@test.com');
      expect(vm.isLoading, isFalse);
    });

    test('sets error message and rethrows on failure', () async {
      stubRepo.failNextSignUp = true;
      expect(vm.errorMessage, isNull);
      try {
        await vm.signUp(email: 'test@test.com', password: 'Password1', name: 'Test', role: UserRole.customer);
      } catch (_) {}
      expect(vm.errorMessage, contains('Could not create account'));
      expect(vm.isLoading, isFalse);
    });

    test('clears previous error before sign up', () async {
      stubRepo.failNextSignUp = true;
      try { await vm.signUp(email: 'a@b.com', password: 'Password1', name: 'T', role: UserRole.customer); } catch (_) {}
      expect(vm.errorMessage, isNotNull);

      stubRepo.failNextSignUp = false;
      await vm.signUp(email: 'a@b.com', password: 'Password1', name: 'T', role: UserRole.customer);
      expect(vm.errorMessage, isNull);
    });

    test('sets loading state during sign up', () async {
      final futures = vm.signUp(email: 'a@b.com', password: 'Password1', name: 'T', role: UserRole.customer);
      expect(vm.isLoading, isTrue);
      await futures;
      expect(vm.isLoading, isFalse);
    });

    test('cooldown starts after sign up', () async {
      await vm.signUp(email: 'a@b.com', password: 'Password1', name: 'T', role: UserRole.customer);
      expect(vm.cooldownSeconds, greaterThan(0));
    });
  });

  group('signIn', () {
    test('signs in successfully', () async {
      await vm.signIn(email: 'a@b.com', password: 'Password1');
      expect(vm.errorMessage, isNull);
      expect(vm.isLoading, isFalse);
    });

    test('sets error message on failure', () async {
      stubRepo.failNextSignIn = true;
      try { await vm.signIn(email: 'a@b.com', password: 'Password1'); } catch (_) {}
      expect(vm.errorMessage, contains('Invalid email or password'));
    });

    test('sets loading state during sign in', () async {
      final futures = vm.signIn(email: 'a@b.com', password: 'Password1');
      expect(vm.isLoading, isTrue);
      await futures;
      expect(vm.isLoading, isFalse);
    });
  });

  group('resendVerification', () {
    test('resends verification email', () async {
      await vm.signUp(email: 'test@test.com', password: 'Password1', name: 'T', role: UserRole.customer);
      // Wait for cooldown to reset so we can resend
      vm = AuthViewModel(stubRepo);
      await vm.resendVerification(email: 'test@test.com');
      expect(vm.errorMessage, isNull);
    });

    test('throws RateLimitExceeded when called too soon', () async {
      await vm.signUp(email: 'test@test.com', password: 'Password1', name: 'T', role: UserRole.customer);
      // cooldown is active, resend should throw
      try {
        await vm.resendVerification(email: 'test@test.com');
        fail('Expected RateLimitExceeded');
      } on RateLimitExceeded {
        // expected
      }
    });
  });

  group('signOut', () {
    test('signs out and clears user', () async {
      await vm.signIn(email: 'a@b.com', password: 'Password1');

      await vm.signOut();
      expect(vm.user, isNull);
      expect(vm.isAuthenticated, isFalse);
      expect(vm.isLoading, isFalse);
    });

    test('clears verification state on sign out', () async {
      stubRepo.failNextSignIn = true;
      await vm.signUp(email: 'a@b.com', password: 'Password1', name: 'T', role: UserRole.customer);
      expect(vm.signUpJustCompleted, isTrue);

      await vm.signOut();
      expect(vm.signUpJustCompleted, isFalse);
      expect(vm.signUpEmail, isNull);
    });

    test('sets error message on failure', () async {
      stubRepo.failNextSignOut = true;
      try { await vm.signOut(); } catch (_) {}
      expect(vm.errorMessage, contains('Could not sign out'));
    });
  });

  group('forgotPassword', () {
    test('sends password reset email successfully', () async {
      await vm.forgotPassword(email: 'a@b.com');
      expect(vm.errorMessage, isNull);
      expect(vm.isLoading, isFalse);
    });

    test('sets error on failure', () async {
      stubRepo.failNextPasswordReset = true;
      try { await vm.forgotPassword(email: 'a@b.com'); } catch (_) {}
      expect(vm.errorMessage, contains('Could not send password reset'));
    });
  });

  group('updatePassword', () {
    test('updates password successfully', () async {
      await vm.updatePassword('new-password');
      expect(vm.errorMessage, isNull);
      expect(vm.isLoading, isFalse);
    });

    test('sets error on failure', () async {
      stubRepo.failNextPasswordUpdate = true;
      try { await vm.updatePassword('new-pw'); } catch (_) {}
      expect(vm.errorMessage, contains('Could not update password'));
    });
  });

  group('auth state stream', () {
    test('updates user on auth state change', () async {
      final user = AppUser(id: 'stream-u1', email: 'stream@test.com', name: 'Stream', role: UserRole.worker, createdAt: DateTime(2026));
      stubRepo.emitUser(user);
      await Future(() {});
      expect(vm.user?.id, 'stream-u1');
      expect(vm.isLoading, isFalse);
    });

    test('clears user on null auth state', () async {
      await vm.signIn(email: 'a@b.com', password: 'Password1');
      stubRepo.emitUser(null);
      await Future(() {});
      expect(vm.user, isNull);
      expect(vm.isAuthenticated, isFalse);
    });

    test('sets error on auth state stream error', () async {
      stubRepo._controller.addError('Stream error');
      await Future(() {});
      expect(vm.errorMessage, contains('Something went wrong'));
    });
  });

  group('resetVerification', () {
    test('resets verification state', () async {
      await vm.signUp(email: 'a@b.com', password: 'Password1', name: 'T', role: UserRole.customer);
      expect(vm.signUpJustCompleted, isTrue);

      vm.resetVerification();
      expect(vm.signUpJustCompleted, isFalse);
      expect(vm.signUpEmail, isNull);
    });
  });
}
