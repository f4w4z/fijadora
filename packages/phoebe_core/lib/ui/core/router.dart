import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app_config.dart';
import '../features/auth/view_models/auth_view_model.dart';
import '../features/auth/views/login_view.dart';
import '../features/auth/views/register_view.dart';
import '../features/auth/views/access_denied_view.dart';
import '../../domain/models/user_role.dart';
import '../features/home/views/home_shell_view.dart';
import '../features/worker/views/worker_shell_view.dart';
import '../features/worker/views/worker_pending_approval_view.dart';
import '../features/staff/views/staff_shell_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authViewModel = ref.watch(authViewModelProvider);
  final appConfig = ref.watch(appConfigProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authViewModel,
    redirect: (context, state) {
      final isAuthenticated = authViewModel.isAuthenticated;
      final location = state.matchedLocation;
      final isLoggingIn = location == '/login';
      final isRegistering = location == '/register';
      final isAccessDenied = location == '/access-denied';

      if (!isAuthenticated) {
        if (!isLoggingIn && !isRegistering) {
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
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/access-denied',
        builder: (context, state) => const AccessDeniedView(),
      ),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const WorkerPendingApprovalView(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          final role = authViewModel.user?.role ?? UserRole.customer;
          if (role == UserRole.worker) {
            return const WorkerShellView();
          }
          if (role == UserRole.admin || role == UserRole.manager) {
            return const StaffShellView();
          }
          return const HomeShellView();
        },
      ),
    ],
  );
});
