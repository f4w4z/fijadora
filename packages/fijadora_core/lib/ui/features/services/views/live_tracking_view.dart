import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/job_status.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/utils/date_extensions.dart';
import '../view_models/jobs_view_model.dart';
import 'job_payment_card.dart';

class LiveTrackingView extends ConsumerStatefulWidget {
  const LiveTrackingView({super.key, required this.jobId, required this.address});

  final String jobId;
  final String address;

  @override
  ConsumerState<LiveTrackingView> createState() => _LiveTrackingViewState();
}

class _LiveTrackingViewState extends ConsumerState<LiveTrackingView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobsAsync = ref.watch(jobsStreamProvider);

    // Find the specific job from the stream
    final job = jobsAsync.valueOrNull?.where((j) => j.id == widget.jobId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Technician', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: job == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(context.pagePad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: job.status.color(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _statusIcon(job.status),
                          size: 40,
                          color: job.status.color(context),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.status.displayName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: job.status.color(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _statusDescription(job.status),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quote / deposit / balance payments
                  JobPaymentCard(job: job),

                  // Status timeline
                  const Text('Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildTimeline(context, job),
                  const SizedBox(height: 24),

                  // Location info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(CupertinoIcons.location, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('Service Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.address,
                          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Schedule info
                  if (job.scheduleDateTime != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(CupertinoIcons.calendar, size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              const Text('Scheduled', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            job.scheduleDateTime!.formattedFull,
                            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Description
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(CupertinoIcons.doc_text, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          job.description,
                          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  // Open in Maps button
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _openInMaps(context),
                    icon: const Icon(CupertinoIcons.map),
                    label: const Text('Open in Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _openInMaps(BuildContext context) async {
    final query = Uri.encodeComponent(widget.address);
    final googleUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$query');
    final appleUrl = Uri.parse('https://maps.apple.com/?daddr=$query');
    final googleLaunchable = await canLaunchUrl(googleUrl);
    final appleLaunchable = await canLaunchUrl(appleUrl);
    if (appleLaunchable && Theme.of(context).platform == TargetPlatform.iOS) {
      await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
    } else if (googleLaunchable) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildTimeline(BuildContext context, MaintenanceJob job) {
    final theme = Theme.of(context);
    final steps = [
      (JobStatus.assigned, 'Assigned'),
      (JobStatus.workerEnRoute, 'En Route'),
      (JobStatus.workerArrived, 'Arrived'),
      (JobStatus.inProgress, 'In Progress'),
      (JobStatus.completed, 'Completed'),
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isDone = job.status.index >= step.$1.index;
        final isActive = job.status.index == step.$1.index;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: isActive ? 16 : 12,
                    height: isActive ? 16 : 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? step.$1.color(context) : theme.colorScheme.surfaceContainerHighest,
                      border: isActive ? Border.all(color: step.$1.color(context), width: 3) : null,
                    ),
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: isDone ? step.$1.color(context).withValues(alpha: 0.4) : theme.colorScheme.surfaceContainerHighest,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: i < steps.length - 1 ? 12 : 0),
                child: Text(
                  step.$2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isDone ? step.$1.color(context) : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  IconData _statusIcon(JobStatus status) => switch (status) {
        JobStatus.pending || JobStatus.quoted => CupertinoIcons.clock,
        JobStatus.assigned => CupertinoIcons.person,
        JobStatus.workerEnRoute => CupertinoIcons.car,
        JobStatus.workerArrived => CupertinoIcons.location,
        JobStatus.inProgress || JobStatus.awaitingParts => CupertinoIcons.hammer_fill,
        JobStatus.waitingApproval => CupertinoIcons.checkmark_seal,
        JobStatus.completed => CupertinoIcons.checkmark_circle_fill,
        JobStatus.rejected || JobStatus.cancelled || JobStatus.onHold => CupertinoIcons.xmark_circle,
        JobStatus.rescheduled => CupertinoIcons.calendar,
      };

  String _statusDescription(JobStatus status) => switch (status) {
        JobStatus.pending => 'Your request has been submitted and is awaiting review.',
        JobStatus.quoted => 'A quote has been provided for this service.',
        JobStatus.assigned => 'A technician has been assigned to your request.',
        JobStatus.workerEnRoute => "The technician is on their way to your location.",
        JobStatus.workerArrived => 'The technician has arrived at your location.',
        JobStatus.inProgress => 'Work is currently in progress.',
        JobStatus.waitingApproval => 'Work is complete and awaiting your approval.',
        JobStatus.completed => 'This service request has been completed.',
        JobStatus.rejected => 'This request has been declined.',
        JobStatus.cancelled => 'This request has been cancelled.',
        JobStatus.onHold => 'This request is temporarily on hold.',
        JobStatus.rescheduled => 'This request has been rescheduled.',
        JobStatus.awaitingParts => 'Waiting for parts to arrive before work can continue.',
      };
}
