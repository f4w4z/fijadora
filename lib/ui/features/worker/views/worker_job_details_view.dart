import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../services/view_models/jobs_view_model.dart';

class WorkerJobDetailsView extends ConsumerStatefulWidget {
  const WorkerJobDetailsView({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<WorkerJobDetailsView> createState() => _WorkerJobDetailsViewState();
}

class _WorkerJobDetailsViewState extends ConsumerState<WorkerJobDetailsView> {
  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobsViewModel = ref.watch(jobsViewModelProvider);

    // Find the job in our VM state
    final jobIndex = jobsViewModel.jobs.indexWhere((j) => j.id == widget.jobId);
    if (jobIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: const Center(child: Text('Job not found')),
      );
    }
    final job = jobsViewModel.jobs[jobIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(job.tradeType.displayName),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Headline info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(job.tradeType.icon, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(job.tradeType.displayName, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: job.status.color(context).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              job.status.displayName,
                              style: TextStyle(
                                color: job.status.color(context),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Location',
                        style: theme.textTheme.titleLarge?.copyWith(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(job.address, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      Text(
                        'Scheduled Date',
                        style: theme.textTheme.titleLarge?.copyWith(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(_formatDate(job.scheduleDateTime), style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Description Card
              Text(
                'Job Description',
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(job.description, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4)),
                ),
              ),
              if (job.status == JobStatus.completed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.shield_fill, color: Colors.green, size: 16),
                      SizedBox(width: 12),
                      Text(
                        '30-Day Workmanship Guarantee Active',
                        style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Active Working Timer (visible when job in progress)
              if (job.status == JobStatus.inProgress) ...[
                const _ActiveTimerDisplay(),
                const SizedBox(height: 24),
              ],

              // Actions Control Card
              _JobProgressControl(
                job: job,
                onUpdateStatus: (newStatus) async {
                  await ref.read(jobsViewModelProvider).updateStatus(job.id, newStatus);
                },
                onCompleteJob: () => _showCompletionSheet(context, job.id),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.videocam_fill, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🎥 Body cam active. Footage is stored for 6 months. Under T&Cs, claims cannot be made after 6 months.',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletionSheet(BuildContext context, String jobId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _JobCompletionSheet(jobId: jobId),
    );
  }
}

class _JobProgressControl extends StatelessWidget {
  const _JobProgressControl({
    required this.job,
    required this.onUpdateStatus,
    required this.onCompleteJob,
  });

  final MaintenanceJob job;
  final ValueChanged<JobStatus> onUpdateStatus;
  final VoidCallback onCompleteJob;

  @override
  Widget build(BuildContext context) {
    switch (job.status) {
      case JobStatus.assigned:
        return ElevatedButton.icon(
          onPressed: () => onUpdateStatus(JobStatus.workerEnRoute),
          icon: const Icon(CupertinoIcons.car_detailed),
          label: const Text('Start Travel (En Route)'),
        );
      case JobStatus.workerEnRoute:
        return ElevatedButton.icon(
          onPressed: () => onUpdateStatus(JobStatus.workerArrived),
          icon: const Icon(CupertinoIcons.location_fill),
          label: const Text('Arrived at Location'),
        );
      case JobStatus.workerArrived:
        return ElevatedButton.icon(
          onPressed: () => onUpdateStatus(JobStatus.inProgress),
          icon: const Icon(CupertinoIcons.play_fill),
          label: const Text('Start Job (Clock In)'),
        );
      case JobStatus.inProgress:
        return ElevatedButton.icon(
          onPressed: onCompleteJob,
          icon: const Icon(CupertinoIcons.check_mark),
          label: const Text('Complete Job'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ActiveTimerDisplay extends StatefulWidget {
  const _ActiveTimerDisplay();

  @override
  State<_ActiveTimerDisplay> createState() => _ActiveTimerDisplayState();
}

class _ActiveTimerDisplayState extends State<_ActiveTimerDisplay> {
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.timer, size: 16, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'ACTIVE JOB TIMER',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.indigo),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _formatDuration(_seconds),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w100, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCompletionSheet extends ConsumerStatefulWidget {
  const _JobCompletionSheet({required this.jobId});
  final String jobId;

  @override
  ConsumerState<_JobCompletionSheet> createState() => _JobCompletionSheetState();
}

class _JobCompletionSheetState extends ConsumerState<_JobCompletionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _photoCaptured = false;
  bool _isCapturing = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitCompletion() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_photoCaptured) return;

    setState(() => _isSubmitting = true);
    try {
      // Updates status to waitingApproval.
      await ref.read(jobsViewModelProvider).updateStatus(widget.jobId, JobStatus.waitingApproval);
      if (mounted) {
        Navigator.pop(context); // Close sheet
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing job: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _simulatePhotoCapture() async {
    setState(() => _isCapturing = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _photoCaptured = true;
        _isCapturing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completion proof photo captured successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Complete Job',
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 16),
                
                // Photo proof capture simulator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF333333)
                          : const Color(0xFFE5E5E5),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_photoCaptured) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300&auto=format&fit=crop&q=60',
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Proof of Work Attached',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ] else ...[
                        Icon(CupertinoIcons.camera_fill, size: 36, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        const Text(
                          'Completion Photo Proof Required',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Take a photo of completed work to submit.',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isCapturing ? null : _simulatePhotoCapture,
                        icon: _isCapturing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 1.5),
                              )
                            : Icon(_photoCaptured ? CupertinoIcons.refresh : CupertinoIcons.camera),
                        label: Text(_isCapturing
                            ? 'Opening camera...'
                            : _photoCaptured
                                ? 'Retake Photo'
                                : 'Capture Proof'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? const Color(0xFF333333)
                                : const Color(0xFFCCCCCC),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Resolution Notes',
                    hintText: 'Describe the repairs done, parts replaced, etc...',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please provide completion notes';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting || !_photoCaptured ? null : _submitCompletion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit for Client Approval'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
