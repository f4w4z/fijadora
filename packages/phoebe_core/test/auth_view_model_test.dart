import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:phoebe_core/data/repositories/auth_repository.dart';
import 'package:phoebe_core/domain/models/app_user.dart';
import 'package:phoebe_core/domain/models/user_role.dart';
import 'package:phoebe_core/ui/features/auth/view_models/auth_view_model.dart';

class StubAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  bool failNextSignIn = false;
  bool failNextSignUp = false;
  bool failNextSignOut = false;
  bool failNextPasswordReset = false;
  bool failNextVerification = false;
  bool failNextPasswordUpdate = false;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  void emitUser(AppUser? user) => _controller.add(user);

  @override
  Future<AppUser> signInWithEmail({required String email, required String password}) async {
    if (failNextSignIn) {
      failNextSignIn = false;
      throw Exception('Invalid credentials');
    }
    _currentUser = AppUser(id: 'auth-1', email: email, name: 'Test', role: UserRole.customer, createdAt: DateTime(2026));
    return _currentUser!;
  }

  @override
  Future<AppUser> signUpWithEmail({required String email, required String password, required String name, required UserRole role}) async {
    if (failNextSignUp) {
      failNextSignUp = false;
      throw Exception('Sign up failed');
    }
    _currentUser = AppUser(id: 'auth-2', email: email, name: name, role: role, createdAt: DateTime(2026));
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    if (failNextSignOut) {
      failNextSignOut = false;
      throw Exception('Sign out failed');
    }
    _currentUser = null;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (failNextPasswordReset) {
      failNextPasswordReset = false;
      throw Exception('Reset failed');
    }
  }

  @override
  Future<void> resendVerificationEmail() async {
    if (failNextVerification) {
      failNextVerification = false;
      throw Exception('Resend failed');
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
  List<AppUser> getAllWorkers() => [];

  @override
  Future<void> refreshWorkers() async {}

  @override
  Future<void> updateWorkerStatus({required String userId, required String status}) async {}

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

  group('signIn', () {
    test('signs in successfully and sets user', () async {
      await vm.signIn(email: 'test@test.com', password: 'password');
      expect(vm.user, isNotNull);
      expect(vm.user!.email, 'test@test.com');
      expect(vm.user!.role, UserRole.customer);
      expect(vm.isAuthenticated, isTrue);
      expect(vm.isLoading, isFalse);
    });

    test('sets error message and rethrows on failure', () async {
      stubRepo.failNextSignIn = true;
      expect(vm.errorMessage, isNull);
      try {
        await vm.signIn(email: 'test@test.com', password: 'wrong');
      } catch (_) {}
      expect(vm.errorMessage, contains('Invalid credentials'));
      expect(vm.isLoading, isFalse);
    });

    test('clears previous error before sign in', () async {
      stubRepo.failNextSignIn = true;
      try { await vm.signIn(email: 'a@b.com', password: 'wrong'); } catch (_) {}
      expect(vm.errorMessage, isNotNull);

      stubRepo.failNextSignIn = false;
      await vm.signIn(email: 'a@b.com', password: 'ok');
      expect(vm.errorMessage, isNull);
    });

    test('sets loading state during sign in', () async {
      final futures = vm.signIn(email: 'a@b.com', password: 'pw');
      expect(vm.isLoading, isTrue);
      await futures;
      expect(vm.isLoading, isFalse);
    });
  });

  group('signUp', () {
    test('signs up successfully with customer role', () async {
      await vm.signUp(email: 'new@test.com', password: 'pw', name: 'New', role: UserRole.customer);
      expect(vm.user?.email, 'new@test.com');
      expect(vm.user?.role, UserRole.customer);
      expect(vm.isLoading, isFalse);
    });

    test('signs up successfully with worker role', () async {
      await vm.signUp(email: 'worker@test.com', password: 'pw', name: 'Worker', role: UserRole.worker);
      expect(vm.user?.role, UserRole.worker);
    });

    test('signs up successfully with admin role', () async {
      await vm.signUp(email: 'admin@test.com', password: 'pw', name: 'Admin', role: UserRole.admin);
      expect(vm.user?.role, UserRole.admin);
    });

    test('sets error message on failure', () async {
      stubRepo.failNextSignUp = true;
      try { await vm.signUp(email: 'a@b.com', password: 'pw', name: 'N', role: UserRole.customer); } catch (_) {}
      expect(vm.errorMessage, contains('Sign up failed'));
      expect(vm.isLoading, isFalse);
    });
  });

  group('signOut', () {
    test('signs out and clears user', () async {
      await vm.signIn(email: 'a@b.com', password: 'pw');
      expect(vm.isAuthenticated, isTrue);

      await vm.signOut();
      expect(vm.user, isNull);
      expect(vm.isAuthenticated, isFalse);
      expect(vm.isLoading, isFalse);
    });

    test('sets error message on failure', () async {
      stubRepo.failNextSignOut = true;
      try { await vm.signOut(); } catch (_) {}
      expect(vm.errorMessage, contains('Sign out failed'));
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
      expect(vm.errorMessage, contains('Reset failed'));
    });
  });

  group('resendVerification', () {
    test('resends verification email successfully', () async {
      await vm.resendVerification();
      expect(vm.errorMessage, isNull);
      expect(vm.isLoading, isFalse);
    });

    test('sets error on failure', () async {
      stubRepo.failNextVerification = true;
      try { await vm.resendVerification(); } catch (_) {}
      expect(vm.errorMessage, contains('Resend failed'));
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
      expect(vm.errorMessage, contains('Update failed'));
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
      await vm.signIn(email: 'a@b.com', password: 'pw');
      stubRepo.emitUser(null);
      await Future(() {});
      expect(vm.user, isNull);
      expect(vm.isAuthenticated, isFalse);
    });

    test('sets error on auth state stream error', () async {
      stubRepo._controller.addError('Stream error');
      await Future(() {});
      expect(vm.errorMessage, contains('Stream error'));
    });
  });
}
