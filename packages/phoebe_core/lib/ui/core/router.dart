import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app_config.dart';
import '../features/auth/view_models/auth_view_model.dart';
import '../features/auth/views/login_view.dart';
import '../features/auth/views/register_view.dart';
import '../features/auth/views/access_denied_view.dart';
import '../../domain/models/user_role.dart';
import '../features/home/views/home_shell_view.dart';
import '../features/worker/views/worker_dashboard_view.dart';
import '../features/admin/views/admin_dashboard_view.dart';
import '../features/manager/views/manager_dashboard_view.dart';

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

      final role = authViewModel.user?.role;
      if (role != null && !appConfig.allowedRoles.contains(role)) {
        return '/access-denied';
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
        path: '/',
        builder: (context, state) {
          final role = authViewModel.user?.role ?? UserRole.customer;
          if (role == UserRole.worker) {
            return const WorkerDashboardView();
          }
          if (role == UserRole.admin) {
            return const AdminDashboardView();
          }
          if (role == UserRole.manager) {
            return const ManagerDashboardView();
          }
          return const HomeShellView();
        },
      ),
    ],
  );
});
