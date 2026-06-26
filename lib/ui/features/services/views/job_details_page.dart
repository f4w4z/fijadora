import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/job_status.dart';
import '../view_models/jobs_view_model.dart';
import '../../../../data/services/telemetry_service.dart';
import '../../../shared/utils/notification_helper.dart';

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
        context.showSnackBar(
          targetStatus == JobStatus.completed
              ? 'Job approved and signed off successfully!'
              : 'Job status: Complaint submitted.',
          type: targetStatus == JobStatus.completed ? SnackBarType.success : SnackBarType.info,
        );
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error submitting review: $e', type: SnackBarType.error);
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
