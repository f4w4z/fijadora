import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/shop_repository.dart';
import '../../../../data/services/app_notification_service.dart';
import '../../../../data/services/telemetry_service.dart';
import '../../../../domain/models/product.dart';

class AdminProductsViewModel extends ChangeNotifier {
  AdminProductsViewModel({
    required this.shopRepository,
    required this.notificationService,
    required this.telemetryService,
  });

  final ShopRepository shopRepository;
  final NotificationService notificationService;
  final TelemetryService telemetryService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<Product> addProduct({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required List<String> imageUrls,
    required String category,
    required int inventoryCount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = Product(
        id: '',
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        imageUrls: imageUrls.isEmpty && imageUrl.isNotEmpty ? [imageUrl] : imageUrls,
        category: category,
        inventoryCount: inventoryCount,
        isReserved: false,
        createdAt: DateTime.now(),
      );

      final created = await shopRepository.createProduct(product);
      telemetryService.logEvent('admin_add_product', {
        'product_name': name,
        'category': category,
        'price': price,
      });

      notificationService.sendNotification(
        title: 'Product Uploaded',
        body: 'Product "$name" has been successfully uploaded to the shop.',
      );

      return created;
    } catch (e) {
      _errorMessage = 'Could not add product.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Product> editProduct({
    required Product existingProduct,
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required List<String> imageUrls,
    required String category,
    required int inventoryCount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = existingProduct.copyWith(
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        imageUrls: imageUrls.isEmpty && imageUrl.isNotEmpty ? [imageUrl] : imageUrls,
        category: category,
        inventoryCount: inventoryCount,
      );

      final updated = await shopRepository.updateProduct(product);
      telemetryService.logEvent('admin_edit_product', {
        'product_id': existingProduct.id,
        'product_name': name,
      });

      notificationService.sendNotification(
        title: 'Product Updated',
        body: 'Product "$name" has been successfully updated.',
      );

      return updated;
    } catch (e) {
      _errorMessage = 'Could not update product.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeProduct(String id, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await shopRepository.deleteProduct(id);
      telemetryService.logEvent('admin_delete_product', {
        'product_id': id,
        'product_name': name,
      });

      notificationService.sendNotification(
        title: 'Product Removed',
        body: 'Product "$name" has been successfully removed from the shop.',
      );
    } catch (e) {
      _errorMessage = 'Could not remove product.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> uploadImage(String fileName, Uint8List fileBytes) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = await shopRepository.uploadProductImage(fileName, fileBytes);
      telemetryService.logEvent('admin_upload_image', {
        'file_name': fileName,
      });
      return url;
    } catch (e) {
      _errorMessage = 'Could not upload image.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Riverpod Provider for AdminProductsViewModel
final adminProductsViewModelProvider = ChangeNotifierProvider<AdminProductsViewModel>((ref) {
  final repository = ref.watch(shopRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final telemetryService = ref.watch(telemetryServiceProvider);

  return AdminProductsViewModel(
    shopRepository: repository,
    notificationService: notificationService,
    telemetryService: telemetryService,
  );
});
