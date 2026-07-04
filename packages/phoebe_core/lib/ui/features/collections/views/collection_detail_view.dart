import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/collection.dart';
import '../../../../domain/models/collection_item.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../view_models/collections_view_model.dart';
import '../widgets/collection_item_tile.dart';
import '../../shop/views/product_detail_view.dart';
import '../../shop/view_models/products_provider.dart';
import '../../services/views/new_request_page.dart';
import '../../../../domain/models/trade_type.dart';
import '../../../../domain/models/product.dart';
import 'collection_form_page.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../staff/view_models/admin_collections_view_model.dart';
import '../../../shared/utils/notification_helper.dart';

class CollectionDetailView extends ConsumerWidget {
  const CollectionDetailView({super.key, required this.collection});

  final Collection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vm = ref.watch(collectionsViewModelProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: false,
              pinned: false,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: AnimatedTapScale(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Icon(CupertinoIcons.back, size: 20)),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedTapScale(
                    onTap: () => vm.toggleLike(collection.id),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Icon(CupertinoIcons.heart, size: 20, color: theme.colorScheme.onSurface)),
                    ),
                  ),
                ),
                if (collection.creatorId == ref.read(authViewModelProvider).user?.id)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AnimatedTapScale(
                      onTap: () => _showCreatorOptions(context, ref, collection),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1A1A) : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Icon(CupertinoIcons.ellipsis_vertical, size: 20)),
                      ),
                    ),
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (collection.coverImageUrl != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      child: CachedNetworkImage(
                        imageUrl: collection.coverImageUrl!,
                        height: 30.h(context),
                        fit: BoxFit.cover,
        placeholder: (_, _) => Container(height: 30.h(context), color: theme.colorScheme.surfaceContainer),
        errorWidget: (_, _, _) => Container(height: 30.h(context), color: theme.colorScheme.surfaceContainer),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.xl, context.pagePad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(collection.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, letterSpacing: -0.3)),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundImage: collection.creatorAvatarUrl != null ? CachedNetworkImageProvider(collection.creatorAvatarUrl!) : null,
                              child: collection.creatorAvatarUrl == null
                                  ? Text(collection.creatorName.isNotEmpty ? collection.creatorName[0].toUpperCase() : '?', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface))
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text('by ${collection.creatorName}', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                            if (collection.isEdited) ...[
                              const SizedBox(width: 6),
                              Text('•  Edited', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
                            ],
                            const Spacer(),
                            Icon(CupertinoIcons.heart, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text('${collection.likeCount}', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        if (collection.description.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(collection.description, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(collection.category.displayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.colorScheme.primary)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0EEEA),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text('${collection.itemCount} items', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => vm.toggleFollow(collection.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Follow', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onPrimary)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text('Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: context.pagePad),
                    itemCount: collection.items.length,
                    itemBuilder: (context, idx) {
                      final item = collection.items[idx];
                      return CollectionItemTile(
                        item: item,
                        onTap: () => _onItemTap(context, ref, item),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatorOptions(BuildContext context, WidgetRef ref, Collection collection) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(CupertinoIcons.pencil, color: Colors.blue),
                  title: const Text('Edit Look', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => CollectionFormPage(collection: collection),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(CupertinoIcons.trash, color: Colors.red),
                  title: const Text('Delete Look', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Look'),
                        content: const Text('Are you sure you want to delete this look? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      try {
                        await ref.read(adminCollectionsViewModelProvider.notifier).removeCollection(
                          collection.id,
                          collection.title,
                        );
                        if (context.mounted) {
                          context.showSnackBar('Look deleted successfully', type: SnackBarType.success);
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          context.showSnackBar('Failed to delete look: $e', type: SnackBarType.error);
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onItemTap(BuildContext context, WidgetRef ref, CollectionItem item) {
    switch (item.itemType) {
      case CollectionItemType.product:
        if (item.referenceId != null) {
          final catalog = ref.read(productsStreamProvider).valueOrNull ?? [];
          final product = _resolveProduct(item, catalog);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailView(product: product),
            ),
          );
        }
      case CollectionItemType.service:
        if (item.referenceId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewRequestPage(
                initialTrade: TradeType.fromString(item.referenceId),
              ),
            ),
          );
        }
      case CollectionItemType.note:
        break;
    }
  }
}

Product _resolveProduct(CollectionItem item, List<Product> catalog) {
  final match = catalog.where((p) => p.id == item.referenceId).firstOrNull;
  if (match != null) return match;
  return Product(
    id: item.referenceId ?? '',
    name: item.label,
    description: item.subtitle ?? '',
    price: double.tryParse(item.subtitle?.replaceAll('\$', '') ?? '0') ?? 0,
    imageUrl: item.imageUrl ?? '',
    imageUrls: item.imageUrl != null ? [item.imageUrl!] : [],
    category: '',
    inventoryCount: 0,
    createdAt: DateTime.now(),
  );
}
