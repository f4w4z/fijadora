import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/shop_repository.dart';
import '../../../../data/services/telemetry_service.dart';
import '../../../../domain/models/product.dart';

class CartViewModel extends StateNotifier<Map<Product, int>> {
  CartViewModel(this._shopRepository, this._telemetryService) : super({});

  final ShopRepository _shopRepository;
  final TelemetryService _telemetryService;

  void addToCart(Product product) {
    if (product.inventoryCount <= 0) return;
    
    final currentQty = state[product] ?? 0;
    if (currentQty >= product.inventoryCount) return; // Cannot exceed available stock

    state = {
      ...state,
      product: currentQty + 1,
    };
  }

  void removeFromCart(Product product) {
    final currentQty = state[product] ?? 0;
    if (currentQty <= 0) return;

    final newState = Map<Product, int>.from(state);
    if (currentQty == 1) {
      newState.remove(product);
    } else {
      newState[product] = currentQty - 1;
    }
    state = newState;
  }

  void clearCart() {
    state = {};
  }

  Future<void> checkoutReservation() async {
    _telemetryService.logEvent('checkout_reservation', {
      'item_count': totalItems,
      'total_amount': totalPrice,
    });
    for (final entry in state.entries) {
      final product = entry.key;
      final quantity = entry.value;
      for (int i = 0; i < quantity; i++) {
        await _shopRepository.reserveProduct(product.id);
      }
    }
    clearCart();
  }

  double get totalPrice {
    double total = 0.0;
    state.forEach((product, qty) {
      total += product.price * qty;
    });
    return total;
  }

  int get totalItems {
    int total = 0;
    state.forEach((_, qty) {
      total += qty;
    });
    return total;
  }
}

final cartViewModelProvider = StateNotifierProvider<CartViewModel, Map<Product, int>>((ref) {
  final shopRepository = ref.watch(shopRepositoryProvider);
  final telemetryService = ref.watch(telemetryServiceProvider);
  return CartViewModel(shopRepository, telemetryService);
});
