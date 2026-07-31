import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/order.dart';
import '../../domain/models/delivery.dart';
import '../../domain/models/product.dart';
import '../services/supabase_service.dart';
import '../services/push_notification_service.dart';
import 'polling_select.dart';

class CartLine {
  final Product product;
  final int quantity;
  const CartLine(this.product, this.quantity);
  double get lineTotal => product.price * quantity;
}

abstract class OrderRepository {
  /// Create an order from cart lines. Delivery fee starts at 0; staff sends a
  /// quote later. Returns the new order id.
  Future<String> createOrder({
    required List<CartLine> lines,
    required String deliveryAddress,
    String? deliveryPhone,
    String? deliveryNote,
  });

  Stream<List<Order>> streamCustomerOrders();
  Stream<List<Order>> streamAllOrders();
  Future<Order?> getOrder(String id);
  Stream<Delivery?> streamDeliveryForOrder(String orderId);

  /// Staff sets the delivery fee and sends the quote to the customer.
  Future<void> sendDeliveryQuote(String orderId, double deliveryFee);

  /// Customer accepts the delivery quote (no online payment).
  Future<void> acceptDeliveryQuote(String orderId);

  /// Mark order paid after Paystack verification (also updates ledger).
  Future<void> markOrderPaid(String orderId, String reference);

  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<void> rejectOrder(String orderId, String reason);
  Future<void> updateDeliveryStatus(String deliveryId, DeliveryStatus status, {String? trackingNote, String? trackingId, String? trackingCompany});
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
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    if (lines.isEmpty) throw Exception('Cart is empty');

    final subtotal = lines.fold<double>(0, (s, l) => s + l.lineTotal);

    final orderResponse = await _client
        .from('orders')
        .insert({
          'customer_id': userId,
          'status': 'pending',
          'subtotal': subtotal,
          'delivery_fee': 0,
          'total': subtotal,
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
      'status': 'preparing',
      'paystack_reference': reference,
      'paystack_paid_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);

    PushNotificationService.sendNotification(
      role: 'admin',
      title: 'New Paid Order',
      body: 'Order #${orderId.substring(0, 8).toUpperCase()} has been paid and is ready to process.',
      data: {'route': '/orders', 'order_id': orderId},
    );
  }

  @override
  Future<void> sendDeliveryQuote(String orderId, double deliveryFee) async {
    // Fetch subtotal to recalculate total.
    final row = await _client.from('orders').select('subtotal').eq('id', orderId).single();
    final subtotal = (row['subtotal'] as num?)?.toDouble() ?? 0;
    final total = subtotal + deliveryFee;

    await _client.from('orders').update({
      'delivery_fee': deliveryFee,
      'total': total,
      'status': 'quoteSent',
    }).eq('id', orderId);

    // Notify customer.
    final order = await getOrderWithItems(orderId);
    PushNotificationService.sendNotification(
      userId: order.customerId,
      title: 'Delivery Quote Ready',
      body: 'Your order #${orderId.substring(0, 8).toUpperCase()} has a delivery fee of \$${deliveryFee.toStringAsFixed(0)}. Open the app to review and pay.',
    );
  }

  @override
  Future<void> acceptDeliveryQuote(String orderId) async {
    await _client.from('orders').update({
      'status': 'preparing',
    }).eq('id', orderId);

    // Notify staff/admin that customer accepted.
    PushNotificationService.sendNotification(
      role: 'admin',
      title: 'Order Accepted',
      body: 'Customer has accepted the delivery quote for order #${orderId.substring(0, 8).toUpperCase()}.',
    );
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _client.from('orders').update({'status': status.name}).eq('id', orderId);
    _notifyCustomer(orderId, _orderNotificationContent(status));
  }

  @override
  Future<void> rejectOrder(String orderId, String reason) async {
    await _client.from('orders').update({
      'status': 'cancelled',
      'rejection_reason': reason,
    }).eq('id', orderId);
    _notifyCustomer(orderId, ('Order Rejected', 'Your order was rejected: $reason'));
  }

  Future<void> _notifyCustomer(String orderId, (String, String) notif) async {
    try {
      final order = await _client.from('orders').select('customer_id').eq('id', orderId).single();
      if (order['customer_id'] != null) {
        PushNotificationService.sendNotification(
          userId: order['customer_id'] as String,
          title: notif.$1,
          body: notif.$2,
        );
      }
    } catch (_) {}
  }

  (String, String) _orderNotificationContent(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending       => ('Order Placed', 'Your order has been received.'),
      OrderStatus.preparing     => ('Preparing Order', 'Your order is being prepared.'),
      OrderStatus.outForDelivery => ('Out for Delivery', 'Your order is on its way!'),
      OrderStatus.delivered     => ('Delivered', 'Your order has been delivered. Enjoy!'),
      OrderStatus.quoteSent     => ('Quote Sent', 'A delivery quote has been sent for your order.'),
      OrderStatus.cancelled     => ('Order Cancelled', 'Your order has been cancelled.'),
      OrderStatus.refunded      => ('Refunded', 'Your order has been refunded.'),
    };
  }

  @override
  Future<void> updateDeliveryStatus(String deliveryId, DeliveryStatus status, {String? trackingNote, String? trackingId, String? trackingCompany}) async {
    final update = {'status': status.name};
    if (trackingNote != null) update['tracking_note'] = trackingNote;
    if (trackingId != null) update['tracking_id'] = trackingId;
    if (trackingCompany != null) update['tracking_company'] = trackingCompany;
    if (status == DeliveryStatus.delivered) update['delivered_at'] = DateTime.now().toIso8601String();
    await _client.from('deliveries').update(update).eq('id', deliveryId);

    // Notify customer about delivery status change
    try {
      final delivery = await _client.from('deliveries').select('order_id').eq('id', deliveryId).single();
      if (delivery['order_id'] != null) {
        final order = await _client.from('orders').select('customer_id').eq('id', delivery['order_id'] as String).single();
        if (order['customer_id'] != null) {
          final (title, body) = _deliveryNotificationContent(status, trackingId, trackingCompany);
          PushNotificationService.sendNotification(
            userId: order['customer_id'] as String,
            title: title,
            body: body,
          );
        }
      }
    } catch (_) {} // notification is best-effort
  }

  (String, String) _deliveryNotificationContent(DeliveryStatus status, String? trackingId, String? trackingCompany) {
    return switch (status) {
      DeliveryStatus.assigned    => ('Order Packed', 'Your package has been handed to the courier.'),
      DeliveryStatus.inTransit   => (trackingCompany != null
          ? 'In Transit via $trackingCompany'
          : 'In Transit',
          trackingId != null
          ? 'Track: $trackingId'
          : 'Your order is on its way!'),
      DeliveryStatus.delivered   => ('Delivered', 'Your order has been delivered. Enjoy!'),
      DeliveryStatus.pickedUp    => ('Packing Complete', 'Your items are being prepared for shipping.'),
      DeliveryStatus.failed      => ('Delivery Failed', 'There was an issue with delivery. Contact support.'),
      _                          => ('Order Update', 'Your order status has been updated.'),
    };
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
