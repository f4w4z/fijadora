import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/job_status.dart';
import '../view_models/jobs_view_model.dart';
import '../../../../data/services/telemetry_service.dart';
import 'live_tracking_view.dart';

class JobDetailsPage extends ConsumerStatefulWidget {
  const JobDetailsPage({super.key, required this.job});

  final MaintenanceJob job;

  @override
  ConsumerState<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends ConsumerState<JobDetailsPage> {
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
    final job = widget.job;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          job.tradeType.displayName,
          style: theme.textTheme.displaySmall?.copyWith(fontSize: 20),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: job.status.color(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              job.status.displayName,
              style: TextStyle(
                color: job.status.color(context),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Description',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(job.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text(
              'Address / Location',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(job.address, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(
              'Scheduled Time',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(_formatDate(job.scheduleDateTime), style: theme.textTheme.bodyMedium),
            if (job.status == JobStatus.waitingApproval) ...[
              CustomerReviewPanel(jobId: job.id),
            ],
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
                      '🎥 Body cam active. Footage stored 6 months. Under T&Cs, claims cannot be made after 6 months.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (job.status == JobStatus.workerEnRoute || job.status == JobStatus.workerArrived) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveTrackingView(
                        jobId: job.id,
                        address: job.address,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                ),
                child: const Text('Track Technician', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class CustomerReviewPanel extends ConsumerStatefulWidget {
  const CustomerReviewPanel({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<CustomerReviewPanel> createState() => CustomerReviewPanelState();
}

class CustomerReviewPanelState extends ConsumerState<CustomerReviewPanel> {
  final _commentController = TextEditingController();
  final _signatureController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(JobStatus targetStatus) async {
    if (targetStatus == JobStatus.completed && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(jobsViewModelProvider).updateStatus(widget.jobId, targetStatus);

      ref.read(telemetryServiceProvider).logEvent('worker_rating', {
        'job_id': widget.jobId,
        'rating': _rating,
        'status': targetStatus.name,
        'comment': _commentController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(targetStatus == JobStatus.completed
                ? 'Job approved and signed off successfully!'
                : 'Job status: Complaint submitted.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Review Completed Work',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Technician has completed repairs. Rate their service and sign off.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starVal = index + 1;
              return IconButton(
                icon: Icon(
                  starVal <= _rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  color: Colors.amber,
                  size: 28,
                ),
                onPressed: () {
                  setState(() => _rating = starVal.toDouble());
                },
              );
            }),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Feedback / Comments',
              hintText: 'Share any notes about the service...',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _signatureController,
            decoration: const InputDecoration(
              labelText: 'Digital Signature (Type Full Name)',
              hintText: 'Your name is required to sign off',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please sign to approve the work';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          if (_isSubmitting)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () => _submitReview(JobStatus.completed),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Approve & Sign Off', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 58,
                  child: OutlinedButton(
                    onPressed: () => _submitReview(JobStatus.rejected),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Reject & Complain', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
