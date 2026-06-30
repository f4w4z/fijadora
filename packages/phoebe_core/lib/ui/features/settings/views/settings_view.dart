import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme_provider.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          _section(context, 'General'),
          _SettingsRow(icon: CupertinoIcons.bell_fill, title: 'Notifications', subtitle: 'Alert preferences'),
          const Divider(height: 1, indent: 44),
          const _AppearanceRow(),
          const Divider(height: 1, indent: 44),
          _SettingsRow(icon: CupertinoIcons.creditcard, title: 'Payment Methods', subtitle: 'Cards & billing'),
          const SizedBox(height: 28),
          _section(context, 'About'),
          _SettingsRow(icon: CupertinoIcons.doc_text, title: 'Terms & Conditions', subtitle: 'Platform terms'),
          const Divider(height: 1, indent: 44),
          _SettingsRow(icon: CupertinoIcons.shield, title: 'Privacy Policy', subtitle: 'Data handling'),
          const Divider(height: 1, indent: 44),
          _SettingsRow(icon: CupertinoIcons.question_circle, title: 'Help & Support', subtitle: 'Get help'),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
            ),
            if (subtitle != null)
              Text(subtitle!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(width: 8),
            Icon(CupertinoIcons.chevron_right, size: 14, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _AppearanceRow extends ConsumerWidget {
  const _AppearanceRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Icon(CupertinoIcons.moon_fill, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Appearance', style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
          ),
          Text(isDark ? 'Dark mode' : 'Light mode', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: isDark,
            activeTrackColor: theme.colorScheme.primary,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
    );
  }
}
