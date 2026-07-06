import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../domain/models/product.dart';
import '../../../../core/utilities/responsive_helpers.dart';

class ProductDetailBottomBar extends StatelessWidget {
  const ProductDetailBottomBar({
    super.key,
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
          padding: EdgeInsets.symmetric(horizontal: context.pagePad, vertical: AppSpacing.md),
          child: Row(
            children: [
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
                const SizedBox(width: AppSpacing.md),
              ],
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
