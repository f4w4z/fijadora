import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../shared/utils/notification_helper.dart';

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
        const SizedBox(height: 8),
        Text(
          'Share your experience with this piece.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final val = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _rating = val.toDouble()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  val <= _rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  size: 34,
                  color: Colors.amber,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Comments',
            hintText: 'Share your thoughts about this piece...',
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () async {
                  final comment = _controller.text.trim();
                  if (comment.isEmpty) return;
                  await widget.onSubmit(_rating, comment);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    context.showSnackBar(
                      'Review submitted successfully!',
                      type: SnackBarType.success,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
