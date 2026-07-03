import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../core/utilities/responsive_helpers.dart';

import '../../../shared/widgets/shimmer_loading.dart';
import '../../services/view_models/jobs_view_model.dart';

class StaffManagerDashboardView extends ConsumerWidget {
  const StaffManagerDashboardView({super.key});

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
                final pendingApprovals = jobs.where((j) => j.status == JobStatus.waitingApproval).length;
                final activeJobs = jobs.where((j) => j.status == JobStatus.inProgress || j.status == JobStatus.assigned).length;

                return [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(context.pagePad, 0, context.pagePad, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _SummaryRow(
                          items: [
                            _SummaryItem(label: 'Properties', value: '2', icon: CupertinoIcons.building_2_fill, color: theme.colorScheme.primary),
                            _SummaryItem(label: 'Pending Approvals', value: '$pendingApprovals', icon: CupertinoIcons.clock, color: const Color(0xFFE65100)),
                            _SummaryItem(label: 'Active Jobs', value: '$activeJobs', icon: CupertinoIcons.hammer_fill, color: const Color(0xFF3F51B5)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        ...jobs.take(5).map((job) => _ActivityRow(job: job, theme: theme)),
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
                        Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        const ShimmerActivityRow(count: 3),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.items});

  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 110),
              margin: const EdgeInsets.only(right: 12),
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
                    decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(item.icon, size: 18, color: item.color),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 2),
                        Text(item.label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.icon, required this.color});
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.job, required this.theme});
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
              child: Icon(_statusIcon(job.status), size: 16, color: job.status.color(context)),
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

  IconData _statusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.pending: return CupertinoIcons.clock;
      case JobStatus.quoted: return CupertinoIcons.doc_text;
      case JobStatus.assigned: return CupertinoIcons.person_fill;
      case JobStatus.workerEnRoute: return CupertinoIcons.location;
      case JobStatus.workerArrived: return CupertinoIcons.house_fill;
      case JobStatus.inProgress: return CupertinoIcons.hammer_fill;
      case JobStatus.waitingApproval: return CupertinoIcons.checkmark_seal_fill;
      case JobStatus.completed: return CupertinoIcons.checkmark_alt_circle_fill;
      case JobStatus.rejected: return CupertinoIcons.xmark_circle_fill;
      case JobStatus.cancelled: return CupertinoIcons.xmark_circle_fill;
      case JobStatus.onHold: return CupertinoIcons.pause_fill;
      case JobStatus.rescheduled: return CupertinoIcons.calendar;
      case JobStatus.awaitingParts: return CupertinoIcons.clock;
    }
  }
}
