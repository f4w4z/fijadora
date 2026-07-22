import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/users_repository.dart';
import '../../../../data/services/app_notification_service.dart';
import '../../../../data/services/push_notification_service.dart';
import '../../../../domain/models/app_user.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../services/view_models/jobs_view_model.dart';

class StaffAdminDashboardView extends ConsumerWidget {
  const StaffAdminDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final jobsAsync = ref.watch(jobsStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.md, context.pagePad, 0),
                child: Text('Dashboard', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: theme.colorScheme.onSurface)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ...jobsAsync.maybeWhen(
              data: (jobs) {
                final pending = jobs.where((j) => j.status == JobStatus.pending).length;
                final active = jobs.where((j) =>
                    j.status == JobStatus.assigned ||
                    j.status == JobStatus.workerEnRoute ||
                    j.status == JobStatus.workerArrived ||
                    j.status == JobStatus.inProgress).length;
                final awaitingApproval = jobs.where((j) => j.status == JobStatus.waitingApproval).length;
                final completed = jobs.where((j) => j.status == JobStatus.completed).length;

                return [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(context.pagePad, 0, context.pagePad, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _SummaryGrid(jobs: jobs, pending: pending, active: active, awaitingApproval: awaitingApproval),
                        const SizedBox(height: 24),
                        Text('Recent Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        ...jobs.take(5).map((job) => _JobRow(job: job, theme: theme)),
                        const SizedBox(height: 16),
                        Text('Status Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        _StatusBar(
                          pending: pending,
                          active: active,
                          awaitingApproval: awaitingApproval,
                          completed: completed,
                          total: jobs.length,
                        ),
                        const SizedBox(height: 24),
                        const _PendingWorkerApprovalsSection(),
                      ]),
                    ),
                  ),
                ];
              },
              orElse: () {
                if (jobsAsync.hasError) {
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('Error: ${jobsAsync.error}', style: TextStyle(color: theme.colorScheme.error)),
                      ),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(context.pagePad, 0, context.pagePad, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const ShimmerSummaryRow(),
                        const SizedBox(height: 24),
                        Text('Recent Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        const ShimmerActivityRow(count: 3),
                        const SizedBox(height: 16),
                        Text('Status Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        const SkeletonBox(width: double.infinity, height: 120, borderRadius: 12),
                      ]),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.jobs, required this.pending, required this.active, required this.awaitingApproval});

  final List<MaintenanceJob> jobs;
  final int pending;
  final int active;
  final int awaitingApproval;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        children: [
          _SummaryCard(label: 'Pending', value: '$pending', icon: CupertinoIcons.clock, color: const Color(0xFFF57F17), theme: theme),
          const SizedBox(width: 12),
          _SummaryCard(label: 'Active', value: '$active', icon: CupertinoIcons.hammer_fill, color: const Color(0xFF3F51B5), theme: theme),
          const SizedBox(width: 12),
          _SummaryCard(label: 'Approval', value: '$awaitingApproval', icon: CupertinoIcons.checkmark_seal_fill, color: const Color(0xFFE65100), theme: theme),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color, required this.theme});

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFE5E5E5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 12),
             Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job, required this.theme});
  final MaintenanceJob job;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final statusColor = job.status.color(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.tradeType.displayName,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    job.address,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                job.status.displayName,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.pending, required this.active, required this.awaitingApproval, required this.completed, required this.total});

  final int pending;
  final int active;
  final int awaitingApproval;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFE5E5E5)),
        ),
        child: Text('No jobs yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (pending > 0) Flexible(flex: pending, child: Container(color: const Color(0xFFF57F17))),
                  if (active > 0) Flexible(flex: active, child: Container(color: const Color(0xFF3F51B5))),
                  if (awaitingApproval > 0) Flexible(flex: awaitingApproval, child: Container(color: const Color(0xFFE65100))),
                  if (completed > 0) Flexible(flex: completed, child: Container(color: const Color(0xFF2E7D32))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _LegendItem(color: const Color(0xFFF57F17), label: 'Pending', count: pending, theme: theme),
          _LegendItem(color: const Color(0xFF3F51B5), label: 'Active', count: active, theme: theme),
          _LegendItem(color: const Color(0xFFE65100), label: 'Awaiting Approval', count: awaitingApproval, theme: theme),
          _LegendItem(color: const Color(0xFF2E7D32), label: 'Completed', count: completed, theme: theme),
        ],
      ),
    );
  }
}

class _PendingWorkerApprovalsSection extends ConsumerWidget {
  const _PendingWorkerApprovalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workers = ref.watch(workersProvider).valueOrNull ?? const [];
    final pending = workers.where((w) => w.workerStatus == 'pending').toList();

    if (pending.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Worker Approvals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
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
        ...pending.map((worker) => _DashboardPendingWorkerCard(
          worker: worker,
          onStatusChanged: () => ref.invalidate(workersProvider),
        )),
      ],
    );
  }
}

class _DashboardPendingWorkerCard extends ConsumerWidget {
  const _DashboardPendingWorkerCard({required this.worker, required this.onStatusChanged});
  final AppUser worker;
  final VoidCallback onStatusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'W',
              style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  worker.email,
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedTapScale(
                onTap: () => _reject(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(CupertinoIcons.xmark, size: 16, color: theme.colorScheme.error),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedTapScale(
                onTap: () => _approve(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(CupertinoIcons.checkmark_alt, size: 16, color: Color(0xFF34C759)),
                ),
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

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label, required this.count, required this.theme});
  final Color color;
  final String label;
  final int count;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface))),
          Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
