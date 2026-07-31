import 'package:flutter/foundation.dart';

@immutable
class OrderItem {
  final String id;
  final String orderId;
  final String? productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;

  const OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String?,
      name: json['name'] as String? ?? '',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'name': name,
      'unit_price': unitPrice,
      'quantity': quantity,
      'image_url': imageUrl,
    };
  }
}

enum OrderStatus {
  pending,
  quoteSent,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
  refunded;

  String get label => switch (this) {
        OrderStatus.quoteSent => 'Quote Sent',
        OrderStatus.outForDelivery => 'Out for Delivery',
        _ => name[0].toUpperCase() + name.substring(1),
      };

  bool get isActive => this != OrderStatus.cancelled && this != OrderStatus.refunded;

  /// Whether the customer needs to take action (accept/pay the delivery quote).
  bool get awaitingCustomerAction => this == OrderStatus.quoteSent;

  /// Maps legacy DB values to the current enum for backward compatibility.
  /// Maps this enum value to the database column value.
  String get toDbName => name;

  static OrderStatus fromDbName(String name) => switch (name) {
        'paid' => OrderStatus.preparing,
        'processing' => OrderStatus.preparing,
        'shipped' => OrderStatus.outForDelivery,
        'quote_sent' => OrderStatus.quoteSent,
        'out_for_delivery' => OrderStatus.outForDelivery,
        _ => OrderStatus.values.firstWhere(
            (e) => e.name == name,
            orElse: () => OrderStatus.pending,
          ),
      };
}

@immutable
class Order {
  final String id;
  final String customerId;
  final OrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String deliveryAddress;
  final String? deliveryPhone;
  final String? deliveryNote;
  final String? paystackReference;
  final DateTime? paystackPaidAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.customerId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryAddress,
    this.deliveryPhone,
    this.deliveryNote,
    this.paystackReference,
    this.paystackPaidAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json, {List<OrderItem> items = const []}) {
    return Order(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      status: OrderStatus.fromDbName(json['status'] as String? ?? 'pending'),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: json['delivery_address'] as String? ?? '',
      deliveryPhone: json['delivery_phone'] as String?,
      deliveryNote: json['delivery_note'] as String?,
      paystackReference: json['paystack_reference'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      paystackPaidAt: json['paystack_paid_at'] != null
          ? DateTime.parse(json['paystack_paid_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'status': status.name,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total': total,
      'delivery_address': deliveryAddress,
      'delivery_phone': deliveryPhone,
      'delivery_note': deliveryNote,
      'paystack_reference': paystackReference,
      'paystack_paid_at': paystackPaidAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
