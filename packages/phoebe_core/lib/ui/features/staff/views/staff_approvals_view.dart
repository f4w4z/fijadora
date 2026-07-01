import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../data/services/notification_service.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../ui/shared/utils/notification_helper.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/user_role.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';

class StaffApprovalsView extends ConsumerStatefulWidget {
  const StaffApprovalsView({super.key});

  @override
  ConsumerState<StaffApprovalsView> createState() => _StaffApprovalsViewState();
}

class _StaffApprovalsViewState extends ConsumerState<StaffApprovalsView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobsRepo = ref.watch(jobsRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<MaintenanceJob>>(
          stream: jobsRepo.streamJobs(userId: 'manager', role: ref.read(authViewModelProvider).user?.role ?? UserRole.manager),
          builder: (context, snapshot) {
            final approvals = (snapshot.data ?? [])
                .where((j) => j.status == JobStatus.waitingApproval)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Approvals', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: theme.colorScheme.onSurface)),
                      ),
                      if (approvals.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${approvals.length} pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.error)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : approvals.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.checkmark_seal_fill, size: 48, color: const Color(0xFF34C759).withValues(alpha: 0.3)),
                                  const SizedBox(height: 12),
                                  Text('No pending approvals', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                              itemCount: approvals.length,
                              itemBuilder: (context, index) {
                                final job = approvals[index];
                                return _ApprovalCard(
                                  job: job,
                                  onApprove: () async {
                                    try {
                                      await jobsRepo.updateJobStatus(jobId: job.id, status: JobStatus.completed);
                                      notificationService.sendNotification(
                                        title: 'Job Approved',
                                        body: '${job.tradeType.displayName} job has been approved',
                                      );
                                      if (context.mounted) {
                                        context.showSnackBar('Job approved', type: SnackBarType.success);
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        context.showSnackBar('Failed to approve: $e', type: SnackBarType.error);
                                      }
                                    }
                                  },
                                  onReject: () async {
                                    try {
                                      await jobsRepo.updateJobStatus(jobId: job.id, status: JobStatus.rejected);
                                      notificationService.sendNotification(
                                        title: 'Job Rejected',
                                        body: '${job.tradeType.displayName} job has been rejected',
                                      );
                                      if (context.mounted) {
                                        context.showSnackBar('Job rejected', type: SnackBarType.success);
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        context.showSnackBar('Failed to reject: $e', type: SnackBarType.error);
                                      }
                                    }
                                  },
                                );
                              },
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

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.job,
    required this.onApprove,
    required this.onReject,
  });

  final MaintenanceJob job;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job.tradeType.displayName.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 0.5),
                ),
              ),
              const Spacer(),
              Text(
                job.status.displayName.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFE65100), letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(job.description, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(CupertinoIcons.location, size: 13, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(job.address, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(CupertinoIcons.clock, size: 13, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                'Scheduled: ${_formatDate(job.scheduleDateTime)}',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AnimatedTapScale(
                  onTap: onReject,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
                    ),
                    child: Center(
                      child: Text('Reject', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.error)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedTapScale(
                  onTap: onApprove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Approve', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
