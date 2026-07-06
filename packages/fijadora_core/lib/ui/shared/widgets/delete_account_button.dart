import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/view_models/auth_view_model.dart';
import 'animated_tap_scale.dart';

class DeleteAccountButton extends ConsumerWidget {
  const DeleteAccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AnimatedTapScale(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'This will permanently delete your account and all associated data. '
              'This action cannot be undone. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          try {
            await ref.read(authViewModelProvider.notifier).deleteAccount();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete account: $e')),
              );
            }
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever_outlined,
                size: 18, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            Text(
              'Delete Account',
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
  }
}
