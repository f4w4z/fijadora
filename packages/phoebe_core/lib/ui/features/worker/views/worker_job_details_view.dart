import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../../services/view_models/jobs_view_model.dart';
import '../../../shared/utils/date_extensions.dart';
import 'job_completion_page.dart';

const _statusSteps = [
  JobStatus.assigned,
  JobStatus.workerEnRoute,
  JobStatus.workerArrived,
  JobStatus.inProgress,
  JobStatus.waitingApproval,
];

class WorkerJobDetailsView extends ConsumerStatefulWidget {
  const WorkerJobDetailsView({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<WorkerJobDetailsView> createState() =>
      _WorkerJobDetailsViewState();
}

class _WorkerJobDetailsViewState
    extends ConsumerState<WorkerJobDetailsView> {
  int _currentStepIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobsViewModel = ref.watch(jobsViewModelProvider);

    final jobIndex =
        jobsViewModel.jobs.indexWhere((j) => j.id == widget.jobId);
    if (jobIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: const Center(child: Text('Job not found')),
      );
    }
    final job = jobsViewModel.jobs[jobIndex];

    _currentStepIndex = _statusSteps.indexOf(job.status);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            expandedHeight: 120,
            pinned: true,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(CupertinoIcons.chevron_left, size: 22, color: theme.colorScheme.onSurface),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(job.tradeType.icon,
                          size: 20, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            job.tradeType.displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Job #${job.id.length > 8 ? job.id.substring(0, 8) : job.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            job.status.color(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        job.status.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: job.status.color(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress stepper
                  if (_currentStepIndex >= 0)
                    _ProgressStepper(
                      currentIndex: _currentStepIndex,
                      theme: theme,
                    ),
                  const SizedBox(height: 24),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          icon: CupertinoIcons.location,
                          label: 'Location',
                          value: job.address,
                          theme: theme,
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          icon: CupertinoIcons.calendar,
                          label: 'Scheduled',
                          value: job.scheduleDateTime.formattedFull,
                          theme: theme,
                        ),
                        if (job.status == JobStatus.completed) ...[
                          const SizedBox(height: 14),
                          _InfoRow(
                            icon: CupertinoIcons.shield_fill,
                            label: 'Guarantee',
                            value: '30-Day Workmanship Guarantee Active',
                            theme: theme,
                            valueColor: const Color(0xFF2E7D32),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      job.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Active timer
                  if (job.status == JobStatus.inProgress) ...[
                    const _ActiveTimerCard(),
                    const SizedBox(height: 20),
                  ],

                  // Action controls
                  _ActionControls(
                    job: job,
                    onUpdateStatus: (newStatus) async {
                      await ref
                          .read(jobsViewModelProvider)
                          .updateStatus(job.id, newStatus);
                    },
                    onCompleteJob: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              JobCompletionPage(jobId: job.id),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Body cam notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.videocam_fill,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Body cam active. Footage stored 6 months.',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStepper extends StatelessWidget {
  const _ProgressStepper({
    required this.currentIndex,
    required this.theme,
  });

  final int currentIndex;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final labels = ['Assigned', 'En Route', 'Arrived', 'In Progress', 'Review'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isCompleted = i <= currentIndex;
          final isCurrent = i == currentIndex;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i <= currentIndex
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    Container(
                      width: isCurrent ? 28 : 24,
                      height: isCurrent ? 28 : 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                      child: Center(
                        child: isCompleted && i < currentIndex
                            ? Icon(CupertinoIcons.check_mark,
                                size: 12,
                                color: theme.colorScheme.onPrimary)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                    if (i < labels.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < currentIndex
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                        isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionControls extends StatelessWidget {
  const _ActionControls({
    required this.job,
    required this.onUpdateStatus,
    required this.onCompleteJob,
  });

  final MaintenanceJob job;
  final ValueChanged<JobStatus> onUpdateStatus;
  final VoidCallback onCompleteJob;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final action = switch (job.status) {
      JobStatus.assigned => _ActionData(
          icon: CupertinoIcons.car_detailed,
          label: 'En Route',
          onTap: () => onUpdateStatus(JobStatus.workerEnRoute),
        ),
      JobStatus.workerEnRoute => _ActionData(
          icon: CupertinoIcons.location_fill,
          label: 'Arrived at Location',
          onTap: () => onUpdateStatus(JobStatus.workerArrived),
        ),
      JobStatus.workerArrived => _ActionData(
          icon: CupertinoIcons.play_fill,
          label: 'Start Job',
          onTap: () => onUpdateStatus(JobStatus.inProgress),
        ),
      JobStatus.inProgress => _ActionData(
          icon: CupertinoIcons.check_mark,
          label: 'Complete Job',
          onTap: onCompleteJob,
          isPrimary: true,
        ),
      _ => null,
    };

    if (action == null) return const SizedBox.shrink();

    final bgColor = action.isPrimary
        ? const Color(0xFF2E7D32)
        : theme.colorScheme.primary;

    return AnimatedTapScale(
      onTap: action.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon,
                size: 18,
                color: theme.colorScheme.onPrimary),
            const SizedBox(width: 10),
            Text(
              action.label,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });
}

class _ActiveTimerCard extends StatefulWidget {
  const _ActiveTimerCard();

  @override
  State<_ActiveTimerCard> createState() => _ActiveTimerCardState();
}

class _ActiveTimerCardState extends State<_ActiveTimerCard> {
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(int total) {
    final h = (total ~/ 3600).toString().padLeft(2, '0');
    final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.timer,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'ACTIVE TIME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _format(_seconds),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w200,
              letterSpacing: 3,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
