import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/cart_view_model.dart';
import '../view_models/checkout_view_model.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../services/service_constants.dart';

class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final checkout = ref.read(checkoutViewModelProvider.notifier);
    await checkout.placeOrder(
      deliveryAddress: _addressController.text.trim(),
      deliveryPhone: _phoneController.text.trim(),
      deliveryNote: _noteController.text.trim(),
    );
    final state = ref.read(checkoutViewModelProvider);
    if (state.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed! We\'ll send you a delivery quote shortly.')),
      );
      Navigator.of(context).pop(true);
    } else if (state.error != null && mounted) {
      _showError(state.error!);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartViewModelProvider);
    final checkout = ref.watch(checkoutViewModelProvider);
    final subtotal = cart.entries.fold<double>(0, (s, e) => s + e.key.price * e.value);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.isEmpty
          ? const EmptyStateWidget(icon: CupertinoIcons.cart, title: 'Nothing to checkout', message: 'Your cart is empty.')
          : SingleChildScrollView(
              padding: EdgeInsets.all(context.pagePad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Delivery Details', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Delivery address', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone number', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Delivery note (optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Text('Order Summary', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...cart.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${e.key.name} Ã— ${e.value}')),
                            Text(formatGhs((e.key.price * e.value))),
                          ],
                        ),
                      )),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text(formatGhs(subtotal)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delivery fee', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      Text('TBD', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (checkout.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(checkout.error!, style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: checkout.isSubmitting ? null : _placeOrder,
                      child: checkout.isSubmitting
                          ? const CircularProgressIndicator()
                          : const Text('Place Order'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Delivery fee will be calculated and sent to you after placing the order.',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
