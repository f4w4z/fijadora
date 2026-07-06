import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../shared/utils/notification_helper.dart';
import '../../../../shared/widgets/star_rating.dart';
import '../../../../core/utilities/responsive_helpers.dart';

class WriteReviewSheet extends StatefulWidget {
  const WriteReviewSheet({
    super.key,
    required this.productId,
    required this.onSubmit,
  });

  final String productId;
  final Future<void> Function(double rating, String comment) onSubmit;

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  final _controller = TextEditingController();
  double _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Write a Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(CupertinoIcons.clear),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Share your experience with this piece.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.xl),
        StarRating(
          rating: _rating,
          onChanged: (v) => setState(() => _rating = v),
          size: 34,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Comments',
            hintText: 'Share your thoughts about this piece...',
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final comment = _controller.text.trim();
                        if (comment.isEmpty) return;
                        setState(() => _isSubmitting = true);
                        try {
                          await widget.onSubmit(_rating, comment);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            context.showSnackBar(
                              'Review submitted successfully!',
                              type: SnackBarType.success,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            context.showSnackBar(
                              'Failed to submit review: $e',
                              type: SnackBarType.error,
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
