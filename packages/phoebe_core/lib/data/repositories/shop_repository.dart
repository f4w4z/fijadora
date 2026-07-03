import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/product.dart';
import '../services/supabase_service.dart';

abstract class ShopRepository {
  Stream<List<Product>> streamProducts();
  Future<Product> reserveProduct(String id);
  Future<void> updateInventory(String id, int quantity);
  Stream<List<String>> streamWishlist();
  Future<void> toggleWishlist(String productId);
  Stream<List<Map<String, dynamic>>> streamReviews(String productId);
  Future<void> addReview(String productId, double rating, String comment);
  void dispose();
}

// 1. Supabase Shop Repository Implementation
class SupabaseShopRepository implements ShopRepository {
  SupabaseShopRepository(this._client);
  final sb.SupabaseClient _client;

  @override
  Stream<List<Product>> streamProducts() {
    return _client
        .from('products')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((data) => data.map((json) => Product.fromJson(json)).toList());
  }

  @override
  Future<Product> reserveProduct(String id) async {
    final response = await _client
        .from('products')
        .update({'is_reserved': true})
        .eq('id', id)
        .select()
        .single();
    return Product.fromJson(response);
  }

  @override
  Future<void> updateInventory(String id, int quantity) async {
    await _client
        .from('products')
        .update({'inventory_count': quantity})
        .eq('id', id);
  }

  @override
  Stream<List<String>> streamWishlist() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return _client
        .from('wishlists')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((json) => json['product_id'] as String).toList());
  }

  @override
  Future<void> toggleWishlist(String productId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from('wishlists')
          .insert({'user_id': userId, 'product_id': productId});
    } catch (_) {
      // If already exists, delete it (toggle behavior)
      await _client
          .from('wishlists')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> streamReviews(String productId) {
    return _client
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('product_id', productId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Map<String, dynamic>.from(json)).toList())
        .asyncMap((reviews) async {
          if (reviews.isEmpty) return reviews;
          final userIds = reviews.map((r) => r['user_id'] as String).toSet().toList();
          final users = await _client.rpc('get_user_names', params: {'user_ids': userIds});
          final names = {for (final u in users) u['id'] as String: u['name'] as String?};
          for (final r in reviews) {
            r['user_name'] = names[r['user_id'] as String] ?? 'User';
          }
          return reviews;
        });
  }

  @override
  Future<void> addReview(String productId, double rating, String comment) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('reviews')
        .insert({
          'user_id': userId,
          'product_id': productId,
          'rating': rating.toInt(),
          'comment': comment
        });
  }

  @override
  void dispose() {}
}

// 2. Mock Shop Repository Implementation
class MockShopRepository implements ShopRepository {
  MockShopRepository() {
    _populateInitialMockProducts();
    _populateMockReviews();
  }

  final _controller = StreamController<List<Product>>.broadcast();
  final _wishlistController = StreamController<List<String>>.broadcast();
  final _reviewsControllers = <String, StreamController<List<Map<String, dynamic>>>>{};
  
  final List<Product> _mockProducts = [];
  final List<String> _wishlistedIds = [];
  final Map<String, List<Map<String, dynamic>>> _mockReviews = {};

  void _populateMockReviews() {
    _mockReviews['prod-1'] = [
      {'id': 'r-1', 'user_id': 'user-1', 'user_name': 'Sarah Jenkins', 'rating': 5, 'comment': 'Stunning design! It looks like an art piece in my living room.', 'created_at': '2026-06-12T10:00:00Z'},
      {'id': 'r-2', 'user_id': 'user-2', 'user_name': 'Michael Chen', 'rating': 4, 'comment': 'Very heavy glass top, but absolute centerpiece.', 'created_at': '2026-05-01T14:30:00Z'},
    ];
    _mockReviews['prod-2'] = [
      {'id': 'r-3', 'user_id': 'user-3', 'user_name': 'David Miller', 'rating': 5, 'comment': 'Extremely comfortable and iconic chair.', 'created_at': '2026-06-15T09:00:00Z'},
    ];
  }

  void _populateInitialMockProducts() {
    _mockProducts.addAll([
      Product(
        id: 'prod-1',
        name: 'Noguchi Coffee Table',
        description: 'Designed by Isamu Noguchi, this table is a masterpiece of modern design, combining an organic wooden base with a thick glass top.',
        price: 780.0,
        imageUrl: 'https://images.unsplash.com/photo-1581428982868-e410dd047a90?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1581428982868-e410dd047a90?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1567538096630-e0c55bd6374c?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800&auto=format&fit=crop&q=80',
        ],
        category: 'Living Room',
        inventoryCount: 4,
        isReserved: false,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'prod-2',
        name: 'Wassily Chair',
        description: 'Designed by Marcel Breuer, this iconic chair features a tubular steel frame with leather straps, offering a sleek modernist aesthetic.',
        price: 950.0,
        imageUrl: 'https://images.unsplash.com/photo-1592078615290-033ee584e267?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1592078615290-033ee584e267?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1616627981762-994a38ebf837?w=800&auto=format&fit=crop&q=80',
        ],
        category: 'Chairs',
        inventoryCount: 2,
        isReserved: false,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'prod-3',
        name: 'Minimalist Oak Bed Frame',
        description: 'Crafted from solid oak wood, this low-profile platform bed frame provides a minimalist, warm, and sturdy foundation for any bedroom.',
        price: 1200.0,
        imageUrl: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1540518614846-7eded433c457?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800&auto=format&fit=crop&q=80',
        ],
        category: 'Bedroom',
        inventoryCount: 3,
        isReserved: false,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'prod-4',
        name: 'Flos Arco Floor Lamp',
        description: 'A revolutionary design featuring a solid marble pedestal and an arched stainless steel stem, perfect for direct lighting over tables.',
        price: 450.0,
        imageUrl: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=800&auto=format&fit=crop&q=80',
        ],
        category: 'Lighting',
        inventoryCount: 8,
        isReserved: false,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'prod-5',
        name: 'Nordic Styled Living Room Set',
        description: 'Get the complete styled look in a single click. This bundle package includes our Noguchi Coffee Table, Wassily Chair, and the Flos Arco Floor Lamp.',
        price: 2100.0,
        imageUrl: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1600210492493-0946911123ea?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1484101403633-562f891dc89a?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1560448204-61dc36dc98c8?w=800&auto=format&fit=crop&q=80',
        ],
        category: 'Bundles',
        inventoryCount: 3,
        isReserved: false,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'prod-6',
        name: 'Modern Bauhaus Dining Set',
        description: 'A curated mid-century dining set featuring a tubular steel dining table and classic Breuer style chairs. Clean, functional, and timeless.',
        price: 1850.0,
        imageUrl: 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=800&auto=format&fit=crop&q=80',
        ],
        category: 'Bundles',
        inventoryCount: 5,
        isReserved: false,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'prod-7',
        name: 'Warm Japandi Bedroom Loft',
        description: 'Blends Japanese minimalism with Scandinavian warmth. Features our solid oak platform frame, linen bedding, and warm paper lamp.',
        price: 2400.0,
        imageUrl: 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=800&auto=format&fit=crop&q=80',
        ],
        category: 'Bundles',
        inventoryCount: 2,
        isReserved: false,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'prod-8',
        name: 'Cozy Rustic Living Room',
        description: 'Bring the charm of rustic style to your space. Features our reclaimed wood coffee table, distressed leather sofa, and vintage rug.',
        price: 3100.0,
        imageUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800&auto=format&fit=crop&q=80',
        ],
        category: 'Bundles',
        inventoryCount: 2,
        isReserved: false,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'prod-9',
        name: 'Urban Industrial Workspace',
        description: 'A productivity-first setup designed with steel and dark wood. Features our adjustable standing desk, ergonomic mesh chair, and smart task light.',
        price: 1450.0,
        imageUrl: 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800&auto=format&fit=crop&q=80',
        ],
        category: 'Bundles',
        inventoryCount: 4,
        isReserved: false,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'prod-10',
        name: 'Minimalist Balcony Garden Set',
        description: 'Transform your outdoor balcony into a serene green escape. Includes weather-resistant teak wood chairs, table, and set of ceramic planters.',
        price: 850.0,
        imageUrl: 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=800&auto=format&fit=crop&q=80',
        ],
        category: 'Bundles',
        inventoryCount: 8,
        isReserved: false,
        createdAt: DateTime.now(),
      ),
    ]);
  }


  void _notifyListeners() {
    _controller.add(List<Product>.from(_mockProducts));
  }

  @override
  Stream<List<Product>> streamProducts() {
    Timer.run(() => _notifyListeners());
    return _controller.stream;
  }

  @override
  Future<Product> reserveProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockProducts.indexWhere((p) => p.id == id);
    if (index == -1) {
      throw Exception('Product not found');
    }
    final current = _mockProducts[index];
    if (current.inventoryCount <= 0) {
      throw Exception('Out of stock');
    }
    final updated = current.copyWith(
      isReserved: true,
      inventoryCount: current.inventoryCount - 1,
    );
    _mockProducts[index] = updated;
    _notifyListeners();
    return updated;
  }

  @override
  Future<void> updateInventory(String id, int quantity) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockProducts.indexWhere((p) => p.id == id);
    if (index != -1) {
      _mockProducts[index] = _mockProducts[index].copyWith(inventoryCount: quantity);
      _notifyListeners();
    }
  }

  @override
  Stream<List<String>> streamWishlist() {
    Timer.run(() => _wishlistController.add(List<String>.from(_wishlistedIds)));
    return _wishlistController.stream;
  }

  @override
  Future<void> toggleWishlist(String productId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_wishlistedIds.contains(productId)) {
      _wishlistedIds.remove(productId);
    } else {
      _wishlistedIds.add(productId);
    }
    _wishlistController.add(List<String>.from(_wishlistedIds));
  }

  @override
  Stream<List<Map<String, dynamic>>> streamReviews(String productId) {
    final controller = _reviewsControllers.putIfAbsent(
      productId,
      () => StreamController<List<Map<String, dynamic>>>.broadcast(),
    );
    Timer.run(() {
      controller.add(List<Map<String, dynamic>>.from(_mockReviews[productId] ?? []));
    });
    return controller.stream;
  }

  @override
  Future<void> addReview(String productId, double rating, String comment) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final list = _mockReviews.putIfAbsent(productId, () => []);
    list.insert(0, {
      'id': 'r-${DateTime.now().millisecondsSinceEpoch}',
      'user_id': 'mock-guest',
      'rating': rating.toInt(),
      'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
    });
    final controller = _reviewsControllers[productId];
    if (controller != null) {
      controller.add(List<Map<String, dynamic>>.from(list));
    }
  }

  @override
  void dispose() {
    _controller.close();
    _wishlistController.close();
    for (final c in _reviewsControllers.values) {
      c.close();
    }
  }
}

// 3. Riverpod Provider definition
final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  ShopRepository repo;
  if (url.isEmpty || anonKey.isEmpty || url.contains('placeholder')) {
    debugPrint('ShopRepository: Using MOCK implementation');
    repo = MockShopRepository();
  } else {
    try {
      final client = SupabaseService.instance.client;
      repo = SupabaseShopRepository(client);
    } catch (e) {
      debugPrint('ShopRepository: Failed to get Supabase client. Falling back to MOCK.');
      repo = MockShopRepository();
    }
  }

  ref.onDispose(() => repo.dispose());

  return repo;
});
