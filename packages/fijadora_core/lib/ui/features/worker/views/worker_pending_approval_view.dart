import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/widgets/app_animations.dart';

class WorkerPendingApprovalView extends ConsumerStatefulWidget {
  const WorkerPendingApprovalView({super.key});

  @override
  ConsumerState<WorkerPendingApprovalView> createState() => _WorkerPendingApprovalViewState();
}

class _WorkerPendingApprovalViewState extends ConsumerState<WorkerPendingApprovalView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authViewModelProvider).user;

    return Scaffold(
      body: SafeArea(
        child: AnimatedAppearance(
          duration: AppDurations.slow,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.pagePad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.clock, size: 48, color: Color(0xFFE65100)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pending Approval',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your account is currently pending admin approval.\nYou will be able to access the worker app once an admin approves your registration.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'W',
                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(user.email, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: () => ref.read(authViewModelProvider.notifier).signOut(),
                    icon: const Icon(CupertinoIcons.square_arrow_right, size: 16),
                    label: const Text('Sign Out'),
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
