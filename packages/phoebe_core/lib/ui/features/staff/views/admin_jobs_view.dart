import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../data/services/app_notification_service.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/trade_type.dart';
import '../../../../domain/models/user_role.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/utils/date_extensions.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../core/utilities/responsive_helpers.dart';

class AdminJobsView extends ConsumerStatefulWidget {
  const AdminJobsView({super.key});

  @override
  ConsumerState<AdminJobsView> createState() => _AdminJobsViewState();
}

class _AdminJobsViewState extends ConsumerState<AdminJobsView> {
  JobStatus? _activeFilter;
  String _searchQuery = '';

  List<Map<String, String>> get _workers {
    final authWorkers = ref.read(authRepositoryProvider).getAllWorkers();
    return authWorkers.map((w) => {
      'id': w.id,
      'name': w.name,
    }).toList();
  }

  List<MaintenanceJob> _filterJobs(List<MaintenanceJob> jobs) {
    var filtered = jobs;
    if (_activeFilter != null) {
      filtered = filtered.where((j) => j.status == _activeFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((j) =>
        j.description.toLowerCase().contains(q) ||
        j.address.toLowerCase().contains(q) ||
        j.tradeType.displayName.toLowerCase().contains(q)
      ).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobsRepo = ref.watch(jobsRepositoryProvider);
    final authUser = ref.watch(authViewModelProvider).user;
    final adminUserId = authUser?.id ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.md, context.pagePad, 0),
              child: Text('Jobs', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: theme.colorScheme.onSurface)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.pagePad),
              child: SizedBox(
                height: 36,
                child: CupertinoSearchTextField(
                  placeholder: 'Search jobs...',
                  onChanged: (v) => setState(() => _searchQuery = v),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  prefixIcon: const Icon(CupertinoIcons.search, size: 16),
                  suffixIcon: const Icon(CupertinoIcons.xmark_circle_fill, size: 16),
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<MaintenanceJob>>(
                stream: jobsRepo.streamJobs(userId: adminUserId, role: UserRole.admin),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final allJobs = snapshot.data ?? [];
                  final jobs = _filterJobs(allJobs);
                  final counts = _buildCounts(allJobs);

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(left: context.pagePad),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'All',
                                  count: counts.total,
                                  selected: _activeFilter == null,
                                  onTap: () => setState(() => _activeFilter = null),
                                  theme: theme,
                                ),
                                const SizedBox(width: 6),
                                _FilterChip(
                                  label: 'Pending',
                                  count: counts.pending,
                                  selected: _activeFilter == JobStatus.pending,
                                  onTap: () => setState(() => _activeFilter = JobStatus.pending),
                                  theme: theme,
                                ),
                                const SizedBox(width: 6),
                                _FilterChip(
                                  label: 'Active',
                                  count: counts.active,
                                  selected: _activeFilter == JobStatus.inProgress,
                                  onTap: () => setState(() => _activeFilter = JobStatus.inProgress),
                                  theme: theme,
                                ),
                                const SizedBox(width: 6),
                                _FilterChip(
                                  label: 'Done',
                                  count: counts.completed,
                                  selected: _activeFilter == JobStatus.completed,
                                  onTap: () => setState(() => _activeFilter = JobStatus.completed),
                                  theme: theme,
                                ),
                                const SizedBox(width: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      if (jobs.isEmpty)
                        SliverFillRemaining(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Column(
                              children: [
                                Icon(CupertinoIcons.square_list, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                Text('No jobs found', style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(context.pagePad, 0, context.pagePad, 120),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return JobCard(
                                  job: jobs[index],
                                  workers: _workers,
                                );
                              },
                              childCount: jobs.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({int total, int pending, int active, int completed}) _buildCounts(List<MaintenanceJob> jobs) {
    int pending = 0, active = 0, completed = 0;
    for (final j in jobs) {
      switch (j.status) {
        case JobStatus.pending:
        case JobStatus.quoted:
        case JobStatus.assigned:
          pending++;
        case JobStatus.workerEnRoute:
        case JobStatus.workerArrived:
        case JobStatus.inProgress:
        case JobStatus.waitingApproval:
        case JobStatus.onHold:
        case JobStatus.rescheduled:
        case JobStatus.awaitingParts:
          active++;
        case JobStatus.completed:
          completed++;
        case JobStatus.rejected:
        case JobStatus.cancelled:
          break;
      }
    }
    return (total: jobs.length, pending: pending, active: active, completed: completed);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.onPrimary.withValues(alpha: 0.2) : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class JobCard extends ConsumerStatefulWidget {
  final MaintenanceJob job;
  final List<Map<String, String>> workers;

  const JobCard({super.key, required this.job, required this.workers});

  @override
  ConsumerState<JobCard> createState() => _JobCardState();
}

class _JobCardState extends ConsumerState<JobCard> {
  bool _isAssigning = false;

  String _workerName(String? workerId) {
    if (workerId == null || workerId.isEmpty) return 'Unassigned';
    final match = widget.workers.cast<Map<String, String>?>().firstWhere(
      (w) => w!['id'] == workerId,
      orElse: () => null,
    );
    return match?['name'] ?? workerId;
  }

  Color _statusColor(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
      case JobStatus.quoted:
      case JobStatus.assigned:
        return Colors.orange;
      case JobStatus.workerEnRoute:
      case JobStatus.workerArrived:
      case JobStatus.inProgress:
      case JobStatus.waitingApproval:
      case JobStatus.onHold:
      case JobStatus.rescheduled:
      case JobStatus.awaitingParts:
        return Colors.blue;
      case JobStatus.completed:
        return Colors.green;
      case JobStatus.rejected:
      case JobStatus.cancelled:
        return Colors.red;
    }
  }

  String _statusLabel(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return 'Pending';
      case JobStatus.quoted:
        return 'Quoted';
      case JobStatus.assigned:
        return 'Assigned';
      case JobStatus.workerEnRoute:
        return 'En Route';
      case JobStatus.workerArrived:
        return 'Arrived';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.waitingApproval:
        return 'Review';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.rejected:
        return 'Rejected';
      case JobStatus.cancelled:
        return 'Cancelled';
      case JobStatus.onHold:
        return 'On Hold';
      case JobStatus.rescheduled:
        return 'Rescheduled';
      case JobStatus.awaitingParts:
        return 'Awaiting Parts';
    }
  }

  Color _tradeColor(TradeType type) {
    switch (type) {
      case TradeType.interiorDesign:
        return const Color(0xFF8E44AD);
      case TradeType.electrical:
        return const Color(0xFFFFB300);
      case TradeType.plumbing:
        return const Color(0xFF1E88E5);
      case TradeType.masonry:
        return const Color(0xFF8D6E63);
      case TradeType.tiling:
        return const Color(0xFF00ACC1);
      case TradeType.designConsultation:
        return const Color(0xFFEC407A);
      case TradeType.acEngineering:
        return const Color(0xFF26A69A);
      case TradeType.kitchenDesigns:
        return const Color(0xFF78909C);
      case TradeType.cleaning:
        return const Color(0xFF1E88E5);
      case TradeType.gardening:
        return const Color(0xFF43A047);
    }
  }

  void _showAssignSheet() {
    final theme = Theme.of(context);
    showAppBottomSheet(
      context: context,
      maxHeight: 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assign Technician', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          ...widget.workers.map((worker) {
          final name = worker['name'] ?? '';
          final id = worker['id'] ?? '';
          final initials = name.split(' ').length >= 2
              ? '${name.split(' ')[0][0]}${name.split(' ')[1][0]}'
              : name.isNotEmpty ? name[0] : '';
          final color = _tradeColor(widget.job.tradeType);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AnimatedTapScale(
              onTap: _isAssigning ? () {} : () => _assignWorker(id, name),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Text(initials, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.star_fill, size: 10, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text('4.9', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              const Text('Available', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_isAssigning)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Icon(CupertinoIcons.chevron_right, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ),
          );
        }),
        ],
      ),
    );
  }

  Future<void> _assignWorker(String workerId, String workerName) async {
    setState(() => _isAssigning = true);

    try {
      await ref.read(jobsRepositoryProvider).assignWorker(jobId: widget.job.id, workerId: workerId);
      ref.read(notificationServiceProvider).sendNotification(title: 'Worker Dispatched', body: 'Job assigned to $workerName.');
      if (mounted) {
        Navigator.of(context).pop();
        context.showSnackBar('Assigned to $workerName', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = widget.job;
    final isUnassigned = job.workerId == null || job.workerId!.isEmpty;
    final statusColor = _statusColor(job.status);
    final tradeColor = _tradeColor(job.tradeType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tradeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(job.tradeType.icon, size: 11, color: tradeColor),
                    const SizedBox(width: 4),
                    Text(job.tradeType.displayName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tradeColor)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_statusLabel(job.status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(job.description, style: TextStyle(fontSize: 14, height: 1.3, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(CupertinoIcons.location_fill, size: 12, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(width: 5),
              Expanded(child: Text(job.address, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(CupertinoIcons.calendar_today, size: 12, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(width: 5),
              Text(job.scheduleDateTime?.formattedDateTime ?? 'Not scheduled', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isUnassigned ? CupertinoIcons.exclamationmark_circle_fill : CupertinoIcons.person_crop_circle_fill,
                      size: 14, color: isUnassigned ? Colors.orange : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isUnassigned ? 'Unassigned' : _workerName(job.workerId),
                      style: TextStyle(fontSize: 12, fontWeight: isUnassigned ? FontWeight.w600 : FontWeight.w500, color: isUnassigned ? Colors.orange.shade700 : theme.colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isUnassigned && job.status == JobStatus.pending)
                AnimatedTapScale(
                  onTap: _showAssignSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.person_badge_plus_fill, size: 13, color: theme.colorScheme.onPrimary),
                        const SizedBox(width: 5),
                        Text('Assign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onPrimary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
