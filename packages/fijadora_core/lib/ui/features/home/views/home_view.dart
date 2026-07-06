import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/home_view_model.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/delete_account_button.dart';
import '../../profile/views/home_detail_list_view.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../settings/views/settings_view.dart';


class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    final propertyAsync = ref.watch(homePropertyProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Loading user session...')),
      );
    }

    final property = propertyAsync.when(
      loading: () => null,
      error: (error, _) => null,
      data: (p) => p,
    );
    final propertyName = property?.name;
    final propertyAddress = property?.address;
    final rooms = property?.units.expand((u) => u.rooms).toList() ?? <dynamic>[];
    final appliances = rooms.expand((r) => (r as dynamic).assets?.where((a) => a.type == 'Appliance') ?? []).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Loading indicator ──────────────────────────────────────────
              if (propertyAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              if (propertyAsync.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(child: Text('Could not load property info',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  )),
                ),
              // ─── Header ────────────────────────────────────────────────────
              FadeSlideTransition(
                delay: const Duration(milliseconds: 0),
                child: Row(
                  children: [
                    Text('Home', style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5,
                    )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async { await ref.read(authViewModelProvider.notifier).signOut(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text('Sign Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface, letterSpacing: 0.3)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ─── Profile ────────────────────────────────────────────
              FadeSlideTransition(
                delay: const Duration(milliseconds: 50),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                                const SizedBox(height: 2),
                                Text(user.email, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Color(0xFF4CAF50).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('ALL GOOD', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Color(0xFF4CAF50))),
                          ),
                        ],
                      ),
                      if (propertyName != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(AppPageRoute(builder: (context) => HomeDetailListView(type: 'rooms', property: property!))),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(CupertinoIcons.house_fill, size: 13, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 10),
                              Text(propertyName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
                              if (propertyAddress != null) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(propertyAddress, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                              const Spacer(),
                              Icon(CupertinoIcons.chevron_right, size: 13, color: theme.colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Stats Row ─────────────────────────────────────────────────
              if (property != null)
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 100),
                  child: Row(
                    children: [
                      _StatPill(icon: CupertinoIcons.square_grid_2x2, value: '${rooms.length}', label: 'Rooms', onTap: () {
                        Navigator.of(context).push(AppPageRoute(builder: (context) => HomeDetailListView(type: 'rooms', property: property)));
                      }),
                      const SizedBox(width: 10),
                      _StatPill(icon: CupertinoIcons.device_desktop, value: '${appliances.length}', label: 'Appliances', onTap: () {
                        Navigator.of(context).push(AppPageRoute(builder: (context) => HomeDetailListView(type: 'appliances', property: property)));
                      }),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Maintenance History ───────────────────────────────────────
              FadeSlideTransition(
                delay: const Duration(milliseconds: 200),
                child: AnimatedTapScale(
                  scaleFactor: 0.97,
                  onTap: () => Navigator.of(context).push(AppPageRoute(builder: (context) => const HomeDetailListView(type: 'history'))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.clock, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text('Maintenance History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
                        ),
                        Text('Invoices, repairs', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(width: 8),
                        Icon(CupertinoIcons.chevron_right, size: 15, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── Settings Button ───────────────────────────────────────────
              FadeSlideTransition(
                delay: const Duration(milliseconds: 250),
                child: AnimatedTapScale(
                  onTap: () => Navigator.of(context).push(AppPageRoute(builder: (_) => const SettingsView())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.settings, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text('Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
                        ),
                        Icon(CupertinoIcons.chevron_right, size: 15, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              FadeSlideTransition(
                delay: const Duration(milliseconds: 300),
                child: const DeleteAccountButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: AnimatedTapScale(
        scaleFactor: 0.95,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface, height: 1.0)),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}


