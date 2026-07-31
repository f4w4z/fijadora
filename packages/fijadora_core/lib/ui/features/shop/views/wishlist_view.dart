import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/repositories/shop_repository.dart';
import '../view_models/cart_view_model.dart';
import '../view_models/wishlist_view_model.dart';
import 'product_detail_view.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../core/utilities/responsive_helpers.dart';

import '../../../shared/widgets/shimmer_loading.dart';
import '../../services/service_constants.dart';

class WishlistView extends ConsumerWidget {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wishlistAsync = ref.watch(wishlistedProductsProvider);
    final shopRepo = ref.read(shopRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: wishlistAsync.when(
        loading: () => const ShimmerListPlaceholder(itemCount: 3),
        error: (err, stack) => ErrorStateWidget(
          message: 'Could not load your wishlist.',
          onRetry: () => ref.invalidate(wishlistProvider),
        ),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyStateWidget(
              icon: CupertinoIcons.heart,
              title: 'Your wishlist is empty',
              message: 'Tap the heart icon on pieces you love.',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: context.pagePad, vertical: AppSpacing.xxl),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF222222)
                        : const Color(0xFFE5E5E5),
                  ),
                ),
                child: Row(
                  children: [
                    // Product Thumbnail
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => ProductDetailView(product: product)),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            memCacheWidth: 150,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: theme.colorScheme.surfaceContainerHighest),
                            errorWidget: (context, url, error) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(CupertinoIcons.photo, size: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Product details
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => ProductDetailView(product: product)),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.category,
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatGhs(product.price),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Actions: add to cart & remove from wishlist
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(CupertinoIcons.cart_badge_plus, size: 22),
                          onPressed: product.inventoryCount > 0
                              ? () {
                                  ref.read(cartViewModelProvider.notifier).addToCart(product);
                                  context.showSnackBar('Added ${product.name} to cart', type: SnackBarType.success);
                                }
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.heart_fill, size: 20, color: Colors.red),
                          onPressed: () async {
                            await shopRepo.toggleWishlist(product.id);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
