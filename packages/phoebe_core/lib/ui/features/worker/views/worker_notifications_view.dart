import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/utilities/responsive_helpers.dart';

class WorkerNotificationsView extends StatefulWidget {
  const WorkerNotificationsView({super.key});

  @override
  State<WorkerNotificationsView> createState() => _WorkerNotificationsViewState();
}

class _WorkerNotificationsViewState extends State<WorkerNotificationsView> {
  bool _newJobAlerts = true;
  bool _jobUpdates = true;
  bool _reminders = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: EdgeInsets.only(left: AppSpacing.lg),
            child: Icon(CupertinoIcons.chevron_left, size: 22, color: theme.colorScheme.onSurface),
          ),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.sm, context.pagePad, 40),
        children: [
          _sectionHeader(theme, 'Job Alerts'),
          _toggleRow(
            theme: theme,
            icon: CupertinoIcons.hammer_fill,
            title: 'New Job Alerts',
            subtitle: 'Get notified when new jobs are available',
            value: _newJobAlerts,
            onChanged: (v) => setState(() => _newJobAlerts = v),
          ),
          const SizedBox(height: 8),
          _toggleRow(
            theme: theme,
            icon: CupertinoIcons.arrow_counterclockwise,
            title: 'Job Updates',
            subtitle: 'Status changes and customer messages',
            value: _jobUpdates,
            onChanged: (v) => setState(() => _jobUpdates = v),
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'Reminders'),
          _toggleRow(
            theme: theme,
            icon: CupertinoIcons.alarm_fill,
            title: 'Upcoming Job Reminders',
            subtitle: 'Get reminded before scheduled jobs',
            value: _reminders,
            onChanged: (v) => setState(() => _reminders = v),
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'General'),
          _toggleRow(
            theme: theme,
            icon: CupertinoIcons.music_note,
            title: 'Sound',
            subtitle: 'Play sound for notifications',
            value: _soundEnabled,
            onChanged: (v) => setState(() => _soundEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.5),
      ),
    );
  }

  Widget _toggleRow({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
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
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          CupertinoSwitch(value: value, activeTrackColor: theme.colorScheme.primary, onChanged: onChanged),
        ],
      ),
    );
  }
}
