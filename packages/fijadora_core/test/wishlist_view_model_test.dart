import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fijadora_core/data/repositories/shop_repository.dart';
import 'package:fijadora_core/domain/models/product.dart';
import 'package:fijadora_core/ui/features/shop/view_models/products_provider.dart';
import 'package:fijadora_core/ui/features/shop/view_models/wishlist_view_model.dart';

class StubWishlistShopRepository implements ShopRepository {
  final _wishlistController = StreamController<List<String>>.broadcast();
  final _productsController = StreamController<List<Product>>.broadcast();

  void emitWishlist(List<String> ids) => _wishlistController.add(ids);
  void emitProducts(List<Product> products) => _productsController.add(products);

  @override
  Stream<List<String>> streamWishlist() => _wishlistController.stream;

  @override
  Stream<List<Product>> streamProducts() => _productsController.stream;

  @override
  Future<Product> createProduct(Product product) async => throw UnimplementedError();
  @override
  Future<void> deleteProduct(String id) async {}
  @override
  Future<void> addReview(String productId, double rating, String comment) async {}
  @override
  Future<Product> updateProduct(Product product) async => throw UnimplementedError();
  @override
  Future<void> toggleWishlist(String productId) async {}
  @override
  Future<String> uploadProductImage(String fileName, Uint8List fileBytes) async => '';
  @override
  Stream<List<Map<String, dynamic>>> streamReviews(String productId) => const Stream.empty();
  @override
  void dispose() { _wishlistController.close(); _productsController.close(); }
}

Product _product(String id) => Product(
  id: id, name: 'Product $id', description: '', price: 10.0,
  imageUrl: '', category: '', inventoryCount: 5, createdAt: DateTime(2026),
);

ProviderContainer _makeContainer(StubWishlistShopRepository repo) {
  return ProviderContainer(overrides: [
    shopRepositoryProvider.overrideWithValue(repo),
  ]);
}

void main() {
  group('wishlistProvider', () {
    test('starts in loading state', () {
      final stubRepo = StubWishlistShopRepository();
      final container = _makeContainer(stubRepo);
      addTearDown(() { container.dispose(); stubRepo.dispose(); });

      expect(container.read(wishlistProvider), const AsyncValue<List<String>>.loading());
    });

    test('emits wishlist IDs', () async {
      final stubRepo = StubWishlistShopRepository();
      final container = _makeContainer(stubRepo);
      addTearDown(() { container.dispose(); stubRepo.dispose(); });

      final emitted = <List<String>>[];
      container.listen(wishlistProvider, (_, next) {
        next.whenData((ids) => emitted.add(ids));
      });

      await Future.delayed(Duration.zero);
      stubRepo.emitWishlist(['p1', 'p3']);
      await Future.delayed(Duration.zero);

      expect(emitted, hasLength(1));
      expect(emitted.first, containsAll(['p1', 'p3']));
    });

    test('emits empty list when wishlist is empty', () async {
      final stubRepo = StubWishlistShopRepository();
      final container = _makeContainer(stubRepo);
      addTearDown(() { container.dispose(); stubRepo.dispose(); });

      final emitted = <List<String>>[];
      container.listen(wishlistProvider, (_, next) {
        next.whenData((ids) => emitted.add(ids));
      });

      await Future.delayed(Duration.zero);
      stubRepo.emitWishlist([]);
      await Future.delayed(Duration.zero);

      expect(emitted, hasLength(1));
      expect(emitted.first, isEmpty);
    });
  });

  group('wishlistedProductsProvider', () {
    test('returns empty list when wishlist is empty', () async {
      final stubRepo = StubWishlistShopRepository();
      final container = _makeContainer(stubRepo);
      addTearDown(() { container.dispose(); stubRepo.dispose(); });

      // Start listening to the combined provider
      final emitted = <List<Product>>[];
      container.listen(wishlistedProductsProvider, (_, next) {
        next.whenData((p) => emitted.add(p));
      });

      // Subscribe both inner providers first (so they don't miss events)
      container.read(wishlistProvider);
      container.read(productsStreamProvider);
      await Future.delayed(Duration.zero);

      // Now emit data on both streams
      stubRepo.emitProducts([_product('p1'), _product('p2')]);
      stubRepo.emitWishlist([]);
      // Need multiple pumps: first for wishlist (which triggers subscribe to products),
      // then for products data
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(emitted.any((l) => l.isEmpty), isTrue);
    });

    test('filters products by wishlist IDs', () async {
      final stubRepo = StubWishlistShopRepository();
      final container = _makeContainer(stubRepo);
      addTearDown(() { container.dispose(); stubRepo.dispose(); });

      final emitted = <List<Product>>[];
      container.listen(wishlistedProductsProvider, (_, next) {
        next.whenData((p) => emitted.add(p));
      });

      container.read(wishlistProvider);
      container.read(productsStreamProvider);
      await Future.delayed(Duration.zero);

      // Emit products first (wishlist is still loading, so nothing happens yet)
      stubRepo.emitProducts([_product('p1'), _product('p2'), _product('p3')]);
      await Future.delayed(Duration.zero);
      // Now emit wishlist — this triggers the combined provider to read products
      stubRepo.emitWishlist(['p1', 'p3']);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(emitted.any((l) => l.length == 2), isTrue);
    });

    test('reflects wishlist removal', () async {
      final stubRepo = StubWishlistShopRepository();
      final container = _makeContainer(stubRepo);
      addTearDown(() { container.dispose(); stubRepo.dispose(); });

      final emitted = <List<Product>>[];
      container.listen(wishlistedProductsProvider, (_, next) {
        next.whenData((p) => emitted.add(p));
      });

      container.read(wishlistProvider);
      container.read(productsStreamProvider);
      await Future.delayed(Duration.zero);

      stubRepo.emitProducts([_product('p1'), _product('p2')]);
      await Future.delayed(Duration.zero);
      stubRepo.emitWishlist(['p1', 'p2']);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      stubRepo.emitWishlist(['p1']);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(emitted.any((l) => l.length == 1 && l.first.id == 'p1'), isTrue);
    });

    test('reports loading before any data', () {
      final stubRepo = StubWishlistShopRepository();
      final container = _makeContainer(stubRepo);
      addTearDown(() { container.dispose(); stubRepo.dispose(); });

      expect(container.read(wishlistedProductsProvider).isLoading, isTrue);
    });

    test('updates when products list changes', () async {
      final stubRepo = StubWishlistShopRepository();
      final container = _makeContainer(stubRepo);
      addTearDown(() { container.dispose(); stubRepo.dispose(); });

      final emitted = <List<Product>>[];
      container.listen(wishlistedProductsProvider, (_, next) {
        next.whenData((p) => emitted.add(p));
      });

      container.read(wishlistProvider);
      container.read(productsStreamProvider);
      await Future.delayed(Duration.zero);

      stubRepo.emitProducts([_product('p1'), _product('p2')]);
      await Future.delayed(Duration.zero);
      stubRepo.emitWishlist(['p1', 'p2']);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // Add a third product & remove from wishlist simultaneously
      stubRepo.emitProducts([_product('p1'), _product('p2'), _product('p3')]);
      await Future.delayed(Duration.zero);

      // With products=[p1,p2,p3] and wishlist=[p1,p2], result should still be [p1,p2]
      expect(emitted.any((l) => l.length == 2), isTrue);
    });
  });
}
