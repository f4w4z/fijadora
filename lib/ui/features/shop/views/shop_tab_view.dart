import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/product.dart';
import '../view_models/cart_view_model.dart';
import '../view_models/wishlist_view_model.dart';
import 'cart_view.dart';
import 'product_detail_view.dart';
import 'wishlist_view.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../../../../ui/shared/widgets/custom_pinned_header.dart';


class ShopTabView extends ConsumerStatefulWidget {
  const ShopTabView({super.key});

  @override
  ConsumerState<ShopTabView> createState() => _ShopTabViewState();
}

class _ShopTabViewState extends ConsumerState<ShopTabView> {
  String _selectedCategory = 'All Products';
  String _searchQuery = '';

  void _showAiConcierge(BuildContext context, List<Product> catalog) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final innerTheme = Theme.of(context);
        final recommendedIds = ['prod-1', 'prod-2'];
        final recommended = catalog.where((p) => recommendedIds.contains(p.id)).toList();
        
        return _AiConciergeSheet(
          theme: innerTheme,
          recommended: recommended,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCartItems = ref.watch(cartViewModelProvider.notifier).totalItems;
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          CustomPinnedHeader(
            title: 'Shop',
            actions: [
              HeaderActionButton(
                icon: CupertinoIcons.heart,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const WishlistView()),
                  );
                },
              ),
              HeaderActionButton(
                icon: CupertinoIcons.cart,
                badgeCount: totalCartItems,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CartView()),
                  );
                },
              ),
            ],
            bottomChild: CupertinoSearchTextField(
              placeholder: 'Search pieces...',
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
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

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Prominent Banner
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),

                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phoebe Curated',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 14,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                'Architectural furniture for modern living spaces.',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.onPrimary,
                                      foregroundColor: theme.colorScheme.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                      elevation: 0,
                                    ),
                                    child: const Text('View Collection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: () => _showAiConcierge(context, products),
                                    icon: const Icon(CupertinoIcons.sparkles, size: 14),
                                    label: const Text('AI Concierge', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: theme.colorScheme.onPrimary,
                                      side: BorderSide(color: theme.colorScheme.onPrimary),
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32.0),

                      if (bundleProducts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'Shop the Look (Styled Rooms)',
                            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        SizedBox(
                          height: 140.0,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            itemCount: bundleProducts.length,
                            itemBuilder: (context, index) {
                              final bundle = bundleProducts[index];
                              return AnimatedTapScale(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => ProductDetailView(product: bundle)),
                                  );
                                },
                                child: Container(
                                  width: 280,
                                  margin: const EdgeInsets.only(right: 16.0),
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
                                      ClipRRect(
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(11.0)),
                                        child: Hero(
                                          tag: 'product-img-${bundle.id}',
                                          child: Image.network(
                                            bundle.imageUrl,
                                            width: 100,
                                            height: 140,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => Container(
                                              color: theme.colorScheme.surfaceContainerHighest,
                                              width: 100,
                                              child: const Icon(CupertinoIcons.photo),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primaryContainer,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'ROOM BUNDLE',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.colorScheme.onPrimaryContainer,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                bundle.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '\$${bundle.price.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.primary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32.0),
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

                      // Products Grid
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
                      filteredProducts.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Text(
                                  'No pieces found in this category.',
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16.0,
                                mainAxisSpacing: 24.0,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
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
                                      // Product image card
                                      Expanded(
                                        child: Card(
                                          clipBehavior: Clip.antiAlias,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                            side: BorderSide(
                                              color: theme.brightness == Brightness.dark
                                                  ? const Color(0xFF222222)
                                                  : const Color(0xFFE5E5E5),
                                            ),
                                          ),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Hero(
                                                tag: 'product-img-${product.id}',
                                                child: Image.network(
                                                  product.imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    color: theme.colorScheme.surfaceContainerHighest,
                                                    child: const Icon(CupertinoIcons.photo),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: Colors.white.withValues(alpha: 0.8),
                                                  child: IconButton(
                                                    icon: const Icon(CupertinoIcons.add, size: 14, color: Colors.black),
                                                    onPressed: () {
                                                      ref.read(cartViewModelProvider.notifier).addToCart(product);
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('${product.name} added to cart'),
                                                          duration: const Duration(seconds: 1),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        product.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        '\$${product.price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) {
          setState(() {
            _selectedCategory = label;
          });
        },
        backgroundColor: theme.colorScheme.surface,
        selectedColor: theme.colorScheme.primary,
        checkmarkColor: theme.colorScheme.onPrimary,
        labelStyle: TextStyle(
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : const Color(0xFFE5E5E5),
          ),
        ),
      ),
    );
  }
}

class _AiConciergeSheet extends StatefulWidget {
  const _AiConciergeSheet({
    required this.theme,
    required this.recommended,
  });

  final ThemeData theme;
  final List<Product> recommended;

  @override
  State<_AiConciergeSheet> createState() => _AiConciergeSheetState();
}

class _AiConciergeSheetState extends State<_AiConciergeSheet> {
  bool _uploaded = false;
  bool _analyzing = false;

  Future<void> _uploadAndAnalyze() async {
    setState(() => _analyzing = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      setState(() {
        _uploaded = true;
        _analyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.sparkles, color: Colors.indigo, size: 20),
                  SizedBox(width: 8),
                  Text('AI Design Concierge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.clear),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a room photo to get recommendations matching your space layout and aesthetic.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _analyzing
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(height: 16),
                        Text('Analyzing room geometry & lighting...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                : _uploaded
                    ? _buildRecommendations(context)
                    : _buildUploadTrigger(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadTrigger(BuildContext context) {
    return InkWell(
      onTap: _uploadAndAnalyze,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: widget.theme.brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.theme.brightness == Brightness.dark
                ? const Color(0xFF333333)
                : const Color(0xFFE5E5E5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.photo_on_rectangle, size: 48, color: widget.theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('Upload Living / Bedroom Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            const Text('Supports JPG, PNG up to 10MB', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=400&auto=format&fit=crop&q=60',
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 16),
            SizedBox(width: 8),
            Text(
              'Aesthetic Style: Warm Minimalist Modern',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Matching Pieces in Shop',
          style: widget.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: widget.recommended.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = widget.recommended[index];
              return InkWell(
                onTap: () {
                  Navigator.pop(context); // Close AI concierge
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProductDetailView(product: product)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.theme.brightness == Brightness.dark
                          ? const Color(0xFF222222)
                          : const Color(0xFFE5E5E5),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(product.imageUrl, width: 48, height: 48, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('\$${product.price.toStringAsFixed(0)}', style: TextStyle(color: widget.theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


