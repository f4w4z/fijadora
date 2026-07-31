import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../services/view_models/jobs_view_model.dart';
import '../../services/service_constants.dart';
import '../../../shared/utils/date_extensions.dart';
import 'job_completion_page.dart';
import '../../../core/utilities/responsive_helpers.dart';

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
                padding: EdgeInsets.only(left: AppSpacing.lg),
                child: Icon(CupertinoIcons.chevron_left, size: 22, color: theme.colorScheme.onSurface),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: EdgeInsets.fromLTRB(context.pagePad, 60, context.pagePad, AppSpacing.lg),
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
              padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.sm, context.pagePad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress stepper
                  if (_currentStepIndex >= 0)
                    _ProgressStepper(
                      currentIndex: _currentStepIndex,
                      theme: theme,
                    ),
                  SizedBox(height: AppSpacing.xxl),

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
                          value: job.scheduleDateTime?.formattedFull ?? 'Not scheduled',
                          theme: theme,
                        ),
                        if (job.contactPhone.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _InfoRow(
                            icon: CupertinoIcons.phone,
                            label: 'Contact',
                            value: job.contactPhone,
                            theme: theme,
                          ),
                        ],
                        if (job.accessNotes.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _InfoRow(
                            icon: CupertinoIcons.lock_fill,
                            label: 'Access',
                            value: job.accessNotes,
                            theme: theme,
                          ),
                        ],
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
                  SizedBox(height: AppSpacing.xl),

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
                  SizedBox(height: AppSpacing.xl),

                  // Active timer
                  if (job.status == JobStatus.inProgress) ...[
                    const _ActiveTimerCard(),
                    SizedBox(height: AppSpacing.xl),
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
                  if (_canSubmitChangeOrder(job.status)) ...[
                    SizedBox(height: 12),
                    _ChangeOrderSection(job: job),
                  ],
                  SizedBox(height: 12),

                  // Navigate to job
                  _NavigateButton(address: job.address),
                  SizedBox(height: AppSpacing.lg),

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

class _NavigateButton extends StatelessWidget {
  const _NavigateButton({required this.address});
  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedTapScale(
      onTap: () async {
        final query = Uri.encodeComponent(address);
        final googleUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$query');
        final appleUrl = Uri.parse('https://maps.apple.com/?daddr=$query');
        final googleLaunchable = await canLaunchUrl(googleUrl);
        final appleLaunchable = await canLaunchUrl(appleUrl);
        if (appleLaunchable && theme.platform == TargetPlatform.iOS) {
          await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
        } else if (googleLaunchable) {
          await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.map_pin_ellipse,
                size: 18, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Text(
              'Navigate to Job',
              style: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
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

bool _canSubmitChangeOrder(JobStatus status) {
  return status == JobStatus.workerArrived ||
      status == JobStatus.inProgress ||
      status == JobStatus.awaitingParts ||
      status == JobStatus.onHold ||
      status == JobStatus.rescheduled;
}

// ── Change orders (worker submits extra work for approval) ───────────────────
class _ChangeOrderSection extends ConsumerWidget {
  const _ChangeOrderSection({required this.job});
  final MaintenanceJob job;

  String _statusLabel(String status) => switch (status) {
        'pending' => 'Pending approval',
        'approved' => 'Awaiting customer payment',
        'paid' => 'Paid',
        _ => status,
      };

  Future<void> _openSubmitSheet(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final amountController = TextEditingController();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Submit Change Order',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'The job will pause until the customer approves and pays the extra amount.',
              style: TextStyle(
                  fontSize: 12, color: Theme.of(sheetContext).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Extra amount (GH₵)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What was the extra work?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                final description = controller.text.trim();
                if (amount == null || amount <= 0 || description.isEmpty) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                        content: Text('Enter a valid amount and description')),
                  );
                  return;
                }
                try {
                  await ref
                      .read(jobsRepositoryProvider)
                      .submitChangeOrder(
                        jobId: job.id,
                        description: description,
                        amount: amount,
                      );
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop(true);
                  }
                } catch (e) {
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext)
                        .showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(sheetContext).colorScheme.primary,
                foregroundColor: Theme.of(sheetContext).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Submit for Approval'),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Change order submitted — job paused until customer pays')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pendingCount =
        job.changeOrders.where((c) => c.status == 'pending').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (job.changeOrders.isNotEmpty) ...[
          Text('Change Orders',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          ...job.changeOrders.map((co) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(co.description,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: theme.colorScheme.onSurface),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text('+${formatGhs(co.amount)}',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE65100))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_statusLabel(co.status),
                          style: const TextStyle(fontSize: 9.5)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
        ],
        AnimatedTapScale(
          onTap: () => _openSubmitSheet(context, ref),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.hammer, size: 18, color: Color(0xFFE65100)),
                const SizedBox(width: 10),
                Text(
                  pendingCount > 0
                      ? 'Submit Another Change Order'
                      : 'Found Extra Work? Submit Change Order',
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
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
