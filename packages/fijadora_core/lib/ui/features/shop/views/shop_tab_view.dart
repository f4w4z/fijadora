import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/models/product.dart';
import '../../collections/view_models/collections_view_model.dart';
import '../view_models/cart_view_model.dart';
import '../view_models/products_provider.dart';
import 'ai_concierge_page.dart';
import 'cart_view.dart';
import 'product_detail_view.dart';
import 'wishlist_view.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../../../../ui/shared/widgets/app_animations.dart';
import '../../../../ui/shared/widgets/custom_pinned_header.dart';
import '../../../../ui/shared/widgets/empty_state_widget.dart';
import '../../../../ui/shared/widgets/error_state_widget.dart';
import '../../../../ui/shared/widgets/floating_header_layout.dart';
import '../../../../ui/shared/widgets/shimmer_loading.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../core/theme.dart';
import 'widgets/shop_the_look_carousel.dart';
import '../../services/service_constants.dart';


class ShopTabView extends ConsumerStatefulWidget {
  const ShopTabView({super.key});

  @override
  ConsumerState<ShopTabView> createState() => _ShopTabViewState();
}

class _ShopTabViewState extends ConsumerState<ShopTabView> with AutomaticKeepAliveClientMixin {
  String _selectedCategory = 'All Products';
  String _searchQuery = '';
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final totalCartItems = ref.watch(cartViewModelProvider.notifier).totalItems;
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        ),
        bodyBuilder: (context, topPadding) {
          return productsAsync.when(
            loading: () => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topPadding)),
                const ShimmerProductGrid(),
              ],
            ),
            error: (error, stack) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topPadding)),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorStateWidget(
                    message: 'Could not load products. Check your connection.',
                    onRetry: () => ref.invalidate(productsStreamProvider),
                  ),
                ),
              ],
            ),
            data: (products) => _ShopContent(
              products: products,
              selectedCategory: _selectedCategory,
              searchQuery: _searchQuery,
              topPadding: topPadding,
              onCategoryChanged: (c) => setState(() => _selectedCategory = c),
              scrollController: _scrollController,
            ),
          );
        },
      ),
    );
  }
}

// â”€â”€â”€ Shop content (separate widget = independent build scope) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ShopContent extends ConsumerWidget {
  const _ShopContent({
    required this.products,
    required this.selectedCategory,
    required this.searchQuery,
    required this.topPadding,
    required this.onCategoryChanged,
    required this.scrollController,
  });

  final List<Product> products;
  final String selectedCategory;
  final String searchQuery;
  final double topPadding;
  final ValueChanged<String> onCategoryChanged;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final categories = ['All Products', ...products.map((p) => p.category).toSet()];
    final featuredCollectionsAsync = ref.watch(featuredCollectionsProvider);

    final query = searchQuery.trim().toLowerCase();
    final filteredProducts = products.where((p) {
      final matchesCategory = selectedCategory == 'All Products' || p.category == selectedCategory;
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productsStreamProvider);
        await ref.read(productsStreamProvider.future);
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topPadding)),
          SliverToBoxAdapter(
            child: _AiConciergeBanner(products: products),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                featuredCollectionsAsync.when(
                  loading: () => const ShimmerShopTheLook(),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('Could not load featured collections',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                  data: (collections) {
                    if (collections.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'Shop the Look',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, letterSpacing: -0.3),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        ShopTheLookCarousel(collections: collections),
                        const SizedBox(height: 24.0),
                      ],
                    );
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Browse Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, letterSpacing: -0.3),
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
                      final isSelected = category == selectedCategory;
                      return AnimatedTapScale(
                        onTap: () => onCategoryChanged(category),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12.0),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : theme.colorScheme.outlineVariant,
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              category.toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32.0),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Pieces',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, letterSpacing: -0.3),
                      ),
                      TextButton(
                        onPressed: () {
                          if (scrollController.hasClients) {
                            final target = 550.0;
                            final max = scrollController.position.maxScrollExtent;
                            scrollController.animateTo(
                              target > max ? max : target,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        child: Text('See All', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
              ],
            ),
          ),
          if (filteredProducts.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: EmptyStateWidget(
                  icon: CupertinoIcons.search,
                  title: 'No pieces found',
                  message: 'Try adjusting your search or browse a different category.',
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
                          AppPageRoute(
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
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16.0),
                                      child: CachedNetworkImage(
                                        imageUrl: product.imageUrl,
                                        memCacheWidth: 300,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: theme.colorScheme.surfaceContainerLow,
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: theme.colorScheme.surfaceContainerLow,
                                          child: const Icon(CupertinoIcons.photo),
                                        ),
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
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
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
                            style: TextStyle(fontSize: 16, height: 1.1, color: theme.colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            formatGhs(product.price),
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: filteredProducts.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 140.0)),
        ],
      ),
    );
  }
}

class _AiConciergeBanner extends StatelessWidget {
  final List<Product> products;
  const _AiConciergeBanner({required this.products});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 120,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // â”€â”€ Background image â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Image.asset(
                'packages/fijadora_core/assets/images/ai_concierge_banner_bg.png',
                fit: BoxFit.cover,
              ),
              // â”€â”€ Dark gradient overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0D1F1C).withValues(alpha: 0.82),
                      const Color(0xFF1A3530).withValues(alpha: 0.60),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              // â”€â”€ Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    // Glassy icon bubble
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.sparkles,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'AI Design Concierge',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Snap a room photo & get perfectly matching pieces',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.75),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // CTA button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AiConciergePage(catalog: products),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Try Now',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

