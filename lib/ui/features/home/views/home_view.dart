import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/custom_pinned_header.dart';
import '../../../shared/widgets/floating_header_layout.dart';
import '../../../core/theme.dart';
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
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
        bodyBuilder: (context, topPadding) {
          return CustomScrollView(
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
                        backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.accent,
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
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                                color: AppTheme.onSurface,
                                height: 1.0,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.textSecondary,
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
                  padding: const EdgeInsets.fromLTRB(28, 48, 28, 0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(CupertinoIcons.house_fill, size: 22, color: AppTheme.accent),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Family Home',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurface,
                                  height: 1.1,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '123 Main Street, Springfield',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textSecondary,
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
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
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
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
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
                      const SizedBox(width: 10),
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
                      const SizedBox(width: 10),
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
                  padding: const EdgeInsets.fromLTRB(28, 56, 28, 0),
                  child: Text(
                    'Upcoming',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
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
                  padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
                  child: _ReminderTile(
                    icon: CupertinoIcons.bell_fill,
                    title: 'Smoke Detector',
                    subtitle: 'Test batteries next week',
                    detail: 'Bi-annual',
                    color: AppTheme.accent,
                  ),
                ),
              ),

              // ─── Maintenance History ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
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
                        color: AppTheme.cardSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(CupertinoIcons.clock, size: 20, color: AppTheme.accent),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Maintenance History',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.onSurface,
                                    letterSpacing: 0.0,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Invoices, repairs, and receipts',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(CupertinoIcons.chevron_right, size: 16, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Settings ───────────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 56, 28, 0),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: _SettingsRow(
                    icon: CupertinoIcons.bell_fill,
                    title: 'Notifications',
                    subtitle: 'Alert preferences',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                  child: _SettingsRow(
                    icon: CupertinoIcons.creditcard,
                    title: 'Payment Methods',
                    subtitle: 'Cards & billing',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                  child: _SettingsRow(
                    icon: CupertinoIcons.doc_text,
                    title: 'Terms & Conditions',
                    subtitle: 'Platform terms',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                  child: _SettingsRow(
                    icon: CupertinoIcons.shield,
                    title: 'Privacy Policy',
                    subtitle: 'Data handling',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                  child: _SettingsRow(
                    icon: CupertinoIcons.question_circle,
                    title: 'Help & Support',
                    subtitle: 'Get help',
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
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
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: AppTheme.accent),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.onSurface,
                  height: 1.0,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
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
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurface,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
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
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      scaleFactor: 0.97,
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: AppTheme.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurface,
                      letterSpacing: 0.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
