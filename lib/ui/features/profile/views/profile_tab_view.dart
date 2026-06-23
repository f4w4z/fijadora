import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/view_models/auth_view_model.dart';
import 'home_detail_list_view.dart';
import '../../../shared/widgets/animated_tap_scale.dart';

class ProfileTabView extends ConsumerWidget {
  const ProfileTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authViewModelProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Hub'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right),
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Info Card
            if (user != null)
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                        ),
                        Text(
                          user.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
            const SizedBox(height: 32.0),

            // Predictive Reminders Card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.bell_fill, color: theme.colorScheme.primary, size: 18),
                      const SizedBox(width: 8.0),
                      Text(
                        'Predictive Reminders',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  _buildReminderItem('Air Filter (HVAC)', 'Replace filter in 6 days (due quarterly)', theme),
                  const SizedBox(height: 10.0),
                  _buildReminderItem('Smoke Detector', 'Test batteries next week (due bi-annually)', theme),
                ],
              ),
            ),

            const SizedBox(height: 32.0),

            // Digital Home Record Section
            Text(
              'Digital Home Record',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16.0),

            // Main features grid list
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.4,
              ),
              children: [
                _buildRecordCard('Rooms', '6 Rooms', CupertinoIcons.square_grid_2x2, theme, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'rooms')),
                  );
                }),
                _buildRecordCard('Appliances', '4 Managed', CupertinoIcons.device_desktop, theme, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'appliances')),
                  );
                }),
                _buildRecordCard('Paint Codes', '3 Active', CupertinoIcons.paintbrush, theme, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'paint')),
                  );
                }),
                _buildRecordCard('Warranties', '3 Enrolled', CupertinoIcons.doc_text, theme, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'warranties')),
                  );
                }),
              ],
            ),

            const SizedBox(height: 32.0),

            // Maintenance History Trigger
            AnimatedTapScale(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const HomeDetailListView(type: 'history')),
                );
              },
              child: Card(
                child: ListTile(
                  leading: Icon(CupertinoIcons.clock, color: theme.colorScheme.primary),
                  title: const Text('Maintenance History', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('View past invoices, repairs, and receipts'),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItem(String title, String subtitle, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(String title, String count, IconData icon, ThemeData theme, VoidCallback onTap) {
    return AnimatedTapScale(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 24, color: theme.colorScheme.primary),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    count,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
