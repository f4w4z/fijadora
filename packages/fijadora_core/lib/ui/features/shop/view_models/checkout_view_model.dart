import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/order_repository.dart';
import '../../../../data/services/paystack_service.dart';
import '../../../../data/services/supabase_service.dart';
import '../view_models/cart_view_model.dart';

class CheckoutState {
  final bool isSubmitting;
  final String? error;
  final String? orderId;
  final bool done;

  /// Paystack state (used only when paying for an existing order).
  final String? authorizationUrl;
  final String? reference;
  final bool mock;

  const CheckoutState({
    this.isSubmitting = false,
    this.error,
    this.orderId,
    this.done = false,
    this.authorizationUrl,
    this.reference,
    this.mock = false,
  });

  CheckoutState copyWith({
    bool? isSubmitting,
    String? error,
    String? orderId,
    bool? done,
    String? authorizationUrl,
    String? reference,
    bool? mock,
  }) {
    return CheckoutState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      orderId: orderId ?? this.orderId,
      done: done ?? this.done,
      authorizationUrl: authorizationUrl ?? this.authorizationUrl,
      reference: reference ?? this.reference,
      mock: mock ?? this.mock,
    );
  }
}

class CheckoutViewModel extends StateNotifier<CheckoutState> {
  CheckoutViewModel(this._ref) : super(const CheckoutState());
  final Ref _ref;

  /// Place an order (no payment). Delivery fee will be added later by staff.
  Future<void> placeOrder({
    required String deliveryAddress,
    String? deliveryPhone,
    String? deliveryNote,
  }) async {
    final cart = _ref.read(cartViewModelProvider);
    if (cart.isEmpty) {
      state = state.copyWith(error: 'Your cart is empty');
      return;
    }
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final lines = cart.entries
          .map((e) => CartLine(e.key, e.value))
          .toList();

      final orderId = await _ref.read(orderRepositoryProvider).createOrder(
            lines: lines,
            deliveryAddress: deliveryAddress,
            deliveryPhone: deliveryPhone,
            deliveryNote: deliveryNote,
          );

      _ref.read(cartViewModelProvider.notifier).clearCart();
      state = state.copyWith(isSubmitting: false, done: true, orderId: orderId);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  /// Initialize Paystack payment for an existing order (after delivery quote).
  Future<void> payForOrder(String orderId, double total) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      final email = user?.email ?? 'customer@fijadora.com';
      final reference = 'ORD_${DateTime.now().millisecondsSinceEpoch}_$orderId';

      final init = await PaystackService.instance.initializeCheckout(
        email: email,
        amountKobo: (total * 100).round(),
        reference: reference,
        orderId: orderId,
      );

      final authUrl = init['authorization_url'] as String?;
      final isMock = init['mock'] == true;
      state = state.copyWith(
        isSubmitting: false,
        authorizationUrl: authUrl,
        mock: isMock,
        reference: reference,
        orderId: orderId,
      );
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  /// Verify payment after returning from Paystack and finalize the order.
  Future<bool> verifyAndFinalize() async {
    if (state.reference == null || state.orderId == null) return false;
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final result = await PaystackService.instance.verifyTransaction(state.reference!);
      final status = result['status'] as String?;
      if (status == 'success') {
        await _ref.read(orderRepositoryProvider).markOrderPaid(state.orderId!, state.reference!);
        state = state.copyWith(isSubmitting: false, done: true);
        return true;
      }
      state = state.copyWith(isSubmitting: false, error: 'Payment not completed');
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final checkoutViewModelProvider = StateNotifierProvider<CheckoutViewModel, CheckoutState>((ref) {
  return CheckoutViewModel(ref);
});
