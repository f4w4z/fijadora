import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
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
  bool _isRechecking = false;

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

  Future<void> _recheck() async {
    setState(() => _isRechecking = true);
    final statusBefore = ref.read(authViewModelProvider).user?.workerStatus;
    try {
      await ref.read(authViewModelProvider.notifier).refreshUser();
      if (!mounted) return;
      final statusAfter = ref.read(authViewModelProvider).user?.workerStatus;
      if (statusAfter == statusBefore) {
        context.showSnackBar('Still pending — check back later', type: SnackBarType.info);
      }
    } catch (_) {
      if (!mounted) return;
      context.showSnackBar('Could not check status. Try again.', type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isRechecking = false);
    }
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
                  const SizedBox(height: 24),
                  AnimatedTapScale(
                    onTap: _isRechecking ? () {} : () { _recheck(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isRechecking
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(CupertinoIcons.arrow_clockwise, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            _isRechecking ? 'Checking...' : 'Re-check Status',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
