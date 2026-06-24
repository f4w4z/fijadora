import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/models/product.dart';
import '../view_models/cart_view_model.dart';
import '../view_models/wishlist_view_model.dart';
import 'ai_concierge_page.dart';
import 'cart_view.dart';
import 'product_detail_view.dart';
import 'wishlist_view.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../../../../ui/shared/widgets/custom_pinned_header.dart';
import '../../../../ui/shared/widgets/floating_header_layout.dart';
import '../../../shared/utils/notification_helper.dart';
import 'widgets/shop_the_look_carousel.dart';


class ShopTabView extends ConsumerStatefulWidget {
  const ShopTabView({super.key});

  @override
  ConsumerState<ShopTabView> createState() => _ShopTabViewState();
}

class _ShopTabViewState extends ConsumerState<ShopTabView> {
  String _selectedCategory = 'All Products';
  String _searchQuery = '';

  void _showAiConcierge(BuildContext context, List<Product> catalog) {
    final recommendedIds = ['prod-1', 'prod-2'];
    final recommended = catalog.where((p) => recommendedIds.contains(p.id)).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiConciergePage(recommended: recommended),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCartItems = ref.watch(cartViewModelProvider.notifier).totalItems;
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      body: FloatingHeaderLayout(
        header: CustomPinnedHeader(
          title: 'Shop',
          actions: [
            GroupedHeaderActions(
              actions: [
                GroupedActionItem(
                  icon: CupertinoIcons.heart,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const WishlistView()),
                    );
                  },
                ),
                GroupedActionItem(
                  icon: CupertinoIcons.cart,
                  badgeCount: totalCartItems,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CartView()),
                    );
                  },
                ),
              ],
            ),
          ],
          bottomChild: CupertinoSearchTextField(
            placeholder: 'Search pieces...',
            onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(color: theme.colorScheme.onSurface),
            placeholderStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            itemColor: theme.colorScheme.onSurfaceVariant,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? theme.inputDecorationTheme.fillColor
                  : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHighest
                    : const Color(0xFFE5E5E5),
              ),
            ),
          ),
        ),
        bodyBuilder: (context, topPadding) {
          return productsAsync.when(
            loading: () => Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: Center(child: Text('Error: $error')),
            ),
            data: (products) {
              // Extract categories dynamically
              final categories = ['All Products', ...products.map((p) => p.category).toSet()];

              final bundleProducts = products.where((p) => p.category == 'Bundles').toList();

              final filteredProducts = products.where((p) {
                final matchesCategory = _selectedCategory == 'All Products' || p.category == _selectedCategory;
                final matchesSearch = _searchQuery.isEmpty ||
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    p.description.toLowerCase().contains(_searchQuery.toLowerCase());
                return matchesCategory && matchesSearch;
              }).toList();

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: topPadding)),
                  SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Prominent Banner
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
                                  width: 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PHOEBE CURATED',
                                    style: TextStyle(fontFamily: 'Inter', 
                                      color: theme.colorScheme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6.0),
                                  Text(
                                    'Architectural furniture for modern living spaces.',
                                    style: TextStyle(fontFamily: 'Instrument Serif', 
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 20,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 12.0),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: SizedBox(
                                          height: 32,
                                          child: ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: theme.colorScheme.primary,
                                              foregroundColor: theme.colorScheme.onPrimary,
                                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                              elevation: 0,
                                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                            ),
                                            child: const Text('VIEW COLLECTION'),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: SizedBox(
                                          height: 32,
                                          child: OutlinedButton.icon(
                                            onPressed: () => _showAiConcierge(context, products),
                                            icon: const Icon(CupertinoIcons.sparkles, size: 10),
                                            label: const Text('AI CONCIERGE'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: theme.colorScheme.onSurface,
                                              side: BorderSide(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12)),
                                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24.0),

                          if (bundleProducts.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                'Shop the Look',
                                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ShopTheLookCarousel(bundles: bundleProducts),
                          ],

                          // Categories list
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              'Browse Categories',
                              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          SizedBox(
                            height: 40.0,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                final isSelected = category == _selectedCategory;
                                return _buildCategoryChip(category, isSelected, theme);
                              },
                            ),
                          ),
                          const SizedBox(height: 32.0),

                          // Products Grid Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Featured Pieces',
                                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('See All'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12.0),
                        ],
                      ),
                    ),
                    if (filteredProducts.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.all(32.0),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              'No pieces found in this category.',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 24.0,
                            childAspectRatio: 0.72,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = filteredProducts[index];
                              return AnimatedTapScale(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailView(product: product),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16.0),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Hero(
                                              tag: 'product-img-${product.id}',
                                              child: CachedNetworkImage(
                                                imageUrl: product.imageUrl,
                                                memCacheWidth: 300,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  color: theme.colorScheme.surfaceContainerHighest,
                                                  child: const Center(
                                                    child: SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    ),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  color: theme.colorScheme.surfaceContainerHighest,
                                                  child: const Icon(CupertinoIcons.photo),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Material(
                                                type: MaterialType.transparency,
                                                child: InkWell(
                                                  onTap: () {
                                                    ref.read(cartViewModelProvider.notifier).addToCart(product);
                                                    context.showSnackBar(
                                                      '${product.name} added to cart',
                                                      type: SnackBarType.success,
                                                      duration: const Duration(seconds: 2),
                                                    );
                                                  },
                                                  borderRadius: BorderRadius.circular(16),
                                                  child: CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
                                                    child: Icon(
                                                      CupertinoIcons.add,
                                                      size: 14,
                                                      color: theme.colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10.0),
                                    Text(
                                      product.name,
                                      style: TextStyle(fontFamily: 'Instrument Serif', 
                                        fontSize: 16,
                                        height: 1.1,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      '\$${product.price.toStringAsFixed(0)}',
                                      style: TextStyle(fontFamily: 'Inter', 
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: filteredProducts.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 120.0), // Padding to clear the bottom nav bar
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
  }

  Widget _buildCategoryChip(String label, bool isSelected, ThemeData theme) {
    return AnimatedTapScale(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? Colors.transparent : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(fontFamily: 'Inter', 
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}




