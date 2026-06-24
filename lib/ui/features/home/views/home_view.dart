import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../domain/models/user_role.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/custom_pinned_header.dart';
import '../../../shared/widgets/floating_header_layout.dart';

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
      body: FloatingHeaderLayout(
        header: CustomPinnedHeader(
          title: 'Profile',
          actions: [
            GroupedHeaderActions(
              actions: [
                GroupedActionItem(
                  icon: CupertinoIcons.square_arrow_right,
                  onTap: () async {
                    await ref.read(authViewModelProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ],
        ),
        bodyBuilder: (context, topPadding) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPadding)),

              // Profile Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0x1F8BA5A7),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: GoogleFonts.instrumentSerif(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildRoleBadge(theme, user.role),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.square_grid_2x2, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.instrumentSerif(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
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
                    childAspectRatio: 1.4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final actions = _getQuickActions(user.role);
                      return _buildActionCard(theme: theme, item: actions[index]);
                    },
                    childCount: _getQuickActions(user.role).length,
                  ),
                ),
              ),

              // Settings
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.gear, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Settings',
                        style: GoogleFonts.instrumentSerif(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: _buildSettingsRow(
                    theme: theme,
                    icon: CupertinoIcons.bell_fill,
                    title: 'Notifications',
                    subtitle: 'Manage alert preferences',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _buildSettingsRow(
                    theme: theme,
                    icon: CupertinoIcons.creditcard,
                    title: 'Payment Methods',
                    subtitle: 'Cards & billing information',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _buildSettingsRow(
                    theme: theme,
                    icon: CupertinoIcons.doc_text,
                    title: 'Terms & Conditions',
                    subtitle: 'Platform terms of service',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _buildSettingsRow(
                    theme: theme,
                    icon: CupertinoIcons.shield,
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _buildSettingsRow(
                    theme: theme,
                    icon: CupertinoIcons.question_circle,
                    title: 'Help & Support',
                    subtitle: 'Get help with your account',
                  ),
                ),
              ),

              // Role Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: _buildRoleInfoCard(theme: theme, role: user.role),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleBadge(ThemeData theme, UserRole role) {
    final (label, color) = switch (role) {
      UserRole.customer => ('Customer', theme.colorScheme.primary),
      UserRole.worker => ('Service Pro', Colors.orange),
      UserRole.admin => ('Admin', Colors.red),
      UserRole.manager => ('Manager', Colors.purple),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }

  List<_QuickActionItem> _getQuickActions(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return [
          _QuickActionItem('Notifications', 'Alert preferences', CupertinoIcons.bell_fill, () {}),
          _QuickActionItem('Payment Methods', 'Cards & billing', CupertinoIcons.creditcard, () {}),
          _QuickActionItem('Refer a Friend', 'Share the app', CupertinoIcons.share, () {}),
          _QuickActionItem('Get Help', 'Contact support', CupertinoIcons.question_circle, () {}),
        ];
      case UserRole.worker:
        return [
          _QuickActionItem('My Schedule', 'Upcoming jobs', CupertinoIcons.calendar, () {}),
          _QuickActionItem('Earnings', 'Payment summary', CupertinoIcons.money_dollar, () {}),
          _QuickActionItem('Availability', 'Set work hours', CupertinoIcons.clock, () {}),
          _QuickActionItem('Support', 'Contact dispatch', CupertinoIcons.question_circle, () {}),
        ];
      case UserRole.admin:
        return [
          _QuickActionItem('Dashboard', 'System overview', CupertinoIcons.chart_bar_fill, () {}),
          _QuickActionItem('Workers', 'Manage team', CupertinoIcons.person_2_fill, () {}),
          _QuickActionItem('Inventory', 'Stock & supplies', CupertinoIcons.tray_full_fill, () {}),
          _QuickActionItem('Analytics', 'Reports & data', CupertinoIcons.graph_square_fill, () {}),
        ];
      case UserRole.manager:
        return [
          _QuickActionItem('Buildings', 'Property portfolio', CupertinoIcons.building_2_fill, () {}),
          _QuickActionItem('Units', 'Tenant overview', CupertinoIcons.square_grid_2x2, () {}),
          _QuickActionItem('Maintenance', 'Open requests', CupertinoIcons.wrench_fill, () {}),
          _QuickActionItem('Reports', 'Monthly summaries', CupertinoIcons.doc_chart_fill, () {}),
        ];
    }
  }

  Widget _buildActionCard({required ThemeData theme, required _QuickActionItem item}) {
    return AnimatedTapScale(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x1F8BA5A7),
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
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return AnimatedTapScale(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x1F8BA5A7),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
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
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 14, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleInfoCard({required ThemeData theme, required UserRole role}) {
    final (title, description, icon) = switch (role) {
      UserRole.customer => (
        'Account Overview',
        'Manage your profile, notification preferences, and payment methods from this screen. Your home details and maintenance records are in Home Hub.',
        CupertinoIcons.person_fill,
      ),
      UserRole.worker => (
        "Professional's Workspace",
        'View your schedule, track earnings, and manage your work availability. Job details and navigation are in the Services tab.',
        CupertinoIcons.hammer_fill,
      ),
      UserRole.admin => (
        'Administrator Access',
        'Full platform control — manage workers, inventory, and system analytics. Monitor all operations from a single dashboard.',
        CupertinoIcons.shield_fill,
      ),
      UserRole.manager => (
        'Property Management',
        'Oversee buildings, units, and tenant maintenance requests across your portfolio. Generate reports and track open work orders.',
        CupertinoIcons.building_2_fill,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _QuickActionItem(this.title, this.subtitle, this.icon, this.onTap);
}
