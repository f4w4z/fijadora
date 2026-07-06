import 'package:flutter_test/flutter_test.dart';
import 'package:fijadora_core/domain/models/product.dart';
import 'package:fijadora_core/ui/features/shop/view_models/cart_view_model.dart';

Product _product({String id = 'p1', double price = 10.0, int stock = 5}) => Product(
  id: id, name: 'Test', description: '', price: price,
  imageUrl: '', category: '', inventoryCount: stock,
  createdAt: DateTime(2026),
);

void main() {
  group('CartViewModel', () {
    late CartViewModel cart;

    setUp(() => cart = CartViewModel());

    test('starts empty', () {
      expect(cart.state, isEmpty);
      expect(cart.totalItems, 0);
      expect(cart.totalPrice, 0.0);
    });

    test('addToCart adds product with quantity 1', () {
      cart.addToCart(_product());
      expect(cart.state.length, 1);
      expect(cart.state.values.first, 1);
    });

    test('addToCart increments quantity for same product', () {
      final p = _product();
      cart.addToCart(p);
      cart.addToCart(p);
      expect(cart.state[p], 2);
    });

    test('addToCart respects inventory limit', () {
      final p = _product(stock: 2);
      cart.addToCart(p);
      cart.addToCart(p);
      cart.addToCart(p); // third should be blocked
      expect(cart.state[p], 2);
    });

    test('addToCart rejects out-of-stock product', () {
      cart.addToCart(_product(stock: 0));
      expect(cart.state, isEmpty);
    });

    test('removeFromCart decrements quantity', () {
      final p = _product();
      cart.addToCart(p);
      cart.addToCart(p);
      cart.removeFromCart(p);
      expect(cart.state[p], 1);
    });

    test('removeFromCart removes product when quantity reaches 0', () {
      final p = _product();
      cart.addToCart(p);
      cart.removeFromCart(p);
      expect(cart.state.containsKey(p), isFalse);
    });

    test('removeFromCart does nothing for missing product', () {
      cart.removeFromCart(_product());
      expect(cart.state, isEmpty);
    });

    test('totalPrice sums correctly', () {
      cart.addToCart(_product(id: 'p1', price: 10.0));
      cart.addToCart(_product(id: 'p2', price: 20.0));
      cart.addToCart(_product(id: 'p1', price: 10.0));
      expect(cart.totalPrice, 40.0);
    });

    test('clearCart empties all items', () {
      cart.addToCart(_product());
      cart.clearCart();
      expect(cart.state, isEmpty);
    });
  });
}
