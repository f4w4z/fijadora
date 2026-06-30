import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/models/collection_item.dart';
import '../../../core/theme.dart';

class CollectionItemTile extends StatelessWidget {
  const CollectionItemTile({
    super.key,
    required this.item,
    this.onTap,
  });

  final CollectionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget tileChild;
    switch (item.itemType) {
      case CollectionItemType.product:
        tileChild = _buildProductTile(theme, isDark);
      case CollectionItemType.service:
        tileChild = _buildServiceTile(theme, isDark);
      case CollectionItemType.note:
        tileChild = _buildNoteTile(theme, isDark);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: item.itemType != CollectionItemType.note ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerLow : const Color(0xFFF0EEEA),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: tileChild,
        ),
      ),
    );
  }

  Widget _buildProductTile(ThemeData theme, bool isDark) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: item.imageUrl != null
                ? CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover)
                : Container(color: theme.colorScheme.surfaceContainer, child: Icon(CupertinoIcons.bag, size: 20, color: theme.colorScheme.onSurfaceVariant)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
              if (item.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(item.subtitle!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.colorScheme.primary)),
        ),
      ],
    );
  }

  Widget _buildServiceTile(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFD4815A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Icon(CupertinoIcons.hammer, size: 20, color: const Color(0xFFD4815A))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
              if (item.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(item.subtitle!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFD4815A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFFD4815A))),
        ),
      ],
    );
  }

  Widget _buildNoteTile(ThemeData theme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Icon(CupertinoIcons.doc_text, size: 20, color: theme.colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
              if (item.noteContent != null) ...[
                const SizedBox(height: 2),
                Text(item.noteContent!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
