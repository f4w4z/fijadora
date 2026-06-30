import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/collection.dart';
import '../../../../domain/models/collection_item.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../view_models/collections_view_model.dart';
import '../widgets/collection_item_tile.dart';
import '../../shop/views/product_detail_view.dart';
import '../../services/views/new_request_page.dart';
import '../../../../domain/models/trade_type.dart';
import '../../../../domain/models/product.dart';

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
                        height: 220,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(height: 220, color: theme.colorScheme.surfaceContainer),
                        errorWidget: (_, __, ___) => Container(height: 220, color: theme.colorScheme.surfaceContainer),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(collection.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, letterSpacing: -0.3)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundImage: collection.creatorAvatarUrl != null ? CachedNetworkImageProvider(collection.creatorAvatarUrl!) : null,
                              child: collection.creatorAvatarUrl == null
                                  ? Text(collection.creatorName.isNotEmpty ? collection.creatorName[0].toUpperCase() : '?', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface))
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text('by ${collection.creatorName}', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                            const Spacer(),
                            Icon(CupertinoIcons.heart, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text('${collection.likeCount}', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        if (collection.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(collection.description, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
                        ],
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 24),
                        Text('Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: collection.items.map((item) => CollectionItemTile(
                        item: item,
                        onTap: () => _onItemTap(context, item),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTap(BuildContext context, CollectionItem item) {
    switch (item.itemType) {
      case CollectionItemType.product:
        if (item.referenceId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailView(
                product: _dummyProduct(item),
              ),
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

// Temporary: resolve product from reference ID
// In production, this would come from the shop repository
Product _dummyProduct(CollectionItem item) {
  return Product(
    id: item.referenceId ?? '',
    name: item.label,
    description: item.subtitle ?? '',
    price: double.tryParse(item.subtitle?.replaceAll('\$', '') ?? '0') ?? 0,
    imageUrl: item.imageUrl ?? '',
    imageUrls: item.imageUrl != null ? [item.imageUrl!] : [],
    category: '',
    inventoryCount: 0,
  );
}
