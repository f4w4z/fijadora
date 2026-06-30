import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../profile/views/home_detail_list_view.dart';
import '../../settings/views/settings_view.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Loading user session...')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header ────────────────────────────────────────────────────
              Row(
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
              const SizedBox(height: 28),

              // ─── Profile + Address ─────────────────────────────────────────
              Container(
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
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'rooms'))),
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
                          Text('Family Home', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
                          const SizedBox(width: 6),
                          Text('123 Main St', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                          const Spacer(),
                          Icon(CupertinoIcons.chevron_right, size: 13, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Stats Row ─────────────────────────────────────────────────
              Row(
                children: [
                  _StatPill(icon: CupertinoIcons.square_grid_2x2, value: '6', label: 'Rooms', onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'rooms')));
                  }),
                  const SizedBox(width: 10),
                  _StatPill(icon: CupertinoIcons.device_desktop, value: '4', label: 'Appliances', onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'appliances')));
                  }),
                  const SizedBox(width: 10),
                  _StatPill(icon: CupertinoIcons.doc_text, value: '3', label: 'Warranties', onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'warranties')));
                  }),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Upcoming ──────────────────────────────────────────────────
              Text('Upcoming', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              _ReminderTile(
                icon: CupertinoIcons.wind, title: 'HVAC Air Filter',
                subtitle: 'Replace in 6 days', detail: 'Quarterly', color: const Color(0xFFD4815A),
              ),
              const SizedBox(height: 8),
              _ReminderTile(
                icon: CupertinoIcons.bell_fill, title: 'Smoke Detector',
                subtitle: 'Test batteries next week', detail: 'Bi-annual', color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),

              // ─── Maintenance History ───────────────────────────────────────
              AnimatedTapScale(
                scaleFactor: 0.97,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'history'))),
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
              const SizedBox(height: 12),

              // ─── Settings Button ───────────────────────────────────────────
              AnimatedTapScale(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsView())),
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
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Icon(icon, size: 17, color: color)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: Text(detail.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

