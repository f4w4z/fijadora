import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/custom_pinned_header.dart';
import '../../../shared/widgets/floating_header_layout.dart';
import '../../../core/theme.dart';
import '../../../core/theme_provider.dart';
import '../../profile/views/home_detail_list_view.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Loading user session...')),
      );
    }

Widget settingsRow(BuildContext context, IconData icon, String title, String subtitle) {
  final theme = Theme.of(context);
  return SizedBox(
        height: 54,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, size: 18, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 14, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      );
    }

    return Scaffold(
      body: FloatingHeaderLayout(
        header: CustomPinnedHeader(
          title: 'Home',
          actions: [
            GestureDetector(
              onTap: () async {
                await ref.read(authViewModelProvider.notifier).signOut();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
        bodyBuilder: (context, topPadding) {
          final theme = Theme.of(context);
          return RefreshIndicator(
            onRefresh: () async => Future.delayed(const Duration(milliseconds: 300)),
            child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPadding + 8)),

              // ─── Profile Hero ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Home Address Card ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Icon(CupertinoIcons.house_fill, size: 22, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Family Home',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '123 Main Street, Springfield',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Color(0xFF4CAF50).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ALL GOOD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Stats Row ─────────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Row(
                    children: [
                      _StatPill(
                        icon: CupertinoIcons.square_grid_2x2,
                        value: '6',
                        label: 'Rooms',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'rooms')),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _StatPill(
                        icon: CupertinoIcons.device_desktop,
                        value: '4',
                        label: 'Appliances',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'appliances')),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _StatPill(
                        icon: CupertinoIcons.doc_text,
                        value: '3',
                        label: 'Warranties',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'warranties')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Reminders ──────────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
                  child: Text(
                    'Upcoming',
                    style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                  child: _ReminderTile(
                    icon: CupertinoIcons.wind,
                    title: 'HVAC Air Filter',
                    subtitle: 'Replace in 6 days',
                    detail: 'Quarterly',
                    color: const Color(0xFFD4815A),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                  child: _ReminderTile(
                    icon: CupertinoIcons.bell_fill,
                    title: 'Smoke Detector',
                    subtitle: 'Test batteries next week',
                    detail: 'Bi-annual',
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              // ─── Maintenance History ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                  child: AnimatedTapScale(
                    scaleFactor: 0.97,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'history')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(CupertinoIcons.clock, size: 20, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Text(
                                'Maintenance History',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: 0.0,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Invoices, repairs, and receipts',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              ],
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_right, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Settings ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
                  child: Text(
                    'Settings',
                    style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        settingsRow(context, CupertinoIcons.bell_fill, 'Notifications', 'Alert preferences'),
                        Divider(height: 1, color: theme.colorScheme.outlineVariant),
                        SizedBox(
                          height: 54,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: Consumer(
                                  builder: (context, ref, _) {
                                    final themeMode = ref.watch(themeModeProvider);
                                    final isDark = themeMode == ThemeMode.dark ||
                                        (themeMode == ThemeMode.system &&
                                            MediaQuery.of(context).platformBrightness == Brightness.dark);
                                    return Icon(
                                      isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Consumer(
                                  builder: (context, ref, _) {
                                    final themeMode = ref.watch(themeModeProvider);
                                    final isDark = themeMode == ThemeMode.dark ||
                                        (themeMode == ThemeMode.system &&
                                            MediaQuery.of(context).platformBrightness == Brightness.dark);
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Appearance',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          isDark ? 'Dark mode' : 'Light mode',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final themeMode = ref.watch(themeModeProvider);
                                  final isDark = themeMode == ThemeMode.dark ||
                                      (themeMode == ThemeMode.system &&
                                          MediaQuery.of(context).platformBrightness == Brightness.dark);
                                    return CupertinoSwitch(
                                      value: isDark,
                                      activeTrackColor: theme.colorScheme.primary,
                                    onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: theme.colorScheme.outlineVariant),
                        settingsRow(context, CupertinoIcons.creditcard, 'Payment Methods', 'Cards & billing'),
                        Divider(height: 1, color: theme.colorScheme.outlineVariant),
                        settingsRow(context, CupertinoIcons.doc_text, 'Terms & Conditions', 'Platform terms'),
                        Divider(height: 1, color: theme.colorScheme.outlineVariant),
                        settingsRow(context, CupertinoIcons.shield, 'Privacy Policy', 'Data handling'),
                        Divider(height: 1, color: theme.colorScheme.outlineVariant),
                        settingsRow(context, CupertinoIcons.question_circle, 'Help & Support', 'Get help'),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
          );
        },
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
    return Expanded(
      child: AnimatedTapScale(
        scaleFactor: 0.95,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.0,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Center(child: Icon(icon, size: 17, color: color)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              detail.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

