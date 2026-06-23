import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/user_role.dart';
import '../../auth/view_models/auth_view_model.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authViewModel = ref.watch(authViewModelProvider);
    final user = authViewModel.user;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Loading user session...')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right),
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(
                              _getRoleIcon(user.role),
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: theme.textTheme.titleLarge,
                              ),
                              Text(
                                user.email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      const Divider(height: 1),
                      const SizedBox(height: 16.0),
                      Text(
                        'Logged in as ${_getRoleDisplayName(user.role)}',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        _getRoleDescription(user.role),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24.0),

              // Placeholder UI based on user role
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getRoleIllustrationIcon(user.role),
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      _getRoleIllustrationTitle(user.role),
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Ready to manage your workspace and view schedules.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return CupertinoIcons.person;
      case UserRole.worker:
        return CupertinoIcons.hammer;
      case UserRole.admin:
        return CupertinoIcons.shield;
      case UserRole.manager:
        return CupertinoIcons.briefcase;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.worker:
        return 'Service Professional';
      case UserRole.admin:
        return 'System Admin';
      case UserRole.manager:
        return 'Property Manager';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Access maintenance requests, bookings, and shop furniture.';
      case UserRole.worker:
        return 'View assigned jobs, schedules, navigation, and client work.';
      case UserRole.admin:
        return 'Complete access to dashboard, workers, jobs, inventory, and users.';
      case UserRole.manager:
        return 'Oversee buildings, rooms, maintenance histories, and units.';
    }
  }

  IconData _getRoleIllustrationIcon(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return CupertinoIcons.house_fill;
      case UserRole.worker:
        return CupertinoIcons.wrench_fill;
      case UserRole.admin:
        return CupertinoIcons.chart_bar_alt_fill;
      case UserRole.manager:
        return CupertinoIcons.building_2_fill;
    }
  }

  String _getRoleIllustrationTitle(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Welcome Home!';
      case UserRole.worker:
        return "Professionals' Dashboard";
      case UserRole.admin:
        return 'Operations Center';
      case UserRole.manager:
        return 'Property Overview';
    }
  }
}
