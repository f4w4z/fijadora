import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../view_models/cart_view_model.dart';
import '../view_models/checkout_view_model.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../core/utilities/responsive_helpers.dart';

class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  static const double _deliveryFee = 1500.0;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final checkout = ref.read(checkoutViewModelProvider.notifier);
    await checkout.placeOrder(
      deliveryFee: _deliveryFee,
      deliveryAddress: _addressController.text.trim(),
      deliveryPhone: _phoneController.text.trim(),
      deliveryNote: _noteController.text.trim(),
    );
    final state = ref.read(checkoutViewModelProvider);
    if (state.authorizationUrl != null) {
      if (state.mock) {
        // Mock mode (Paystack key not configured): skip browser, auto-confirm.
        if (mounted) _verify();
        return;
      }
      final uri = Uri.parse(state.authorizationUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // After returning, verify payment.
        if (mounted) _verify();
      }
    } else if (state.error != null && mounted) {
      _showError(state.error!);
    }
  }

  Future<void> _verify() async {
    final ok = await ref.read(checkoutViewModelProvider.notifier).verifyAndFinalize();
    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful! Your order is confirmed.')),
        );
        Navigator.of(context).pop(true);
      } else {
        _showError(ref.read(checkoutViewModelProvider).error ?? 'Payment could not be verified');
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment'),
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
    final total = subtotal + _deliveryFee;

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
                    maxLines: 2,
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
                            Expanded(child: Text('${e.key.name} × ${e.value}')),
                            Text('\$${(e.key.price * e.value).toStringAsFixed(0)}'),
                          ],
                        ),
                      )),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('\$${subtotal.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery fee'),
                      Text('\$${_deliveryFee.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      onPressed: checkout.isSubmitting ? null : _pay,
                      child: checkout.isSubmitting
                          ? const CircularProgressIndicator()
                          : const Text('Pay with Paystack'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
