import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/shop_repository.dart';
import '../../../../domain/models/product.dart';
import '../view_models/cart_view_model.dart';
import '../view_models/wishlist_view_model.dart';
import 'cart_view.dart';

class ProductDetailView extends ConsumerStatefulWidget {
  const ProductDetailView({super.key, required this.product});

  final Product product;

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

    // Watch wishlist state
    final wishlistAsync = ref.watch(wishlistProvider);
    final isWishlisted = wishlistAsync.maybeWhen(
      data: (ids) => ids.contains(widget.product.id),
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(
              isWishlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              color: isWishlisted ? Colors.red : null,
            ),
            onPressed: () async {
              await shopRepo.toggleWishlist(widget.product.id);
            },
          ),
          IconButton(
            icon: Badge(
              label: Text('$totalCartItems'),
              isLabelVisible: totalCartItems > 0,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(CupertinoIcons.shopping_cart),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CartView()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 1.2,
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Hero(
                  tag: 'product-img-${widget.product.id}',
                  child: Image.network(
                    widget.product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      CupertinoIcons.photo,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Stock Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.product.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (widget.product.inventoryCount <= 0)
                        const Text(
                          'Out of Stock',
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                        )
                      else
                        Text(
                          '${widget.product.inventoryCount} items left',
                          style: TextStyle(
                            color: widget.product.inventoryCount < 3 ? Colors.orange : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    widget.product.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Text(
                    '\$${widget.product.price.toStringAsFixed(0)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF222222)
                        : const Color(0xFFE5E5E5),
                    height: 1,
                  ),
                  const SizedBox(height: 24),
                  // Details
                  Text(
                    'Details',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _simulateARView(context),
                          icon: const Icon(CupertinoIcons.eye, size: 16),
                          label: const Text('AR View in Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF333333)
                                  : const Color(0xFFE5E5E5),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _simulate3DView(context),
                          icon: const Icon(CupertinoIcons.cube, size: 16),
                          label: const Text('3D Model Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF333333)
                                  : const Color(0xFFE5E5E5),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Divider(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF222222)
                        : const Color(0xFFE5E5E5),
                    height: 1,
                  ),
                  const SizedBox(height: 24),
                  // Reviews Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customer Reviews',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        onPressed: () => _showWriteReviewSheet(context),
                        icon: const Icon(CupertinoIcons.pencil, size: 14),
                        label: const Text('Write Review', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Stream reviews
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: shopRepo.streamReviews(widget.product.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final reviews = snapshot.data ?? [];
                      if (reviews.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No reviews yet. Be the first to share your experience!',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          final rating = (review['rating'] as num).toDouble();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    review['user'] as String? ?? 'Guest User',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    review['date'] as String? ?? '',
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (starIdx) {
                                  return Icon(
                                    starIdx < rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                                    size: 12,
                                    color: Colors.amber,
                                  );
                                }),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                review['comment'] as String? ?? '',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF222222)
                  : const Color(0xFFE5E5E5),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: widget.product.inventoryCount > 0 && cartQty < widget.product.inventoryCount
                        ? () {
                            ref.read(cartViewModelProvider.notifier).addToCart(widget.product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added ${widget.product.name} to cart'),
                                action: SnackBarAction(
                                  label: 'View Cart',
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const CartView()),
                                    );
                                  },
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.product.inventoryCount <= 0
                          ? 'Out of Stock'
                          : cartQty >= widget.product.inventoryCount
                              ? 'Max Stock Added'
                              : 'Add to Cart',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _simulateARView(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 0.3,
                child: Image.network(
                  'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=600&auto=format&fit=crop&q=60',
                  fit: BoxFit.cover,
                ),
              ),
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.eye_solid, color: Colors.white, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Simulating True-to-Scale AR View',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Move device slowly to align with floor grid...',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: IconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _simulate3DView(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final innerTheme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: innerTheme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '3D Room Placement Preview',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.clear),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Placed relative to digital Home Profile model (Living Room)',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: innerTheme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: innerTheme.colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.cube_box_fill, color: innerTheme.colorScheme.primary, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          '3D Spatial Model Loaded',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Fits with 1.4m clearance around walls',
                          style: TextStyle(color: innerTheme.colorScheme.onSurfaceVariant, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: innerTheme.colorScheme.primary,
                  foregroundColor: innerTheme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Add Styled Look to Room Record', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWriteReviewSheet(BuildContext context) {
    final reviewController = TextEditingController();
    double selectedRating = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final modalTheme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Write a Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text('Your Rating', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (starIdx) {
                      final starValue = starIdx + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= selectedRating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                          size: 32,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setStateModal(() {
                            selectedRating = starValue.toDouble();
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comments',
                      hintText: 'Share your thoughts about this piece...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final comment = reviewController.text.trim();
                      if (comment.isEmpty) return;

                      await ref.read(shopRepositoryProvider).addReview(
                            widget.product.id,
                            selectedRating,
                            comment,
                          );

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review submitted successfully!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: modalTheme.colorScheme.primary,
                      foregroundColor: modalTheme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
