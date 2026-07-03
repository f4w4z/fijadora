import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app_config.dart';
import '../features/auth/view_models/auth_view_model.dart';
import '../features/auth/views/login_view.dart';
import '../features/auth/views/register_view.dart';
import '../features/auth/views/access_denied_view.dart';
import '../features/auth/views/forgot_password_view.dart';
import '../features/auth/views/verify_email_view.dart';
import '../features/auth/views/reset_password_view.dart';
import '../../domain/models/user_role.dart';
import '../features/home/views/home_shell_view.dart';
import '../features/worker/views/worker_shell_view.dart';
import '../features/worker/views/worker_pending_approval_view.dart';
import '../features/staff/views/staff_shell_view.dart';
import '../shared/widgets/app_animations.dart';

/// Fade transition for auth-related screens.
CustomTransitionPage<void> _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.slow,
    reverseTransitionDuration: AppDurations.normal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppCurves.defaultCurve),
        child: child,
      );
    },
  );
}

/// Slide + fade transition for main shell screens.
CustomTransitionPage<void> _slidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.page,
    reverseTransitionDuration: AppDurations.slow,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppCurves.page, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: child,
      );
    },
  );
}

final initialUriProvider = Provider<Uri?>((ref) => null);

final routerProvider = Provider<GoRouter>((ref) {
  final authViewModel = ref.read(authViewModelProvider);
  final appConfig = ref.read(appConfigProvider);
  final initialUri = ref.read(initialUriProvider);

  String initialLocation = '/';
  if (initialUri != null) {
    if (initialUri.toString().contains('type=recovery') ||
        initialUri.toString().contains('access_token') ||
        initialUri.fragment.contains('type=recovery')) {
      initialLocation = '/reset-password';
    } else {
      final path = initialUri.path;
      if (path.isNotEmpty) {
        initialLocation = path;
      }
    }
  }

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authViewModel,
    redirect: (context, state) {
      final isAuthenticated = authViewModel.isAuthenticated;
      final location = state.matchedLocation;
      final isLoggingIn = location == '/login';
      final isRegistering = location == '/register';
      final isAccessDenied = location == '/access-denied';

      if (!isAuthenticated) {
        if (!isLoggingIn && !isRegistering && location != '/forgot-password' && location != '/verify-email' && location != '/reset-password') {
          return '/login';
        }
        return null;
      }

      if (isAccessDenied) return null;

      if (isLoggingIn || isRegistering) {
        return '/';
      }

      final user = authViewModel.user;
      if (user != null) {
        if (!appConfig.allowedRoles.contains(user.role)) {
          return '/access-denied';
        }
        if (user.role == UserRole.worker && user.workerStatus == 'pending' && location != '/pending-approval') {
          return '/pending-approval';
        }
        if (user.role == UserRole.worker && (user.workerStatus == 'rejected' || user.workerStatus == null) && location != '/access-denied') {
          return '/access-denied';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadePage(const LoginView(), state),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _fadePage(const RegisterView(), state),
      ),
      GoRoute(
        path: '/access-denied',
        pageBuilder: (context, state) => _fadePage(const AccessDeniedView(), state),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _fadePage(const ForgotPasswordView(), state),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) => _fadePage(
          VerifyEmailView(email: state.uri.queryParameters['email'] ?? ''),
          state,
        ),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => _fadePage(const ResetPasswordView(), state),
      ),
      GoRoute(
        path: '/pending-approval',
        pageBuilder: (context, state) => _fadePage(const WorkerPendingApprovalView(), state),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) {
          final role = authViewModel.user?.role ?? UserRole.customer;
          if (role == UserRole.worker) {
            return _slidePage(const WorkerShellView(), state);
          }
          if (role == UserRole.admin || role == UserRole.manager) {
            return _slidePage(const StaffShellView(), state);
          }
          return _slidePage(const HomeShellView(), state);
        },
      ),
    ],
  );
});
