import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../../domain/models/app_user.dart';
import '../../../../data/repositories/users_repository.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/app_notification_service.dart';
import '../../../../data/services/push_notification_service.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../core/utilities/responsive_helpers.dart';

class StaffWorkersView extends ConsumerWidget {
  const StaffWorkersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFE5E5E5);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.md, context.pagePad, 0),
              child: Text('Workers', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: theme.colorScheme.onSurface)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildWorkerList(context, ref, theme, borderColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerList(BuildContext context, WidgetRef ref, ThemeData theme, Color borderColor) {
    final workersAsync = ref.watch(workersProvider);
    return workersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateWidget(
        message: 'Could not load workers.',
        onRetry: () => ref.invalidate(workersProvider),
      ),
      data: (workers) => _buildLoadedList(context, ref, theme, workers),
    );
  }

  Widget _buildLoadedList(BuildContext context, WidgetRef ref, ThemeData theme, List<AppUser> workers) {
    final pending = workers.where((w) => w.workerStatus == 'pending').toList();
    final approved = workers.where((w) => w.workerStatus == 'approved').toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.sm, context.pagePad, 120),
      children: [
        if (pending.isNotEmpty) ...[
          Row(
            children: [
              Text('Pending Approvals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${pending.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE65100))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...pending.map((worker) => _PendingWorkerCard(
            worker: worker,
            onStatusChanged: () => ref.invalidate(workersProvider),
          )),
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            Text('Team', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(width: 8),
            Text('${approved.length} approved', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 10),
        if (approved.isNotEmpty)
          ...approved.map((worker) => _ApprovedAuthWorkerCard(worker: worker)),
        if (approved.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(CupertinoIcons.person_3_fill, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('No approved workers yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
      ],
    );
  }

}

class _PendingWorkerCard extends ConsumerWidget {
  const _PendingWorkerCard({required this.worker, required this.onStatusChanged});
  final AppUser worker;
  final VoidCallback onStatusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final orange = const Color(0xFFE65100);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: orange.withValues(alpha: 0.12),
            child: Text(
              worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'W',
              style: TextStyle(fontWeight: FontWeight.w700, color: orange, fontSize: 20, letterSpacing: -0.5),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 1),
                Text(worker.email, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Worker', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: orange, letterSpacing: 0.3)),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.clock_solid, size: 9, color: orange),
                    const SizedBox(width: 4),
                    Text('Pending', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: orange, letterSpacing: 0.3)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedTapScale(
                    onTap: () => _approve(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.checkmark_alt, size: 14, color: const Color(0xFF34C759)),
                          const SizedBox(width: 4),
                          Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF34C759))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedTapScale(
                    onTap: () => _reject(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.xmark, size: 14, color: theme.colorScheme.error),
                          const SizedBox(width: 4),
                          Text('Reject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.error)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _approve(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).updateWorkerStatus(userId: worker.id, status: 'approved');
    PushNotificationService.sendNotification(
      userId: worker.id,
      title: 'Account Approved',
      body: 'You can now access the worker app.',
    );
    ref.read(notificationServiceProvider).sendNotification(
      title: 'Worker Approved',
      body: '${worker.name} can now access the worker app.',
    );
    onStatusChanged();
    if (context.mounted) {
      context.showSnackBar('${worker.name} approved', type: SnackBarType.success);
    }
  }

  void _reject(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).updateWorkerStatus(userId: worker.id, status: 'rejected');
    PushNotificationService.sendNotification(
      userId: worker.id,
      title: 'Account Rejected',
      body: 'Your worker registration was not approved.',
    );
    onStatusChanged();
    if (context.mounted) {
      context.showSnackBar('${worker.name} rejected', type: SnackBarType.error);
    }
  }
}

class _ApprovedAuthWorkerCard extends StatelessWidget {
  const _ApprovedAuthWorkerCard({required this.worker});
  final AppUser worker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = const Color(0xFF34C759);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: green.withValues(alpha: 0.1),
            child: Text(
              worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'W',
              style: TextStyle(fontWeight: FontWeight.w700, color: green, fontSize: 20, letterSpacing: -0.5),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 1),
                Text(worker.email, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Worker', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: green, letterSpacing: 0.3)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.checkmark_seal_fill, size: 11, color: green),
                const SizedBox(width: 4),
                Text('Approved', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: green, letterSpacing: 0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

