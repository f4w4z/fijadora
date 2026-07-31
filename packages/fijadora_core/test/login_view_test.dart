import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fijadora_core/app_config.dart';
import 'package:fijadora_core/data/repositories/auth_repository.dart';
import 'package:fijadora_core/domain/models/app_user.dart';
import 'package:fijadora_core/domain/models/user_role.dart';
import 'package:fijadora_core/ui/features/auth/view_models/auth_view_model.dart';
import 'package:fijadora_core/ui/features/auth/views/login_view.dart';

class StubAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  bool failNextSignIn = false;
  bool failNextSignUp = false;
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
  Future<void> deleteAccount() async {}

  @override
  void dispose() {
    _controller.close();
  }
}

class _ControllableAuthRepository extends StubAuthRepository {
  final _signInCompleter = Completer<void>();

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _signInCompleter.future;
    return super.signIn(email: email, password: password);
  }

  void completeSignIn() => _signInCompleter.complete();
}

Widget _createTestApp(AuthViewModel vm) {
  return ProviderScope(
    overrides: [
      authViewModelProvider.overrideWith((ref) => vm),
      appConfigProvider.overrideWith((ref) => AppConfig.customer),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const LoginView()),
          GoRoute(path: '/register', builder: (context, state) => const Scaffold(body: Text('Register'))),
          GoRoute(path: '/forgot-password', builder: (context, state) => const Scaffold(body: Text('Forgot Password'))),
        ],
      ),
    ),
  );
}

void main() {
  group('LoginView', () {
    testWidgets('renders sign in form', (tester) async {
      final stubRepo = StubAuthRepository();
      final authVM = AuthViewModel(stubRepo);

      await tester.pumpWidget(_createTestApp(authVM));
      await tester.pumpAndSettle();

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('shows validation error on empty submit', (tester) async {
      final stubRepo = StubAuthRepository();
      final authVM = AuthViewModel(stubRepo);

      await tester.pumpWidget(_createTestApp(authVM));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter email'), findsOneWidget);
    });

    testWidgets('validates email format', (tester) async {
      final stubRepo = StubAuthRepository();
      final authVM = AuthViewModel(stubRepo);

      await tester.pumpWidget(_createTestApp(authVM));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows loading indicator during sign in', (tester) async {
      final controllableRepo = _ControllableAuthRepository();
      final loadingVM = AuthViewModel(controllableRepo);

      await tester.pumpWidget(_createTestApp(loadingVM));
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@test.com');

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'Password1');

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.byKey(const ValueKey('login_loading')), findsOneWidget);

      controllableRepo.completeSignIn();
      await tester.pumpAndSettle();
    });
  });
}
