import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/order.dart';
import '../../domain/models/delivery.dart';
import '../../domain/models/product.dart';
import '../services/supabase_service.dart';
import 'polling_select.dart';

class CartLine {
  final Product product;
  final int quantity;
  const CartLine(this.product, this.quantity);
  double get lineTotal => product.price * quantity;
}

abstract class OrderRepository {
  /// Create an order from cart lines. Returns the new order id.
  Future<String> createOrder({
    required List<CartLine> lines,
    required String deliveryAddress,
    String? deliveryPhone,
    String? deliveryNote,
    required double deliveryFee,
  });

  Stream<List<Order>> streamCustomerOrders();
  Stream<List<Order>> streamAllOrders();
  Future<Order?> getOrder(String id);
  Stream<Delivery?> streamDeliveryForOrder(String orderId);

  /// Mark order paid after Paystack verification (also updates ledger).
  Future<void> markOrderPaid(String orderId, String reference);

  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<void> updateDeliveryStatus(String deliveryId, DeliveryStatus status, {String? trackingNote});
  Future<List<OrderItem>> fetchOrderItems(String orderId);
  Future<Order> getOrderWithItems(String orderId);
  Future<void> assignDeliveryWorker(String deliveryId, String workerId);
}

class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository(this._client);
  final sb.SupabaseClient _client;

  @override
  Future<String> createOrder({
    required List<CartLine> lines,
    required String deliveryAddress,
    String? deliveryPhone,
    String? deliveryNote,
    required double deliveryFee,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    if (lines.isEmpty) throw Exception('Cart is empty');

    final subtotal = lines.fold<double>(0, (s, l) => s + l.lineTotal);
    final total = subtotal + deliveryFee;

    final orderResponse = await _client
        .from('orders')
        .insert({
          'customer_id': userId,
          'status': 'pending',
          'subtotal': subtotal,
          'delivery_fee': deliveryFee,
          'total': total,
          'delivery_address': deliveryAddress,
          'delivery_phone': deliveryPhone,
          'delivery_note': deliveryNote,
        })
        .select()
        .single();

    final orderId = orderResponse['id'] as String;

    final items = lines
        .map((l) => {
              'order_id': orderId,
              'product_id': l.product.id,
              'name': l.product.name,
              'unit_price': l.product.price,
              'quantity': l.quantity,
              'image_url': l.product.imageUrl,
            })
        .toList();

    await _client.from('order_items').insert(items);

    // Create a delivery record (Amazon-style delivery).
    await _client.from('deliveries').insert({'order_id': orderId});

    return orderId;
  }

  @override
  Stream<List<Order>> streamCustomerOrders() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return pollingSelect<Order>(
      client: _client,
      table: 'orders',
      fromJson: Order.fromJson,
      eqColumn: 'customer_id',
      eqValue: userId,
      orderBy: 'created_at',
      ascending: false,
    );
  }

  @override
  Stream<List<Order>> streamAllOrders() {
    return pollingSelect<Order>(
      client: _client,
      table: 'orders',
      fromJson: Order.fromJson,
      orderBy: 'created_at',
      ascending: false,
    );
  }

  @override
  Future<Order?> getOrder(String id) async {
    final orderData = await _client.from('orders').select().eq('id', id).single();
    final itemsData = await _client.from('order_items').select().eq('order_id', id);
    final items = (itemsData as List)
        .map((json) => OrderItem.fromJson(json))
        .toList();
    return Order.fromJson(orderData, items: items);
  }

  @override
  Stream<Delivery?> streamDeliveryForOrder(String orderId) {
    return _client
        .from('deliveries')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('created_at', ascending: false)
        .map((data) => data.isEmpty ? null : Delivery.fromJson(data.first));
  }

  @override
  Future<List<OrderItem>> fetchOrderItems(String orderId) async {
    final data = await _client
        .from('order_items')
        .select()
        .eq('order_id', orderId)
        .order('id');
    return (data as List).map((json) => OrderItem.fromJson(json)).toList();
  }

  @override
  Future<Order> getOrderWithItems(String orderId) async {
    final orderData = await _client.from('orders').select().eq('id', orderId).single();
    final items = await fetchOrderItems(orderId);
    return Order.fromJson(orderData, items: items);
  }

  @override
  Future<void> markOrderPaid(String orderId, String reference) async {
    await _client.from('orders').update({
      'status': 'paid',
      'paystack_reference': reference,
      'paystack_paid_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _client.from('orders').update({'status': status.name}).eq('id', orderId);
  }

  @override
  Future<void> updateDeliveryStatus(String deliveryId, DeliveryStatus status, {String? trackingNote}) async {
    final update = {'status': status.name};
    if (trackingNote != null) update['tracking_note'] = trackingNote;
    if (status == DeliveryStatus.delivered) update['delivered_at'] = DateTime.now().toIso8601String();
    await _client.from('deliveries').update(update).eq('id', deliveryId);
  }

  @override
  Future<void> assignDeliveryWorker(String deliveryId, String workerId) async {
    await _client.from('deliveries').update({
      'assigned_worker_id': workerId,
      'status': 'assigned',
    }).eq('id', deliveryId);
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return SupabaseOrderRepository(SupabaseService.instance.client);
});

/// Cached delivery stream for an order. Keeps a single subscription so the
/// delivery tracker doesn't re-subscribe (and re-flicker) on every rebuild.
final deliveryForOrderProvider =
    StreamProvider.family<Delivery?, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).streamDeliveryForOrder(orderId);
});
