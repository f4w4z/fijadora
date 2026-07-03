import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app_config.dart';
import '../view_models/auth_view_model.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/widgets/app_animations.dart';

class AccessDeniedView extends ConsumerWidget {
  const AccessDeniedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.read(appConfigProvider);
    return Scaffold(
      body: Center(
        child: AnimatedAppearance(
          duration: AppDurations.slow,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 72, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: AppSpacing.xxl),
                Text('Wrong App', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'This app is for ${config.label} users only.\nPlease sign in with the correct account.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                FilledButton.icon(
                  onPressed: () => ref.read(authViewModelProvider).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
