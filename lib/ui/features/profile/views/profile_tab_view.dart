import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_detail_list_view.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/custom_pinned_header.dart';
import '../../../shared/widgets/floating_header_layout.dart';
import '../../../core/theme.dart';
import '../../../core/theme_provider.dart';

class ProfileTabView extends ConsumerWidget {
  const ProfileTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: FloatingHeaderLayout(
        header: CustomPinnedHeader(
          title: 'Profile',
          actions: [
            GroupedHeaderActions(
              actions: [
                GroupedActionItem(
                  icon: CupertinoIcons.refresh,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
        bodyBuilder: (context, topPadding) {
          return RefreshIndicator(
            onRefresh: () async => Future.delayed(const Duration(milliseconds: 300)),
            child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPadding)),

              // Home Identity Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(CupertinoIcons.house_fill, size: 22, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Family Home',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '123 Main Street, Springfield',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ALL GOOD',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Home Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      _buildStatCard(theme, '6', 'Rooms', CupertinoIcons.square_grid_2x2, () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'rooms')),
                        );
                      }),
                      const SizedBox(width: 12),
                      _buildStatCard(theme, '4', 'Appliances', CupertinoIcons.device_desktop, () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'appliances')),
                        );
                      }),
                      const SizedBox(width: 12),
                      _buildStatCard(theme, '3', 'Warranties', CupertinoIcons.doc_text, () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'warranties')),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Predictive Reminders
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.bell_fill, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Predictive Reminders',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: _buildReminderCard(
                    theme: theme,
                    title: 'Air Filter (HVAC)',
                    subtitle: 'Replace filter in 6 days',
                    detail: 'Due quarterly',
                    isUrgent: true,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _buildReminderCard(
                    theme: theme,
                    title: 'Smoke Detector',
                    subtitle: 'Test batteries next week',
                    detail: 'Due bi-annually',
                    isUrgent: false,
                  ),
                ),
              ),

              // Digital Home Record
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.doc_text, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Digital Home Record',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final items = [
                        _RecordGridItem('Rooms', '6 Rooms', CupertinoIcons.square_grid_2x2, () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'rooms')),
                          );
                        }),
                        _RecordGridItem('Appliances', '4 Managed', CupertinoIcons.device_desktop, () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'appliances')),
                          );
                        }),
                        _RecordGridItem('Paint Codes', '3 Active', CupertinoIcons.paintbrush, () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'paint')),
                          );
                        }),
                        _RecordGridItem('Warranties', '3 Enrolled', CupertinoIcons.doc_text, () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'warranties')),
                          );
                        }),
                      ];
                      return _buildGridCard(theme: theme, item: items[index]);
                    },
                    childCount: 4,
                  ),
                ),
              ),

              // Maintenance History
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: AnimatedTapScale(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'history')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Icon(CupertinoIcons.clock, size: 18, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Maintenance History',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'View past invoices, repairs, and receipts',
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
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

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ─── Settings ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
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
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: _ProfileSettingsRow(
                    icon: CupertinoIcons.bell_fill,
                    title: 'Notifications',
                    subtitle: 'Alert preferences',
                    theme: theme,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _ProfileSettingsRow(
                    icon: CupertinoIcons.creditcard,
                    title: 'Payment Methods',
                    subtitle: 'Cards & billing',
                    theme: theme,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final themeMode = ref.watch(themeModeProvider);
                      final isDark = themeMode == ThemeMode.dark ||
                          (themeMode == ThemeMode.system &&
                              MediaQuery.of(context).platformBrightness == Brightness.dark);
                      return _ProfileSettingsRow(
                        icon: isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                        title: 'Appearance',
                        subtitle: isDark ? 'Dark mode' : 'Light mode',
                        theme: theme,
                        trailing: CupertinoSwitch(
                          value: isDark,
                          activeTrackColor: theme.colorScheme.primary,
                          onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _ProfileSettingsRow(
                    icon: CupertinoIcons.doc_text,
                    title: 'Terms & Conditions',
                    subtitle: 'Platform terms',
                    theme: theme,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _ProfileSettingsRow(
                    icon: CupertinoIcons.shield,
                    title: 'Privacy Policy',
                    subtitle: 'Data handling',
                    theme: theme,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _ProfileSettingsRow(
                    icon: CupertinoIcons.question_circle,
                    title: 'Help & Support',
                    subtitle: 'Get help',
                    theme: theme,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String value, String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: AnimatedTapScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required String detail,
    required bool isUrgent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isUrgent
              ? Colors.orange.withValues(alpha: 0.3)
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isUrgent ? Colors.orange : theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUrgent
                  ? Colors.orange.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              detail.toUpperCase(),
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: isUrgent ? Colors.orange : theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard({required ThemeData theme, required _RecordGridItem item}) {
    return AnimatedTapScale(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 18, color: theme.colorScheme.primary),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordGridItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _RecordGridItem(this.title, this.subtitle, this.icon, this.onTap);
}

class _ProfileSettingsRow extends StatelessWidget {
  const _ProfileSettingsRow({
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
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, size: 18, color: theme.colorScheme.primary),
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
            trailing ?? Icon(CupertinoIcons.chevron_right, size: 14, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
