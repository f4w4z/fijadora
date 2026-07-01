import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/user_role.dart';
import '../../auth/view_models/auth_view_model.dart';

class StaffAdminDashboardView extends ConsumerWidget {
  const StaffAdminDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final jobsRepo = ref.watch(jobsRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<MaintenanceJob>>(
          stream: jobsRepo.streamJobs(userId: 'admin', role: ref.read(authViewModelProvider).user?.role ?? UserRole.admin),
          builder: (context, snapshot) {
            final jobs = snapshot.data ?? [];
            final pending = jobs.where((j) => j.status == JobStatus.pending).length;
            final active = jobs.where((j) =>
                j.status == JobStatus.assigned ||
                j.status == JobStatus.workerEnRoute ||
                j.status == JobStatus.workerArrived ||
                j.status == JobStatus.inProgress).length;
            final awaitingApproval = jobs.where((j) => j.status == JobStatus.waitingApproval).length;
            final completed = jobs.where((j) => j.status == JobStatus.completed).length;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Text('Dashboard', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: theme.colorScheme.onSurface)),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
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
                    ]),
                  ),
                ),
              ],
            );
          },
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFE5E5E5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: job.status.color(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(job.tradeType.displayName[0], style: TextStyle(fontWeight: FontWeight.bold, color: job.status.color(context), fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.tradeType.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(job.address, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: job.status.color(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(job.status.displayName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: job.status.color(context)), maxLines: 1),
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
