import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FloatingIconButton extends StatelessWidget {
  const FloatingIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 17),
      ),
    );
  }
}

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'Out of Stock',
          style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
    }
    final isLow = count < 4;
    final color = isLow ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isLow ? 'Only $count left' : '$count in stock',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class FeatureButton extends StatelessWidget {
  const FeatureButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.surface
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceContainerHighest
                : const Color(0xFFE5E5E5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuantityStepperButton extends StatelessWidget {
  const QuantityStepperButton({super.key, required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.theme,
    required this.review,
    required this.rating,
  });

  final ThemeData theme;
  final Map<String, dynamic> review;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      (review['user'] as String? ?? 'G')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    review['user'] as String? ?? 'Guest User',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                review['date'] as String? ?? '',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                i < rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                size: 12,
                color: Colors.amber,
              ),
            )),
          ),
          const SizedBox(height: 8),
          Text(
            review['comment'] as String? ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
