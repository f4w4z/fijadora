import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../../domain/models/app_user.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/app_notification_service.dart';
import '../../../core/utilities/responsive_helpers.dart';

class StaffWorkersView extends ConsumerStatefulWidget {
  const StaffWorkersView({super.key});

  @override
  ConsumerState<StaffWorkersView> createState() => _StaffWorkersViewState();
}

class _StaffWorkersViewState extends ConsumerState<StaffWorkersView> {
  @override
  void initState() {
    super.initState();
    ref.read(authRepositoryProvider).refreshWorkers();
  }

  @override
  Widget build(BuildContext context) {
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
              child: _buildWorkerList(theme, borderColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerList(ThemeData theme, Color borderColor) {
    final authWorkers = ref.watch(authRepositoryProvider).getAllWorkers();
    final pending = authWorkers.where((w) => w.workerStatus == 'pending').toList();
    final approved = authWorkers.where((w) => w.workerStatus == 'approved').toList();

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
            onStatusChanged: () {
              ref.read(authRepositoryProvider).refreshWorkers();
              setState(() {});
            },
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE65100).withValues(alpha: 0.1),
            child: Text(
              worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'W',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100), fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(worker.email, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('PENDING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFE65100))),
          ),
          const SizedBox(width: 8),
          AnimatedTapScale(
            onTap: () => _approve(context, ref),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(CupertinoIcons.checkmark_alt, size: 18, color: Color(0xFF34C759)),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedTapScale(
            onTap: () => _reject(context, ref),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(CupertinoIcons.xmark, size: 18, color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _approve(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).updateWorkerStatus(userId: worker.id, status: 'approved');
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
    final borderColor = theme.brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFE5E5E5);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'W',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(worker.email, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('APPROVED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF34C759))),
          ),
        ],
      ),
    );
  }
}

