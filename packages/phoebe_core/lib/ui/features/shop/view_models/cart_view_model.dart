import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/product.dart';

class CartViewModel extends StateNotifier<Map<Product, int>> {
  CartViewModel() : super({});

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
  return CartViewModel();
});
