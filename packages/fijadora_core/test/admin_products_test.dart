import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fijadora_core/data/repositories/shop_repository.dart';
import 'package:fijadora_core/data/services/app_notification_service.dart';
import 'package:fijadora_core/data/services/telemetry_service.dart';
import 'package:fijadora_core/domain/models/product.dart';
import 'package:fijadora_core/ui/features/staff/view_models/admin_products_view_model.dart';

// Stub Shop Repository for testing
class StubShopRepository implements ShopRepository {
  final List<Product> _products = [];

  @override
  Stream<List<Product>> streamProducts() async* {
    yield List.unmodifiable(_products);
  }

  @override
  Future<Product> createProduct(Product product) async {
    final created = product.copyWith(
      id: 'stub-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    _products.add(created);
    return created;
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx == -1) throw Exception('Product not found');
    _products[idx] = product;
    return product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
  }

  @override
  Future<String> uploadProductImage(String fileName, Uint8List fileBytes) async {
    return 'https://example.com/uploads/$fileName';
  }

  @override
  Stream<List<String>> streamWishlist() => const Stream.empty();
  @override
  Future<void> toggleWishlist(String productId) async {}
  @override
  Stream<List<Map<String, dynamic>>> streamReviews(String productId) => const Stream.empty();
  @override
  Future<void> addReview(String productId, double rating, String comment) async {}
  @override
  void dispose() {}
}

class DummyNotificationService implements NotificationService {
  final List<String> sentTitles = [];
  
  @override
  void sendNotification({required String title, required String body}) {
    sentTitles.add(title);
  }

  @override
  Stream<AppNotification> get notificationsStream => const Stream.empty();

  @override
  void dispose() {}
}

class DummyTelemetryService implements TelemetryService {
  final List<String> loggedEvents = [];

  @override
  void logEvent(String name, [Map<String, dynamic>? parameters]) {
    loggedEvents.add(name);
  }

  @override
  void captureException(Object error, [StackTrace? stackTrace]) {}
}

void main() {
  late StubShopRepository stubShopRepo;
  late DummyNotificationService dummyNotificationService;
  late DummyTelemetryService dummyTelemetryService;
  late AdminProductsViewModel adminProductsViewModel;

  setUp(() {
    stubShopRepo = StubShopRepository();
    dummyNotificationService = DummyNotificationService();
    dummyTelemetryService = DummyTelemetryService();
    adminProductsViewModel = AdminProductsViewModel(
      shopRepository: stubShopRepo,
      notificationService: dummyNotificationService,
      telemetryService: dummyTelemetryService,
    );
  });

  group('ShopRepository & AdminProductsViewModel CRUD Tests', () {
    test('Create product success', () async {
      final initialProducts = await stubShopRepo.streamProducts().first;
      final countBefore = initialProducts.length;

      final product = await adminProductsViewModel.addProduct(
        name: 'Test Oak Desk',
        description: 'Solid oak desk',
        price: 350.0,
        imageUrl: 'https://example.com/desk.jpg',
        imageUrls: [],
        category: 'Workspace',
        inventoryCount: 5,
      );

      expect(product.id, isNotEmpty);
      expect(product.name, 'Test Oak Desk');
      expect(product.category, 'Workspace');

      final updatedProducts = await stubShopRepo.streamProducts().first;
      expect(updatedProducts.length, countBefore + 1);
      expect(updatedProducts.any((p) => p.name == 'Test Oak Desk'), isTrue);

      expect(dummyNotificationService.sentTitles.contains('Product Uploaded'), isTrue);
      expect(dummyTelemetryService.loggedEvents.contains('admin_add_product'), isTrue);
    });

    test('Update product success', () async {
      final product = await adminProductsViewModel.addProduct(
        name: 'Oak Desk',
        description: 'Solid oak desk',
        price: 350.0,
        imageUrl: 'https://example.com/desk.jpg',
        imageUrls: [],
        category: 'Workspace',
        inventoryCount: 5,
      );

      final updated = await adminProductsViewModel.editProduct(
        existingProduct: product,
        name: 'Updated Name',
        description: product.description,
        price: 999.0,
        imageUrl: product.imageUrl,
        imageUrls: product.imageUrls,
        category: product.category,
        inventoryCount: 22,
      );

      expect(updated.id, product.id);
      expect(updated.name, 'Updated Name');
      expect(updated.price, 999.0);
      expect(updated.inventoryCount, 22);

      final products = await stubShopRepo.streamProducts().first;
      final refreshed = products.firstWhere((p) => p.id == product.id);
      expect(refreshed.name, 'Updated Name');
      expect(refreshed.price, 999.0);

      expect(dummyNotificationService.sentTitles.contains('Product Updated'), isTrue);
      expect(dummyTelemetryService.loggedEvents.contains('admin_edit_product'), isTrue);
    });

    test('Delete product success', () async {
      final product = await adminProductsViewModel.addProduct(
        name: 'Temporary Item',
        description: 'Will be deleted',
        price: 100.0,
        imageUrl: 'https://example.com/temp.jpg',
        imageUrls: [],
        category: 'Misc',
        inventoryCount: 1,
      );

      final beforeDelete = await stubShopRepo.streamProducts().first;
      final countBefore = beforeDelete.length;

      await adminProductsViewModel.removeProduct(product.id, product.name);

      final afterDelete = await stubShopRepo.streamProducts().first;
      expect(afterDelete.length, countBefore - 1);
      expect(afterDelete.any((p) => p.id == product.id), isFalse);

      expect(dummyNotificationService.sentTitles.contains('Product Removed'), isTrue);
      expect(dummyTelemetryService.loggedEvents.contains('admin_delete_product'), isTrue);
    });

    test('Upload product image success', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final url = await adminProductsViewModel.uploadImage('test.jpg', bytes);
      
      expect(url, isNotEmpty);
      expect(dummyTelemetryService.loggedEvents.contains('admin_upload_image'), isTrue);
    });
  });
}
