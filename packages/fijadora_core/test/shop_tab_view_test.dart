import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fijadora_core/data/repositories/shop_repository.dart';
import 'package:fijadora_core/data/repositories/collections_repository.dart';
import 'package:fijadora_core/domain/models/product.dart';
import 'package:fijadora_core/domain/models/collection.dart';
import 'package:fijadora_core/ui/features/shop/views/shop_tab_view.dart';
import 'package:fijadora_core/ui/shared/widgets/shimmer_loading.dart';
import 'package:fijadora_core/ui/shared/widgets/empty_state_widget.dart';

class StubShopRepository implements ShopRepository {
  final _productsController = StreamController<List<Product>>.broadcast();

  void emitProducts(List<Product> products) => _productsController.add(products);

  @override
  Stream<List<Product>> streamProducts() => _productsController.stream;

  @override
  Stream<List<String>> streamWishlist() => const Stream.empty();

  @override
  Future<void> toggleWishlist(String productId) async {}

  @override
  Stream<List<Map<String, dynamic>>> streamReviews(String productId) => const Stream.empty();

  @override
  Future<void> addReview(String productId, double rating, String comment) async {}

  @override
  Future<Product> createProduct(Product product) async => throw UnimplementedError();

  @override
  Future<Product> updateProduct(Product product) async => throw UnimplementedError();

  @override
  Future<void> deleteProduct(String id) async {}

  @override
  Future<String> uploadProductImage(String fileName, Uint8List fileBytes) async => '';

  @override
  void dispose() {
    _productsController.close();
  }
}

class StubCollectionsRepository implements CollectionsRepository {
  @override
  Future<bool> hasUserLiked(String collectionId, String userId) async => false;
  @override
  Future<bool> hasUserFollowed(String collectionId, String userId) async => false;
  final _featuredController = StreamController<List<Collection>>.broadcast();

  void emitFeatured(List<Collection> collections) => _featuredController.add(collections);

  @override
  Stream<List<Collection>> streamFeaturedCollections() => _featuredController.stream;

  @override
  Stream<List<Collection>> streamCollections() => const Stream.empty();

  @override
  Future<void> toggleFollow(String collectionId, String userId) async {}

  @override
  Future<void> toggleLike(String collectionId, String userId) async {}

  @override
  Future<Collection> createCollection(Collection collection) async => throw UnimplementedError();

  @override
  Future<Collection> updateCollection(Collection collection) async => throw UnimplementedError();

  @override
  Future<void> deleteCollection(String id) async {}

  @override
  Future<String> uploadCoverImage(String fileName, Uint8List fileBytes) async => '';

  @override
  Future<void> setFeatured(String collectionId, bool isFeatured) async {}

  @override
  void dispose() {
    _featuredController.close();
  }
}

Product _product(String id, {String category = 'Decor'}) => Product(
      id: id,
      name: 'Product $id',
      description: 'Description for $id',
      price: 49.99,
      imageUrl: '',
      category: category,
      inventoryCount: 10,
      createdAt: DateTime(2026),
    );


Widget _buildTestWidget({
  required StubShopRepository shopRepo,
  required StubCollectionsRepository collectionsRepo,
}) {
  return ProviderScope(
    overrides: [
      shopRepositoryProvider.overrideWithValue(shopRepo),
      collectionsRepositoryProvider.overrideWithValue(collectionsRepo),
    ],
    child: const MaterialApp(
      home: ShopTabView(),
    ),
  );
}

void main() {
  group('ShopTabView', () {
    testWidgets('renders the shop tab', (tester) async {
      final shopRepo = StubShopRepository();
      final collectionsRepo = StubCollectionsRepository();
      addTearDown(() {
        shopRepo.dispose();
        collectionsRepo.dispose();
      });

      await tester.pumpWidget(_buildTestWidget(
        shopRepo: shopRepo,
        collectionsRepo: collectionsRepo,
      ));
      await tester.pump();

      expect(find.text('Shop'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.cart), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      final shopRepo = StubShopRepository();
      final collectionsRepo = StubCollectionsRepository();
      addTearDown(() {
        shopRepo.dispose();
        collectionsRepo.dispose();
      });

      await tester.pumpWidget(_buildTestWidget(
        shopRepo: shopRepo,
        collectionsRepo: collectionsRepo,
      ));
      await tester.pump();

      expect(find.text('Shop'), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('shows products when loaded', (tester) async {
      final shopRepo = StubShopRepository();
      final collectionsRepo = StubCollectionsRepository();
      addTearDown(() {
        shopRepo.dispose();
        collectionsRepo.dispose();
      });

      await tester.pumpWidget(_buildTestWidget(
        shopRepo: shopRepo,
        collectionsRepo: collectionsRepo,
      ));
      await tester.pump();

      shopRepo.emitProducts([
        _product('p1', category: 'Decor'),
        _product('p2', category: 'Furniture'),
      ]);
      collectionsRepo.emitFeatured([]);

      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Verify data arrived: categories from products appear
      expect(find.text('DECOR'), findsOneWidget);
      expect(find.text('FURNITURE'), findsOneWidget);
      expect(find.text('Featured Pieces'), findsOneWidget);

      // Scroll down to make the product grid visible
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pump();
      await tester.pump();

      expect(find.text('Product p1'), findsOneWidget);
      expect(find.text('Product p2'), findsOneWidget);
    });

    testWidgets('handles empty product list', (tester) async {
      final shopRepo = StubShopRepository();
      final collectionsRepo = StubCollectionsRepository();
      addTearDown(() {
        shopRepo.dispose();
        collectionsRepo.dispose();
      });

      await tester.pumpWidget(_buildTestWidget(
        shopRepo: shopRepo,
        collectionsRepo: collectionsRepo,
      ));
      await tester.pump();

      shopRepo.emitProducts([]);
      collectionsRepo.emitFeatured([]);

      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Scroll down to make the empty state visible
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pump();
      await tester.pump();

      expect(find.text('No pieces found'), findsOneWidget);
      expect(find.byType(EmptyStateWidget), findsOneWidget);
    });
  });
}
