import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../view_models/cart_view_model.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../core/utilities/responsive_helpers.dart';

class CartView extends ConsumerWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartViewModelProvider);
    final cartNotifier = ref.read(cartViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () {
                cartNotifier.clearCart();
              },
              child: Text(
                'Clear All',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const EmptyStateWidget(
              icon: CupertinoIcons.bag,
              title: 'Your cart is empty',
              message: 'Explore curated pieces in our shop.',
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: context.pagePad, vertical: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      cart.entries.map((entry) {
                        final product = entry.key;
                        final qty = entry.value;

                        return Dismissible(
                          key: ValueKey(product.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: context.pagePad),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(CupertinoIcons.trash, color: Colors.white),
                          ),
                          onDismissed: (_) => cartNotifier.removeFromCart(product),
                          child: Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Product Thumbnail
                              ClipRRect(
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
                              const SizedBox(width: 16),
                              // Product details
                              Expanded(
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
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '\$${product.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity Adjusters
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(CupertinoIcons.minus_circle, size: 20),
                                        onPressed: () {
                                          cartNotifier.removeFromCart(product);
                                        },
                                      ),
                                      Text(
                                        '$qty',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(CupertinoIcons.plus_circle, size: 20),
                                        onPressed: () {
                                          cartNotifier.addToCart(product);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Price summary
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.pagePad, vertical: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              '\$${cartNotifier.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reservation Deposit (10%)',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              '\$${(cartNotifier.totalPrice * 0.1).toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Divider(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '\$${(cartNotifier.totalPrice * 1.1).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.huge),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.surfaceContainerHighest,
                    width: 0.5,
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: context.pagePad, vertical: AppSpacing.lg),
              child: SafeArea(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const CheckoutProgressDialog(),
                        );
                        
                        await cartNotifier.checkoutReservation();
                        
                        if (context.mounted) {
                          Navigator.of(context).pop(); // dismiss loading
                           showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              icon: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                                  size: 40,
                                ),
                              ),
                              title: const Text('Reservation Placed'),
                              content: const Text(
                                  'Your architectural furniture reservation has been successfully registered. View details on your orders page.',
                                  textAlign: TextAlign.center),
                              actionsAlignment: MainAxisAlignment.center,
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(); // dismiss dialog
                                    Navigator.of(context).pop(); // back to shop tab
                                  },
                                  child: const Text('Done'),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop(); // dismiss loading
                          context.showSnackBar('Reservation failed: $e', type: SnackBarType.error);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirm Reservation',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class CheckoutProgressDialog extends StatefulWidget {
  const CheckoutProgressDialog({super.key});

  @override
  State<CheckoutProgressDialog> createState() => _CheckoutProgressDialogState();
}

class _CheckoutProgressDialogState extends State<CheckoutProgressDialog> {
  int _messageIndex = 0;
  late final Timer _timer;
  final List<String> _messages = [
    'Reserving items...',
    'Verifying inventory...',
    'Generating scheduled job...',
    'Finalizing details...',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E5E5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                _messages[_messageIndex],
                key: ValueKey<int>(_messageIndex),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
