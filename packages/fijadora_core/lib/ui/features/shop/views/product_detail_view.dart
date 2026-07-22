import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/shop_repository.dart';
import '../../../../domain/models/product.dart';
import '../view_models/cart_view_model.dart';
import '../view_models/wishlist_view_model.dart';
import 'cart_view.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import 'widgets/product_image_gallery.dart';
import 'widgets/write_review_sheet.dart';
import 'widgets/product_detail_bottom_bar.dart';
import 'widgets/product_detail_info_widgets.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/widgets/shimmer_loading.dart';

class ProductDetailView extends ConsumerStatefulWidget {
  const ProductDetailView({
    super.key,
    required this.product,
    this.heroTag,
  });

  final Product product;
  final String? heroTag;

  @override
  ConsumerState<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<ProductDetailView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartViewModelProvider);
    final cartQty = cart[widget.product] ?? 0;
    final totalCartItems = ref.watch(cartViewModelProvider.notifier).totalItems;
    final shopRepo = ref.read(shopRepositoryProvider);

    final wishlistAsync = ref.watch(wishlistProvider);
    final isWishlisted = wishlistAsync.maybeWhen(
      data: (ids) => ids.contains(widget.product.id),
      orElse: () => false,
    );

    final bool inStock = widget.product.inventoryCount > 0;
    final bool maxAdded = cartQty >= widget.product.inventoryCount;
    final bool canAdd = inStock && !maxAdded;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildTransparentAppBar(context, theme, isWishlisted, shopRepo, totalCartItems),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductImageGallery(
              product: widget.product,
              heroTag: widget.heroTag,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.xxl, context.pagePad, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.product.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      StockBadge(count: widget.product.inventoryCount),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.product.name,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${widget.product.price.toStringAsFixed(0)}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      if (inStock)
                        Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? theme.colorScheme.surfaceContainer
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              QuantityStepperButton(
                                icon: CupertinoIcons.minus,
                                onTap: cartQty > 0
                                    ? () => ref
                                        .read(cartViewModelProvider.notifier)
                                        .removeFromCart(widget.product)
                                    : null,
                              ),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '$cartQty',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              QuantityStepperButton(
                                icon: CupertinoIcons.plus,
                                onTap: canAdd
                                    ? () => ref
                                        .read(cartViewModelProvider.notifier)
                                        .addToCart(widget.product)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'About this piece',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.product.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.65,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customer Reviews',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showWriteReviewSheet(context),
                        icon: const Icon(CupertinoIcons.pencil, size: 13),
                        label: const Text(
                          'Write Review',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Consumer(
                    builder: (context, ref, _) {
                      final reviewsAsync = ref.watch(productReviewsProvider(widget.product.id));
                      if (reviewsAsync.isLoading && !reviewsAsync.hasValue) {
                        return const ShimmerReviewCard(count: 2);
                      }
                      if (reviewsAsync.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(child: Text('Could not load reviews',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          )),
                        );
                      }
                      final reviews = reviewsAsync.value ?? [];
                      if (reviews.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.star, size: 20, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'No reviews yet. Be the first!',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: reviews.asMap().entries.map((entry) {
                          final i = entry.key;
                          final review = entry.value;
                          final rating = (review['rating'] as num).toDouble();
                          return Padding(
                            padding: EdgeInsets.only(bottom: i < reviews.length - 1 ? 12 : 0),
                            child: ReviewCard(
                              theme: theme,
                              review: review,
                              rating: rating,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ProductDetailBottomBar(
        theme: theme,
        inStock: inStock,
        maxAdded: maxAdded,
        cartQty: cartQty,
        product: widget.product,
        onAddToCart: canAdd
            ? () {
                ref.read(cartViewModelProvider.notifier).addToCart(widget.product);
                context.showSnackBar(
                  '${widget.product.name} added to cart',
                  type: SnackBarType.success,
                  action: SnackBarAction(
                    label: 'View Cart',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartView()),
                    ),
                  ),
                );
              }
            : null,
        onViewCart: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CartView()),
        ),
        totalCartItems: totalCartItems,
      ),
    );
  }

  PreferredSizeWidget _buildTransparentAppBar(
    BuildContext context,
    ThemeData theme,
    bool isWishlisted,
    ShopRepository shopRepo,
    int totalCartItems,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: FloatingIconButton(
          icon: CupertinoIcons.chevron_left,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        FloatingIconButton(
          icon: isWishlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          iconColor: isWishlisted ? Colors.red : null,
          onTap: () => shopRepo.toggleWishlist(widget.product.id),
        ),
        const SizedBox(width: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            FloatingIconButton(
              icon: CupertinoIcons.cart,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartView()),
              ),
            ),
            if (totalCartItems > 0)
              Positioned(
                right: 2,
                top: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$totalCartItems',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  void _showWriteReviewSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      maxHeight: 0.75,
      child: WriteReviewSheet(
        productId: widget.product.id,
        onSubmit: (rating, comment) async {
          await ref.read(shopRepositoryProvider).addReview(
                widget.product.id, rating, comment);
        },
      ),
    );
  }
}

/// Loads a product by id (used for deep links / push announcement taps).
class ProductDetailByIdView extends ConsumerWidget {
  const ProductDetailByIdView({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(productByIdProvider(productId)).when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => Scaffold(
            appBar: AppBar(title: const Text('Product')),
            body: const Center(child: Text('Product not found')),
          ),
          data: (product) {
            if (product == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Product')),
                body: const Center(child: Text('Product not found')),
              );
            }
            return ProductDetailView(product: product);
          },
        );
  }
}
