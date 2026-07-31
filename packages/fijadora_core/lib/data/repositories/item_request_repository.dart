import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/item_request.dart';
import '../services/supabase_service.dart';
import 'polling_select.dart';

abstract class ItemRequestRepository {
  Stream<List<ItemRequest>> streamCustomerRequests();
  Stream<List<ItemRequest>> streamAllRequests();
  Future<ItemRequest> createRequest({
    required String title,
    required String description,
    String? category,
    String? imageUrl,
  });
  Future<ItemRequest> getRequest(String id);
  Future<String> uploadRequestImage(String fileName, Uint8List fileBytes);
  Future<void> updateStatus(String id, ItemRequestStatus status, {String? linkedProductId});
  Future<void> fulfillRequest(String id, {String? linkedProductId});
}

class SupabaseItemRequestRepository implements ItemRequestRepository {
  SupabaseItemRequestRepository(this._client);
  final sb.SupabaseClient _client;

  @override
  Stream<List<ItemRequest>> streamCustomerRequests() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return pollingSelect<ItemRequest>(
      client: _client,
      table: 'item_requests',
      fromJson: ItemRequest.fromJson,
      eqColumn: 'customer_id',
      eqValue: userId,
      orderBy: 'created_at',
      ascending: false,
    );
  }

  @override
  Stream<List<ItemRequest>> streamAllRequests() {
    return pollingSelect<ItemRequest>(
      client: _client,
      table: 'item_requests',
      fromJson: ItemRequest.fromJson,
      orderBy: 'created_at',
      ascending: false,
    );
  }

  @override
  Future<ItemRequest> createRequest({
    required String title,
    required String description,
    String? category,
    String? imageUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final response = await _client
        .from('item_requests')
        .insert({
          'customer_id': userId,
          'title': title,
          'description': description,
          'category': category,
          'image_url': imageUrl,
          'status': 'open',
        })
        .select()
        .single();
    return ItemRequest.fromJson(response);
  }

  @override
  Future<ItemRequest> getRequest(String id) async {
    final data = await _client.from('item_requests').select().eq('id', id).single();
    return ItemRequest.fromJson(data);
  }

  @override
  Future<String> uploadRequestImage(String fileName, Uint8List fileBytes) async {
    final path = 'item_requests/$fileName';
    await _client.storage.from('product-images').uploadBinary(
      path,
      fileBytes,
      fileOptions: const sb.FileOptions(cacheControl: '3600', upsert: true),
    );
    return _client.storage.from('product-images').getPublicUrl(path);
  }

  @override
  Future<void> updateStatus(String id, ItemRequestStatus status, {String? linkedProductId}) async {
    final update = {'status': status.name};
    if (linkedProductId != null) update['linked_product_id'] = linkedProductId;
    await _client.from('item_requests').update(update).eq('id', id);
  }

  @override
  Future<void> fulfillRequest(String id, {String? linkedProductId}) async {
    final update = {'status': ItemRequestStatus.fulfilled.name};
    if (linkedProductId != null) update['linked_product_id'] = linkedProductId;
    await _client.from('item_requests').update(update).eq('id', id);

    final req = await getRequest(id);
    try {
      await _client.functions.invoke(
        'send-request-fulfilled',
        body: {
          'customerId': req.customerId,
          'requestTitle': req.title,
        },
      );
    } catch (e) {
      // Don't fail the whole operation if email sending fails
    }
  }
}

final itemRequestRepositoryProvider = Provider<ItemRequestRepository>((ref) {
  return SupabaseItemRequestRepository(SupabaseService.instance.client);
});
