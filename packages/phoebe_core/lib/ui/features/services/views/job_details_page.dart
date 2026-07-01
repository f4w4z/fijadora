import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    setState(() => _isSubmitting = true);
    try {
      ref.read(telemetryServiceProvider).logEvent('customer_feedback', {
        'job_id': widget.jobId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
      });

      if (mounted) {
        context.showSnackBar(
          'Feedback submitted. The manager will review the completed work.',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error submitting feedback: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'How was the service?',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Rate the completed work. Your feedback will help the manager make a final review.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
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
            hintText: 'Any notes about the service...',
          ),
        ),
        const SizedBox(height: 20),
        if (_isSubmitting)
          const Center(child: CircularProgressIndicator())
        else
          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Submit Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}
