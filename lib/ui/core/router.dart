import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/view_models/auth_view_model.dart';
import '../features/auth/views/login_view.dart';
import '../features/auth/views/register_view.dart';
import '../../domain/models/user_role.dart';
import '../features/home/views/home_shell_view.dart';
import '../features/worker/views/worker_dashboard_view.dart';
import '../features/admin/views/admin_dashboard_view.dart';
import '../features/manager/views/manager_dashboard_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch the view model to trigger router rebuilds when state changes
  final authViewModel = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authViewModel,
    redirect: (context, state) {
      final isAuthenticated = authViewModel.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      if (!isAuthenticated) {
        // Not authenticated: only allow login or register routes
        if (!isLoggingIn && !isRegistering) {
          return '/login';
        }
        return null;
      }

      // Authenticated: prevent visiting login/register pages
      if (isLoggingIn || isRegistering) {
        return '/';
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
