import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/shop_repository.dart';
import '../../../../domain/models/product.dart';
import '../view_models/cart_view_model.dart';
import '../view_models/wishlist_view_model.dart';
import 'cart_view.dart';
import '../../../shared/utils/notification_helper.dart';

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
  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
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
            // ────────────────────────────────────────────────────────────────
            // Swipeable multi-image gallery
            // ────────────────────────────────────────────────────────────────
            _ImageGallery(
              product: widget.product,
              heroTag: widget.heroTag,
            ),

            // ────────────────────────────────────────────────────────────────
            // Product Details Content
            // ────────────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ────────────────────────────────────────────────
                  // Category + stock badge
                  // ────────────────────────────────────────────────
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
                      _StockBadge(count: widget.product.inventoryCount),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ────────────────────────────────────────────────
                  // Product name
                  // ────────────────────────────────────────────────
                  Text(
                    widget.product.name,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ────────────────────────────────────────────────
                  // Price + qty stepper
                  // ────────────────────────────────────────────────
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
                      // Quantity stepper
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
                              _StepperButton(
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
                              _StepperButton(
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

                  // ────────────────────────────────────────────────
                  // AR / 3D buttons
                  // ────────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureButton(
                          icon: CupertinoIcons.eye,
                          label: 'AR View',
                          onTap: () => _simulateARView(context),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FeatureButton(
                          icon: CupertinoIcons.cube,
                          label: '3D Model',
                          onTap: () => _simulate3DView(context),
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ────────────────────────────────────────────────
                  // Description
                  // ────────────────────────────────────────────────
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
                  const SizedBox(height: 32),

                  // ────────────────────────────────────────────────
                  // Reviews
                  // ────────────────────────────────────────────────
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
                  const SizedBox(height: 12),

                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: shopRepo.streamReviews(widget.product.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final reviews = snapshot.data ?? [];
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
                              const SizedBox(width: 12),
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
                            child: _ReviewCard(
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

      // ──────────────────────────────────────────────────────────────────────
      // Bottom bar — Add to Cart
      // ──────────────────────────────────────────────────────────────────────
      bottomNavigationBar: _BottomBar(
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

  // ---------------------------------------------------------------------------
  // Transparent AppBar with floating buttons
  // ---------------------------------------------------------------------------
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
        child: _FloatingIconButton(
          icon: CupertinoIcons.chevron_left,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        _FloatingIconButton(
          icon: isWishlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          iconColor: isWishlisted ? Colors.red : null,
          onTap: () => shopRepo.toggleWishlist(widget.product.id),
        ),
        const SizedBox(width: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            _FloatingIconButton(
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

  // ---------------------------------------------------------------------------
  // Modals (unchanged logic, improved presentation is in the sheet itself)
  // ---------------------------------------------------------------------------
  void _simulateARView(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Opacity(
                  opacity: 0.3,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=600&auto=format&fit=crop&q=60',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Grid overlay
              CustomPaint(painter: _GridPainter()),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(CupertinoIcons.eye_solid, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'AR Room View',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Move device slowly to align with floor...',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 18),
                  ),
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
      builder: (context) {
        final innerTheme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: innerTheme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: innerTheme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '3D Room Placement',
                    style: innerTheme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: innerTheme.colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.xmark, size: 14, color: innerTheme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Placed in your digital Home Profile (Living Room)',
                style: TextStyle(color: innerTheme.colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: innerTheme.brightness == Brightness.dark
                          ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                          : [const Color(0xFFF8F8F8), const Color(0xFFEEEEEE)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: innerTheme.brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.cube_box_fill,
                        color: innerTheme.colorScheme.primary,
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '3D Spatial Model Loaded',
                        style: innerTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fits with 1.4m clearance around walls',
                        style: TextStyle(color: innerTheme.colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green, size: 14),
                            SizedBox(width: 6),
                            Text('Space Compatible', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: innerTheme.colorScheme.primary,
                  foregroundColor: innerTheme.colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save to Room Record', style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        final modalTheme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              decoration: BoxDecoration(
                color: modalTheme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: modalTheme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Write a Review',
                    style: modalTheme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share your experience with this piece.',
                    style: TextStyle(color: modalTheme.colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final val = i + 1;
                      return GestureDetector(
                        onTap: () => setStateModal(() => selectedRating = val.toDouble()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            val <= selectedRating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                            size: 34,
                            color: Colors.amber,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comments',
                      hintText: 'Share your thoughts about this piece...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final comment = reviewController.text.trim();
                      if (comment.isEmpty) return;
                      await ref.read(shopRepositoryProvider).addReview(
                            widget.product.id, selectedRating, comment);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        context.showSnackBar(
                          'Review submitted successfully!',
                          type: SnackBarType.success,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: modalTheme.colorScheme.primary,
                      foregroundColor: modalTheme.colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

// =============================================================================
// Sub-widgets
// =============================================================================

/// Swipeable multi-image gallery with page indicators and thumbnail strip
class _ImageGallery extends StatefulWidget {
  const _ImageGallery({
    required this.product,
    this.heroTag,
  });
  final Product product;
  final String? heroTag;

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  late final PageController _pageController;
  int _currentIndex = 0;

  List<String> get _images {
    final urls = widget.product.imageUrls;
    if (urls.isNotEmpty) return urls;
    if (widget.product.imageUrl.isNotEmpty) return [widget.product.imageUrl];
    return [];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = _images;
    final hasMultiple = images.length > 1;
    final galleryHeight = MediaQuery.of(context).size.height * 0.52;

    return SizedBox(
      height: galleryHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── PageView of images ──────────────────────────────────────────
          images.isEmpty
              ? Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(CupertinoIcons.photo, size: 64, color: theme.colorScheme.onSurfaceVariant),
                )
              : PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _openFullscreen(context, images, index),
                      child: index == 0
                          ? Hero(
                              tag: widget.heroTag ?? 'product-img-${widget.product.id}',
                              child: _NetworkImage(url: images[index]),
                            )
                          : _NetworkImage(url: images[index]),
                    );
                  },
                ),
          // No vignette gradients overlaying the image


          // ── Image counter badge ─────────────────────────────────────────
          if (hasMultiple)
            Positioned(
              right: 16,
              bottom: 56,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          // ── Dot indicators ──────────────────────────────────────────────
          if (hasMultiple)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  final isActive = i == _currentIndex;
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: isActive ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  void _openFullscreen(BuildContext context, List<String> images, int startIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) => _FullscreenGallery(
          images: images,
          initialIndex: startIndex,
          productId: widget.product.id,
          heroTag: widget.heroTag,
        ),
      ),
    );
  }
}

/// Full-screen pinch-to-zoom gallery
class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({
    required this.images,
    required this.initialIndex,
    required this.productId,
    this.heroTag,
  });
  final List<String> images;
  final int initialIndex;
  final String productId;
  final String? heroTag;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late int _currentIndex;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: index == widget.initialIndex
                      ? Hero(
                          tag: widget.heroTag ?? 'product-img-${widget.productId}',
                          child: Image.network(
                            widget.images[index],
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(CupertinoIcons.photo, color: Colors.white54, size: 64),
                          ),
                        )
                      : Image.network(
                          widget.images[index],
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(CupertinoIcons.photo, color: Colors.white54, size: 64),
                        ),
                ),
              );
            },
          ),
          // Close button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ),
          // Counter
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
          // Thumbnail strip at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                ),
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 24),
              child: SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.images.length,
                  itemBuilder: (context, i) {
                    final isActive = i == _currentIndex;
                    return GestureDetector(
                      onTap: () => _ctrl.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            widget.images[i],
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: Colors.white12,
                              child: const Icon(CupertinoIcons.photo, color: Colors.white54, size: 20),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple network image with error state
class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, e, s) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(CupertinoIcons.photo, size: 64, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Circular floating icon button used in the AppBar overlay
class _FloatingIconButton extends StatelessWidget {
  const _FloatingIconButton({
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

/// Inventory / stock status badge
class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.count});
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

/// AR / 3D feature action button
class _FeatureButton extends StatelessWidget {
  const _FeatureButton({
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

/// Quantity stepper button (+ / -)
class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, this.onTap});
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

/// A single review card
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
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

/// Bottom Add-to-Cart action bar
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.theme,
    required this.inStock,
    required this.maxAdded,
    required this.cartQty,
    required this.product,
    required this.onAddToCart,
    required this.onViewCart,
    required this.totalCartItems,
  });

  final ThemeData theme;
  final bool inStock;
  final bool maxAdded;
  final int cartQty;
  final Product product;
  final VoidCallback? onAddToCart;
  final VoidCallback onViewCart;
  final int totalCartItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF222222)
                : const Color(0xFFE8E8E8),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              // Cart icon button
              if (totalCartItems > 0) ...[
                GestureDetector(
                  onTap: onViewCart,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFE5E5E5),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(CupertinoIcons.cart, size: 20, color: theme.colorScheme.onSurface),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Add to Cart button
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onAddToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: inStock ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                      foregroundColor: inStock ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (inStock && !maxAdded)
                          const Icon(CupertinoIcons.bag_badge_plus, size: 16),
                        if (inStock && !maxAdded) const SizedBox(width: 8),
                        Text(
                          !inStock
                              ? 'Out of Stock'
                              : maxAdded
                                  ? 'Max in Cart ($cartQty)'
                                  : 'Add to Cart',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
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
}

/// Custom grid painter for the AR view overlay
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
