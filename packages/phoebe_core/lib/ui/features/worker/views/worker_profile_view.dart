import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../../../../ui/shared/widgets/custom_pinned_header.dart';
import '../../../../ui/shared/widgets/floating_header_layout.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../services/view_models/jobs_view_model.dart';
import '../../../core/theme_provider.dart';
import 'worker_notifications_view.dart';
import 'worker_availability_view.dart';
import 'worker_help_center_view.dart';
import 'worker_terms_view.dart';

class WorkerProfileView extends ConsumerWidget {
  const WorkerProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authViewModelProvider).user;
    final allJobs = ref.watch(jobsViewModelProvider).jobs;

    final completedJobs =
        allJobs.where((j) => j.workerId == user?.id).length;
    final inProgress = allJobs
        .where((j) =>
            j.workerId == user?.id &&
            (j.status.name == 'inProgress' ||
                j.status.name == 'workerEnRoute' ||
                j.status.name == 'workerArrived'))
        .length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FloatingHeaderLayout(
        header: CustomPinnedHeader(
          title: 'Profile',
          actions: [
            GroupedHeaderActions(
              actions: [
                GroupedActionItem(
                  icon: CupertinoIcons.square_arrow_right,
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('Sign Out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await ref.read(authViewModelProvider.notifier).signOut();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        bodyBuilder: (context, topPadding) {
          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(jobsViewModelProvider).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topPadding)),

                // Worker info card
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 4, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: theme
                                .colorScheme.primary
                                .withValues(alpha: 0.12),
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'W',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'Worker',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Service Professional',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32)
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ONLINE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Stats row
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        _ProfileStat(
                          theme: theme,
                          value: '$completedJobs',
                          label: 'Jobs Done',
                          icon: CupertinoIcons.hammer_fill,
                        ),
                        const SizedBox(width: 10),
                        _ProfileStat(
                          theme: theme,
                          value: '$inProgress',
                          label: 'Active',
                          icon: CupertinoIcons.clock_fill,
                        ),
                        const SizedBox(width: 10),
                        _ProfileStat(
                          theme: theme,
                          value: '${allJobs.length}',
                          label: 'Total',
                          icon: CupertinoIcons.tray_full_fill,
                        ),
                      ],
                    ),
                  ),
                ),

                // Settings section
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: _SettingsRow(
                      icon: CupertinoIcons.bell_fill,
                      title: 'Notifications',
                      subtitle: 'Job alerts & reminders',
                      theme: theme,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerNotificationsView())),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Consumer(
                      builder: (context, ref, _) {
                        final themeMode =
                            ref.watch(themeModeProvider);
                        final isDark = themeMode == ThemeMode.dark ||
                            (themeMode == ThemeMode.system &&
                                MediaQuery.of(context)
                                        .platformBrightness ==
                                    Brightness.dark);
                        return _SettingsRow(
                          icon: isDark
                              ? CupertinoIcons.moon_fill
                              : CupertinoIcons.sun_max_fill,
                          title: 'Appearance',
                          subtitle:
                              isDark ? 'Dark mode' : 'Light mode',
                          theme: theme,
                          trailing: CupertinoSwitch(
                            value: isDark,
                            activeTrackColor:
                                theme.colorScheme.primary,
                            onChanged: (_) => ref
                                .read(themeModeProvider.notifier)
                                .toggleTheme(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: _SettingsRow(
                      icon: CupertinoIcons.location,
                      title: 'Availability',
                      subtitle: 'Set working hours & zones',
                      theme: theme,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerAvailabilityView())),
                    ),
                  ),
                ),

                // Support section
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Text(
                      'Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: _SettingsRow(
                      icon: CupertinoIcons.question_circle,
                      title: 'Help Center',
                      subtitle: 'Guides & FAQs',
                      theme: theme,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerHelpCenterView())),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: _SettingsRow(
                      icon: CupertinoIcons.doc_text,
                      title: 'Terms of Service',
                      subtitle: 'Platform policies',
                      theme: theme,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerTermsView())),
                    ),
                  ),
                ),

                // Sign out
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: _SignOutButton(theme: theme),
                  ),
                ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: 140)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.theme,
    required this.value,
    required this.label,
    required this.icon,
  });

  final ThemeData theme;
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeData theme;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            trailing ??
                Icon(CupertinoIcons.chevron_right,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return AnimatedTapScale(
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign Out'),
                content:
                    const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      'Sign Out',
                      style: TextStyle(
                          color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              await ref
                  .read(authViewModelProvider.notifier)
                  .signOut();
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.error
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.square_arrow_right,
                    size: 18, color: theme.colorScheme.error),
                const SizedBox(width: 10),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
