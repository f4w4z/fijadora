import 'dart:async';
import 'dart:typed_data';
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
  Future<Product> createProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(String id);
  Future<String> uploadProductImage(String fileName, Uint8List fileBytes);
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
  Future<Product> createProduct(Product product) async {
    final json = product.toJson();
    if (product.id.isEmpty) {
      json.remove('id');
    }
    json.remove('created_at');
    final response = await _client
        .from('products')
        .insert(json)
        .select()
        .single();
    return Product.fromJson(response);
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final json = product.toJson();
    json.remove('created_at');
    final response = await _client
        .from('products')
        .update(json)
        .eq('id', product.id)
        .select()
        .single();
    return Product.fromJson(response);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client
        .from('products')
        .delete()
        .eq('id', id);
  }

  @override
  Future<String> uploadProductImage(String fileName, Uint8List fileBytes) async {
    final path = 'products/$fileName';
    await _client.storage.from('product-images').uploadBinary(
      path,
      fileBytes,
      fileOptions: const sb.FileOptions(cacheControl: '3600', upsert: true),
    );
    return _client.storage.from('product-images').getPublicUrl(path);
  }

  @override
  void dispose() {}
}

// 3. Riverpod Provider definition
final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  final client = SupabaseService.instance.client;
  final repo = SupabaseShopRepository(client);
  ref.onDispose(() => repo.dispose());
  return repo;
});
