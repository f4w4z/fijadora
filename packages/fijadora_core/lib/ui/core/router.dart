import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app_config.dart';
import '../../data/services/analytics_service.dart';
import '../features/auth/view_models/auth_view_model.dart';
import '../features/auth/views/login_view.dart';
import '../features/auth/views/register_view.dart';
import '../features/auth/views/access_denied_view.dart';
import '../features/auth/views/forgot_password_view.dart';

import '../features/auth/views/reset_password_view.dart';
import '../../domain/models/user_role.dart';
import '../features/home/views/home_shell_view.dart';
import '../features/worker/views/worker_shell_view.dart';
import '../features/worker/views/worker_pending_approval_view.dart';
import '../features/staff/views/staff_shell_view.dart';
import '../shared/widgets/app_animations.dart';

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

final rootNavigatorKey = GlobalKey<NavigatorState>();

final customerTabProvider = StateProvider<int>((ref) => 0);
final staffTabProvider = StateProvider<int>((ref) => 0);
final workerTabProvider = StateProvider<int>((ref) => 0);

final routerProvider = Provider<GoRouter>((ref) {
  final authViewModel = ref.watch(authViewModelProvider);
  final appConfig = ref.read(appConfigProvider);
  final initialUri = ref.read(initialUriProvider);

  String initialLocation = '/';
  if (initialUri != null) {
    if (initialUri.fragment.contains('type=recovery')) {
      initialLocation = '/reset-password';
    } else if (initialUri.fragment.contains('type=signup') ||
               initialUri.fragment.contains('access_token=') ||
               initialUri.fragment.contains('access_token&')) {
      initialLocation = '/';
    } else {
      final pathWithQuery = initialUri.hasQuery ? '${initialUri.path}?${initialUri.query}' : initialUri.path;
      if (pathWithQuery.isNotEmpty) {
        initialLocation = pathWithQuery;
      }
    }
  }

  final analyticsObserver = ref.read(analyticsObserverProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: authViewModel,
    observers: [analyticsObserver],
    redirect: (context, state) {
      final isAuthenticated = authViewModel.isAuthenticated;
      final location = state.matchedLocation;
      final isLoggingIn = location == '/login';
      final isRegistering = location == '/register';
      final isAccessDenied = location == '/access-denied';
      final isForgotPassword = location == '/forgot-password';
      final isResetPassword = location == '/reset-password';
      final isPendingApproval = location == '/pending-approval';

      // Unauthenticated — only allow auth screens
      if (!isAuthenticated) {
        final allowed = isLoggingIn || isRegistering || isForgotPassword || isResetPassword;
        if (!allowed) return '/login';

        // If app doesn't allow registration, redirect register to login
        if (isRegistering && !appConfig.canRegister) return '/login';

        return null;
      }

      // Authenticated — block auth screens
      if (isLoggingIn || isRegistering || isForgotPassword) return '/';

      if (isAccessDenied) return null;

      // Role-based access control
      final user = authViewModel.user;
      if (user != null) {
        if (!appConfig.allowedRoles.contains(user.role)) {
          return '/access-denied';
        }
        if (user.role == UserRole.worker) {
          final status = user.workerStatus;
          if (status == null || status == 'pending') {
            if (location != '/pending-approval') return '/pending-approval';
          } else if (status == 'rejected') {
            if (location != '/access-denied') return '/access-denied';
          }
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
