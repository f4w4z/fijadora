import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:phoebe_core/data/repositories/auth_repository.dart';
import 'package:phoebe_core/domain/models/app_user.dart';
import 'package:phoebe_core/domain/models/user_role.dart';
import 'package:phoebe_core/ui/features/auth/view_models/auth_view_model.dart';
import 'package:phoebe_core/ui/features/auth/views/login_view.dart';

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

class _ControllableAuthRepository extends StubAuthRepository {
  final _signInCompleter = Completer<void>();

  @override
  Future<AppUser> signInWithEmail({required String email, required String password}) async {
    await _signInCompleter.future;
    return super.signInWithEmail(email: email, password: password);
  }

  void completeSignIn() => _signInCompleter.complete();
}

Widget _createTestApp(AuthViewModel vm) {
  return ProviderScope(
    overrides: [
      authViewModelProvider.overrideWith((ref) => vm),
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
    testWidgets('renders login form', (tester) async {
      final stubRepo = StubAuthRepository();
      final authVM = AuthViewModel(stubRepo);

      await tester.pumpWidget(_createTestApp(authVM));
      await tester.pumpAndSettle();

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      final stubRepo = StubAuthRepository();
      final authVM = AuthViewModel(stubRepo);

      await tester.pumpWidget(_createTestApp(authVM));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter email'), findsOneWidget);
      expect(find.text('Please enter password'), findsOneWidget);
    });

    testWidgets('validates email format', (tester) async {
      final stubRepo = StubAuthRepository();
      final authVM = AuthViewModel(stubRepo);

      await tester.pumpWidget(_createTestApp(authVM));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsNothing);
    });

    testWidgets('validates password minimum length', (tester) async {
      final stubRepo = StubAuthRepository();
      final authVM = AuthViewModel(stubRepo);

      await tester.pumpWidget(_createTestApp(authVM));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'test@test.com');
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      expect(find.text('Please enter a valid email'), findsNothing);
    });

    testWidgets('shows loading indicator during sign in', (tester) async {
      final controllableRepo = _ControllableAuthRepository();
      final loadingVM = AuthViewModel(controllableRepo);

      await tester.pumpWidget(_createTestApp(loadingVM));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'test@test.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.byKey(const ValueKey('login_loading')), findsOneWidget);

      controllableRepo.completeSignIn();
      await tester.pumpAndSettle();
    });

    testWidgets('calls signIn with credentials', (tester) async {
      final stubRepo = StubAuthRepository();
      final authVM = AuthViewModel(stubRepo);

      await tester.pumpWidget(_createTestApp(authVM));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'test@test.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(authVM.user, isNotNull);
      expect(authVM.user!.email, 'test@test.com');
    });
  });
}
