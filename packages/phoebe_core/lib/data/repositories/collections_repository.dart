import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/collection.dart';
import '../../domain/models/collection_item.dart';
import '../services/supabase_service.dart';

abstract class CollectionsRepository {
  Stream<List<Collection>> streamCollections();
  Stream<List<Collection>> streamFeaturedCollections();
  Future<void> toggleFollow(String collectionId, String userId);
  Future<void> toggleLike(String collectionId, String userId);
  Future<Collection> createCollection(Collection collection);
  Future<Collection> updateCollection(Collection collection);
  Future<void> deleteCollection(String id);
  Future<String> uploadCoverImage(String fileName, Uint8List fileBytes);
  Future<void> setFeatured(String collectionId, bool isFeatured);
  void dispose();
}

class SupabaseCollectionsRepository implements CollectionsRepository {
  SupabaseCollectionsRepository(this._client);

  final sb.SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _collectionSub;
  final _controller = StreamController<List<Collection>>.broadcast();

  @override
  Stream<List<Collection>> streamCollections() {
    _collectionSub = _client
        .from('collections')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) async {
          try {
            final collections = await _hydrateItems(data);
            if (!_controller.isClosed) {
              _controller.add(collections);
            }
          } catch (e) {
            debugPrint('SupabaseCollectionsRepository - hydrate error: $e');
          }
        }, onError: (e) {
          debugPrint('SupabaseCollectionsRepository - stream error: $e');
        });

    return _controller.stream;
  }

  @override
  Stream<List<Collection>> streamFeaturedCollections() {
    return _controller.stream.map(
      (collections) => collections.where((c) => c.isFeatured).toList()
        ..sort((a, b) => a.featuredOrder.compareTo(b.featuredOrder)),
    );
  }

  Future<List<Collection>> _hydrateItems(List<Map<String, dynamic>> collectionsJson) async {
    return Future.wait(collectionsJson.map((json) async {
      final itemsData = await _client
          .from('collection_items')
          .select()
          .eq('collection_id', json['id'] as String);
      json['items'] = itemsData
          .map((e) => CollectionItem.fromJson(e))
          .toList();
      return Collection.fromJson(json);
    }));
  }

  @override
  Future<void> toggleFollow(String collectionId, String userId) async {
    final existing = await _client
        .from('collection_follows')
        .select('id')
        .eq('user_id', userId)
        .eq('collection_id', collectionId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('collection_follows')
          .delete()
          .eq('user_id', userId)
          .eq('collection_id', collectionId);
      await _client.rpc('decrement_collection_follow', params: {'col_id': collectionId});
    } else {
      await _client.from('collection_follows').insert({
        'user_id': userId,
        'collection_id': collectionId,
      });
      await _client.rpc('increment_collection_follow', params: {'col_id': collectionId});
    }
  }

  @override
  Future<void> toggleLike(String collectionId, String userId) async {
    final existing = await _client
        .from('collection_likes')
        .select('id')
        .eq('user_id', userId)
        .eq('collection_id', collectionId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('collection_likes')
          .delete()
          .eq('user_id', userId)
          .eq('collection_id', collectionId);
      await _client.rpc('decrement_collection_like', params: {'col_id': collectionId});
    } else {
      await _client.from('collection_likes').insert({
        'user_id': userId,
        'collection_id': collectionId,
      });
      await _client.rpc('increment_collection_like', params: {'col_id': collectionId});
    }
  }

  @override
  Future<Collection> createCollection(Collection collection) async {
    final now = DateTime.now();
    final data = {
      'title': collection.title,
      'description': collection.description,
      'cover_image_url': collection.coverImageUrl,
      'creator_id': collection.creatorId,
      'creator_name': collection.creatorName,
      'creator_avatar_url': collection.creatorAvatarUrl,
      'category': collection.category.name,
      'is_public': collection.isPublic,
      'is_featured': collection.isFeatured,
      'featured_order': collection.featuredOrder,
      'created_at': now.toIso8601String(),
    };
    final result = await _client.from('collections').insert(data).select('id').single();
    final id = result['id'] as String;
    for (final item in collection.items) {
      await _client.from('collection_items').insert({
        'collection_id': id,
        'item_type': item.itemType.name,
        'reference_id': item.referenceId,
        'label': item.label,
        'subtitle': item.subtitle,
        'image_url': item.imageUrl,
        'note_content': item.noteContent,
      });
    }
    return collection.copyWith(id: id, createdAt: now);
  }

  @override
  Future<Collection> updateCollection(Collection collection) async {
    await _client.from('collections').update({
      'title': collection.title,
      'description': collection.description,
      'cover_image_url': collection.coverImageUrl,
      'category': collection.category.name,
      'is_public': collection.isPublic,
      'is_featured': collection.isFeatured,
      'featured_order': collection.featuredOrder,
    }).eq('id', collection.id);

    await _client.from('collection_items').delete().eq('collection_id', collection.id);
    for (final item in collection.items) {
      await _client.from('collection_items').insert({
        'collection_id': collection.id,
        'item_type': item.itemType.name,
        'reference_id': item.referenceId,
        'label': item.label,
        'subtitle': item.subtitle,
        'image_url': item.imageUrl,
        'note_content': item.noteContent,
      });
    }
    return collection;
  }

  @override
  Future<void> deleteCollection(String id) async {
    await _client.from('collection_items').delete().eq('collection_id', id);
    await _client.from('collection_follows').delete().eq('collection_id', id);
    await _client.from('collection_likes').delete().eq('collection_id', id);
    await _client.from('collections').delete().eq('id', id);
  }

  @override
  Future<void> setFeatured(String collectionId, bool isFeatured) async {
    await _client.from('collections').update({
      'is_featured': isFeatured,
      'featured_order': isFeatured ? DateTime.now().millisecondsSinceEpoch : 0,
    }).eq('id', collectionId);
  }

  @override
  Future<String> uploadCoverImage(String fileName, Uint8List fileBytes) async {
    final path = 'collection_covers/$fileName';
    await _client.storage.from('product-images').uploadBinary(
      path,
      fileBytes,
      fileOptions: const sb.FileOptions(cacheControl: '3600', upsert: true),
    );
    final url = _client.storage.from('product-images').getPublicUrl(path);
    return url;
  }

  @override
  void dispose() {
    _collectionSub?.cancel();
    _controller.close();
  }
}

// 3. Riverpod Provider definition
final collectionsRepositoryProvider = Provider<CollectionsRepository>((ref) {
  final client = SupabaseService.instance.client;
  final repo = SupabaseCollectionsRepository(client);
  ref.onDispose(() => repo.dispose());
  return repo;
});
