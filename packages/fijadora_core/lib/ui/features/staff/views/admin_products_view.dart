import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/product.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../../../../ui/shared/widgets/empty_state_widget.dart';
import '../../../../ui/shared/widgets/shimmer_loading.dart';
import '../../../core/theme.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../shop/view_models/products_provider.dart';
import '../view_models/admin_products_view_model.dart';
import 'admin_collections_view.dart';
import 'product_form_page.dart';
import 'product_list_card.dart';
import 'staff_commerce_view.dart';

class AdminProductsView extends ConsumerStatefulWidget {
  const AdminProductsView({super.key});

  static const List<String> categories = [
    'All',
    'Lighting',
    'Decor',
    'Textiles',
    'Chairs',
    'Bedroom',
    'Living Room',
  ];

  @override
  ConsumerState<AdminProductsView> createState() => _AdminProductsViewState();
}

class _AdminProductsViewState extends ConsumerState<AdminProductsView> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsStreamProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage Shop Products',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.creditcard, color: theme.colorScheme.onSurfaceVariant),
            tooltip: 'Commerce (Orders, Requests, Payouts, Workers)',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const StaffCommerceView()),
            ),
          ),
          IconButton(
            icon: Icon(CupertinoIcons.collections, color: theme.colorScheme.onSurfaceVariant),
            tooltip: 'Manage Looks',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AdminCollectionsView()),
            ),
          ),
          IconButton(
            icon: Icon(CupertinoIcons.add_circled, color: theme.colorScheme.primary, size: 28),
            tooltip: 'Upload Product',
            onPressed: () => _openProductForm(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.pagePad, vertical: AppSpacing.sm),
              child: CupertinoSearchTextField(
                placeholder: 'Search products by name or category...',
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

            // Categories Filter Selector
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: context.pagePad - 8),
                itemCount: AdminProductsView.categories.length,
                itemBuilder: (context, index) {
                  final cat = AdminProductsView.categories[index];
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: AnimatedTapScale(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Products Stream List
            Expanded(
              child: productsAsync.when(
                loading: () => ListView.builder(
                  itemCount: 4,
                  padding: EdgeInsets.symmetric(horizontal: context.pagePad, vertical: 8),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const SkeletonBox(width: 80, height: 80, borderRadius: 12),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SkeletonBox(width: 140, height: 16, borderRadius: 4),
                                const SizedBox(height: 8),
                                const SkeletonBox(width: 80, height: 12, borderRadius: 4),
                                const SizedBox(height: 8),
                                const SkeletonBox(width: 50, height: 14, borderRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                error: (err, stack) => Center(
                  child: EmptyStateWidget(
                    icon: CupertinoIcons.exclamationmark_triangle,
                    title: 'Error Loading Products',
                    message: 'Something went wrong while loading products. Pull to retry.',
                  ),
                ),
                data: (products) {
                  // Filter products
                  final filtered = products.where((p) {
                    final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        p.category.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: EmptyStateWidget(
                        icon: CupertinoIcons.square_grid_2x2,
                        title: 'No Products Found',
                        message: _searchQuery.isNotEmpty
                            ? 'No matches found for "$_searchQuery".'
                            : 'No products added in category "$_selectedCategory" yet.',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    padding: EdgeInsets.fromLTRB(context.pagePad, 8, context.pagePad, 80),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return ProductListCard(
                        product: product,
                        onEdit: () => _openProductForm(context, product: product),
                        onDelete: () => _confirmDelete(context, product),
                        theme: theme,
                        isDark: isDark,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProductForm(BuildContext context, {Product? product}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ProductFormPage(product: product),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to permanently delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final viewModel = ref.read(adminProductsViewModelProvider.notifier);
      try {
        await viewModel.removeProduct(product.id, product.name);
        if (context.mounted) {
          context.showSnackBar('Product deleted successfully', type: SnackBarType.success);
        }
      } catch (e) {
        if (context.mounted) {
          context.showSnackBar('Failed to delete product: $e', type: SnackBarType.error);
        }
      }
    }
  }
}
